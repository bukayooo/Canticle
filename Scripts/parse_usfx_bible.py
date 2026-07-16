#!/usr/bin/env python3
"""Parses eBible.org's KJV + Apocrypha USFX XML into per-book JSON files
matching the app's Bible JSON schema (Resources/Bible/<slug>.json).

Replaces a lost scratchpad-only parser (see README.md) that had a sporadic
bug dropping individual words with no discernible pattern (traced against
this same source: the dropped words sat in ordinary <w> tags structurally
identical to neighboring words that weren't dropped) - so unlike everything
else in Scripts/, this doesn't patch known-bad spots, it re-derives the
whole corpus from source with a parser that walks the XML tree properly
(via .text/.tail, not regex) so no word can be silently skipped regardless
of nesting.

Not part of the app build - run manually if the source ever needs
re-fetching or re-parsing:

    python3 Scripts/parse_usfx_bible.py [--out DIR]

Downloads (once, cached under a temp dir):
    https://eBible.org/Scriptures/eng-kjv_usfx.zip

Writes (default): a scratch directory for review, NOT directly into
Resources/Bible - diff against the current files before copying over.
"""
import argparse
import json
import re
import sys
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BIBLE_DIR = REPO_ROOT / "Canticle/Canticle/Resources/Bible"
CACHE_DIR = Path(tempfile.gettempdir()) / "canticle_usfx_cache"
USFX_URL = "https://eBible.org/Scriptures/eng-kjv_usfx.zip"

USFX_BOOK_TO_CANONICAL = {
    "GEN": "Genesis", "EXO": "Exodus", "LEV": "Leviticus", "NUM": "Numbers",
    "DEU": "Deuteronomy", "JOS": "Joshua", "JDG": "Judges", "RUT": "Ruth",
    "1SA": "1 Samuel", "2SA": "2 Samuel", "1KI": "1 Kings", "2KI": "2 Kings",
    "1CH": "1 Chronicles", "2CH": "2 Chronicles", "EZR": "Ezra", "NEH": "Nehemiah",
    "EST": "Esther", "JOB": "Job", "PSA": "Psalms", "PRO": "Proverbs",
    "ECC": "Ecclesiastes", "SNG": "Song of Solomon", "ISA": "Isaiah",
    "JER": "Jeremiah", "LAM": "Lamentations", "EZK": "Ezekiel", "DAN": "Daniel",
    "HOS": "Hosea", "JOL": "Joel", "AMO": "Amos", "OBA": "Obadiah",
    "JON": "Jonah", "MIC": "Micah", "NAM": "Nahum", "HAB": "Habakkuk",
    "ZEP": "Zephaniah", "HAG": "Haggai", "ZEC": "Zechariah", "MAL": "Malachi",
    "TOB": "Tobit", "JDT": "Judith", "ESG": "Additions to Esther",
    "WIS": "Wisdom of Solomon", "SIR": "Ecclesiasticus", "BAR": "Baruch",
    "S3Y": "Prayer of Azariah", "SUS": "Susanna", "BEL": "Bel and the Dragon",
    "1MA": "1 Maccabees", "2MA": "2 Maccabees", "1ES": "1 Esdras",
    "MAN": "Prayer of Manasseh", "2ES": "2 Esdras",
    "MAT": "Matthew", "MRK": "Mark", "LUK": "Luke", "JHN": "John", "ACT": "Acts",
    "ROM": "Romans", "1CO": "1 Corinthians", "2CO": "2 Corinthians",
    "GAL": "Galatians", "EPH": "Ephesians", "PHP": "Philippians",
    "COL": "Colossians", "1TH": "1 Thessalonians", "2TH": "2 Thessalonians",
    "1TI": "1 Timothy", "2TI": "2 Timothy", "TIT": "Titus", "PHM": "Philemon",
    "HEB": "Hebrews", "JAS": "James", "1PE": "1 Peter", "2PE": "2 Peter",
    "1JN": "1 John", "2JN": "2 John", "3JN": "3 John", "JUD": "Jude",
    "REV": "Revelation",
}


def local(tag):
    return tag.split("}", 1)[-1] if "}" in tag else tag


def fetch_usfx_xml():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    xml_path = CACHE_DIR / "eng-kjv_usfx.xml"
    if xml_path.exists():
        return xml_path
    zip_path = CACHE_DIR / "eng-kjv_usfx.zip"
    request = urllib.request.Request(USFX_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request) as response:
        zip_path.write_bytes(response.read())
    with zipfile.ZipFile(zip_path) as zf:
        zf.extract("eng-kjv_usfx.xml", CACHE_DIR)
    return xml_path


def load_manifest():
    with open(BIBLE_DIR / "manifest.json", encoding="utf-8") as f:
        entries = json.load(f)
    return {e["book"]: e for e in entries}


