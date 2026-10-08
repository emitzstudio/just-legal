/**
 * The bundled structured legal dataset with indexed access, plus the demo
 * catalogs for Legal Updates and Documents. Ported from LegalDataService
 * and ContentCatalog on iOS.
 */

import coreData from "@/data/legalCore.json";
import sectionsData from "@/data/sections.json";
import updatesData from "@/data/updates.json";
import documentsData from "@/data/documents.json";
import type {
  CaseLaw,
  DocumentKind,
  LegalAct,
  LegalCategory,
  LegalChapter,
  LegalCore,
  LegalDefinition,
  LegalSection,
  LegalTopic,
  LegalUpdate,
  LexDocument,
  Situation,
  UpdateCategory,
} from "./models";

const core = coreData as LegalCore;
const sections = ([...(sectionsData as LegalSection[])] as LegalSection[]).sort((a, b) => a.sortIndex - b.sortIndex);

const sectionById = new Map(sections.map((section) => [section.id, section]));
const actById = new Map(core.acts.map((act) => [act.id, act]));
const categoryById = new Map(core.categories.map((category) => [category.id, category]));
const definitionById = new Map(core.definitions.map((definition) => [definition.id, definition]));
const caseLawById = new Map(core.caseLaws.map((caseLaw) => [caseLaw.id, caseLaw]));
const situationById = new Map(core.situations.map((situation) => [situation.id, situation]));
const topicById = new Map(core.topics.map((topic) => [topic.id, topic]));
const chapterById = new Map<string, LegalChapter>();
const chapterActId = new Map<string, string>();
for (const act of core.acts) {
  for (const chapter of act.chapters) {
    chapterById.set(chapter.id, chapter);
    chapterActId.set(chapter.id, act.id);
  }
}
const sectionsByAct = new Map<string, LegalSection[]>();
const sectionsByChapter = new Map<string, LegalSection[]>();
for (const section of sections) {
  const inAct = sectionsByAct.get(section.actId) ?? [];
  inAct.push(section);
  sectionsByAct.set(section.actId, inAct);
  const inChapter = sectionsByChapter.get(section.chapterId) ?? [];
  inChapter.push(section);
  sectionsByChapter.set(section.chapterId, inChapter);
}

/** Major codes first, then the other Acts — same order as the iOS hubs. */
const preferredOrder = [
  "bns",
  "bnss",
  "bsa",
  "contract-act",
  "it-act-2000",
  "constitution",
  "cpa-2019",
  "tpa-1882",
  "hma-1955",
  "ida-1947",
  "ita-1961",
  "copyright-1957",
];
const orderIndex = new Map(preferredOrder.map((id, index) => [id, index]));

export const legalData = {
  core,
  sections,
  act: (id: string): LegalAct | undefined => actById.get(id),
  section: (id: string): LegalSection | undefined => sectionById.get(id),
  chapter: (id: string): LegalChapter | undefined => chapterById.get(id),
  actIdForChapter: (chapterId: string): string | undefined => chapterActId.get(chapterId),
  category: (id: string): LegalCategory | undefined => categoryById.get(id),
  definition: (id: string): LegalDefinition | undefined => definitionById.get(id),
  caseLaw: (id: string): CaseLaw | undefined => caseLawById.get(id),
  situation: (id: string): Situation | undefined => situationById.get(id),
  topic: (id: string): LegalTopic | undefined => topicById.get(id),
  sectionsInAct: (actId: string): LegalSection[] => sectionsByAct.get(actId) ?? [],
  sectionsInChapter: (chapterId: string): LegalSection[] => sectionsByChapter.get(chapterId) ?? [],
  actsInCategory(categoryId: string): LegalAct[] {
    const category = categoryById.get(categoryId);
    if (!category) return [];
    return category.actIds.map((id) => actById.get(id)).filter((act): act is LegalAct => !!act);
  },
  orderedActs(): LegalAct[] {
    return [...core.acts].sort(
      (a, b) => (orderIndex.get(a.id) ?? Number.MAX_SAFE_INTEGER) - (orderIndex.get(b.id) ?? Number.MAX_SAFE_INTEGER),
    );
  },
  /** Previous and next loaded sections within the same Act. */
  neighbors(section: LegalSection): { previous: LegalSection | null; next: LegalSection | null } {
    const list = sectionsByAct.get(section.actId) ?? [];
    const index = list.findIndex((item) => item.id === section.id);
    if (index < 0) return { previous: null, next: null };
    return {
      previous: index > 0 ? list[index - 1] : null,
      next: index < list.length - 1 ? list[index + 1] : null,
    };
  },
};

// MARK: - Legal Updates (demo editorial content)

const updates = updatesData as LegalUpdate[];

export const LegalUpdatesCatalog = {
  updates,
  update: (id: string): LegalUpdate | undefined => updates.find((update) => update.id === id),
  updatesIn: (category: UpdateCategory | null): LegalUpdate[] =>
    category ? updates.filter((update) => update.category === category) : updates,
};

// MARK: - Documents (Bare Acts + downloadable formats)

const documents = documentsData as LexDocument[];

export const DocumentCatalog = {
  documents,
  document: (id: string): LexDocument | undefined => documents.find((document) => document.id === id),
  documentsOf: (kind: DocumentKind): LexDocument[] => documents.filter((document) => document.kind === kind),
};
