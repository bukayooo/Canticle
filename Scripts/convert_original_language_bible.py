#!/usr/bin/env python3
"""One-off conversion of the OpenScriptures Hebrew Bible (OSIS XML), MorphGNT/
SBLGNT (tab-delimited txt), CCAT/CATSS morphologically-tagged Septuagint
(Beta Code .mlxx), and the Vulgate's Latin 2 Esdras (scraped from vulgate.org)
into per-book JSON files matching the app's existing Bible JSON schema, so
they can be bundled as an "original languages" alternative to the KJV/AV
English text.

Not part of the app build - run manually whenever the source corpora change:

    python3 Scripts/convert_original_language_bible.py

Requires: pip install betacode pygtrie

Reads:
    ~/Downloads/Old Testament/*.xml       (OSIS, Westminster Leningrad Codex)
    ~/Downloads/New Testament/*-morphgnt.txt
    https://ccat.sas.upenn.edu/gopher/text/religion/biblical/lxxmorph/*.mlxx (cached locally)
    https://vulgate.org/ot/4esdras_*.htm (cached locally)

Writes:
    Canticle/Canticle/Canticle/Resources/BibleOriginal/<slug>.json
"""
import html
import json
import re
import sys
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

try:
    import betacode.conv as betacode
except ImportError:
    sys.exit("Missing dependency - run: pip install betacode pygtrie")

REPO_ROOT = Path(__file__).resolve().parent.parent
BIBLE_DIR = REPO_ROOT / "Canticle/Canticle/Resources/Bible"
OUTPUT_DIR = REPO_ROOT / "Canticle/Canticle/Resources/BibleOriginal"
PSALTER_DIR = REPO_ROOT / "Canticle/Canticle/Resources/Psalter"
OT_SOURCE_DIR = Path.home() / "Downloads/Old Testament"
NT_SOURCE_DIR = Path.home() / "Downloads/New Testament"
CACHE_DIR = Path(tempfile.gettempdir()) / "canticle_apocrypha_cache"
CCAT_BASE_URL = "https://ccat.sas.upenn.edu/gopher/text/religion/biblical/lxxmorph/"
VULGATE_BASE_URL = "https://vulgate.org/ot/"

# Apocrypha books whose Greek text is a single, ordinary .mlxx file - no
# recombination or verse-slicing needed beyond the generic parser. Tobit uses
# the Vaticanus/Alexandrinus recension (the shorter text-form that actually
# circulated as "the" Greek Bible historically) over the longer Sinaiticus
# text; Susanna and Bel and the Dragon use Theodotion's translation (the one
# that became liturgically standard) over the Old Greek.
APOCRYPHA_LXX_BOOKS = {
    "Tobit": "22.TobitBA.mlxx",
    "Judith": "21.Judith.mlxx",
    "Wisdom of Solomon": "35.Wisdom.mlxx",
    "Ecclesiasticus": "36.Sirach.mlxx",
    "Susanna": "64.SusTh.mlxx",
    "Bel and the Dragon": "60.BelTh.mlxx",
    "1 Maccabees": "24.1Macc.mlxx",
    "2 Maccabees": "25.2Macc.mlxx",
    "1 Esdras": "18.1Esdras.mlxx",
}

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


