#!/usr/bin/env bash
# Starts firemq in the background and waits until it is ready.
set -euo pipefail

log="$RUNNER_TEMP/firemq.log"
flags=(--amqp "$LISTEN:$AMQP_PORT" --fire "$LISTEN:$FIRE_PORT" --http "$LISTEN:$HTTP_PORT" --amqps off --fires off)
if [ "$PERSISTENT" = true ]; then
  flags+=(--data-dir "$RUNNER_TEMP/firemq-data")
else
  flags+=(--ephemeral)
fi
# shellcheck disable=SC2206
[ -n "$ARGS" ] && flags+=($ARGS)

# Containers and other hosts reach the broker through a non-loopback address, where the
# guest user is refused by default.
[ "$LISTEN" = 127.0.0.1 ] || export FIREMQ_LOOPBACK_USERS=

case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    exe=$(command -v firemq.exe || command -v firemq)
    pwsh -NoProfile -Command "Start-Process -FilePath '$(cygpath -w "$exe")' -ArgumentList '${flags[*]}' -RedirectStandardOutput '$(cygpath -w "$log")' -RedirectStandardError '$(cygpath -w "$log").err' -WindowStyle Hidden"
    ;;
  *)
    nohup firemq "${flags[@]}" > "$log" 2>&1 &
    ;;
esac

host=$LISTEN
[ "$host" = 0.0.0.0 ] && host=127.0.0.1
for _ in $(seq 1 300); do
  if curl -fsS "http://$host:$HTTP_PORT/healthz" >/dev/null 2>&1; then
    version=$(firemq --version | awk '{print $2}')
    echo "FireMQ $version is ready"
    {
      echo "amqp-url=amqp://guest:guest@$host:$AMQP_PORT"
      echo "fire-url=fire://guest:guest@$host:$FIRE_PORT"
      echo "ws-url=ws://$host:$HTTP_PORT/fire"
      echo "http-url=http://$host:$HTTP_PORT"
      echo "version=$version"
    } >> "$GITHUB_OUTPUT"
    exit 0
  fi
  sleep 0.1
done
echo "::error::FireMQ did not start within 30 seconds"
cat "$log" "$log.err" 2>/dev/null || true
exit 1
