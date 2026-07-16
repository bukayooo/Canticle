#!/usr/bin/env python3
"""One-off conversion of the OpenScriptures Hebrew Bible (OSIS XML) and
MorphGNT/SBLGNT (tab-delimited txt) source corpora into per-book JSON files
matching the app's existing Bible JSON schema, so they can be bundled as an
"original languages" alternative to the KJV/AV English text.

Not part of the app build - run manually whenever the source corpora change:

    python3 Scripts/convert_original_language_bible.py

Reads:
    ~/Downloads/Old Testament/*.xml       (OSIS, Westminster Leningrad Codex)
    ~/Downloads/New Testament/*-morphgnt.txt

Writes:
    Canticle/Canticle/Canticle/Resources/BibleOriginal/<slug>.json
"""
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BIBLE_DIR = REPO_ROOT / "Canticle/Canticle/Resources/Bible"
OUTPUT_DIR = REPO_ROOT / "Canticle/Canticle/Resources/BibleOriginal"
PSALTER_DIR = REPO_ROOT / "Canticle/Canticle/Resources/Psalter"
OT_SOURCE_DIR = Path.home() / "Downloads/Old Testament"
NT_SOURCE_DIR = Path.home() / "Downloads/New Testament"

OSIS_BOOK_TO_CANONICAL = {
    "Gen": "Genesis", "Exod": "Exodus", "Lev": "Leviticus", "Num": "Numbers",
    "Deut": "Deuteronomy", "Josh": "Joshua", "Judg": "Judges", "Ruth": "Ruth",
    "1Sam": "1 Samuel", "2Sam": "2 Samuel", "1Kgs": "1 Kings", "2Kgs": "2 Kings",
    "1Chr": "1 Chronicles", "2Chr": "2 Chronicles", "Ezra": "Ezra", "Neh": "Nehemiah",
    "Esth": "Esther", "Job": "Job", "Ps": "Psalms", "Prov": "Proverbs",
    "Eccl": "Ecclesiastes", "Song": "Song of Solomon", "Isa": "Isaiah",
    "Jer": "Jeremiah", "Lam": "Lamentations", "Ezek": "Ezekiel", "Dan": "Daniel",
    "Hos": "Hosea", "Joel": "Joel", "Amos": "Amos", "Obad": "Obadiah",
    "Jonah": "Jonah", "Mic": "Micah", "Nah": "Nahum", "Hab": "Habakkuk",
    "Zeph": "Zephaniah", "Hag": "Haggai", "Zech": "Zechariah", "Mal": "Malachi",
}

NT_FILENAME_TO_CANONICAL = {
    "61-Mt": "Matthew", "62-Mk": "Mark", "63-Lk": "Luke", "64-Jn": "John",
    "65-Ac": "Acts", "66-Ro": "Romans", "67-1Co": "1 Corinthians",
    "68-2Co": "2 Corinthians", "69-Ga": "Galatians", "70-Eph": "Ephesians",
    "71-Php": "Philippians", "72-Col": "Colossians", "73-1Th": "1 Thessalonians",
    "74-2Th": "2 Thessalonians", "75-1Ti": "1 Timothy", "76-2Ti": "2 Timothy",
    "77-Tit": "Titus", "78-Phm": "Philemon", "79-Heb": "Hebrews", "80-Jas": "James",
    "81-1Pe": "1 Peter", "82-2Pe": "2 Peter", "83-1Jn": "1 John", "84-2Jn": "2 John",
    "85-3Jn": "3 John", "86-Jud": "Jude", "87-Re": "Revelation",
}


def local(tag):
    return tag.split("}", 1)[-1] if "}" in tag else tag


def load_manifest():
    with open(BIBLE_DIR / "manifest.json", encoding="utf-8") as f:
        entries = json.load(f)
    return {e["book"]: e for e in entries}


def word_text(el):
    """Full text of a <w> element, including a letter inside a nested
    <seg type="x-large/x-small/x-suspended"> (a single Masoretic letter given
    special typography) - itertext() picks up both the seg's own text and
    whatever surrounds it inside the same <w>, whereas el.text alone would
    silently drop that letter.

    OSHB also marks morpheme boundaries *within* a word using a literal "/"
    (e.g. "בְּ/רֵאשִׁית" = the prefixed preposition "in" + "beginning") - a
    scholarly convention for morphological study, not an orthographic
    character, so it's stripped for continuous reading text."""
    return "".join(el.itertext()).strip().replace("/", "")


def find_qere_word(note_el, ns):
    rdg = note_el.find(f"{ns}rdg")
    if rdg is None:
        return None
    w = rdg.find(f"{ns}w")
    if w is None:
        return None
    text = word_text(w)
    return text or None