class VerseCollector:
    """Walks a <book> element's subtree in document order, accumulating text
    only while "inside" a verse span (between a <v> marker and its <ve/>),
    via proper .text/.tail concatenation - never regex - so a word can't be
    silently dropped regardless of how deeply it's nested (<q>, <nd>, <wj>,
    <add> etc. all just wrap words that belong in the verse). <f> (footnote)
    subtrees are skipped entirely; everything outside any verse span (book
    titles, section headings, Psalm/song descriptive titles) is naturally
    excluded since nothing accumulates until a <v> opens one."""

    def __init__(self):
        self.verses = {}  # (chapter, verse) -> list of text chunks
        self.chapter = None
        self.verse = None

    def close_verse(self):
        self.verse = None

    def open_verse(self, verse_num):
        self.verse = verse_num
        self.verses.setdefault((self.chapter, self.verse), [])

    def add_text(self, text):
        if self.verse is not None and text:
            self.verses[(self.chapter, self.verse)].append(text)

    def walk(self, elem, skip=False):
        tag = local(elem.tag)
        if tag == "f":
            skip = True
        elif not skip:
            if tag == "c":
                self.chapter = int(elem.get("id"))
                self.close_verse()
            elif tag == "v":
                self.open_verse(int(elem.get("id")))
            elif tag == "ve":
                self.close_verse()
            elif elem.text:
                self.add_text(elem.text)
        for child in elem:
            self.walk(child, skip=skip)
            if not skip and child.tail:
                self.add_text(child.tail)


PILCROW_RE = re.compile(r"¶\s?")
WHITESPACE_RE = re.compile(r"\s+")


def clean_verse_text(chunks):
    text = "".join(chunks)
    text = PILCROW_RE.sub("", text)
    text = WHITESPACE_RE.sub(" ", text).strip()
    return text


def parse_book(book_elem):
    collector = VerseCollector()
    collector.walk(book_elem)
    by_chapter = {}
    for (chapter, verse), chunks in collector.verses.items():
        text = clean_verse_text(chunks)
        if not text:
            continue
        by_chapter.setdefault(chapter, {})[verse] = text

    chapter_list = []
    for chapter_num in sorted(by_chapter):
        verse_map = by_chapter[chapter_num]
        max_verse = max(verse_map)
        verse_list = [verse_map.get(v, "") for v in range(1, max_verse + 1)]
        chapter_list.append({"chapter": chapter_num, "verses": verse_list})
    return chapter_list


def sanity_check(canonical_name, chapter_list, manifest_entry, warnings):
    expected_chapters = manifest_entry["chapterCount"]
    if len(chapter_list) != expected_chapters:
        warnings.append(
            f"{canonical_name}: produced {len(chapter_list)} chapters, manifest expects {expected_chapters}"
        )
    current_path = BIBLE_DIR / f"{manifest_entry['slug']}.json"
    if not current_path.exists():
        return
    with open(current_path, encoding="utf-8") as f:
        current = json.load(f)
    current_counts = {c["chapter"]: len(c["verses"]) for c in current["chapters"]}
    for c in chapter_list:
        expected = current_counts.get(c["chapter"])
        if expected is not None and expected != len(c["verses"]):
            warnings.append(
                f"{canonical_name} {c['chapter']}: produced {len(c['verses'])} verses, "
                f"current file has {expected}"
            )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=str(REPO_ROOT / "Scripts/_usfx_reparse_output"))
    args = parser.parse_args()
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    manifest = load_manifest()
    warnings = []

    xml_path = fetch_usfx_xml()
    print(f"Parsing {xml_path}...")
    tree = ET.parse(xml_path)
    root = tree.getroot()
    ns = root.tag.split("}", 1)[0] + "}" if root.tag.startswith("{") else ""

    written = 0
    for book_elem in root.findall(f"{ns}book"):
        usfx_code = book_elem.get("id")
        if usfx_code == "FRT":
            continue
        canonical_name = USFX_BOOK_TO_CANONICAL.get(usfx_code)
        if canonical_name is None:
            warnings.append(f"unrecognized USFX book code {usfx_code!r}, skipping")
            continue
        entry = manifest.get(canonical_name)
        if entry is None:
            warnings.append(f"no manifest entry for book {canonical_name!r}, skipping")
            continue

        chapter_list = parse_book(book_elem)
        sanity_check(canonical_name, chapter_list, entry, warnings)
        book_json = {"book": canonical_name, "chapters": chapter_list}
        out_path = out_dir / f"{entry['slug']}.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(book_json, f, ensure_ascii=False)
        written += 1

    print(f"Wrote {written} books to {out_dir}")
    if warnings:
        print(f"\n{len(warnings)} warning(s):", file=sys.stderr)
        for w in warnings:
            print(f"  - {w}", file=sys.stderr)
    else:
        print("No warnings.")


if __name__ == "__main__":
    main()
