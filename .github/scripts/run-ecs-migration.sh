#!/usr/bin/env bash
set -euo pipefail

for name in AWS_REGION ECS_CLUSTER BACKEND_ECS_SERVICE BACKEND_TASK_FAMILY MIGRATION_TASK_FAMILY BACKEND_CONTAINER_NAME IMAGE_URI; do
  if [[ -z "${!name:-}" ]]; then
    echo "Required environment variable $name is not set." >&2
    exit 1
  fi
done

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

aws ecs describe-services \
  --region "$AWS_REGION" \
  --cluster "$ECS_CLUSTER" \
  --services "$BACKEND_ECS_SERVICE" \
  --output json > "$work_dir/backend-service.json"

if ! jq -e --arg service "$BACKEND_ECS_SERVICE" '
  ([.services[] | select(.serviceName == $service and .status == "ACTIVE")] | length) == 1
' "$work_dir/backend-service.json" >/dev/null; then
  echo "Expected exactly one ACTIVE ECS service named $BACKEND_ECS_SERVICE." >&2
  jq '.failures' "$work_dir/backend-service.json" >&2
  exit 1
fi

network_configuration="$(
  jq -ce --arg service "$BACKEND_ECS_SERVICE" '
    [.services[] | select(.serviceName == $service)][0]
    | .networkConfiguration.awsvpcConfiguration
    | if (.subnets | length) > 0 and (.securityGroups | length) > 0
      then .
      else error("Backend service has no subnet or security-group configuration")
      end
  ' "$work_dir/backend-service.json"
)"

aws ecs describe-task-definition \
  --region "$AWS_REGION" \
  --task-definition "$BACKEND_TASK_FAMILY" \
  --query 'taskDefinition' \
  --output json > "$work_dir/backend-task-definition.json"

if ! jq -e --arg name "$BACKEND_CONTAINER_NAME" \
  '([.containerDefinitions[] | select(.name == $name)] | length) == 1' \
  "$work_dir/backend-task-definition.json" >/dev/null; then
  echo "Expected exactly one container named $BACKEND_CONTAINER_NAME in $BACKEND_TASK_FAMILY." >&2
  exit 1
fi

jq \
  --arg family "$MIGRATION_TASK_FAMILY" \
  --arg name "$BACKEND_CONTAINER_NAME" \
  --arg image "$IMAGE_URI" '
    del(
      .taskDefinitionArn,
      .revision,
      .status,
      .requiresAttributes,
      .compatibilities,
      .registeredAt,
      .registeredBy
    )
    | .family = $family
    | .containerDefinitions |= map(
        if .name == $name then
          .image = $image
          | .command = ["node", "scripts/migrate.js", "up"]
        else
          .
        end
      )
  ' "$work_dir/backend-task-definition.json" > "$work_dir/migration-task-definition.json"

migration_task_definition_arn="$(
  aws ecs register-task-definition \
    --region "$AWS_REGION" \
    --cli-input-json "file://$work_dir/migration-task-definition.json" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text
)"

jq -n \
  --arg cluster "$ECS_CLUSTER" \
  --arg task_definition "$migration_task_definition_arn" \
  --argjson network "$network_configuration" '
    {
      cluster: $cluster,
      taskDefinition: $task_definition,
      launchType: "FARGATE",
      count: 1,
      networkConfiguration: { awsvpcConfiguration: $network }
    }
  ' > "$work_dir/run-task.json"

aws ecs run-task \
  --region "$AWS_REGION" \
  --cli-input-json "file://$work_dir/run-task.json" \
  --output json > "$work_dir/run-task-response.json"

task_arn="$(jq -r '.tasks[0].taskArn // empty' "$work_dir/run-task-response.json")"
failure_count="$(jq -r '.failures | length' "$work_dir/run-task-response.json")"

if [[ -z "$task_arn" || "$failure_count" != "0" ]]; then
  echo "ECS could not start the migration task." >&2
  jq '.failures' "$work_dir/run-task-response.json" >&2
  exit 1
fi

echo "Waiting for migration task $task_arn to stop."
aws ecs wait tasks-stopped \
  --region "$AWS_REGION" \
  --cluster "$ECS_CLUSTER" \
  --tasks "$task_arn"

aws ecs describe-tasks \
  --region "$AWS_REGION" \
  --cluster "$ECS_CLUSTER" \
  --tasks "$task_arn" \
  --output json > "$work_dir/task-result.json"

exit_code="$(
  jq -r --arg name "$BACKEND_CONTAINER_NAME" '
    [.tasks[0].containers[] | select(.name == $name)][0].exitCode // "missing"
  ' "$work_dir/task-result.json"
)"

if [[ "$exit_code" != "0" ]]; then
  stopped_reason="$(jq -r '.tasks[0].stoppedReason // "No stopped reason reported."' "$work_dir/task-result.json")"
  container_reason="$(
    jq -r --arg name "$BACKEND_CONTAINER_NAME" '
      [.tasks[0].containers[] | select(.name == $name)][0].reason // ""
    ' "$work_dir/task-result.json"
  )"
  echo "Database migration failed with exit code $exit_code." >&2
  echo "Stopped reason: $stopped_reason" >&2
  if [[ -n "$container_reason" ]]; then
    echo "Container reason: $container_reason" >&2
  fi
  exit 1
fi

echo "Database migration completed successfully."
