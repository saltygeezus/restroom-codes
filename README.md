# CodeLoo – crowdsourced restroom door codes

Static site in `docs/` served by GitHub Pages: https://saltygeezus.github.io/restroom-codes/
Data lives in Supabase (supabase-js from CDN, anon key + Row Level Security).

## Setup Supabase
1. Create a project at supabase.com.
2. SQL Editor → run `supabase/schema.sql` (tables `places`, `codes`, `votes`, view `code_stats`, RLS: anon may select/insert only; 7 real seed codes near ZIP 92029).
3. Project Settings → API: copy **Project URL** and **anon public** key into `docs/config.js`. Never use the service_role key.
4. Commit & push; Pages redeploys.

Until `config.js` is filled in, the app runs in **demo mode**: a yellow banner is shown and data is stored only in the browser's localStorage.

## iPhone
Open the URL in Safari → Share → Add to Home Screen (manifest, apple-touch-icon, standalone).

## Legacy
`server.py` + `static/` is the original local Python/SQLite prototype (`python3 server.py`, port 8765). It is not used by the hosted site. The Render config was removed.
