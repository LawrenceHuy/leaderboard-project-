#!/usr/bin/env bash
# Cach dung: ./run_test.sh <ten_lan> <threads>
export AWS_PAGER=""
NAME=${1:?Thieu ten lan}; TH=${2:-20}
START=$(date +%s000)
echo "Start: $(date -u +%FT%TZ)  Account: $(aws sts get-caller-identity --query Account --output text)  Region: us-east-1"
python3 simulate.py --players 1000 --rounds 5 --threads $TH | tee run_${NAME}.txt
sleep 10
END=$(date +%s000)
echo "End: $(date -u +%FT%TZ)"
N=$(aws logs filter-log-events --log-group-name /aws/lambda/stream_processor \
  --filter-pattern ConditionalCheckFailed --start-time $START --end-time $END \
  --query 'length(events)' --output text)
echo "So dong ConditionalCheckFailed trong khoang chay: $N" | tee -a run_${NAME}.txt
