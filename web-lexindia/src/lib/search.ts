/**
 * Local search across sections, acts, definitions, case laws and
 * IPC → BNS mappings, plus the universal search over every product
 * surface. Ported from SearchEngine + GlobalSearch on iOS.
 */

import { legalData, DocumentCatalog, LegalUpdatesCatalog } from "./legalData";
import {
  documentKindEnglishTitle,
  updateCategoryEnglish,
  type CaseLaw,
  type IPCMapping,
  type LegalAct,
  type LegalDefinition,
  type LegalSection,
  type LegalTopic,
  type LegalUpdate,
  type LexDocument,
  type SavedItem,
} from "./models";

export interface SectionHit {
  section: LegalSection;
  reason: string | null;
}

export interface SearchResults {
  mappings: IPCMapping[];
  sections: SectionHit[];
  definitions: LegalDefinition[];
  acts: LegalAct[];
  topics: LegalTopic[];
  caseLaws: CaseLaw[];
}

const emptyResults = (): SearchResults => ({
  mappings: [],
  sections: [],
  definitions: [],
  acts: [],
  topics: [],
  caseLaws: [],
});

export const searchResultsEmpty = (results: SearchResults): boolean =>
  results.mappings.length === 0 &&
  results.sections.length === 0 &&
  results.definitions.length === 0 &&
  results.acts.length === 0 &&
  results.topics.length === 0 &&
  results.caseLaws.length === 0;

const tokenize = (query: string): string[] => query.split(/[^\p{L}\p{N}]+/u).filter(Boolean);

export function search(rawQuery: string): SearchResults {
  const query = rawQuery.trim().toLowerCase();
  if (!query) return emptyResults();

  const tokens = tokenize(query);
  const numericTokens = tokens.filter((token) => /^\d/.test(token));
  const results = emptyResults();
  const { core, sections } = legalData;

  // IPC → BNS mappings: "420", "ipc 302", "sedition"
  results.mappings = core.ipcMappings
    .filter((mapping) => {
      const ipcLower = mapping.ipc.toLowerCase();
      if (numericTokens.some((token) => ipcLower.includes(token))) return true;
      return query.length > 3 && mapping.ipcTitle.toLowerCase().includes(query);
    })
    .slice(0, 6);

  // Sections, scored.
  const scored: [LegalSection, number, string | null][] = [];
  for (const section of sections) {
    let score = 0;
    let reason: string | null = null;
    const titleLower = section.title.toLowerCase();
    const numberLower = section.number.toLowerCase();

    if (numberLower === query) {
      score = Math.max(score, 100);
    } else if (tokens.includes(numberLower)) {
      score = Math.max(score, 95);
    } else if (numericTokens.length > 0 && numericTokens.some((token) => numberLower.startsWith(token))) {
      score = Math.max(score, 62);
    }

    if (section.ipcLabel) {
      const ipcLower = section.ipcLabel.toLowerCase();
      if (numericTokens.some((token) => ipcLower.includes(token)) && score < 80) {
        score = 80;
        reason = `Earlier ${section.ipcLabel}`;
      }
    }

    if (titleLower === query) {
      score = Math.max(score, 92);
    } else if (query.length > 2 && titleLower.includes(query)) {
      score = Math.max(score, 60);
    } else if (tokens.some((token) => token.length > 2 && titleLower.includes(token))) {
      score = Math.max(score, 38);
    }

    for (const keyword of section.keywords) {
      if (keyword === query) {
        score = Math.max(score, 66);
      } else if (tokens.includes(keyword)) {
        score = Math.max(score, 48);
        if (reason === null && !titleLower.includes(keyword)) reason = `Covers \u201C${keyword}\u201D`;
      } else if (query.length > 3 && keyword.includes(query)) {
        score = Math.max(score, 34);
        if (reason === null) reason = `Covers \u201C${keyword}\u201D`;
      }
    }

    if (score === 0 && query.length > 4 && section.explanation.toLowerCase().includes(query)) {
      score = 18;
      reason = "Mentioned in the plain-language guide";
    }

    if (score > 0) scored.push([section, score, reason]);
  }
  results.sections = scored
    .sort((a, b) => b[1] - a[1])
    .slice(0, 12)
    .map(([section, , reason]) => ({ section, reason }));

  // Acts.
  results.acts = core.acts
    .filter((act) => {
      const nameLower = act.name.toLowerCase();
      const shortLower = act.shortName?.toLowerCase() ?? "";
      if (query.length >= 2 && (nameLower.includes(query) || shortLower === query)) return true;
      return tokens.some((token) => token.length > 2 && (nameLower.includes(token) || shortLower === token));
    })
    .slice(0, 4);

  // Definitions.
  results.definitions = core.definitions
    .filter((definition) => {
      const termLower = definition.term.toLowerCase();
      if (query.length >= 2 && termLower.includes(query)) return true;
      if (tokens.some((token) => token.length > 3 && termLower.includes(token))) return true;
      return query.length > 4 && definition.meaning.toLowerCase().includes(query);
    })
    .slice(0, 5);

  // Topics.
  results.topics = core.topics
    .filter((topic) => {
      const nameLower = topic.name.toLowerCase();
      if (query.length >= 3 && nameLower.includes(query)) return true;
      return tokens.some((token) => token.length > 3 && nameLower.includes(token));
    })
    .slice(0, 3);

  // Case laws.
  results.caseLaws = core.caseLaws
    .filter((caseLaw) => {
      const titleLower = caseLaw.title.toLowerCase();
      if (query.length > 3 && titleLower.includes(query)) return true;
      if (tokens.some((token) => token.length > 3 && titleLower.includes(token))) return true;
      return query.length > 4 && caseLaw.principle.toLowerCase().includes(query);
    })
    .slice(0, 4);

  return results;
}

