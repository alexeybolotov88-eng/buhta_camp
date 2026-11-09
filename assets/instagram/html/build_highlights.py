#!/usr/bin/env python3
"""Generate Instagram highlight cover HTML files for Бухта Camp."""

from pathlib import Path

OUT = Path(__file__).resolve().parent

ICONS = {
    "smeny": """
      <rect x="18" y="22" width="64" height="56" rx="8" fill="none" stroke="currentColor" stroke-width="4"/>
      <path d="M18 38h64" stroke="currentColor" stroke-width="4"/>
      <path d="M34 14v16M66 14v16" stroke="currentColor" stroke-width="4" stroke-linecap="round"/>
      <rect x="30" y="48" width="12" height="12" rx="2" fill="currentColor"/>
      <rect x="50" y="48" width="12" height="12" rx="2" fill="currentColor"/>
    """,
    "program": """
      <path d="M10 52 C22 52 28 38 40 38 C52 38 58 58 70 58 C82 58 88 44 90 44" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round"/>
      <path d="M10 64 C22 64 28 50 40 50 C52 50 58 70 70 70 C82 70 88 56 90 56" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" opacity="0.45"/>
    """,
    "parents": """
      <rect x="22" y="24" width="56" height="44" rx="6" fill="none" stroke="currentColor" stroke-width="4"/>
      <circle cx="40" cy="42" r="7" fill="none" stroke="currentColor" stroke-width="4"/>
      <path d="M28 60l14-16 10 10 8-8 12 14" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    """,
    "reviews": """
      <path d="M22 28h36c8 0 14 6 14 14v10c0 8-6 14-14 14H48l-16 16v-16h-10c-8 0-14-6-14-14V42c0-8 6-14 14-14z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"/>
      <path d="M34 46h28M34 56h18" stroke="currentColor" stroke-width="4" stroke-linecap="round"/>
    """,
    "zayavka": """
      <circle cx="50" cy="50" r="34" fill="none" stroke="currentColor" stroke-width="4"/>
      <path d="M32 50h30M48 36l16 14-16 14" fill="none" stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
    """,
}

COVERS = [
    ("smeny", "Смены", "#14352f", "#e8c547", False),
    ("program", "Программа", "#14352f", "#e8c547", False),
    ("parents", "Родителям", "#1f6b5e", "#f3f7f5", False),
    ("reviews", "Отзывы", "#14352f", "#e8c547", False),
    ("zayavka", "Заявка", "#d4572a", "#ffffff", True),
]

TPL = """<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8" />
  <title>Highlight {label}</title>
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@700&family=Syne:wght@800&display=swap" rel="stylesheet" />
  <style>
    * {{ margin: 0; box-sizing: border-box; }}
    html, body {{ width: 1080px; height: 1080px; overflow: hidden; }}
    .canvas {{
      width: 1080px; height: 1080px;
      background: {bg};
      display: grid; place-items: center;
    }}
    .inner {{
      width: 420px; text-align: center; color: {fg};
    }}
    .icon {{ width: 280px; height: 280px; margin: 0 auto; }}
    .icon svg {{ width: 100%; height: 100%; display: block; }}
  </style>
</head>
<body>
  <div class="canvas">
    <div class="inner">
      <div class="icon">
        <svg viewBox="0 0 100 100" fill="none">{icon}</svg>
      </div>
    </div>
  </div>
</body>
</html>
"""

for key, label, bg, fg, _coral in COVERS:
    html = TPL.format(label=label, bg=bg, fg=fg, icon=ICONS[key])
    (OUT / f"highlight-{key}.html").write_text(html, encoding="utf-8")
    print("wrote", f"highlight-{key}.html")
