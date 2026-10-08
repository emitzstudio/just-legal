/**
 * Structured content, user and access models — a 1:1 port of the iOS
 * model layer so the dataset and persisted state stay interchangeable.
 */

// MARK: - Legal dataset

export interface LegalCategory {
  id: string;
  name: string;
  tagline: string;
  actIds: string[];
  extentLabel: string;
}

export interface LegalChapter {
  id: string;
  numeral: string;
  title: string;
  rangeLabel: string;
}

export interface LegalAct {
  id: string;
  name: string;
  shortName: string | null;
  categoryId: string;
  summary: string;
  /** "available" when guided sections exist, "preparing" otherwise. */
  status: string;
  extentLabel: string;
  effectiveLabel: string;
  sourceLabel: string;
  chapters: LegalChapter[];
}

export interface LegalSection {
  id: string;
  actId: string;
  chapterId: string;
  number: string;
  sortIndex: number;
  title: string;
  officialText?: string | null;
  /** "full", "extract", or "unavailable". */
  officialStatus: string;
  textNote?: string | null;
  explanation: string;
  example?: string | null;
  keyPoints: string[];
  relatedSectionIds: string[];
  caseLawIds: string[];
  definitionIds: string[];
  ipcLabel?: string | null;
  keywords: string[];
  curated?: boolean | null;
}

export interface LegalDefinition {
  id: string;
  term: string;
  meaning: string;
  sourceNote?: string | null;
  relatedSectionIds: string[];
  relatedCaseLawIds: string[];
}

export interface CaseLaw {
  id: string;
  title: string;
  court: string;
  year: number;
  principle: string;
  summary: string;
  relatedSectionIds: string[];
}

export interface IPCMapping {
  id: string;
  ipc: string;
  ipcTitle: string;
  bnsLabel: string;
  sectionId?: string | null;
  note?: string | null;
}

export interface Situation {
  id: string;
  title: string;
  blurb: string;
  symbol: string;
  intro: string;
  sectionIds: string[];
  definitionIds: string[];
}

export interface LegalTopic {
  id: string;
  name: string;
  sectionIds: string[];
}

export interface LegalCore {
  categories: LegalCategory[];
  acts: LegalAct[];
  definitions: LegalDefinition[];
  caseLaws: CaseLaw[];
  ipcMappings: IPCMapping[];
  situations: Situation[];
  topics: LegalTopic[];
  popularSearches: string[];
  askSuggestions: string[];
}

export const actDisplayShortName = (act: LegalAct): string => act.shortName ?? act.name;
export const actIsPreparing = (act: LegalAct): boolean => act.status === "preparing";
export const sectionHasOfficialText = (section: LegalSection): boolean =>
  section.officialStatus !== "unavailable" && !!section.officialText;
export const sectionHasGuide = (section: LegalSection): boolean => section.curated === true;

// MARK: - Interface language & appearance

export type AppLanguage = "en" | "hi";

export const APP_LANGUAGES: AppLanguage[] = ["en", "hi"];

export const languageNativeName = (language: AppLanguage): string => (language === "hi" ? "हिन्दी" : "English");
export const languageEnglishName = (language: AppLanguage): string => (language === "hi" ? "Hindi" : "English");

export type ThemeMode = "system" | "light" | "dark";

export const THEME_MODES: ThemeMode[] = ["system", "light", "dark"];

// MARK: - Legal updates

export type UpdateCategory = "supreme-court" | "high-court" | "judgment" | "new-law" | "amendment" | "notification";

export const UPDATE_CATEGORIES: UpdateCategory[] = [
  "supreme-court",
  "high-court",
  "judgment",
  "new-law",
  "amendment",
  "notification",
];

export const updateCategoryEnglish: Record<UpdateCategory, string> = {
  "supreme-court": "Supreme Court",
  "high-court": "High Courts",
  judgment: "Judgments",
  "new-law": "New laws",
  amendment: "Amendments",
  notification: "Notifications",
};

export const updateCategoryPastelIndex = (category: UpdateCategory): number => UPDATE_CATEGORIES.indexOf(category);

