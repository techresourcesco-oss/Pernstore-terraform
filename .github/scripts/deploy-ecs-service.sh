#!/usr/bin/env bash
set -euo pipefail

for name in AWS_REGION ECS_CLUSTER ECS_SERVICE TASK_FAMILY CONTAINER_NAME IMAGE_URI; do
  if [[ -z "${!name:-}" ]]; then
    echo "Required environment variable $name is not set." >&2
    exit 1
  fi
done

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

aws ecs describe-task-definition \
  --region "$AWS_REGION" \
  --task-definition "$TASK_FAMILY" \
  --query 'taskDefinition' \
  --output json > "$work_dir/current-task-definition.json"

if ! jq -e --arg name "$CONTAINER_NAME" \
  '([.containerDefinitions[] | select(.name == $name)] | length) == 1' \
  "$work_dir/current-task-definition.json" >/dev/null; then
  echo "Expected exactly one container named $CONTAINER_NAME in $TASK_FAMILY." >&2
  exit 1
fi

jq --arg name "$CONTAINER_NAME" --arg image "$IMAGE_URI" '
  del(
    .taskDefinitionArn,
    .revision,
    .status,
    .requiresAttributes,
    .compatibilities,
    .registeredAt,
    .registeredBy
  )
  | .containerDefinitions |= map(
      if .name == $name then .image = $image else . end
    )
' "$work_dir/current-task-definition.json" > "$work_dir/new-task-definition.json"

new_task_definition_arn="$(
  aws ecs register-task-definition \
    --region "$AWS_REGION" \
    --cli-input-json "file://$work_dir/new-task-definition.json" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text
)"

aws ecs update-service \
  --region "$AWS_REGION" \
  --cluster "$ECS_CLUSTER" \
  --service "$ECS_SERVICE" \
  --task-definition "$new_task_definition_arn" >/dev/null

aws ecs wait services-stable \
  --region "$AWS_REGION" \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE"

aws ecs describe-services \
  --region "$AWS_REGION" \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --output json > "$work_dir/service.json"

primary_task_definition_arn="$(
  jq -r '
    .services[0].deployments[]
    | select(.status == "PRIMARY")
    | .taskDefinition
  ' "$work_dir/service.json"
)"

if [[ "$primary_task_definition_arn" != "$new_task_definition_arn" ]]; then
  echo "ECS PRIMARY deployment does not use the newly registered task definition." >&2
  echo "Expected: $new_task_definition_arn" >&2
  echo "Actual:   $primary_task_definition_arn" >&2
  exit 1
fi

echo "Service $ECS_SERVICE is stable on $new_task_definition_arn."