def process_verse(verse_el, ns, osis_book_code, chapter, verse, warnings, verses):
    """Walk a verse's children once, accumulating reconstructed text into
    `verses` (keyed by (canonical_book, chapter, verse)). A verse normally
    maps entirely onto its own (book, chapter, verse) identity, but a plain
    <note>KJV:Book.Ch.V</note> child mid-stream retargets everything from
    that point on - which is how the source marks both whole-verse
    renumbering (Psalms superscriptions, the Joel/Malachi chapter shifts,
    etc.) and the rarer case of a single WLC verse split across a KJV verse
    boundary (e.g. 1 Kings 22:21/22): the note sits at the exact word where
    the split happens, so no separate versification table is needed."""
    current_target = (OSIS_BOOK_TO_CANONICAL[osis_book_code], chapter, verse)
    parts = []  # list of (text, glue_left, glue_right) for the current target

    def flush():
        nonlocal current_target
        if not parts:
            return
        text = ""
        prev_glue_right = False
        for idx, (t, glue_left, glue_right) in enumerate(parts):
            if idx == 0 or glue_left or prev_glue_right:
                text += t
            else:
                text += " " + t
            prev_glue_right = glue_right
        if current_target in verses:
            verses[current_target] += " " + text
        else:
            verses[current_target] = text
        parts.clear()

    children = list(verse_el)
    i = 0
    n = len(children)
    while i < n:
        el = children[i]
        tag = local(el.tag)

        if tag == "note":
            note_type = el.get("type")
            if note_type == "variant":
                qw = find_qere_word(el, ns)
                if qw is not None:
                    parts.append((qw, False, False))
                # else: qere is explicitly empty ("not read"), standalone
                # (no preceding ketiv consumed here) - nothing to add.
                i += 1
                continue
            text = (el.text or "").strip()
            m = re.match(r"KJV:(\w+)\.(\d+)\.(\d+)", text)
            if m:
                flush()
                book_code, kjv_ch, kjv_v = m.group(1), int(m.group(2)), int(m.group(3))
                current_target = (OSIS_BOOK_TO_CANONICAL.get(book_code, book_code), kjv_ch, kjv_v)
            # else: editorial/critical-apparatus note (large/small/suspended
            # letter callouts, Leningrad-vs-BHS notes, etc.) - not verse text.
            i += 1
            continue

        if tag == "w":
            text = word_text(el)
            if el.get("type") == "x-ketiv":
                nxt = children[i + 1] if i + 1 < n else None
                if nxt is not None and local(nxt.tag) == "note" and nxt.get("type") == "variant":
                    qw = find_qere_word(nxt, ns)
                    if qw is not None:
                        parts.append((qw, False, False))
                    # else empty qere -> word marked "not read", omit entirely.
                    i += 2
                    continue
                # ketiv with no paired qere note - fall back to the ketiv text.
                parts.append((text, False, False))
                i += 1
                continue
            parts.append((text, False, False))
            i += 1
            continue

        if tag == "seg":
            segtype = el.get("type")
            segtext = (el.text or "").strip()
            if segtype == "x-maqqef":
                parts.append((segtext, True, True))
            elif segtype == "x-sof-pasuq":
                parts.append((segtext, True, False))
            elif segtype == "x-paseq":
                parts.append((segtext, False, False))
            elif segtype in ("x-pe", "x-samekh", "x-reversednun"):
                pass  # parashah/scribal marginal markers, not verse text.
            else:
                warnings.append(f"unrecognized seg type {segtype!r} in {verse_el.get('osisID')}")
                parts.append((segtext, False, False))
            i += 1
            continue

        warnings.append(f"unrecognized element <{tag}> in {verse_el.get('osisID')}")
        i += 1

    flush()


