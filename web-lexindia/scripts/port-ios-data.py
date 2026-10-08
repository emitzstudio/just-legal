#!/usr/bin/env python3
"""
Ports the LexIndia iOS content layer into JSON for the web app.

Reads the bundled dataset plus the Swift source tables (interface strings,
Hindi content localisation, the Legal Updates / Documents catalogs, the
E-Vakeel scenario bank, curated quiz banks and the legal pages) and writes
them to web-lexindia/src/data. Re-run whenever the iOS content changes so
both platforms stay identical.
"""

import glob
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.dirname(HERE)
IOS = os.path.join(os.path.dirname(WEB), "ios-lexindia", "LexIndia")
OUT = os.path.join(WEB, "src", "data")
os.makedirs(OUT, exist_ok=True)


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def write(name, payload, indent=None):
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=indent)
        handle.write("\n")
    print(f"wrote {name}")


# --- Swift literal tokenizer / parser -------------------------------------

TOKEN_RE = re.compile(
    r"""
    (?P<ws>\s+|//[^\n]*)
  | (?P<mstr>\"\"\"\n(?P<mbody>.*?)\n[ \t]*\"\"\")
  | (?P<str>"(?:[^"\\\n]|\\.)*")
  | (?P<num>-?\d+(?:\.\d+)?)
  | (?P<ident>\.?[A-Za-z_][A-Za-z0-9_]*)
  | (?P<punct>[()\[\]:,])
    """,
    re.S | re.X,
)

ENUM = {
    "supremeCourt": "supreme-court",
    "highCourt": "high-court",
    "judgment": "judgment",
    "newLaw": "new-law",
    "amendment": "amendment",
    "notification": "notification",
    "bareAct": "bare-act",
    "courtForm": "court-form",
    "examNote": "exam-note",
    "previousPaper": "previous-paper",
    "revision": "revision",
}


def decode(raw):
    out = []
    i = 0
    while i < len(raw):
        ch = raw[i]
        if ch != "\\":
            out.append(ch)
            i += 1
            continue
        nxt = raw[i + 1]
        if nxt == "n":
            out.append("\n")
            i += 2
        elif nxt == "t":
            out.append("\t")
            i += 2
        elif nxt == "u":
            close = raw.index("}", i)
            out.append(chr(int(raw[i + 3 : close], 16)))
            i = close + 1
        else:
            out.append(nxt)
            i += 2
    return "".join(out)


def tokenize(text):
    tokens = []
    pos = 0
    while pos < len(text):
        match = TOKEN_RE.match(text, pos)
        if not match:
            raise ValueError(f"Unexpected character at {pos}: {text[pos:pos+20]!r}")
        pos = match.end()
        kind = match.lastgroup
        if kind == "ws":
            continue
        if kind == "mstr":
            tokens.append(("str", decode(match.group("mbody"))))
        elif kind == "mbody":
            continue
        elif kind == "str":
            tokens.append(("str", decode(match.group("str")[1:-1])))
        else:
            tokens.append((kind, match.group(kind)))
    return tokens


class Parser:
    def __init__(self, text):
        self.tokens = tokenize(text)
        self.index = 0

    def peek(self):
        return self.tokens[self.index] if self.index < len(self.tokens) else (None, None)

    def take(self):
        token = self.tokens[self.index]
        self.index += 1
        return token

    def take_punct(self, value):
        kind, got = self.take()
        if kind != "punct" or got != value:
            raise ValueError(f"expected {value!r}, got {got!r}")

    def value(self):
        kind, val = self.take()
        if kind == "str":
            return val
        if kind == "num":
            return float(val) if "." in val else int(val)
        if kind == "punct" and val == "[":
            return self.collection()
        if kind == "ident":
            if val == "nil":
                return None
            if val == "true":
                return True
            if val == "false":
                return False
            if val.startswith("."):
                return ENUM.get(val[1:], val[1:])
            nkind, nval = self.peek()
            if nkind == "punct" and nval == "(":
                return self.call(val)
            return val
        raise ValueError(f"unexpected token {kind} {val!r}")

    def collection(self):
        nkind, nval = self.peek()
        if nkind == "punct" and nval == "]":
            self.take()
            return []
        first = self.value()
        nkind, nval = self.peek()
        if nkind == "punct" and nval == ":":
            self.take()
            result = {first: self.value()}
            while True:
                nkind, nval = self.peek()
                if nkind == "punct" and nval == ",":
                    self.take()
                    nkind, nval = self.peek()
                    if nkind == "punct" and nval == "]":
                        self.take()
                        return result
                    key = self.value()
                    self.take_punct(":")
                    result[key] = self.value()
                else:
                    self.take_punct("]")
                    return result
        items = [first]
        while True:
            nkind, nval = self.peek()
            if nkind == "punct" and nval == ",":
                self.take()
                nkind, nval = self.peek()
                if nkind == "punct" and nval == "]":
                    self.take()
                    return items
                items.append(self.value())
            else:
                self.take_punct("]")
                return items

    def call(self, name):
        self.take_punct("(")
        obj = {}
        while True:
            nkind, nval = self.peek()
            if nkind == "punct" and nval == ")":
                self.take()
                return obj
            _, label = self.take()
            self.take_punct(":")
            obj[label] = self.value()
            nkind, nval = self.peek()
            if nkind == "punct" and nval == ",":
                self.take()


