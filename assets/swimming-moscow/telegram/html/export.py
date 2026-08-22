#!/usr/bin/env python3
"""Export Swimming Moscow Telegram HTML to PNG."""

import subprocess
import tempfile
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT / "export"


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, format, *args):  # noqa: A003
        return


def shot(url: str, out: Path, w: int, h: int) -> None:
    user_data = tempfile.mkdtemp(prefix="sm-tg-")
    cmd = [
        "/opt/google/chrome/chrome",
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        f"--user-data-dir={user_data}",
        f"--window-size={w},{h}",
        f"--screenshot={out}",
        "--virtual-time-budget=8000",
        "--run-all-compositor-stages-before-draw",
        url,
    ]
    subprocess.run(cmd, timeout=18, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if not out.exists():
        raise SystemExit(f"export failed: {out}")


def main() -> None:
    EXPORT.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", 8766), Handler)
    Thread(target=server.serve_forever, daemon=True).start()
    time.sleep(0.3)
    try:
        jobs = [
            ("html/telegram-september-1280x720.html", "telegram-september-1280x720.png", 1280, 720),
            ("html/telegram-september-1280x720.html", "telegram-september-1080x1080.png", 1080, 1080),
            ("html/telegram-september-cartoon-1080.html", "telegram-september-cartoon-1080.png", 1080, 1080),
        ]
        for rel, name, w, h in jobs:
            out = EXPORT / name
            shot(f"http://127.0.0.1:8766/{rel}", out, w, h)
            print(f"wrote {name} ({out.stat().st_size} bytes)")
    finally:
        server.shutdown()


if __name__ == "__main__":
    main()
