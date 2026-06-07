#!/usr/bin/env python3
"""Insert a new <item> into appcast.xml for a Sparkle release.

Used by .github/workflows/release.yml. Idempotent: skips if the version is
already present (ignoring XML comments).

Usage:
  update_appcast.py --version 1.1 --build 2 \
      --url https://github.com/<repo>/releases/download/v1.1/SpaceMonger-1.1.zip \
      --length 1234567 --signature <edSignature> [--min-system 13.0] [--file appcast.xml]
"""
import argparse
import datetime
import pathlib
import re
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True)
    ap.add_argument("--build", required=True)
    ap.add_argument("--url", required=True)
    ap.add_argument("--length", required=True)
    ap.add_argument("--signature", required=True)
    ap.add_argument("--min-system", default="13.0")
    ap.add_argument("--file", default="appcast.xml")
    args = ap.parse_args()

    path = pathlib.Path(args.file)
    xml = path.read_text(encoding="utf-8")

    # Ignore commented-out examples when checking for duplicates.
    without_comments = re.sub(r"<!--.*?-->", "", xml, flags=re.DOTALL)
    if f'sparkle:shortVersionString="{args.version}"' in without_comments:
        print(f"appcast already lists version {args.version}; nothing to do.")
        return

    date = datetime.datetime.now(datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")
    item = (
        "    <item>\n"
        f"      <title>Version {args.version}</title>\n"
        f"      <pubDate>{date}</pubDate>\n"
        f"      <sparkle:minimumSystemVersion>{args.min_system}</sparkle:minimumSystemVersion>\n"
        "      <enclosure\n"
        f'        url="{args.url}"\n'
        f'        sparkle:version="{args.build}"\n'
        f'        sparkle:shortVersionString="{args.version}"\n'
        f'        length="{args.length}"\n'
        '        type="application/octet-stream"\n'
        f'        sparkle:edSignature="{args.signature}" />\n'
        "    </item>\n"
    )

    if "</language>" in xml:
        xml = xml.replace("</language>", "</language>\n\n" + item, 1)
    elif "</channel>" in xml:
        xml = xml.replace("</channel>", item + "  </channel>", 1)
    else:
        print("Could not find an insertion point in appcast.xml", file=sys.stderr)
        sys.exit(1)

    path.write_text(xml, encoding="utf-8")
    print(f"Inserted appcast item for {args.version} (build {args.build}).")


if __name__ == "__main__":
    main()
