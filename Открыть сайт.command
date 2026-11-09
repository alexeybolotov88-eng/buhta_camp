#!/bin/bash
# Always serve the site from the project folder, even when this file is copied elsewhere.
SITE_DIR="/Users/documents/camp"
PORT=8765
URL="http://127.0.0.1:${PORT}/index.html"

cd "$SITE_DIR" || {
  osascript -e 'display alert "Бухта Camp" message "Не найдена папка сайта: '"$SITE_DIR"'" as critical'
  exit 1
}

if ! lsof -Pi :"$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
  nohup python3 -m http.server "$PORT" >/tmp/buhta-camp-server.log 2>&1 &
  sleep 0.6
fi

open "$URL"
