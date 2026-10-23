#!/usr/bin/env bash
# Cach dung: ./cleanup.sh <Owner> [hau_to_bucket]   (cung tham so voi deploy.sh)
export AWS_PAGER="" AWS_DEFAULT_REGION=us-east-1
OWNER="${1:?Thieu Owner}"; SUFFIX="${2:-}"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET="$(echo "$OWNER" | tr A-Z a-z)-leaderboard-web-${ACCOUNT}${SUFFIX:+-$SUFFIX}"
echo "== Cleanup: Owner=$OWNER Account=$ACCOUNT Bucket=$BUCKET =="

for u in $(aws lambda list-event-source-mappings --function-name stream_processor \
           --query 'EventSourceMappings[].UUID' --output text 2>/dev/null); do
  aws lambda delete-event-source-mapping --uuid "$u" >/dev/null || true
done
for id in $(aws apigatewayv2 get-apis --query "Items[?Name=='leaderboard-api'].ApiId" --output text); do
  aws apigatewayv2 delete-api --api-id "$id" || true
done
for fn in stream_processor get_top10; do
  aws lambda delete-function --function-name $fn || true
  aws logs delete-log-group --log-group-name /aws/lambda/$fn || true
done
aws s3 rb "s3://$BUCKET" --force || true
aws dynamodb delete-table --table-name Scores >/dev/null || true
aws dynamodb delete-table --table-name Leaderboard >/dev/null || true
aws cloudwatch delete-alarms --alarm-names leaderboard-stream-Errors leaderboard-stream-Throttles || true
aws cloudwatch delete-dashboards --dashboard-names Leaderboard || true
aws dynamodb wait table-not-exists --table-name Scores 2>/dev/null || true
aws dynamodb wait table-not-exists --table-name Leaderboard 2>/dev/null || true

echo "== Con lai (phai rong) =="
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=Leaderboard \
  --query "ResourceTagMappingList[].ResourceARN" --output text
