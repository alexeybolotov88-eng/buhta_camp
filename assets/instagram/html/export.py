#!/usr/bin/env python3
"""Export Instagram header HTML canvases to PNG via Chrome headless."""

from __future__ import annotations

import subprocess
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "html"
EXPORT = ROOT / "export"
CHROME = "/opt/google/chrome/chrome"

JOBS = [
    ("html/avatar.html", "avatar-1080.png", 1080, 1080, 1),
    ("html/grid-span.html", "grid-span-3240x1080.png", 3240, 1080, 1),
    ("html/highlight-smeny.html", "highlight-smeny.png", 1080, 1080, 1),
    ("html/highlight-program.html", "highlight-program.png", 1080, 1080, 1),
    ("html/highlight-parents.html", "highlight-parents.png", 1080, 1080, 1),
    ("html/highlight-reviews.html", "highlight-reviews.png", 1080, 1080, 1),
    ("html/highlight-zayavka.html", "highlight-zayavka.png", 1080, 1080, 1),
    ("html/profile-a.html", "profile-a.png", 390, 844, 3),
    ("html/profile-b.html", "profile-b.png", 390, 844, 3),
    ("html/profile-c.html", "profile-c.png", 390, 844, 3),
    ("html/preview.html", "preview-1920x1080.png", 1920, 1080, 1),
]


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, format, *args):  # noqa: A003
        return


def screenshot(url: str, out: Path, width: int, height: int, scale: int) -> None:
    import tempfile

    out.parent.mkdir(parents=True, exist_ok=True)
    user_data = tempfile.mkdtemp(prefix="buhta-chrome-")
    cmd = [
        "/opt/google/chrome/chrome",
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--no-first-run",
        "--no-default-browser-check",
        f"--user-data-dir={user_data}",
        f"--force-device-scale-factor={scale}",
        f"--window-size={width},{height}",
        f"--screenshot={out}",
        "--virtual-time-budget=8000",
        "--run-all-compositor-stages-before-draw",
        url,
    ]
    try:
        subprocess.run(cmd, check=False, timeout=18, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        pass
    if not out.exists() or out.stat().st_size < 1000:
        raise SystemExit(f"screenshot failed: {out}")
    print(f"wrote {out.name} ({out.stat().st_size} bytes)", flush=True)


def crop_grid(span: Path) -> None:
    try:
        from PIL import Image
    except ImportError:
        subprocess.run(["python3", "-m", "pip", "install", "pillow", "-q", "--break-system-packages"], check=True)
        from PIL import Image

    im = Image.open(span)
    w, h = im.size
    tile = w // 3
    names = ["grid-01.png", "grid-02.png", "grid-03.png"]
    for i, name in enumerate(names):
        im.crop((i * tile, 0, (i + 1) * tile, h)).save(EXPORT / name, "PNG")
        print(f"wrote {name}")


def main() -> None:
    EXPORT.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", 8765), Handler)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    time.sleep(0.3)
    try:
        for rel, name, w, h, scale in JOBS:
            screenshot(f"http://127.0.0.1:8765/{rel}", EXPORT / name, w, h, scale)
        crop_grid(EXPORT / "grid-span-3240x1080.png")
    finally:
        server.shutdown()


if __name__ == "__main__":
    main()