// MARK: - Universal search

export interface SettingsSearchEntry {
  id: string;
  titleKey: string;
  icon: string;
  /** Route path; null when the row opens the plans sheet instead. */
  path: string | null;
  opensPlans: boolean;
  matchTerms: string[];
}

export const SettingsSearchCatalog: SettingsSearchEntry[] = [
  {
    id: "s-appearance",
    titleKey: "account.appearance",
    icon: "appearance",
    path: "/settings/appearance",
    opensPlans: false,
    matchTerms: ["appearance", "theme", "dark", "light", "mode", "थीम", "डार्क", "लाइट"],
  },
  {
    id: "s-language",
    titleKey: "account.language",
    icon: "language",
    path: "/settings/language",
    opensPlans: false,
    matchTerms: ["language", "hindi", "english", "भाषा", "हिन्दी", "इंग्लिश"],
  },
  {
    id: "s-appcolor",
    titleKey: "account.appColor",
    icon: "color",
    path: "/settings/color",
    opensPlans: false,
    matchTerms: ["colour", "color", "accent", "paint", "रंग", "कलर"],
  },
  {
    id: "s-credits",
    titleKey: "account.credits.history",
    icon: "credits",
    path: "/credits",
    opensPlans: false,
    matchTerms: ["credit", "credits", "balance", "क्रेडिट", "बैलेंस"],
  },
  {
    id: "s-downloads",
    titleKey: "account.downloads",
    icon: "downloads",
    path: "/downloads",
    opensPlans: false,
    matchTerms: ["download", "downloads", "pdf", "डाउनलोड"],
  },
  {
    id: "s-plans",
    titleKey: "account.membership",
    icon: "plans",
    path: null,
    opensPlans: true,
    matchTerms: ["plan", "plans", "subscription", "membership", "price", "प्लान", "सदस्यता"],
  },
  {
    id: "s-notes",
    titleKey: "account.saved",
    icon: "notes",
    path: "/notes",
    opensPlans: false,
    matchTerms: ["saved", "notes", "bookmark", "नोट", "सेव"],
  },
  {
    id: "s-recents",
    titleKey: "account.recents",
    icon: "recents",
    path: "/recents",
    opensPlans: false,
    matchTerms: ["recent", "recently", "history", "हाल"],
  },
];

export interface GlobalSearchResults {
  core: SearchResults;
  documents: LexDocument[];
  studentDocs: LexDocument[];
  quizzesMatch: boolean;
  updates: LegalUpdate[];
  savedSections: LegalSection[];
  settings: SettingsSearchEntry[];
}

export const globalSearchEmpty = (results: GlobalSearchResults): boolean =>
  searchResultsEmpty(results.core) &&
  results.documents.length === 0 &&
  results.studentDocs.length === 0 &&
  !results.quizzesMatch &&
  results.updates.length === 0 &&
  results.savedSections.length === 0 &&
  results.settings.length === 0;

/** Searches every surface of LexIndia for the universal search screen. */
export function globalSearch(rawQuery: string, saved: SavedItem[]): GlobalSearchResults {
  const query = rawQuery.trim().toLowerCase();
  const results: GlobalSearchResults = {
    core: emptyResults(),
    documents: [],
    studentDocs: [],
    quizzesMatch: false,
    updates: [],
    savedSections: [],
    settings: [],
  };
  if (!query) return results;

  results.core = search(rawQuery);
  if (query.length < 2) return results;

  const matchesDocument = (document: LexDocument): boolean => {
    if (document.title.toLowerCase().includes(query)) return true;
    if (query.length > 3 && document.summary.toLowerCase().includes(query)) return true;
    return documentKindEnglishTitle[document.kind].toLowerCase().includes(query);
  };
  results.documents = DocumentCatalog.documents
    .filter((document) => (document.kind === "bare-act" || document.kind === "court-form") && matchesDocument(document))
    .slice(0, 5);
  results.studentDocs = DocumentCatalog.documents
    .filter(
      (document) =>
        ["exam-note", "previous-paper", "revision"].includes(document.kind) && matchesDocument(document),
    )
    .slice(0, 5);

  const quizTerms = ["quiz", "क्विज", "mcq", "practice test", "प्रश्नोत्तरी"];
  results.quizzesMatch = quizTerms.some((term) => query.includes(term) || (term.includes(query) && query.length >= 3));

  if (query.length >= 3) {
    results.updates = LegalUpdatesCatalog.updates
      .filter(
        (update) =>
          update.title.toLowerCase().includes(query) ||
          update.snippet.toLowerCase().includes(query) ||
          updateCategoryEnglish[update.category].toLowerCase().includes(query),
      )
      .slice(0, 4);
  }

  results.savedSections = saved
    .map((item) => legalData.section(item.sectionId))
    .filter((section): section is LegalSection => !!section)
    .filter((section) => section.title.toLowerCase().includes(query) || section.number.toLowerCase() === query)
    .slice(0, 4);

  results.settings = SettingsSearchCatalog.filter((entry) =>
    entry.matchTerms.some((term) => term.includes(query) || query.includes(term)),
  );

  return results;
}
