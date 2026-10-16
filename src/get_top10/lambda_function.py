import os, json, boto3
from decimal import Decimal

table = boto3.resource("dynamodb").Table(os.environ.get("LEADERBOARD_TABLE", "Leaderboard"))


def _default(o):
    if isinstance(o, Decimal):
        return int(o) if o % 1 == 0 else float(o)
    raise TypeError


def lambda_handler(event, context):
    item = table.get_item(Key={"boardId": "GLOBAL"}).get("Item", {})
    body = {"top": item.get("top", [])[:10], "updatedAt": item.get("updatedAt")}
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps(body, default=_default),
    }