export interface LegalUpdate {
  id: string;
  category: UpdateCategory;
  title: string;
  source: string;
  dateLabel: string;
  snippet: string;
  body: string[];
  relatedSectionIds: string[];
}

// MARK: - Documents

export type DocumentKind = "bare-act" | "court-form" | "exam-note" | "previous-paper" | "revision";

export const DOCUMENT_KINDS: DocumentKind[] = ["bare-act", "court-form", "exam-note", "previous-paper", "revision"];

export const documentKindEnglishTitle: Record<DocumentKind, string> = {
  "bare-act": "Bare Acts",
  "court-form": "Court forms",
  "exam-note": "Exam notes",
  "previous-paper": "Previous year papers",
  revision: "Revision material",
};

/** Bare Acts stay inside LexIndia; everything else can be downloaded. */
export const documentKindIsDownloadable = (kind: DocumentKind): boolean => kind !== "bare-act";
export const documentKindIndex = (kind: DocumentKind): number => DOCUMENT_KINDS.indexOf(kind);

export interface LexDocument {
  id: string;
  kind: DocumentKind;
  title: string;
  summary: string;
  meta: string;
  actId: string | null;
  body: string[];
}

export const documentFileName = (document: LexDocument): string => `${document.id}.pdf`;

// MARK: - User data

export interface CreditTransaction {
  id: string;
  date: string;
  delta: number;
  reason: string;
}

export interface SavedItem {
  sectionId: string;
  note: string;
  savedAt: string;
  editedAt?: string | null;
}

export interface RecentItem {
  sectionId: string;
  date: string;
}

export interface DownloadRecord {
  documentId: string;
  fileName: string;
  date: string;
}

export interface EVakeelRecord {
  id: string;
  role: "user" | "assistant";
  text: string;
  lead?: string | null;
  mappingNote?: string | null;
  sectionIds: string[];
  cost: number;
  advisory?: string | null;
  date: string;
}

export interface UserSnapshot {
  profileName: string;
  credits: number;
  creditHistory: CreditTransaction[];
  isSubscribed: boolean;
  planName: string | null;
  subscribedAt: string | null;
  saved: SavedItem[];
  recents: RecentItem[];
  recentSearches: string[];
  savedDefinitionIds: string[];
  downloads: DownloadRecord[];
  language: AppLanguage;
  themeMode: ThemeMode;
  evakeelRecords: EVakeelRecord[];
  quizWeeklyClaimWeek: string | null;
  quizzesPlayed: number;
  quizPerfectStreak: number;
  evakeelDockOnRight: boolean;
  evakeelDockY: number;
}

// MARK: - Access & plans

export interface AuthUser {
  name: string;
  email: string;
  joinedAt: string;
}

export type Entitlement =
  | { kind: "none" }
  | { kind: "trial"; start: string; end: string }
  | { kind: "subscription"; planId: string; start: string; end: string }
  | { kind: "devUnlimited" };

export interface SubscriptionPlan {
  id: string;
  months: number;
  priceINR: number;
  includedCredits: number;
  isRecommended: boolean;
}

/** The five production plans, in display order. Do not invent others. */
export const PlanCatalog = {
  monthlyBaselineINR: 128,
  plans: [
    { id: "plan-12m", months: 12, priceINR: 588, includedCredits: 480, isRecommended: true },
    { id: "plan-9m", months: 9, priceINR: 428, includedCredits: 320, isRecommended: false },
    { id: "plan-6m", months: 6, priceINR: 328, includedCredits: 200, isRecommended: false },
    { id: "plan-3m", months: 3, priceINR: 228, includedCredits: 90, isRecommended: false },
    { id: "plan-1m", months: 1, priceINR: 128, includedCredits: 30, isRecommended: false },
  ] as SubscriptionPlan[],
  plan(id: string): SubscriptionPlan | undefined {
    return this.plans.find((plan) => plan.id === id);
  },
};

export const planDurationLabel = (plan: SubscriptionPlan): string =>
  plan.months === 1 ? "1 month" : `${plan.months} months`;
export const planPriceLabel = (plan: SubscriptionPlan): string => `₹${plan.priceINR}`;
export const planSavingsINR = (plan: SubscriptionPlan): number | null => {
  const saved = plan.months * PlanCatalog.monthlyBaselineINR - plan.priceINR;
  return saved > 0 ? saved : null;
};