def reconstruct_plain_verse_text(verse_el, ns, warnings):
    """Like process_verse, but ignores <note>KJV:...</note> retargeting entirely -
    used for the Psalter's own Hebrew text, which (unlike the Lesson-reading
    BibleOriginal text) doesn't need KJV-aligned verse numbers, just each
    Psalm's natural Masoretic verses in order."""
    parts = []

    children = list(verse_el)
    i = 0
    n = len(children)
    while i < n:
        el = children[i]
        tag = local(el.tag)

        if tag == "note":
            if el.get("type") == "variant":
                qw = find_qere_word(el, ns)
                if qw is not None:
                    parts.append((qw, False, False))
            i += 1
            continue

        if tag == "w":
            text = word_text(el)
            if el.get("type") == "x-ketiv":
                nxt = children[i + 1] if i + 1 < n else None
                if nxt is not None and local(nxt.tag) == "note" and nxt.get("type") == "variant":
                    qw = find_qere_word(nxt, ns)
                    if qw is not None:
                        parts.append((qw, False, False))
                    i += 2
                    continue
                parts.append((text, False, False))
                i += 1
                continue
            parts.append((text, False, False))
            i += 1
            continue

        if tag == "seg":
            segtype = el.get("type")
            segtext = (el.text or "").strip()
            if segtype == "x-maqqef":
                parts.append((segtext, True, True))
            elif segtype == "x-sof-pasuq":
                parts.append((segtext, True, False))
            elif segtype == "x-paseq":
                parts.append((segtext, False, False))
            elif segtype in ("x-pe", "x-samekh", "x-reversednun"):
                pass
            else:
                warnings.append(f"unrecognized seg type {segtype!r} in {verse_el.get('osisID')}")
                parts.append((segtext, False, False))
            i += 1
            continue

        warnings.append(f"unrecognized element <{tag}> in {verse_el.get('osisID')}")
        i += 1

    text = ""
    prev_glue_right = False
    for idx, (t, glue_left, glue_right) in enumerate(parts):
        if idx == 0 or glue_left or prev_glue_right:
            text += t
        else:
            text += " " + t
        prev_glue_right = glue_right
    return text


def convert_hebrew_psalter(xml_path, warnings):
    """Builds Hebrew Psalms for the 1662 Psalter display (Resources/Psalter), which
    always shows a *complete* psalm rather than a verse range - so, unlike
    BibleOriginal/psalms_kjv.json (built for KJV-aligned Lesson references),
    this uses each Psalm's own natural Masoretic verse numbering. Per
    VerseMap.xml's own comment, every KJV-versification note in Psalms exists
    solely because the WLC counts the superscription as verse 1 where the KJV
    doesn't number it at all - so a chapter having any such note at all means
    its WLC verse 1 is a superscription, split out here as `title` (matching
    the Coverdale Psalter JSON's title/verses shape) rather than left as
    verse 1 of the body."""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    ns = root.tag.split("}", 1)[0] + "}" if root.tag.startswith("{") else ""

    psalms = []
    for chapter_el in root.iter(f"{ns}chapter"):
        chapter_num = int(chapter_el.get("osisID").split(".")[-1])
        verse_els = chapter_el.findall(f"{ns}verse")

        # Find the first WLC verse annotated as KJV's verse 1. Usually that's
        # WLC verse 1 itself (no split needed - Psalm 23's ascription is part
        # of verse 1 in both numbering systems), but a handful of psalms have
        # a superscription spanning *two* WLC verses (e.g. Psalm 51 names
        # Nathan the prophet across WLC 51:1-2, with real content starting at
        # WLC 51:3 = KJV 51:1) - so this scans rather than assuming a fixed
        # one-verse offset. No match at all (the ordinary case) means no
        # superscription and nothing to split out.
        body_start = 0
        found = False
        for idx, verse_el in enumerate(verse_els):
            for child in verse_el:
                if local(child.tag) == "note" and child.get("type") is None:
                    text = (child.text or "").strip()
                    m = re.match(r"KJV:\w+\.\d+\.(\d+)", text)
                    if m and int(m.group(1)) == 1:
                        body_start = idx
                        found = True
                        break
            if found:
                break

        title_els = verse_els[:body_start]
        body_els = verse_els[body_start:]
        title = " ".join(reconstruct_plain_verse_text(v, ns, warnings) for v in title_els)
        verses = [reconstruct_plain_verse_text(v, ns, warnings) for v in body_els]
        psalms.append({"number": chapter_num, "title": title, "verses": verses})

    psalms.sort(key=lambda p: p["number"])
    for p in psalms:
        expected = 176 if p["number"] == 119 else None
        if expected is not None and len(p["verses"]) != expected:
            warnings.append(f"Psalm {p['number']}: expected {expected} verses (acrostic), got {len(p['verses'])}")
    return psalms


def convert_ot_book(xml_path, warnings):
    tree = ET.parse(xml_path)
    root = tree.getroot()
    ns = root.tag.split("}", 1)[0] + "}" if root.tag.startswith("{") else ""
    osis_book_code = xml_path.stem

    verses = {}  # (canonical_book, chapter, verse) -> text
    for chapter_el in root.iter(f"{ns}chapter"):
        chapter_num = int(chapter_el.get("osisID").split(".")[-1])
        for verse_el in chapter_el.findall(f"{ns}verse"):
            verse_num = int(verse_el.get("osisID").split(".")[-1])
            process_verse(verse_el, ns, osis_book_code, chapter_num, verse_num, warnings, verses)

    return group_into_book_json(verses)


