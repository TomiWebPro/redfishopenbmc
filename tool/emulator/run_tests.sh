#!/usr/bin/env bash
# Runs the DMTF Redfish-Mockup-Server integration suite (EMU-1..EMU-4).
#
# Requirements: python3-venv, openssl, flutter on PATH.
# Side effects: everything lives under /tmp (cloned server, venv, cert, logs);
# nothing is written inside the repo. The server is always stopped via `trap`.
#
# Usage:
#   tool/emulator/run_tests.sh
#
# Pinned upstream: DMTF/Redfish-Mockup-Server @ 23d21f9a3610f6b6fbb71ffc941296b159a524d2
# (verified 2026-10-22; update deliberately, then update the pin here).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EMU_DIR=/tmp/redfish-mockup-server
VENV=/tmp/redfish-emulator-venv
CERT=/tmp/redfish-emulator-cert.pem
KEY=/tmp/redfish-emulator-key.pem
LOG=/tmp/redfish-emulator.log
PORT=8443
URL="https://127.0.0.1:${PORT}"
PIN="23d21f9a3610f6b6fbb71ffc941296b159a524d2"

server_pid=""

cleanup() {
  if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "[emulator] preparing server (pin $PIN)…"

if [[ ! -d "$EMU_DIR/.git" ]]; then
  git clone --depth 1 https://github.com/DMTF/Redfish-Mockup-Server "$EMU_DIR"
fi
( cd "$EMU_DIR" && git fetch --depth 1 origin "$PIN" && git checkout -q "$PIN" )

if [[ ! -x "$VENV/bin/python" ]]; then
  python3 -m venv "$VENV"
fi
"$VENV/bin/pip" install -q -r "$EMU_DIR/requirements.txt"

if [[ ! -f "$CERT" ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes -days 2 \
    -keyout "$KEY" -out "$CERT" \
    -subj "/CN=127.0.0.1" \
    -addext "subjectAltName=IP:127.0.0.1,DNS:localhost" >/dev/null 2>&1
fi

echo "[emulator] starting server on $URL …"
"$VENV/bin/python" "$EMU_DIR/redfishMockupServer.py" \
  -H 127.0.0.1 -p "$PORT" \
  -D "$REPO_ROOT/test/fixtures/redfish/dmtf_mockup" \
  -s --cert "$CERT" --key "$KEY" -S \
  > "$LOG" 2>&1 &
server_pid=$!

echo "[emulator] waiting for health…"
for i in $(seq 1 30); do
  if curl -ksSf "$URL/redfish/v1/" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
curl -ksSf "$URL/redfish/v1/" >/dev/null

echo "[emulator] running tests…"
flutter test test_integration/emulator \
  --dart-define=REDFISH_EMULATOR_URL="$URL"

echo "[emulator] done."