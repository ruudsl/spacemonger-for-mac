// Pull live data from GitHub: latest release (download link, version, size,
// notes) and the star count. Also reveals a demo video if web/demo.mp4 exists.
(function () {
  "use strict";
  var REPO = "ruudsl/spacemonger-for-mac";
  var FALLBACK = "https://github.com/" + REPO + "/releases/latest";
  var buttons = ["navDownload", "heroDownload", "footDownload"]
    .map(function (id) { return document.getElementById(id); })
    .filter(Boolean);

  function tr(key) {
    return (window.SMI18N && window.SMI18N.t) ? window.SMI18N.t(key) : key;
  }

  // Non-Mac hint.
  if (!/Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent)) {
    var hint = document.getElementById("osHint");
    if (hint) hint.hidden = false;
  }

  // Latest release.
  fetch("https://api.github.com/repos/" + REPO + "/releases/latest", {
    headers: { Accept: "application/vnd.github+json" }
  })
    .then(function (r) { return r.ok ? r.json() : Promise.reject(r.status); })
    .then(function (rel) {
      var assets = rel.assets || [];
      var dmg = assets.find(function (a) { return /\.dmg$/i.test(a.name); });
      var zip = assets.find(function (a) { return /\.zip$/i.test(a.name); });
      var asset = dmg || zip;
      var url = asset ? asset.browser_download_url : (rel.html_url || FALLBACK);
      buttons.forEach(function (b) { b.href = url; });

      var tag = (rel.tag_name || "").replace(/^v/, "");
      window.__latest = { version: tag, url: url };
      if (window.renderMeta) window.renderMeta();

      // version · size · universal
      var info = document.getElementById("dlInfo");
      if (info && (asset || tag)) {
        var bits = [];
        if (tag) bits.push("v" + tag);
        if (asset && asset.size) bits.push((asset.size / 1048576).toFixed(1) + " MB");
        bits.push("Universal (Apple Silicon & Intel)");
        info.textContent = bits.join(" · ");
        info.hidden = false;
      }

      // What's new
      var notes = (rel.body || "").trim();
      if (notes) {
        var sec = document.getElementById("whatsnew");
        var nameEl = document.getElementById("releaseName");
        var notesEl = document.getElementById("releaseNotes");
        var linkEl = document.getElementById("releaseLink");
        if (nameEl) nameEl.textContent = rel.name || rel.tag_name || "";
        if (notesEl) notesEl.textContent = notes.length > 1400 ? notes.slice(0, 1400) + "…" : notes;
        if (linkEl) linkEl.href = "https://github.com/" + REPO + "/releases";
        if (sec) sec.hidden = false;
      }
    })
    .catch(function () { buttons.forEach(function (b) { b.href = FALLBACK; }); });

  // Star count (social proof).
  fetch("https://api.github.com/repos/" + REPO, { headers: { Accept: "application/vnd.github+json" } })
    .then(function (r) { return r.ok ? r.json() : Promise.reject(r.status); })
    .then(function (repo) {
      var n = repo.stargazers_count;
      if (typeof n === "number") {
        var badge = document.getElementById("starBadge");
        var count = document.getElementById("starCount");
        if (count) count.textContent = n >= 1000 ? (n / 1000).toFixed(1) + "k" : String(n);
        if (badge) badge.hidden = false;
      }
    })
    .catch(function () {});

  // Optional demo video (web/demo.mp4) — shown only if present.
  fetch("demo.mp4", { method: "HEAD" })
    .then(function (r) {
      if (!r.ok) return;
      var sec = document.getElementById("demo");
      var vid = document.getElementById("demoVideo");
      if (!sec || !vid) return;
      vid.src = "demo.mp4";
      vid.autoplay = true; vid.muted = true; vid.loop = true;
      sec.hidden = false;
      var p = vid.play();
      if (p && p.catch) p.catch(function () {});
    })
    .catch(function () {});
})();
