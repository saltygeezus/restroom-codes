#!/bin/bash
# Restart the app server on port 8765
cd /workspace/restroom-codes
pkill -f "restroom-codes/server.py"; sleep 0.5
nohup python3 /workspace/restroom-codes/server.py > server.log 2>&1 &
sleep 1; curl -s -o /dev/null -w "server: %{http_code}\n" http://localhost:8765/
# Public tunnel (fails on this box: outbound port 7844/QUIC blocked). Works on networks that allow it:
# cloudflared tunnel --url http://localhost:8765