def parse_literal_after(text, pattern):
    """Parses the Swift literal that follows the first regex match."""
    match = re.search(pattern, text)
    if not match:
        raise ValueError(f"pattern not found: {pattern}")
    start = match.end()
    # Cut the source at the end of the balanced literal so tokenizing stays cheap.
    depth = 0
    pos = start
    in_str = False
    while pos < len(text):
        ch = text[pos]
        if in_str:
            if ch == "\\":
                pos += 1
            elif text.startswith('"""', pos):
                in_str = False
                pos += 2
            elif ch == '"' and not multi:
                in_str = False
        else:
            if text.startswith('"""', pos):
                in_str = True
                multi = True
                pos += 2
            elif ch == '"':
                in_str = True
                multi = False
            elif ch in "[(":
                depth += 1
            elif ch in "])":
                depth -= 1
                if depth == 0:
                    pos += 1
                    break
        pos += 1
    return Parser(text[start - 1 : pos]).value()


# --- Interface strings ------------------------------------------------------

LINE_RE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"\s*,?\s*$')


def parse_string_table(text, start_marker, end_marker):
    start = text.index(start_marker) + len(start_marker)
    end = text.index(end_marker, start)
    table = {}
    for line in text[start:end].splitlines():
        match = LINE_RE.match(line)
        if match:
            table[decode(match.group(1))] = decode(match.group(2))
    return table


strings_src = read(os.path.join(IOS, "Services", "LexStrings.swift"))
english = parse_string_table(strings_src, "private static let english: [String: String] = [", "\n    ]")
hindi = parse_string_table(strings_src, ".hindi: [", "\n        ]")
write("strings.json", {"en": english, "hi": hindi}, indent=1)
print(f"  en {len(english)} keys · hi {len(hindi)} keys")

# --- Hindi content localisation ---------------------------------------------

localize_src = read(os.path.join(IOS, "Services", "LexLocalize.swift"))
localize = {}
for name in [
    "actNames", "actSummaries", "actExtents", "actEffectives", "actSources",
    "bnsChapters", "categoryNames", "categoryTaglines", "categoryExtents",
    "situationTitles", "situationBlurbs", "topicNames",
    "docTitles", "docSummaries", "docMetas",
    "updateTitles", "updateSnippets", "updateDates", "reminderTitles",
]:
    localize[name] = parse_literal_after(localize_src, rf"private static let {name}: \[String: String\] = ")
localize["suggestionsHindi"] = parse_literal_after(localize_src, r"private static let suggestionsHindi: \[String\] = ")
write("localize.json", localize, indent=1)

# --- Legal Updates & Documents ----------------------------------------------

catalog_src = read(os.path.join(IOS, "Services", "ContentCatalog.swift"))
updates = parse_literal_after(catalog_src, r"static let updates: \[LegalUpdate\] = ")
documents = []
for group in ["bareActs", "courtForms", "examNotes", "previousPapers", "revision"]:
    documents += parse_literal_after(catalog_src, rf"static let {group}: \[LexDocument\] = ")
write("updates.json", updates, indent=1)
write("documents.json", documents, indent=1)
print(f"  {len(updates)} updates · {len(documents)} documents")

# --- E-Vakeel scenarios -----------------------------------------------------

scenario_src = read(os.path.join(IOS, "Services", "EVakeelScenarios.swift"))
scenarios = parse_literal_after(scenario_src, r"static let all: \[EVakeelScenario\] = ")
write("scenarios.json", scenarios, indent=1)
print(f"  {len(scenarios)} scenarios")

# --- Curated quiz banks -----------------------------------------------------

quiz_src = read(os.path.join(IOS, "Services", "QuizEngine.swift"))
banks = {}
for topic, name in [("bnss", "bnssBank"), ("evidence", "evidenceBank"), ("constitution", "constitutionBank"), ("contract", "contractBank")]:
    banks[topic] = parse_literal_after(quiz_src, rf"private static let {name}: \[Seed\] = ")
write("quizBanks.json", banks, indent=1)

# --- Legal pages ------------------------------------------------------------

pages_src = read(os.path.join(IOS, "Views", "Account", "LegalPagesView.swift"))
english_start = pages_src.index("private var englishParagraphs")
hindi_start = pages_src.index("private var hindiParagraphs")
pages = {"en": {}, "hi": {}}
for lang, chunk in [("en", pages_src[english_start:hindi_start]), ("hi", pages_src[hindi_start:])]:
    for kind in ["privacy", "terms", "disclaimer"]:
        pages[lang][kind] = parse_literal_after(chunk, rf"case \.{kind}:\s*return ")
write("legalPages.json", pages, indent=1)

# --- Dataset ----------------------------------------------------------------

resources = os.path.join(IOS, "Resources")
core = json.load(open(os.path.join(resources, "LegalCore.json"), encoding="utf-8"))
write("legalCore.json", core)
sections = []
for path in sorted(glob.glob(os.path.join(resources, "BNS_Ch*.json"))) + [os.path.join(resources, "SectionsOther.json")]:
    sections += json.load(open(path, encoding="utf-8"))
sections.sort(key=lambda s: s["sortIndex"])
write("sections.json", sections)
print(f"  {len(sections)} sections")