export interface TrialReminder {
  id: string;
  offsetMinutes: number;
  title: string;
}

/** The fixed reminder schedule for the 24-hour trial. */
export const TrialReminderSchedule: TrialReminder[] = [
  { id: "r-12h", offsetMinutes: 720, title: "Halfway through your free day" },
  { id: "r-18h", offsetMinutes: 1080, title: "6 hours left in your trial" },
  { id: "r-20h", offsetMinutes: 1200, title: "4 hours left in your trial" },
  { id: "r-22h", offsetMinutes: 1320, title: "2 hours left in your trial" },
  { id: "r-23h", offsetMinutes: 1380, title: "1 hour left in your trial" },
  { id: "r-23h30", offsetMinutes: 1410, title: "30 minutes left in your trial" },
  { id: "r-23h45", offsetMinutes: 1425, title: "15 minutes left in your trial" },
  { id: "r-23h55", offsetMinutes: 1435, title: "5 minutes left in your trial" },
  { id: "r-23h58", offsetMinutes: 1438, title: "Your trial is about to end" },
];

/**
 * DEVELOPMENT ONLY — gates the "permanent test access" entitlement.
 * Must be `false` in production builds.
 */
export const DevConfig = {
  permanentTestAccessEnabled: true,
};

// MARK: - Credits

export interface CreditPack {
  id: string;
  amount: number;
  priceINR: number;
  note: string | null;
}

/** Mock packs — amounts and prices are finalized later, only here. */
export const CreditPackCatalog: CreditPack[] = [
  { id: "p20", amount: 20, priceINR: 99, note: null },
  { id: "p60", amount: 60, priceINR: 249, note: "credits.pack.popular" },
  { id: "p150", amount: 150, priceINR: 499, note: "credits.pack.best" },
];

// MARK: - Quiz

export type QuizTopic = "bns" | "ipcBns" | "bnss" | "evidence" | "constitution" | "contract" | "definitions" | "cases";

export const QUIZ_TOPICS: QuizTopic[] = [
  "bns",
  "ipcBns",
  "bnss",
  "evidence",
  "constitution",
  "contract",
  "definitions",
  "cases",
];

export const quizTopicPastelIndex = (topic: QuizTopic): number => QUIZ_TOPICS.indexOf(topic);

export interface QuizQuestion {
  id: string;
  topic: QuizTopic;
  prompt: string;
  options: string[];
  answerIndex: number;
}

export interface QuizRewardRule {
  questionCount: number;
  credits: number;
}

/** MOCK reward configuration — adjust here, never hard-coded in views. */
export const QuizConfig = {
  lengths: [
    { questionCount: 20, credits: 5 },
    { questionCount: 50, credits: 10 },
    { questionCount: 100, credits: 15 },
  ] as QuizRewardRule[],
  /** Consecutive 100% quizzes required to unlock the weekly reward. */
  streakTarget: 5,
  /** Score fraction for the encouraging "Excellent work!" headline. */
  passThreshold: 0.8,
  /** One minute per question. */
  timeLimit(questionCount: number): number {
    return questionCount * 60;
  },
  rule(count: number): QuizRewardRule | undefined {
    return this.lengths.find((rule) => rule.questionCount === count);
  },
};

// MARK: - E-Vakeel

export interface EVakeelScenario {
  id: string;
  phrases: string[];
  body: string;
  sectionIds: string[];
  serious: boolean;
}

/** MOCK pricing — variable per-question costs, configured here only. */
export const EVakeelPricing = {
  simpleCost: 1,
  detailedCost: 2,
  estimatedCost(question: string): number {
    const lower = question.toLowerCase();
    const isLong = question.length > 160;
    const multiPart = (question.match(/\?/g) ?? []).length > 1;
    const drafting = ["draft", "notice format", "agreement", "in detail", "step by step", "procedure for", "how do i file"].some(
      (term) => lower.includes(term),
    );
    return isLong || multiPart || drafting ? this.detailedCost : this.simpleCost;
  },
};

export type LegalPageKind = "privacy" | "terms" | "disclaimer";
