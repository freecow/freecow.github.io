#!/usr/bin/env bash

# MkDocs dev server helper
# Usage:
#   ./start.sh start   # start in background (default)
#   ./start.sh stop    # stop background server
#   ./start.sh restart # restart server
#   ./start.sh status  # show status
#   ./start.sh logs    # tail logs
#
# Env vars:
#   ADDR (default 0.0.0.0)  PORT (default 8000)

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$ROOT_DIR"

ADDR=${ADDR:-0.0.0.0}
PORT=${PORT:-8000}
PID_FILE=".mkdocs.pid"
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/mkdocs.log"

ensure_poetry_env() {
  if ! command -v poetry >/dev/null 2>&1; then
    echo "❌ poetry 未安装。请先安装: curl -sSL https://install.python-poetry.org | python3 -" >&2
    exit 1
  fi

  # If env not created, run install (no-root: we don't package this project)
  if ! poetry env info --path >/dev/null 2>&1; then
    echo "➡️  初始化 Poetry 环境..."
    poetry install --no-root
  fi

  # Activate env for this shell (Poetry 2.x 推荐 env activate)
  ENV_PATH=$(poetry env info --path)
  # shellcheck disable=SC1090
  source "$ENV_PATH/bin/activate"
}

is_running() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null || true)
    if [[ -n "${pid}" ]] && kill -0 "$pid" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

start() {
  mkdir -p "$LOG_DIR"

  if is_running; then
    echo "ℹ️  已在运行 (PID $(cat "$PID_FILE")), 跳过启动。使用 ./start.sh restart 可重启。"
    exit 0
  fi

  ensure_poetry_env
  echo "🚀 启动 MkDocs: http://$ADDR:$PORT (日志: $LOG_FILE)"
  nohup mkdocs serve -a "$ADDR:$PORT" >>"$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  sleep 0.6
  if is_running; then
    echo "✅ 已启动 (PID $(cat "$PID_FILE"))"
  else
    echo "❌ 启动失败，查看日志: $LOG_FILE" >&2
    exit 1
  fi
}

stop() {
  if ! is_running; then
    echo "ℹ️  未发现运行中的服务。"
    rm -f "$PID_FILE" 2>/dev/null || true
    return 0
  fi
  local pid
  pid=$(cat "$PID_FILE")
  echo "🛑 停止 MkDocs (PID $pid) ..."
  kill "$pid" 2>/dev/null || true
  # 等待最多 5s
  for i in 1 2 3 4 5; do
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  if kill -0 "$pid" >/dev/null 2>&1; then
    echo "⚠️  进程未退出，尝试强制停止"
    kill -9 "$pid" 2>/dev/null || true
  fi
  rm -f "$PID_FILE" 2>/dev/null || true
  echo "✅ 已停止"
}

status() {
  if is_running; then
    echo "✅ 运行中 (PID $(cat "$PID_FILE")) - http://$ADDR:$PORT"
  else
    echo "❌ 未运行"
  fi
}

logs() {
  mkdir -p "$LOG_DIR"
  echo "📜 查看日志 (Ctrl-C 退出): $LOG_FILE"
  touch "$LOG_FILE"
  tail -f "$LOG_FILE"
}

case "${1:-start}" in
  start)   start ;;
  stop)    stop ;;
  restart) stop; start ;;
  status)  status ;;
  logs)    logs ;;
  *) echo "用法: $0 {start|stop|restart|status|logs}"; exit 2 ;;
esac

