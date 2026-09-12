# buhta_camp

Static marketing website for "Бухта Camp" (a kids camp). Plain HTML, CSS, and vanilla
JavaScript — there is no build system, package manager, bundler, or test/lint tooling.

- Pages: `index.html`, `o-lagere.html`, `smeny.html`, `otzyvy.html`, `kontakty.html`
- Styling: `styles.css` (referenced as `styles.css?v=N` cache-busting query in HTML)
- Behavior: `script.js` (nav toggle, booking modal, submit toast, tabs, scroll reveal)
- Assets: `images/`, `assets/`; design reference in `DESIGN.md`
- Fonts load from Google Fonts over the network.

## Cursor Cloud specific instructions

- There are no dependencies to install and nothing to build, lint, or unit-test. The
  "app" is the static files served over HTTP.
- Run it with any static file server from the repo root, e.g.
  `python3 -m http.server 8000 --bind 127.0.0.1`, then open
  `http://127.0.0.1:8000/index.html`. Do not open the HTML via `file://` — relative
  asset paths and the fonts preconnect assume an HTTP origin.
- Core interactive flow to smoke-test: click "Оставить заявку" to open the booking
  modal, fill the form (name/phone/child/shift), submit — a toast
  ("<name>, заявка принята...") appears bottom-right for ~4s. This is handled entirely
  client-side in `script.js`; there is no backend, so no form data is persisted.
- Bumping `styles.css?v=N` in the HTML files is just cache-busting; edits to `styles.css`
  are picked up on a normal reload.
