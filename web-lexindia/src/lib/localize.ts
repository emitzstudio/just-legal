/**
 * Hindi display layer for DATA-DRIVEN content: Act names, categories,
 * situations, topics, documents, updates and BNS chapter headings.
 * Statutory body text is NEVER translated — Act and chapter names use the
 * official Hindi titles as enacted. Mirrors LexLocalize on iOS.
 */

import localizeData from "@/data/localize.json";
import type {
  AppLanguage,
  DocumentKind,
  LegalAct,
  LegalCategory,
  LegalTopic,
  LegalUpdate,
  LexDocument,
  QuizTopic,
  Situation,
  SubscriptionPlan,
  UpdateCategory,
} from "./models";
import { t } from "./strings";

type Table = Record<string, string>;

const L = localizeData as {
  actNames: Table;
  actSummaries: Table;
  actExtents: Table;
  actEffectives: Table;
  actSources: Table;
  bnsChapters: Table;
  categoryNames: Table;
  categoryTaglines: Table;
  categoryExtents: Table;
  situationTitles: Table;
  situationBlurbs: Table;
  topicNames: Table;
  docTitles: Table;
  docSummaries: Table;
  docMetas: Table;
  updateTitles: Table;
  updateSnippets: Table;
  updateDates: Table;
  reminderTitles: Table;
  suggestionsHindi: string[];
};

const pick = (table: Table, id: string, fallback: string, language: AppLanguage): string =>
  language === "hi" ? (table[id] ?? fallback) : fallback;

// MARK: - Acts

export const actName = (act: LegalAct, language: AppLanguage) => pick(L.actNames, act.id, act.name, language);
export const actNameById = (id: string, fallback: string, language: AppLanguage) =>
  pick(L.actNames, id, fallback, language);
export const actSummary = (act: LegalAct, language: AppLanguage) =>
  pick(L.actSummaries, act.id, act.summary, language);
export const actExtent = (act: LegalAct, language: AppLanguage) =>
  pick(L.actExtents, act.id, act.extentLabel, language);
export const actEffective = (act: LegalAct, language: AppLanguage) =>
  pick(L.actEffectives, act.id, act.effectiveLabel, language);
export const actSource = (act: LegalAct, language: AppLanguage) =>
  pick(L.actSources, act.id, act.sourceLabel, language);

// MARK: - BNS chapters

export function chapterTitle(numeral: string, fallback: string, actId: string, language: AppLanguage): string {
  if (language !== "hi" || actId !== "bns") return fallback;
  return L.bnsChapters[numeral] ?? fallback;
}

/** "Chapter XVII · Of Offences Against Property" / "अध्याय XVII · …" */
export function chapterLine(numeral: string, title: string, actId: string, language: AppLanguage): string {
  return `${t("reader.chapter", language)} ${numeral} · ${chapterTitle(numeral, title, actId, language)}`;
}

// MARK: - Categories

export const categoryName = (category: LegalCategory, language: AppLanguage) =>
  pick(L.categoryNames, category.id, category.name, language);
export const categoryTagline = (category: LegalCategory, language: AppLanguage) =>
  pick(L.categoryTaglines, category.id, category.tagline, language);
export const categoryExtent = (category: LegalCategory, language: AppLanguage) =>
  pick(L.categoryExtents, category.id, category.extentLabel, language);

// MARK: - Situations & topics

export const situationTitle = (situation: Situation, language: AppLanguage) =>
  pick(L.situationTitles, situation.id, situation.title, language);
export const situationBlurb = (situation: Situation, language: AppLanguage) =>
  pick(L.situationBlurbs, situation.id, situation.blurb, language);
export const topicName = (topic: LegalTopic, language: AppLanguage) =>
  pick(L.topicNames, topic.id, topic.name, language);

// MARK: - Documents

export const docTitle = (document: LexDocument, language: AppLanguage) =>
  pick(L.docTitles, document.id, document.title, language);
export const docSummary = (document: LexDocument, language: AppLanguage) =>
  pick(L.docSummaries, document.id, document.summary, language);
