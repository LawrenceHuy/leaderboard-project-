import boto3, random, time, argparse
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor
from botocore.config import Config

p = argparse.ArgumentParser()
p.add_argument("--players", type=int, default=1000)
p.add_argument("--rounds", type=int, default=5)
p.add_argument("--threads", type=int, default=20)
a = p.parse_args()

ddb = boto3.client("dynamodb", region_name="us-east-1",
                   config=Config(max_pool_connections=max(50, a.threads),
                                 retries={"max_attempts": 10}))
scores = {f"player{i:04d}": 0 for i in range(a.players)}
lat = []

def update(pid):
    scores[pid] += random.randint(10, 500)  # chi tang diem
    t = time.time()
    ddb.put_item(TableName="Scores", Item={
        "playerId": {"S": pid},
        "score": {"N": str(scores[pid])},
        "updatedAt": {"S": datetime.now(timezone.utc).isoformat()}})
    lat.append(time.time() - t)

def read_board():
    item = ddb.get_item(TableName="Leaderboard", Key={"boardId": {"S": "GLOBAL"}},
                        ConsistentRead=True).get("Item")
    if not item:
        return 0, []
    top = [(e["M"]["playerId"]["S"], int(e["M"]["score"]["N"])) for e in item["top"]["L"]]
    return int(item["version"]["N"]), top

# xoa du lieu cu de khong lan giua cac lan chay
ddb.delete_item(TableName="Leaderboard", Key={"boardId": {"S": "GLOBAL"}})

t0 = time.time()
for r in range(a.rounds):
    with ThreadPoolExecutor(a.threads) as ex:
        list(ex.map(update, list(scores)))
    print(f"round {r+1}/{a.rounds} done")
    time.sleep(1)
write_end = time.time()
write_time = write_end - t0

# cho Lambda xu ly xong: version khong doi 4 giay lien tiep (toi da 60s)
last, stable, waited, last_change = -1, 0, 0, write_end
while stable < 4 and waited < 60:
    v, _ = read_board()
    if v != last:
        stable, last_change = 0, time.time()
    else:
        stable += 1
    last = v; waited += 1; time.sleep(1)
drain = max(0.0, last_change - write_end)

version, actual = read_board()
expected = sorted(scores.items(), key=lambda x: (-x[1], x[0]))[:10]
exp_scores = [s for _, s in expected]
act_scores = [s for _, s in actual]
pairs_ok = all(scores.get(pid) == s for pid, s in actual)

lat.sort()
print(f"Threads         : {a.threads}")
print(f"Tong so lan ghi : {a.players * a.rounds}")
print(f"Thoi gian ghi   : {write_time:.1f}s (phia client)")
print(f"Do tre moi lan ghi: TB {sum(lat)/len(lat)*1000:.0f}ms, p95 {lat[int(len(lat)*0.95)]*1000:.0f}ms, max {lat[-1]*1000:.0f}ms")
print(f"Lambda xu ly them sau khi ghi xong: {drain:.1f}s")
print(f"Version cuoi    : {version}")
print("Expected:", expected[:3], "...")
print("Actual  :", actual[:3], "...")
print("MATCH" if exp_scores == act_scores and pairs_ok else "MISMATCH")
