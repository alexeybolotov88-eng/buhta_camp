# Buhta Camp — agent tooling notes

## Skills (`.agents/skills/`)

Design / research: `refero-design`, `frontend-design`, `web-design-guidelines`, `image`, `performance`
Marketing / sales: `product-marketing`, `copywriting`, `cro`, `analytics`, `ab-testing`
SEO: `seo-audit`, `seo`, `schema`

Always read `.agents/product-marketing.md` before marketing copy.

## MCP (`.cursor/mcp.json`)

| Server | Status | What you need |
|--------|--------|----------------|
| `21st` | Configured | API key already in local mcp.json |
| `playwright` | Ready | Chromium + headless shell installed (see below) |
| `refero` | URL added | Refero Pro + OAuth in Cursor, or Bearer token |

Refresh MCP in Cursor after changes: Settings → MCP → refresh / restart.

## Playwright (Chromium for MCP screenshots)

**Status: installed and verified** (2026-08-15)

- Package: `playwright` ^1.55.0 in `package.json` (devDependency); local `node_modules/` (gitignored)
- Browsers path: `PLAYWRIGHT_BROWSERS_PATH=/Users/documents/Library/Caches/ms-playwright`
- Installed builds:
  - `chromium-1187` → `…/chrome-mac/Chromium.app/Contents/MacOS/Chromium`
  - `chromium_headless_shell-1187` → `…/chrome-mac/headless_shell`
- Smoke: headless launch + screenshot OK

### Retry / reinstall

If browsers are missing or MCP screenshots fail:

```bash
cd /Users/documents/camp
export PLAYWRIGHT_BROWSERS_PATH="$HOME/Library/Caches/ms-playwright"
# clear stuck lock if a previous install hung
rm -rf "$PLAYWRIGHT_BROWSERS_PATH/__dirlock"
./node_modules/.bin/playwright install chromium
```

If `playwright install` hangs at download, install via curl instead:

```bash
export PLAYWRIGHT_BROWSERS_PATH="$HOME/Library/Caches/ms-playwright"
REV=1187   # match playwright version’s chromium build
mkdir -p /tmp/pw-dl "$PLAYWRIGHT_BROWSERS_PATH"

curl -L -o /tmp/pw-dl/chromium.zip \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/chromium/${REV}/chromium-mac-arm64.zip"
curl -L -o /tmp/pw-dl/headless.zip \
  "https://cdn.playwright.dev/dbazure/download/playwright/builds/chromium/${REV}/chromium-headless-shell-mac-arm64.zip"

rm -rf "$PLAYWRIGHT_BROWSERS_PATH/chromium-${REV}" \
       "$PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-${REV}" \
       "$PLAYWRIGHT_BROWSERS_PATH/__dirlock"
mkdir -p "$PLAYWRIGHT_BROWSERS_PATH/chromium-${REV}" \
         "$PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-${REV}"
unzip -q /tmp/pw-dl/chromium.zip -d "$PLAYWRIGHT_BROWSERS_PATH/chromium-${REV}"
unzip -q /tmp/pw-dl/headless.zip -d "$PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-${REV}"
touch "$PLAYWRIGHT_BROWSERS_PATH/chromium-${REV}/INSTALLATION_COMPLETE" \
      "$PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-${REV}/INSTALLATION_COMPLETE"
```

Intel Mac: use `chromium-mac.zip` / `chromium-headless-shell-mac.zip` (without `-arm64`).

## Not installable as a skill (needs your accounts)

1. **Яндекс Метрика / GA** — counter ID → then use `analytics` skill to wire events.
2. **Заявки в Telegram / CRM** — bot token or webhook endpoint.
3. **Refero live screens** — Pro subscription at refero.design.
4. **Реальные фото смен** — upload to `images/` (AI photos are temporary).
