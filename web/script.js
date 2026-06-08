// Point every Download button at the newest GitHub Release asset (the .dmg if
// present, else .zip). i18n.js renders the localized version label.
(function () {
  const REPO = "ruudsl/spacemonger-for-mac";
  const FALLBACK = `https://github.com/${REPO}/releases/latest`;
  const buttons = ["navDownload", "heroDownload", "footDownload"]
    .map((id) => document.getElementById(id))
    .filter(Boolean);

  // Gentle hint for non-Mac visitors.
  if (!/Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent)) {
    const hint = document.getElementById("osHint");
    if (hint) hint.hidden = false;
  }

  fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
    headers: { Accept: "application/vnd.github+json" },
  })
    .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
    .then((release) => {
      const assets = release.assets || [];
      const dmg = assets.find((a) => a.name.toLowerCase().endsWith(".dmg"));
      const zip = assets.find((a) => a.name.toLowerCase().endsWith(".zip"));
      const asset = dmg || zip;
      const url = asset ? asset.browser_download_url : release.html_url || FALLBACK;

      buttons.forEach((b) => (b.href = url));

      const tag = (release.tag_name || "").replace(/^v/, "");
      window.__latest = { version: tag, url: url };
      if (typeof window.renderMeta === "function") window.renderMeta();
    })
    .catch(() => {
      buttons.forEach((b) => (b.href = FALLBACK));
    });
})();