def group_into_book_json(verses):
    by_book = {}
    for (book, chapter, verse), text in verses.items():
        by_book.setdefault(book, {}).setdefault(chapter, {})[verse] = text
    books = {}
    for book, chapters in by_book.items():
        chapter_list = []
        for chapter_num in sorted(chapters):
            verse_map = chapters[chapter_num]
            max_verse = max(verse_map)
            verse_list = [verse_map.get(v, "") for v in range(1, max_verse + 1)]
            chapter_list.append({"chapter": chapter_num, "verses": verse_list})
        books[book] = {"book": book, "chapters": chapter_list}
    return books


def convert_nt_book(txt_path):
    verses = {}
    with open(txt_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            fields = line.split()
            bcv, text = fields[0], fields[3]
            chapter, verse = int(bcv[2:4]), int(bcv[4:6])
            verses.setdefault(chapter, {}).setdefault(verse, []).append(text)

    chapter_list = []
    for chapter_num in sorted(verses):
        verse_map = verses[chapter_num]
        max_verse = max(verse_map)
        verse_list = [" ".join(verse_map.get(v, [])) for v in range(1, max_verse + 1)]
        chapter_list.append({"chapter": chapter_num, "verses": verse_list})
    return chapter_list


def sanity_check(canonical_name, chapter_list, manifest_entry, warnings):
    expected_chapters = manifest_entry["chapterCount"]
    if len(chapter_list) != expected_chapters:
        warnings.append(
            f"{canonical_name}: produced {len(chapter_list)} chapters, manifest expects {expected_chapters}"
        )
    english_path = BIBLE_DIR / f"{manifest_entry['slug']}.json"
    if not english_path.exists():
        return
    with open(english_path, encoding="utf-8") as f:
        english = json.load(f)
    english_counts = {c["chapter"]: len(c["verses"]) for c in english["chapters"]}
    for c in chapter_list:
        expected = english_counts.get(c["chapter"])
        if expected is not None and expected != len(c["verses"]):
            warnings.append(
                f"{canonical_name} {c['chapter']}: produced {len(c['verses'])} verses, "
                f"English text has {expected}"
            )


def main():
    manifest = load_manifest()
    warnings = []
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("Converting Old Testament (Hebrew)...")
    ot_books = {}
    for xml_path in sorted(OT_SOURCE_DIR.glob("*.xml")):
        if xml_path.stem == "VerseMap":
            continue
        ot_books.update(convert_ot_book(xml_path, warnings))

    for canonical_name, book_json in ot_books.items():
        entry = manifest.get(canonical_name)
        if entry is None:
            warnings.append(f"no manifest entry for OT book {canonical_name!r}, skipping")
            continue
        sanity_check(canonical_name, book_json["chapters"], entry, warnings)
        out_path = OUTPUT_DIR / f"{entry['slug']}.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(book_json, f, ensure_ascii=False)
        print(f"  wrote {out_path.name}")

    print("Converting New Testament (Greek)...")
    for txt_path in sorted(NT_SOURCE_DIR.glob("*-morphgnt.txt")):
        prefix = txt_path.stem.replace("-morphgnt", "")
        canonical_name = NT_FILENAME_TO_CANONICAL.get(prefix)
        if canonical_name is None:
            warnings.append(f"unrecognized NT filename {txt_path.name}, skipping")
            continue
        entry = manifest.get(canonical_name)
        if entry is None:
            warnings.append(f"no manifest entry for NT book {canonical_name!r}, skipping")
            continue
        chapter_list = convert_nt_book(txt_path)
        sanity_check(canonical_name, chapter_list, entry, warnings)
        book_json = {"book": canonical_name, "chapters": chapter_list}
        out_path = OUTPUT_DIR / f"{entry['slug']}.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(book_json, f, ensure_ascii=False)
        print(f"  wrote {out_path.name}")

    print("Converting Psalter (Hebrew, natural verse divisions)...")
    psalms = convert_hebrew_psalter(OT_SOURCE_DIR / "Ps.xml", warnings)
    if len(psalms) != 150:
        warnings.append(f"Hebrew Psalter: produced {len(psalms)} psalms, expected 150")
    psalter_out_path = PSALTER_DIR / "psalms_hebrew.json"
    with open(psalter_out_path, "w", encoding="utf-8") as f:
        json.dump(psalms, f, ensure_ascii=False)
    print(f"  wrote {psalter_out_path.name}")

    if warnings:
        print(f"\n{len(warnings)} warning(s):", file=sys.stderr)
        for w in warnings:
            print(f"  - {w}", file=sys.stderr)
    else:
        print("\nNo warnings.")


if __name__ == "__main__":
    main()
