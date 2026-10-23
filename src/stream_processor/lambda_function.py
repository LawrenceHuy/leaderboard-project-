import os, time, logging
from datetime import datetime, timezone
import boto3
from boto3.dynamodb.types import TypeDeserializer
from botocore.exceptions import ClientError

log = logging.getLogger()
log.setLevel(logging.INFO)
table = boto3.resource("dynamodb").Table(os.environ.get("LEADERBOARD_TABLE", "Leaderboard"))
deser = TypeDeserializer()
BOARD_ID, TOP_N = "GLOBAL", 10


def update_board(latest):
    item = table.get_item(Key={"boardId": BOARD_ID}, ConsistentRead=True).get("Item")
    version = int(item["version"]) if item else 0
    board = {e["playerId"]: e["score"] for e in (item["top"] if item else [])}
    board.update(latest)
    top = sorted(board.items(), key=lambda x: x[1], reverse=True)[:TOP_N]
    new_item = {
        "boardId": BOARD_ID,
        "top": [{"playerId": p, "score": s} for p, s in top],
        "version": version + 1,
        "updatedAt": datetime.now(timezone.utc).isoformat(),
    }
    kwargs = {"Item": new_item}
    if item:
        kwargs["ConditionExpression"] = "version = :v"
        kwargs["ExpressionAttributeValues"] = {":v": version}
    else:
        kwargs["ConditionExpression"] = "attribute_not_exists(boardId)"
    table.put_item(**kwargs)


def lambda_handler(event, context):
    latest = {}
    for r in event["Records"]:
        if r["eventName"] not in ("INSERT", "MODIFY"):
            continue
        img = {k: deser.deserialize(v) for k, v in r["dynamodb"]["NewImage"].items()}
        latest[img["playerId"]] = img["score"]
    if not latest:
        return {"processed": 0}

    for attempt in range(6):
        try:
            update_board(latest)
            log.info("processed %d players", len(latest))
            return {"processed": len(latest)}
        except ClientError as e:
            if e.response["Error"]["Code"] != "ConditionalCheckFailedException":
                raise
            log.warning("ConditionalCheckFailed attempt=%d players=%d", attempt + 1, len(latest))
            time.sleep(0.05 * 2 ** attempt)
    raise RuntimeError("Khong ghi duoc Leaderboard sau nhieu lan thu")
