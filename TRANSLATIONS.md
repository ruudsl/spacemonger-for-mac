# Translating SpaceMonger

The UI ships in 15 languages. The current translations are **machine-quality**
(structurally validated, but not yet reviewed by native speakers). This guide
lets a native speaker improve any language **without touching Swift code**.

## Where the strings live

| Language | Edit here | Notes |
| --- | --- | --- |
| Dutch (`nl`) | `SpaceMonger/nl.lproj/Localizable.strings` | hand-maintained — edit directly |
| All others (`en`, `fr`, `de`, `it`, `pl`, `ru`, `es`, `pt-PT`, `sv`, `tr`, `uk`, `zh-Hans`, `zh-Hant`, `ja`) | **`tools/make_locales.py`** | generated — edit the Python, then regenerate |
| Plurals | `*.lproj/Localizable.strings**dict**` (`en`, `nl`) | for `%lld item` vs `%lld items` |

> ⚠️ Don't edit the generated `.lproj/Localizable.strings` for non-Dutch
> languages directly — `make_locales.py` overwrites them. Edit the translation
> in the Python dictionaries (`T["fr"]`, `HELP_T["de"]`, …) instead.

## How to edit and regenerate

1. Find the English key and your language's value in `tools/make_locales.py`.
2. Improve the value (keep the key unchanged; keep every `%@` / `%lld`).
3. Regenerate and validate:

   ```sh
   python3 tools/make_locales.py
   python3 tools/check_locales.py
   ```

For Dutch, edit `nl.lproj/Localizable.strings` directly, then run
`check_locales.py`.

## Rules

- **Keep the format specifiers** exactly: `%@` (text), `%lld` (number). Same
  count and meaning as English. The checker enforces this.
- **Keep keyboard symbols** as-is: `⌘ ⇧ ⌥ ⌫ ⌘Y …`.
- **Follow Apple's platform terminology** for your language (the wording macOS
  itself uses), e.g.:
  - Quick Look → fr *Coup d'œil*, de *Übersicht*, ja *クイックルック*
  - Move to Trash → fr *Placer dans la corbeille*, de *In den Papierkorb legen*
  - Reveal in Finder, Settings, etc.
- Leave a value identical to English when the term is the same in your language
  (e.g. *OK*, *MB*, product names). The checker reports these as info, not errors.
- App-specific terms — translate consistently throughout: **Collector**, **Focus**,
  **Sunburst/Treemap**, **System & hidden space**, **purgeable space**.

## Validation

`tools/check_locales.py` checks every language against English for missing keys,
format-specifier mismatches and empty values. CI runs it on every pull request
(`.github/workflows/locales.yml`), and also verifies the generated files match
`make_locales.py`. Green check = safe to merge.