export const docMeta = (document: LexDocument, language: AppLanguage) =>
  pick(L.docMetas, document.id, document.meta, language);

export const documentKindTitle = (kind: DocumentKind, language: AppLanguage) => t(`docs.kind.${kind}`, language);
export const documentKindBlurb = (kind: DocumentKind, language: AppLanguage) =>
  t(`docs.kind.${kind}.blurb`, language);
export const documentKindBadge = (kind: DocumentKind, language: AppLanguage) =>
  kind === "bare-act" ? t("docs.badge.readInApp", language) : "PDF";
export const documentKindAccessLabel = (kind: DocumentKind, language: AppLanguage) =>
  t(kind === "bare-act" ? "docs.readInApp" : "docs.downloadPdf", language);

// MARK: - Legal updates

export const updateTitle = (update: LegalUpdate, language: AppLanguage) =>
  pick(L.updateTitles, update.id, update.title, language);
export const updateSnippet = (update: LegalUpdate, language: AppLanguage) =>
  pick(L.updateSnippets, update.id, update.snippet, language);
export const updateDate = (update: LegalUpdate, language: AppLanguage) =>
  pick(L.updateDates, update.id, update.dateLabel, language);
export const updateSource = (update: LegalUpdate, language: AppLanguage) =>
  language === "hi" ? "LexIndia डेस्क · डेमो सारांश" : update.source;
export const updateCategoryLabel = (category: UpdateCategory, language: AppLanguage) =>
  t(`updates.cat.${category}`, language);

// MARK: - Misc labels

export const quizTopicLabel = (topic: QuizTopic, language: AppLanguage) => t(`quiz.topic.${topic}`, language);
export const themeModeLabel = (mode: string, language: AppLanguage) => t(`theme.${mode}`, language);
export const themeModeDetail = (mode: string, language: AppLanguage) => t(`theme.${mode}.detail`, language);

export const suggestions = (english: string[], language: AppLanguage): string[] =>
  language === "hi" ? L.suggestionsHindi : english;

export const reminderTitle = (id: string, fallback: string, language: AppLanguage) =>
  pick(L.reminderTitles, id, fallback, language);

// MARK: - Dates, durations & numbers

const locale = (language: AppLanguage) => (language === "hi" ? "hi-IN" : "en-IN");

/** Locale-aware medium date, e.g. "21 Aug 2027" / "21 अगस्त 2027". */
export function date(value: string | Date, language: AppLanguage): string {
  return new Intl.DateTimeFormat(locale(language), { day: "numeric", month: "short", year: "numeric" }).format(
    new Date(value),
  );
}

/** Locale-aware date with time, e.g. "21 Aug 2027, 4:03 PM". */
export function dateTime(value: string | Date, language: AppLanguage): string {
  return new Intl.DateTimeFormat(locale(language), {
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(value));
}

/** "21h 34m" / "21 घं 34 मि", "58m" / "58 मिनट", "under a minute". */
export function remaining(seconds: number, language: AppLanguage): string {
  const totalMinutes = Math.floor(seconds / 60);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (language === "hi") {
    if (hours > 0) return `${hours} घं ${minutes} मि`;
    if (minutes > 0) return `${minutes} मिनट`;
    return "एक मिनट से कम";
  }
  if (hours > 0) return `${hours}h ${minutes}m`;
  if (minutes > 0) return `${minutes}m`;
  return "under a minute";
}

/** "12 months" / "12 माह". */
export function planDuration(months: number, language: AppLanguage): string {
  if (language === "hi") return months === 1 ? "1 माह" : `${months} माह`;
  return months === 1 ? "1 month" : `${months} months`;
}

/** "≈ ₹49/month" / "≈ ₹49/माह". */
export function perMonth(plan: SubscriptionPlan, language: AppLanguage): string {
  const value = Math.round(plan.priceINR / plan.months);
  return language === "hi" ? `≈ ₹${value}/माह` : `≈ ₹${value}/month`;
}
