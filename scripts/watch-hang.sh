#!/usr/bin/env bash
# Watch opencode background server; capture stack when /api/info hangs.
# Usage: nohup scripts/watch-hang.sh >/tmp/opencode/watch.log 2>&1 &
set -u
OUT=/tmp/opencode/hang
mkdir -p "$OUT"
fails=0
while true; do
  python3 - <<'EOF' > /tmp/opencode/probe.txt 2>/dev/null
import json,urllib.request,base64,time
s=json.load(open('/home/YOURUSER/.local/state/opencode/service.json'))
auth=base64.b64encode(f"opencode:{s['password']}".encode()).decode()
req=urllib.request.Request(s['url']+'/api/info',headers={'Authorization':'Basic '+auth})
t=time.time()
try:
    urllib.request.urlopen(req,timeout=2.0).read()
    print(f"{time.time()-t:.3f} {s['pid']} ok")
except Exception as e:
    print(f"{time.time()-t:.3f} {s['pid']} {type(e).__name__}")
EOF
  read -r dt pid st < /tmp/opencode/probe.txt || { sleep 2; continue; }
  if [ "$st" != "ok" ]; then
    fails=$((fails+1))
  else
    fails=0
  fi
  ts=$(date +%Y%m%dT%H%M%S)
  if [ "$fails" -eq 2 ]; then
    {
      echo "=== hang detected $ts pid=$pid probe=$dt ==="
      ps -o pid,ppid,stat,pcpu,pmem,etime,time,rss,wchan:32,cmd -p "$pid"
      echo "--- threads state ---"
      for t in /proc/$pid/task/*; do awk '{print $1,$3,$14,$15}' "$t/stat" 2>/dev/null; done | head -60
      echo "--- eu-stack ---"
      timeout 10 eu-stack -p "$pid" 2>&1 | head -200
      echo "--- gdb bt all ---"
      timeout 25 gdb -p "$pid" -batch -ex 'set pagination off' -ex 'thread apply all bt 25' 2>&1 | grep -v '^\[New LWP' | head -300
      echo "--- last log lines ---"
      tail -25 /home/YOURUSER/.local/share/opencode/log/opencode.log
    } > "$OUT/hang-$ts.txt" 2>&1
    echo "$ts hang captured pid=$pid"
    sleep 20
    fails=0
  fi
  sleep 1
done
