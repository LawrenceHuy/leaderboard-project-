#!/usr/bin/env bash
# Cach dung: ./deploy.sh <Owner> [hau_to_bucket]
#   vi du: ./deploy.sh CaoGiaHuy        |  ./deploy.sh HieuNghia
#   neu ten bucket vua xoa bi OperationAborted: ./deploy.sh CaoGiaHuy v2
set -euo pipefail
export AWS_PAGER="" AWS_DEFAULT_REGION=us-east-1
cd "$(dirname "$0")/../.."          # ve thu muc goc repo
OWNER="${1:?Thieu Owner, vd: ./deploy.sh CaoGiaHuy}"
SUFFIX="${2:-}"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/LabRole"
BUCKET="$(echo "$OWNER" | tr A-Z a-z)-leaderboard-web-${ACCOUNT}${SUFFIX:+-$SUFFIX}"
SITE="http://${BUCKET}.s3-website-us-east-1.amazonaws.com"
echo "== Deploy: Owner=$OWNER Account=$ACCOUNT Bucket=$BUCKET =="

echo "[1/7] DynamoDB"
aws dynamodb create-table --table-name Scores \
  --attribute-definitions AttributeName=playerId,AttributeType=S \
  --key-schema AttributeName=playerId,KeyType=HASH --billing-mode PAY_PER_REQUEST \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES \
  --tags Key=Project,Value=Leaderboard Key=Owner,Value=$OWNER >/dev/null
aws dynamodb create-table --table-name Leaderboard \
  --attribute-definitions AttributeName=boardId,AttributeType=S \
  --key-schema AttributeName=boardId,KeyType=HASH --billing-mode PAY_PER_REQUEST \
  --tags Key=Project,Value=Leaderboard Key=Owner,Value=$OWNER >/dev/null
aws dynamodb wait table-exists --table-name Scores
aws dynamodb wait table-exists --table-name Leaderboard
STREAM_ARN=$(aws dynamodb describe-table --table-name Scores --query Table.LatestStreamArn --output text)

echo "[2/7] Lambda + log retention"
for fn in stream_processor get_top10; do
  rm -f /tmp/$fn.zip
  zip -q -j /tmp/$fn.zip src/$fn/lambda_function.py
  aws lambda create-function --function-name $fn --runtime python3.12 \
    --handler lambda_function.lambda_handler --role "$ROLE_ARN" --timeout 30 \
    --zip-file fileb:///tmp/$fn.zip \
    --environment "Variables={LEADERBOARD_TABLE=Leaderboard}" \
    --tags Project=Leaderboard,Owner=$OWNER >/dev/null
  aws lambda wait function-active-v2 --function-name $fn
  aws logs create-log-group --log-group-name /aws/lambda/$fn \
    --tags Project=Leaderboard,Owner=$OWNER 2>/dev/null || true
  aws logs put-retention-policy --log-group-name /aws/lambda/$fn --retention-in-days 7
done

echo "[3/7] Event source mapping + reserved concurrency"
UUID=$(aws lambda create-event-source-mapping --function-name stream_processor \
  --event-source-arn "$STREAM_ARN" --starting-position LATEST --batch-size 10 \
  --maximum-batching-window-in-seconds 1 --maximum-retry-attempts 3 \
  --bisect-batch-on-function-error --tags Project=Leaderboard,Owner=$OWNER \
  --query UUID --output text)
aws lambda put-function-concurrency --function-name stream_processor --reserved-concurrent-executions 10 >/dev/null
for i in $(seq 1 30); do
  STATE=$(aws lambda get-event-source-mapping --uuid "$UUID" --query State --output text)
  [ "$STATE" = "Enabled" ] && break; sleep 2
done
echo "    Mapping state: $STATE"
[ "$STATE" = "Enabled" ] || { echo "CANH BAO: mapping khong Enabled"; aws lambda get-event-source-mapping --uuid "$UUID" --query "[State,LastProcessingResult]"; }

echo "[4/7] HTTP API (CORS hep + throttling)"
API_ID=$(aws apigatewayv2 create-api --name leaderboard-api --protocol-type HTTP \
  --cors-configuration AllowOrigins=$SITE,AllowMethods=GET \
  --tags Project=Leaderboard,Owner=$OWNER --query ApiId --output text)
FN_ARN=$(aws lambda get-function --function-name get_top10 --query Configuration.FunctionArn --output text)
INT_ID=$(aws apigatewayv2 create-integration --api-id "$API_ID" --integration-type AWS_PROXY \
  --integration-uri "$FN_ARN" --payload-format-version 2.0 --query IntegrationId --output text)
aws apigatewayv2 create-route --api-id "$API_ID" --route-key "GET /top10" --target integrations/$INT_ID >/dev/null
aws apigatewayv2 create-stage --api-id "$API_ID" --stage-name '$default' --auto-deploy \
  --default-route-settings ThrottlingBurstLimit=20,ThrottlingRateLimit=10 \
  --tags Project=Leaderboard,Owner=$OWNER >/dev/null
aws lambda add-permission --function-name get_top10 --statement-id apigw \
  --action lambda:InvokeFunction --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:${ACCOUNT}:${API_ID}/*/*/top10" >/dev/null
API_URL="https://${API_ID}.execute-api.us-east-1.amazonaws.com/top10"

echo "[5/7] S3 web"
aws s3api create-bucket --bucket "$BUCKET" >/dev/null
aws s3api put-bucket-tagging --bucket "$BUCKET" \
  --tagging "TagSet=[{Key=Project,Value=Leaderboard},{Key=Owner,Value=$OWNER}]"
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
aws s3api put-bucket-policy --bucket "$BUCKET" --policy \
  "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::${BUCKET}/*\"}]}"
aws s3 website "s3://$BUCKET/" --index-document index.html
sed "s|__API_URL__|$API_URL|" web/index.html > /tmp/index.html
aws s3 cp /tmp/index.html "s3://$BUCKET/index.html" --content-type text/html >/dev/null

echo "[6/7] CloudWatch dashboard + alarm"
aws cloudwatch put-dashboard --dashboard-name Leaderboard --dashboard-body file://docs/scripts/dashboard.json >/dev/null
for m in Errors Throttles; do
  aws cloudwatch put-metric-alarm --alarm-name leaderboard-stream-$m \
    --namespace AWS/Lambda --metric-name $m --dimensions Name=FunctionName,Value=stream_processor \
    --statistic Sum --period 60 --evaluation-periods 1 --threshold 0 \
    --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching \
    --tags Key=Project,Value=Leaderboard Key=Owner,Value=$OWNER
done

echo "Cho 45s de stream reader san sang"; sleep 45
echo "[7/7] Kiem tra nhanh"
sleep 5
curl -s -o /dev/null -w "API /top10 -> HTTP %{http_code}\n" "$API_URL"
curl -s -o /dev/null -w "Web index  -> HTTP %{http_code}\n" "$SITE/index.html"
echo "API: $API_URL"
echo "WEB: $SITE"
echo "Luu y: simulate.py dung bang Scores/Leaderboard, khong phu thuoc API/bucket."
