# SpaceMonger landing page

A self-contained static site (no build step) for promoting and downloading the
app. The Download buttons fetch the **latest GitHub Release** at runtime and
point at its `.dmg` (or `.zip`) asset, falling back to the releases page.

Files: `index.html`, `styles.css`, `script.js`, `icon*.png`, `shots/`.

## Deploy on Vercel

1. Push this repo to GitHub (already done).
2. In Vercel: **Add New… ▸ Project ▸ Import** this repository.
3. Set **Root Directory** to `web`.
4. **Framework Preset:** *Other* (it's a static site — no build command, output
   is the directory itself).
5. **Deploy.** Add a custom domain under the project's **Domains** tab if you
   like.

That's it — every push to the connected branch redeploys. The download link
always tracks your newest release, so you don't touch the site when you ship a
new version.

## Local preview

```sh
cd web && python3 -m http.server 8000   # then open http://localhost:8000
```