def fetch_cached(url, cache_name):
    """Downloads url on first use and caches it under CACHE_DIR, so repeated
    script runs (e.g. while iterating on parsing logic) don't re-fetch."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_path = CACHE_DIR / cache_name
    if not cache_path.exists():
        request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(request) as response:
            cache_path.write_bytes(response.read())
    return cache_path


def parse_mlxx_verses(path):
    """Parses a CCAT/CATSS .mlxx file (verse-marker line "BookAbbrev Ch:V",
    then one word per line with the Beta-Code word as the first
    whitespace-separated column) into {(chapter, verse): unicode_text}.
    Single-chapter books (e.g. the Epistle of Jeremiah) mark verses as plain
    "BookAbbrev V" with no chapter number at all - treated as chapter 1.
    Unlike MorphGNT, this corpus carries no punctuation at all - verses are
    plain space-joined word streams."""
    verses = {}
    chapter = verse = None
    words = []

    def flush():
        if chapter is not None and words:
            verses[(chapter, verse)] = " ".join(words)

    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            m = re.match(r"^[A-Za-z0-9]+ (\d+):(\d+)$", line) or re.match(r"^[A-Za-z0-9]+ (\d+)()$", line)
            if m:
                flush()
                chapter, verse = (int(m.group(1)), int(m.group(2))) if m.group(2) else (1, int(m.group(1)))
                words = []
                continue
            beta_word = line.split()[0]
            words.append(betacode.beta_to_uni(beta_word))
    flush()
    return verses


def verses_to_chapter_list(verses, renumber_as_single_chapter=False):
    """Groups a {(chapter, verse): text} dict into the app's chapter/verse
    JSON shape. If renumber_as_single_chapter is set, the dict is emitted as
    a single chapter 1 in (chapter, verse) order, starting at verse 1 -
    used for extracted sub-passages (Prayer of Azariah, Prayer of Manasseh)
    that don't keep their host book's own numbering."""
    if renumber_as_single_chapter:
        ordered = sorted(verses.items())
        return [{"chapter": 1, "verses": [text for _, text in ordered]}]

    by_chapter = {}
    for (chapter, verse), text in verses.items():
        by_chapter.setdefault(chapter, {})[verse] = text
    chapter_list = []
    for chapter_num in sorted(by_chapter):
        verse_map = by_chapter[chapter_num]
        max_verse = max(verse_map)
        verse_list = [verse_map.get(v, "") for v in range(1, max_verse + 1)]
        chapter_list.append({"chapter": chapter_num, "verses": verse_list})
    return chapter_list


def convert_simple_lxx_book(filename):
    path = fetch_cached(CCAT_BASE_URL + filename, filename)
    verses = parse_mlxx_verses(path)
    return verses_to_chapter_list(verses)


def convert_baruch():
    baruch_path = fetch_cached(CCAT_BASE_URL + "54.Baruch.mlxx", "54.Baruch.mlxx")
    epjer_path = fetch_cached(CCAT_BASE_URL + "55.EpJer.mlxx", "55.EpJer.mlxx")
    verses = parse_mlxx_verses(baruch_path)
    epjer_verses = parse_mlxx_verses(epjer_path)
    # The Epistle of Jeremiah is bundled as Baruch chapter 6 in the standalone
    # English book; the source treats it as its own single-chapter work, so
    # renumber its own chapter to 6, keeping its verse numbers as-is.
    for (_, verse), text in epjer_verses.items():
        verses[(6, verse)] = text
    return verses_to_chapter_list(verses)


def convert_prayer_of_azariah():
    path = fetch_cached(CCAT_BASE_URL + "62.DanielTh.mlxx", "62.DanielTh.mlxx")
    verses = parse_mlxx_verses(path)
    # The Prayer of Azariah and Song of the Three Young Men is inserted into
    # Theodotion's Daniel 3 between the Hebrew/Aramaic's verses 23 and 24;
    # verified against the existing English text that it runs 3:24-3:90
    # (67 verses) and renumbers as its own chapter 1, verses 1-67.
    extracted = {(3, v): t for (c, v), t in verses.items() if c == 3 and 24 <= v <= 90}
    return verses_to_chapter_list(extracted, renumber_as_single_chapter=True)


def convert_prayer_of_manasseh():
    path = fetch_cached(CCAT_BASE_URL + "30.Odes.mlxx", "30.Odes.mlxx")
    verses = parse_mlxx_verses(path)
    # The Prayer of Manasseh is Ode 12 in the Odes appendix that follows
    # Psalms in Septuagint manuscripts; the Odes file uses "Od N:V" verse
    # markers matching the general "Chapter:Verse" parser, with "Od" as the
    # book abbreviation and 12 as the chapter number.
    extracted = {(12, v): t for (c, v), t in verses.items() if c == 12}
    return verses_to_chapter_list(extracted, renumber_as_single_chapter=True)


def parse_esther_lettered_verses(path):
    """Like parse_mlxx_verses, but keyed by (chapter, verse, letter) so the
    Additions' lettered sub-verses (e.g. "Esth 1:1a") aren't collapsed onto
    their base verse number - ordinary verses get letter=""."""
    verses = {}
    key = None
    words = []

    def flush():
        if key is not None and words:
            verses[key] = " ".join(words)

    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            m = re.match(r"^Esth (\d+):(\d+)([a-z]?)$", line)
            if m:
                flush()
                key = (int(m.group(1)), int(m.group(2)), m.group(3))
                words = []
                continue
            beta_word = line.split()[0]
            words.append(betacode.beta_to_uni(beta_word))
    flush()
    return verses


def convert_additions_to_esther():
    """The six Additions survive only interspersed within the Greek Esther,
    marked with lettered sub-verses (e.g. 1:1a-1:1s for Addition A). The
    standalone English "Additions to Esther" instead uses a Vulgate-era
    convention (chapters 10-16) that isn't reproduced here: counting both
    texts shows 89 Greek lettered verses against 104 English verses, a real
    split-differently mismatch rather than just a numbering-label difference
    (investigated and confirmed - see conversation/commit history), so
    forcing alignment would risk silently misattributing verses. Nothing in
    this app cites "Additions to Esther" by chapter:verse (the lectionary
    only ever references canonical Esther, and there's no general
    Bible-browsing view), so there's no functional requirement to match the
    English numbering - this instead emits the six Additions as their own
    chapters, in the order they appear in the Greek text, each using its own
    natural lettered-verse sequence."""
    path = fetch_cached(CCAT_BASE_URL + "20.Esther.mlxx", "20.Esther.mlxx")
    verses = parse_esther_lettered_verses(path)

    # (anchor chapter, anchor verse) pairs marking where each Addition's
    # lettered verses are attached; Addition D is unique in spanning two
    # anchors (5:1 and 5:2).
    additions = [
        [(1, 1)],   # A - prologue before ch.1 (Mordecai's dream)
        [(3, 13)],  # B - the king's decree, within ch.3
        [(4, 17)],  # C - Mordecai's and Esther's prayers, within ch.4
        [(5, 1), (5, 2)],  # D - Esther's audience with the king, within ch.5
        [(8, 12)],  # E - the king's second decree, within ch.8
        [(10, 3)],  # F - colophon / interpretation of the dream, after ch.10
    ]

    chapter_list = []
    for chapter_num, anchors in enumerate(additions, start=1):
        ordered = sorted(
            (verse, letter, text)
            for (chapter, verse, letter), text in verses.items()
            if letter and (chapter, verse) in anchors
        )
        chapter_list.append({"chapter": chapter_num, "verses": [text for _, _, text in ordered]})
    return chapter_list


def convert_latin_2esdras():
    chapter_list = []
    for chapter_num in range(1, 17):
        filename = f"4esdras_{chapter_num}.htm"
        path = fetch_cached(VULGATE_BASE_URL + filename, filename)
        page = path.read_text(encoding="utf-8", errors="replace")
        matches = re.findall(
            r'<SUP class="Vulgate">(\d+)</SUP>.*?<span class="Latin">(.*?)</span>',
            page,
            re.DOTALL,
        )
        verse_map = {}
        for verse_str, raw_text in matches:
            text = html.unescape(" ".join(raw_text.split()))
            # vulgate.org's own HTML occasionally has a stray space before
            # verse-final punctuation (e.g. "disciplina ." instead of
            # "disciplina.") - confirmed against an independent transcription
            # (CCEL) that no word is actually missing there, just a formatting
            # quirk in this source, so it's safe to collapse generically.
            text = re.sub(r"\s+([:;,.!?])", r"\1", text)
            verse_map[int(verse_str)] = text
        max_verse = max(verse_map)
        verse_list = [verse_map.get(v, "") for v in range(1, max_verse + 1)]
        chapter_list.append({"chapter": chapter_num, "verses": verse_list})
    return chapter_list


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


def write_book(canonical_name, chapter_list, manifest, warnings, skip_sanity_check=False):
    entry = manifest.get(canonical_name)
    if entry is None:
        warnings.append(f"no manifest entry for book {canonical_name!r}, skipping")
        return
    if not skip_sanity_check:
        sanity_check(canonical_name, chapter_list, entry, warnings)
    book_json = {"book": canonical_name, "chapters": chapter_list}
    out_path = OUTPUT_DIR / f"{entry['slug']}.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(book_json, f, ensure_ascii=False)
    print(f"  wrote {out_path.name}")


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

    print("Converting Apocrypha (Greek Septuagint + Latin 2 Esdras)...")
    for canonical_name, filename in APOCRYPHA_LXX_BOOKS.items():
        write_book(canonical_name, convert_simple_lxx_book(filename), manifest, warnings)
    write_book("Baruch", convert_baruch(), manifest, warnings)
    write_book("Prayer of Azariah", convert_prayer_of_azariah(), manifest, warnings)
    write_book("Prayer of Manasseh", convert_prayer_of_manasseh(), manifest, warnings)
    write_book("2 Esdras", convert_latin_2esdras(), manifest, warnings)
    # Deliberately renumbered (see convert_additions_to_esther docstring) -
    # comparing against the English chapters 10-16 would just produce noisy,
    # meaningless warnings since the two numbering schemes don't correspond.
    write_book(
        "Additions to Esther", convert_additions_to_esther(), manifest, warnings, skip_sanity_check=True
    )

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
