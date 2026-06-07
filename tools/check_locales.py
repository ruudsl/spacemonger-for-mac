#!/usr/bin/env python3
"""Validates the localizations so (native-speaker) reviewers can edit safely.

Checks, against the English source (en.lproj):
  • missing keys      — a language is missing a string (falls back to English)
  • format mismatch   — %@ / %lld counts differ from English (would crash/garble)
  • empty values      — a translation is blank
  • (info) untranslated — value identical to English

Exit code is non-zero if any *error* (missing key or format mismatch) is found,
so it can gate CI. Run:  python3 tools/check_locales.py
"""
import glob
import os
import re
import sys

BASE = os.path.join(os.path.dirname(__file__), "..", "SpaceMonger")
SOURCE = "en"

_PAIR = re.compile(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')
_FMT = re.compile(r"%(?:\d+\$)?[#0\-+ ]*\d*(?:ll?|h)?[@dioufgGeExXsp]")


def parse(path):
    out = {}
    with open(path, encoding="utf-8") as f:
        for m in _PAIR.finditer(f.read()):
            out[m.group(1)] = m.group(2)
    return out


def specifiers(text):
    # Normalise away positional indices / flags so we compare conversion types.
    toks = []
    for t in _FMT.findall(text):
        toks.append(re.sub(r"\d+\$", "", t))
    return sorted(toks)


def main():
    en_path = os.path.join(BASE, f"{SOURCE}.lproj", "Localizable.strings")
    en = parse(en_path)

    errors = 0
    warnings = 0
    for lproj in sorted(glob.glob(os.path.join(BASE, "*.lproj"))):
        code = os.path.basename(lproj)[:-len(".lproj")]
        if code == SOURCE:
            continue
        table = parse(os.path.join(lproj, "Localizable.strings"))

        missing = [k for k in en if k not in table]
        mismatched = []
        empty = []
        untranslated = 0
        for key, value in table.items():
            if key in en:
                if specifiers(value) != specifiers(en[key]):
                    mismatched.append(key)
                if value.strip() == "":
                    empty.append(key)
                if value == en[key]:
                    untranslated += 1

        if missing or mismatched or empty:
            print(f"\n[{code}]")
            for k in missing:
                print(f"  MISSING      {k!r}")
            for k in mismatched:
                print(f"  FORMAT ⚠      {k!r}")
                print(f"               en: {en[k]!r}")
                print(f"               {code}: {table[k]!r}")
            for k in empty:
                print(f"  EMPTY        {k!r}")
            errors += len(missing) + len(mismatched) + len(empty)
        else:
            print(f"[{code}] OK ({len(table)} keys, {untranslated} still English)")

    print()
    if errors:
        print(f"FAILED: {errors} error(s).")
        sys.exit(1)
    print("All localizations valid.")


if __name__ == "__main__":
    main()
