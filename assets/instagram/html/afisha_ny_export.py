#!/usr/bin/env python3
"""Export the New Year afisha HTML canvases to PNG via headless Chrome."""

from __future__ import annotations

import subprocess
import tempfile
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT / "export"
CHROME = "/opt/google/chrome/chrome"

JOBS = [
    ("html/afisha-ny-post.html", "afisha-ny-post-1080x1350.png", 1080, 1350),
    ("html/afisha-ny-story.html", "afisha-ny-story-1080x1920.png", 1080, 1920),
]


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, *args):  # noqa: A003
        return


def screenshot(url: str, out: Path, width: int, height: int) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    user_data = tempfile.mkdtemp(prefix="buhta-ny-chrome-")
    cmd = [
        CHROME,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--no-first-run",
        "--no-default-browser-check",
        f"--user-data-dir={user_data}",
        "--force-device-scale-factor=1",
        f"--window-size={width},{height}",
        f"--screenshot={out}",
        "--virtual-time-budget=8000",
        "--run-all-compositor-stages-before-draw",
        url,
    ]
    try:
        subprocess.run(cmd, check=False, timeout=25, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        pass
    if not out.exists() or out.stat().st_size < 1000:
        raise SystemExit(f"screenshot failed: {out}")
    print(f"wrote {out.name} ({out.stat().st_size} bytes)", flush=True)


def main() -> None:
    EXPORT.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", 8766), Handler)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    time.sleep(0.3)
    try:
        for rel, name, w, h in JOBS:
            screenshot(f"http://127.0.0.1:8766/{rel}", EXPORT / name, w, h)
    finally:
        server.shutdown()


if __name__ == "__main__":
    main()
