#!/usr/bin/env bash
set -euo pipefail

for name in AWS_REGION ECS_CLUSTER BACKEND_TASK_FAMILY MIGRATION_TASK_FAMILY BACKEND_CONTAINER_NAME IMAGE_URI MIGRATION_SUBNETS MIGRATION_SECURITY_GROUPS; do
  if [[ -z "${!name:-}" ]]; then
    echo "Required environment variable $name is not set." >&2
    exit 1
  fi
done

subnets_json="$(
  jq -ce '
    if type == "array" and length > 0 and all(.[]; type == "string" and length > 0)
    then .
    else error("MIGRATION_SUBNETS must be a non-empty JSON string array")
    end
  ' <<< "$MIGRATION_SUBNETS"
)"

security_groups_json="$(
  jq -ce '
    if type == "array" and length > 0 and all(.[]; type == "string" and length > 0)
    then .
    else error("MIGRATION_SECURITY_GROUPS must be a non-empty JSON string array")
    end
  ' <<< "$MIGRATION_SECURITY_GROUPS"
)"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

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
  --argjson subnets "$subnets_json" \
  --argjson security_groups "$security_groups_json" '
    {
      cluster: $cluster,
      taskDefinition: $task_definition,
      launchType: "FARGATE",
      count: 1,
      networkConfiguration: {
        awsvpcConfiguration: {
          subnets: $subnets,
          securityGroups: $security_groups,
          assignPublicIp: "DISABLED"
        }
      }
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
