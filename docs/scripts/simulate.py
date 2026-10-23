import boto3, random, time, argparse
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor

p = argparse.ArgumentParser()
p.add_argument("--players", type=int, default=1000)
p.add_argument("--rounds", type=int, default=5)
p.add_argument("--threads", type=int, default=20)
a = p.parse_args()

ddb = boto3.resource("dynamodb", region_name="us-east-1")
scores_tbl, board_tbl = ddb.Table("Scores"), ddb.Table("Leaderboard")
scores = {f"player{i:04d}": 0 for i in range(a.players)}


def update(pid):
    scores[pid] += random.randint(10, 500)
    scores_tbl.put_item(Item={"playerId": pid, "score": scores[pid],
                              "updatedAt": datetime.now(timezone.utc).isoformat()})


start = time.time()
for r in range(a.rounds):
    with ThreadPoolExecutor(a.threads) as ex:
        list(ex.map(update, list(scores)))
    print(f"round {r+1}/{a.rounds} done")
    time.sleep(1)
print(f"Tong thoi gian ghi: {time.time()-start:.1f}s")

time.sleep(5)
expected = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:10]
actual = board_tbl.get_item(Key={"boardId": "GLOBAL"})["Item"]["top"]
print("Expected:", expected[:3], "...")
print("Actual  :", [(e["playerId"], int(e["score"])) for e in actual][:3], "...")
print("MATCH" if [k for k, _ in expected] == [e["playerId"] for e in actual] else "MISMATCH")
