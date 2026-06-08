# SpaceMonger landing page

A self-contained static site (no build step) for promoting and downloading the
app. Localized into all 15 app languages, with a release-tracking download CTA.

## Files

- `index.html`, `styles.css`, `script.js`, `i18n.js` — the page + i18n.
- `icon*.png`, `og.png`, `shots/` — images (run `make_og.py` to regenerate the
  social card; `optimize-images.sh` to produce WebP screenshots).
- `robots.txt`, `sitemap.xml`, `404.html`, `vercel.json` — SEO / hosting.

## What it does

- **15 languages** with browser auto-detection, a 🌐 switcher, `?lang=` deep
  links, and per-language `<title>` / meta description.
- **Live data from GitHub**: download button → latest release asset; version +
  file size; a "What's new" section from the release notes; star count.
- **SEO**: canonical + `hreflang`, `sitemap.xml`, `robots.txt`, JSON-LD
  (`SoftwareApplication`), a real 1200×630 OG image.
- **Performance**: lazy + sized images, `<picture>` WebP, preloaded hero icon,
  cache headers.
- **A11y**: focus-visible styles, `prefers-reduced-motion`, semantic FAQ.
- **Security headers** + a 404 page (`vercel.json`).
- Optional **demo video**: drop `web/demo.mp4` and it appears automatically.

## Deploy on Vercel

1. Vercel ▸ **Add New… ▸ Project ▸ Import** this repo.
2. **Root Directory** = `web`. **Framework Preset** = *Other*.
3. **Deploy.** Enable **Web Analytics** in the project for privacy-friendly
   stats (the page already includes the script tag). Add a custom domain and
   update the URLs in `sitemap.xml` / `robots.txt`.

## Local preview

```sh
cd web && python3 -m http.server 8000   # http://localhost:8000
```
