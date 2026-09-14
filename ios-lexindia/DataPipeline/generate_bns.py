#!/usr/bin/env python3
"""
LexIndia BNS data pipeline.

Extracts the full text of the Bharatiya Nyaya Sanhita, 2023 from the official
Gazette PDF and emits per-chapter section JSON files for the app bundle,
merging hand-curated plain-language guides on top of the extracted text.

Stages:
  extract  — PDF -> /tmp/bns/runs.jsonl  (page text runs with coordinates)
             usage: generate_bns.py extract <pdf> <start_page> <end_page>
  snapshot — copy legacy curated sections into curated_bns_legacy.json
  build    — runs.jsonl -> Resources/BNS_ChXX.json + validation report

Gazette layout (raw text-matrix coordinates):
  x ~120       marginal notes on even pages (outer/left margin)
  x ~1011-1016 marginal notes on odd pages (outer/right margin)
  x ~245       body continuation lines (flush left)
  x ~295       paragraph starts, x ~345-570 clause indents / centered headings
  header line  "THE GAZETTE OF INDIA EXTRAORDINARY [PART II ...]" + page number
  x==0,y==0    trailing per-page aggregate duplicate (dropped)
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
RES = os.path.normpath(os.path.join(ROOT, "..", "LexIndia", "Resources"))
CACHE = "/tmp/bns/runs.jsonl"

EXPECTED_RANGES = {
    1: (1, 3), 2: (4, 13), 3: (14, 44), 4: (45, 62), 5: (63, 99),
    6: (100, 146), 7: (147, 158), 8: (159, 168), 9: (169, 177),
    10: (178, 188), 11: (189, 197), 12: (198, 205), 13: (206, 226),
    14: (227, 269), 15: (270, 297), 16: (298, 302), 17: (303, 334),
    18: (335, 350), 19: (351, 357), 20: (358, 358),
}

PLACEHOLDER_GUIDE = (
    "The plain-language LexIndia guide for this section is being prepared. "
    "The official text above is the authoritative wording of the law."
)

STOPWORDS = {
    "of", "the", "and", "for", "with", "from", "into", "to", "in", "by", "or",
    "any", "etc", "when", "who", "not", "under", "upon", "than", "which",
    "shall", "being", "after", "before", "having", "other", "such", "a", "an",
    "on", "as", "at", "is", "be", "done", "act", "acts", "section", "matters",
    "against", "relating", "committed", "commit", "cases", "certain",
}


def chapter_of(num: int) -> int:
    for ch, (lo, hi) in EXPECTED_RANGES.items():
        if lo <= num <= hi:
            return ch
    raise ValueError(f"section {num} outside known ranges")


# ---------------------------------------------------------------- extract ----

def stage_extract(pdf_path: str, start: int, end: int) -> None:
    from pypdf import PdfReader

    reader = PdfReader(pdf_path)
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    mode = "a" if start > 0 else "w"
    with open(CACHE, mode) as out:
        for index in range(start, min(end, len(reader.pages))):
            runs = []

            def visitor(text, cm, tm, font_dict, font_size):
                t = text.replace("\n", " ")
                if not t.strip():
                    return
                x, y = round(tm[4]), round(tm[5])
                if x == 0 and y == 0:
                    return  # trailing aggregate duplicate
                if re.fullmatch(r"[_\s]+", t):
                    return  # header rule drawn as underscores
                runs.append([x, y, t])

            reader.pages[index].extract_text(visitor_text=visitor)
            out.write(json.dumps({"page": index + 1, "runs": runs}) + "\n")
    print(f"extracted pages {start + 1}..{min(end, len(reader.pages))}")


# ------------------------------------------------------------------ lines ----

def group_lines(runs):
    """Group runs into visual lines by y (tolerance 3), preserving stream order."""
    lines = []
    for x, y, t in runs:
        placed = False
        for line in lines:
            if abs(line["y"] - y) <= 3:
                line["parts"].append(t)
                placed = True
                break
        if not placed:
            lines.append({"y": y, "x": x, "parts": [t]})
    for line in lines:
        line["text"] = "".join(line["parts"])
    lines.sort(key=lambda l: l["y"])
    return lines


# Case-sensitive: the running header is all-caps ("THE GAZETTE OF INDIA..."),
# while body text legitimately contains "Official Gazette" in mixed case.
HEADER_PAT = re.compile(r"GAZETTE OF INDIA|^\[?P(?:art|ART) II|^S(?:ec|EC)\.\s*\d*\]")
CITATION_PAT = re.compile(r"^\s*\d+\s+of\s+\d{4}\s*\.?\s*$")
END_PAT = re.compile(r"AKAR SINGH|Joint Secretary|Legislative Counsel|Secretary to the Govt|MGIPMRND|UPLOADED BY|PRINTED BY|GOVERNMENT OF INDIA PRESS|Digitally signed|Signature Not|^Date:|^Reason:|^Location:", re.I)


def load_pages():
    pages = []
    with open(CACHE) as f:
        for line in f:
            pages.append(json.loads(line))
    pages.sort(key=lambda p: p["page"])
    return pages


def classify(pages):
    """Split runs into body lines and margin lines, dropping gazette chrome."""
    body, margin = [], []
    for page in pages:
        runs = page["runs"]
        header_ys = {y for x, y, t in runs if HEADER_PAT.search(t.strip())}
        kept = []
        for x, y, t in runs:
            if any(abs(y - hy) <= 3 for hy in header_ys):
                continue
            kept.append([x, y, t])
        body_runs = [r for r in kept if 235 <= r[0] < 950]
        margin_runs = [r for r in kept if 50 <= r[0] < 235 or r[0] >= 950]
        for line in group_lines(body_runs):
            body.append({"page": page["page"], **line})
        for line in group_lines(margin_runs):
            margin.append({"page": page["page"], **line})
    return body, margin


# ------------------------------------------------------------------ clean ----

def clean(text: str) -> str:
    text = text.replace("\ufffd", "")
    text = text.replace("––", "—").replace("--", "—")
    text = re.sub(r"\s+", " ", text)
    text = re.sub(r"\s+([,.;:)\]])", r"\1", text)
    text = re.sub(r"([(\[])\s+", r"\1", text)
    text = re.sub(r",(?=[A-Za-z])", ", ", text)
    text = re.sub(r"(Explanation|Illustration|Exception)(\d)", r"\1 \2", text)
    text = text.replace("hawalatransaction", "hawala transaction")
    text = text.replace("“Y our", "“Your")
    return text.strip()


def title_case_clean(raw: str) -> str:
    t = clean(raw)
    t = t.rstrip(".").strip()
    # Kerning splits like "V oluntarily": titles never contain single-letter
    # party names, so joining a lone capital to a following word is safe here.
    t = re.sub(r"\b([B-Z]) (?=[a-z]{2})", r"\1", t)
    t = re.sub(r"\bof(?=property\b)", "of ", t)
    return t[:1].upper() + t[1:] if t else t


# ------------------------------------------------------------------ parse ----

SECTION_PAT = re.compile(r"^(\d{1,3})\.(?!\d)\s*(.*)$")
CHAPTER_PAT = re.compile(r"^CHAPTER\s+([IVXLC]+)\s*$")
ILLUS_PAT = re.compile(r"^Illustrations?\.?$")
# A new paragraph only ever begins with a clause label, an Explanation /
# Exception / Illustration heading, or a proviso. Everything else is a
# wrapped continuation line, whatever its indent.
STARTER_PAT = re.compile(r"^\(\s*[a-z0-9ivx]{1,5}\s*\)|^Explanations?\b|^Exceptions?\b|^Illustrations?\b|^Provided\b|^CHAPTER\b")


def parse_body(body_lines, log):
    sections = []      # dicts: number, paragraphs, page
    chapters = []      # numerals in order
    current = None
    expected = 1
    seen_chapter_1 = False
    in_chapter_title = False

    for line in body_lines:
        text = line["text"].strip()
        if not text:
            continue
        if not seen_chapter_1:
            if CHAPTER_PAT.match(text) and CHAPTER_PAT.match(text).group(1) == "I":
                seen_chapter_1 = True
                chapters.append("I")
                in_chapter_title = True
            continue
        if expected > 358 and (END_PAT.search(text) or re.fullmatch(r"[—–\-\s]{3,}", text)):
            break

        chapter_match = CHAPTER_PAT.match(text)
        if chapter_match:
            chapters.append(chapter_match.group(1))
            in_chapter_title = True
            continue
        if in_chapter_title:
            if text == text.upper() and not SECTION_PAT.match(text):
                continue  # chapter title line(s); titles come from LegalCore
            in_chapter_title = False

        section_match = SECTION_PAT.match(text)
        if section_match and int(section_match.group(1)) == expected and 260 <= line["x"] <= 340:
            if current:
                sections.append(current)
            current = {
                "number": expected,
                "page": line["page"],
                "y": line["y"],
                "paragraphs": [section_match.group(2).strip()] if section_match.group(2).strip() else [],
            }
            expected += 1
            continue

        if current is None:
            log.append(f"PREAMBLE-DROP p{line['page']}: {text[:70]}")
            continue

        if line["x"] >= 400 and text.startswith(("Of ", "of ")) and len(text) < 85 and not text.endswith((",", ";")):
            log.append(f"GROUPHEAD-DROP p{line['page']} x={line['x']}: {text[:70]}")
            continue

        if line["x"] >= 480 and not ILLUS_PAT.match(text):
            log.append(f"CENTER-KEEP p{line['page']} x={line['x']}: {text[:80]}")

        previous_is_illus = bool(current["paragraphs"]) and ILLUS_PAT.match(current["paragraphs"][-1].strip())
        if current["paragraphs"] and not STARTER_PAT.match(text) and not previous_is_illus:
            current["paragraphs"][-1] += " " + text
        else:
            current["paragraphs"].append(text)

    if current:
        sections.append(current)
    return sections, chapters


def filter_margin(margin_lines, first_body_y_page1, log):
    """Drop masthead, act citations and signature-box junk from margin lines."""
    kept = []
    for line in margin_lines:
        text = line["text"].strip()
        if not text:
            continue
        if line["page"] == 1 and line["y"] < first_body_y_page1 - 5:
            log.append(f"MARGIN-MASTHEAD-DROP: {text[:60]}")
            continue
        if CITATION_PAT.match(text) or END_PAT.search(text) or "=" in text:
            log.append(f"MARGIN-JUNK-DROP p{line['page']}: {text[:60]}")
            continue
        kept.append({"page": line["page"], "y": line["y"], "text": text})
    return kept


def align_titles(margin_lines, parsed, log):
    """Partition ordered margin lines into len(parsed) contiguous groups.

    Marginal notes start at (approximately) the y of their section's first
    line, so we minimise the total distance between each group's first line
    and its section anchor via dynamic programming.
    """
    pos = lambda page, y: page * 2000 + y
    lines = sorted(margin_lines, key=lambda l: pos(l["page"], l["y"]))
    anchors = [pos(s["page"], s.get("y", 0)) for s in parsed]
    n_lines, n_groups = len(lines), len(anchors)
    if n_lines < n_groups:
        print(f"FATAL: {n_lines} margin lines < {n_groups} sections")
        sys.exit(1)
    INF = float("inf")
    # f[j][i]: min cost, first i lines assigned to first j groups (1-based)
    prev_row = [0.0 if i == 0 else INF for i in range(n_lines + 1)]
    choices = []
    for j in range(1, n_groups + 1):
        row = [INF] * (n_lines + 1)
        choice = [0] * (n_lines + 1)
        for i in range(j, n_lines + 1):
            # either line i extends group j, or group j starts at line i
            extend = row[i - 1]
            start = prev_row[i - 1] + abs(pos(lines[i - 1]["page"], lines[i - 1]["y"]) - anchors[j - 1])
            if start <= extend:
                row[i], choice[i] = start, 1
            else:
                row[i], choice[i] = extend, 0
        choices.append(choice)
        prev_row = row
    # backtrack split points
    groups = [[] for _ in range(n_groups)]
    i, j = n_lines, n_groups
    while j > 0:
        groups[j - 1].insert(0, lines[i - 1])
        if choices[j - 1][i] == 1:
            j -= 1
        i -= 1
    return [
        {"page": g[0]["page"], "title": title_case_clean(" ".join(l["text"] for l in g))}
        for g in groups
    ]


# ------------------------------------------------------------------ build ----

def load_curated():
    curated = {}
    legacy_path = os.path.join(ROOT, "curated_bns_legacy.json")
    if not os.path.exists(legacy_path):
        merged = []
        for name in ["SectionsBNS1.json", "SectionsBNS2.json"]:
            path = os.path.join(RES, name)
            if os.path.exists(path):
                merged.extend(json.load(open(path)))
        with open(legacy_path, "w") as f:
            json.dump(merged, f, indent=1, ensure_ascii=False)
    for entry in json.load(open(legacy_path)):
        curated[int(entry["number"])] = entry
    extra_path = os.path.join(ROOT, "curated_extra.json")
    if os.path.exists(extra_path):
        for entry in json.load(open(extra_path)):
            number = int(entry["number"])
            if number in curated:
                curated[number].update(entry)  # partial override
            else:
                curated[number] = entry
    return curated


def auto_keywords(title: str):
    words = re.findall(r"[a-z]+", title.lower())
    out = []
    for w in words:
        if len(w) > 3 and w not in STOPWORDS and w not in out:
            out.append(w)
    return out[:6]


def stage_build():
    log = []
    pages = load_pages()
    body, margin = classify(pages)

    first_body_y_page1 = None
    for line in body:
        if line["page"] == 1 and CHAPTER_PAT.match(line["text"].strip()):
            first_body_y_page1 = line["y"]
            break
    if first_body_y_page1 is None:
        first_body_y_page1 = 0

    parsed, chapter_numerals = parse_body(body, log)
    margin_kept = filter_margin(margin, first_body_y_page1, log)
    print(f"sections parsed: {len(parsed)}   margin lines: {len(margin_kept)}   chapters: {len(chapter_numerals)}")
    if len(parsed) != 358:
        with open("/tmp/bns/log.txt", "w") as f:
            f.write("\n".join(log))
        sys.exit(1)
    titles = align_titles(margin_kept, parsed, log)

    curated = load_curated()
    report_mismatch = []
    page_drift = [
        f"{s['number']}: section p{s['page']} vs title p{t['page']}"
        for s, t in zip(parsed, titles)
        if abs(s["page"] - t["page"]) > 1
    ]
    if page_drift:
        print("PAGE DRIFT (section vs title):")
        for d in page_drift[:20]:
            print("  ", d)
    output = []
    for section, title_block in zip(parsed, titles):
        number = section["number"]
        title = title_block["title"]
        text = "\n\n".join(clean(p) for p in section["paragraphs"] if clean(p))
        entry_curated = curated.get(number)
        if entry_curated and entry_curated.get("title"):
            norm = lambda s: re.sub(r"[^a-z]", "", s.lower())
            if norm(entry_curated["title"])[:14] != norm(title)[:14]:
                report_mismatch.append(f"{number}: curated='{entry_curated['title']}' pdf='{title}'")
        entry = {
            "id": f"bns-{number}",
            "actId": "bns",
            "chapterId": f"bns-ch{chapter_of(number)}",
            "number": str(number),
            "sortIndex": number * 10,
            "title": title,
            "officialText": text if len(text) >= 60 else (entry_curated or {}).get("officialText", text),
            "officialStatus": "full" if len(text) >= 60 else "extract",
            "explanation": entry_curated["explanation"] if entry_curated else PLACEHOLDER_GUIDE,
            "keyPoints": entry_curated["keyPoints"] if entry_curated else [],
            "relatedSectionIds": entry_curated["relatedSectionIds"] if entry_curated else [],
            "caseLawIds": entry_curated["caseLawIds"] if entry_curated else [],
            "definitionIds": entry_curated["definitionIds"] if entry_curated else [],
            "keywords": entry_curated["keywords"] if entry_curated else auto_keywords(title),
            "curated": bool(entry_curated),
        }
        if entry_curated and entry_curated.get("example"):
            entry["example"] = entry_curated["example"]
        if entry_curated and entry_curated.get("ipcLabel"):
            entry["ipcLabel"] = entry_curated["ipcLabel"]
        output.append(entry)

    by_chapter = {}
    for entry in output:
        by_chapter.setdefault(entry["chapterId"], []).append(entry)
    for ch in range(1, 21):
        entries = by_chapter.get(f"bns-ch{ch}", [])
        lo, hi = EXPECTED_RANGES[ch]
        assert len(entries) == hi - lo + 1, f"chapter {ch}: {len(entries)} sections, expected {hi - lo + 1}"
        path = os.path.join(RES, f"BNS_Ch{ch:02d}.json")
        with open(path, "w") as f:
            json.dump(entries, f, indent=1, ensure_ascii=False)

    lengths = sorted(((len(e["officialText"]), e["number"]) for e in output), reverse=True)
    short = [(n, l) for l, n in lengths if l < 80]
    print(f"curated: {sum(1 for e in output if e['curated'])}")
    print("longest:", [(n, l) for l, n in lengths[:5]])
    print("shortest/suspect:", short[:10] if short else "none < 80 chars")
    if report_mismatch:
        print("TITLE MISMATCHES (curated vs pdf):")
        for m in report_mismatch:
            print("  ", m)
    with open("/tmp/bns/log.txt", "w") as f:
        f.write("\n".join(log))
    with open("/tmp/bns/preview.txt", "w") as f:
        for e in output:
            f.write(f"--- {e['number']}. {e['title']}  [{len(e['officialText'])} chars]\n")
            f.write(e["officialText"][:400] + "\n\n")
    print("wrote 20 chapter files to", RES)
    print("debug: /tmp/bns/log.txt /tmp/bns/preview.txt")


if __name__ == "__main__":
    if sys.argv[1] == "extract":
        stage_extract(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
    elif sys.argv[1] == "build":
        stage_build()
