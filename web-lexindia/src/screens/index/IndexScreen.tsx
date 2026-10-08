/**
 * The List — an app-wide index / table of contents and the first screen
 * after sign-in. Every row is either a direct destination or a sub-list
 * that drills deeper (Law Library → Areas → Acts → Chapters → Sections).
 * Deliberately a flat, scannable index, not another dashboard.
 */

import {
  ArrowLeftRight,
  ArrowUpRight,
  BookMarked,
  Bookmark,
  Clock,
  Download,
  FileText,
  Globe,
  GraduationCap,
  Info,
  Landmark,
  LayoutGrid,
  Lock,
  MessagesSquare,
  Newspaper,
  Palette,
  Quote,
  Search,
  Settings,
  SunMoon,
  Tag,
  UserCircle2,
  Contact,
  ChevronRight,
  ChevronsRight,
  BookA,
  FileCheck2,
  type LucideIcon,
} from "lucide-react";
import { type ReactNode } from "react";
import { Link, useParams } from "react-router-dom";

import { categoryIcon, documentKindIcon, symbolIcon } from "@/components/lex/icons";
import { Hairline, IconTile, Overline, SearchButton, TrustFootnote } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { DocumentCatalog, LegalUpdatesCatalog, legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { DOCUMENT_KINDS, actDisplayShortName, languageNativeName } from "@/lib/models";
import { useTheme } from "@/stores/themeStore";
import { useUI, type LexTab } from "@/stores/uiStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

export type IndexGroup = "library" | "students" | "documents" | "myspace" | "settings" | "situations" | "topics";

type Target = { kind: "path"; path: string } | { kind: "group"; group: IndexGroup } | { kind: "tab"; tab: LexTab } | { kind: "evakeel" };

interface IndexEntry {
  id: string;
  title: string;
  subtitle: string;
  icon: LucideIcon;
  pastelIndex: number;
  target: Target;
  trailing?: string | null;
}

const entry = (
  id: string,
  title: string,
  subtitle: string,
  icon: LucideIcon,
  pastelIndex: number,
  target: Target,
  trailing?: string | null,
): IndexEntry => ({ id, title, subtitle, icon, pastelIndex, target, trailing });

export function IndexScreen() {
  const { t } = useLex();
  const { core } = legalData;

  const explore: IndexEntry[] = [
    entry("library", t("tab.library"), t("index.library.sub"), Landmark, 0, { kind: "group", group: "library" }),
    entry("students", t("tab.students"), t("index.students.sub"), GraduationCap, 2, { kind: "group", group: "students" }),
    entry("updates", t("library.updates"), t("index.updates.sub"), Newspaper, 4, { kind: "path", path: "/updates" }, `${LegalUpdatesCatalog.updates.length}`),
    entry("documents", t("library.documentsForms"), t("index.documents.sub"), FileText, 7, { kind: "group", group: "documents" }, `${DocumentCatalog.documents.length}`),
    entry("ipc", "IPC → BNS", t("index.ipc.sub"), ArrowLeftRight, 5, { kind: "path", path: "/ipc-bns" }),
    entry("situations", t("myspace.situations"), t("index.situations.sub"), Contact, 1, { kind: "group", group: "situations" }, `${core.situations.length}`),
    entry("topics", t("library.topics"), t("index.topics.sub"), Tag, 3, { kind: "group", group: "topics" }, `${core.topics.length}`),
  ];
  const yours: IndexEntry[] = [
    entry("myspace", t("tab.myspace"), t("index.myspace.sub"), LayoutGrid, 6, { kind: "group", group: "myspace" }),
    entry("evakeel", "E-Vakeel", t("index.evakeel.sub"), MessagesSquare, 2, { kind: "evakeel" }),
  ];
  const more: IndexEntry[] = [
    entry("settings", t("account.settings"), t("index.settings.sub"), Settings, 4, { kind: "group", group: "settings" }),
    entry("account", t("tab.account"), `${t("myspace.membership")} · ${t("account.credits")}`, UserCircle2, 0, { kind: "tab", tab: "account" }),
  ];

  return (
    <Screen>
      <div className="flex items-start gap-3 pt-3.5">
        <div className="min-w-0 flex-1">
          <h1 className="text-[34px] font-bold leading-tight text-ink">{t("tab.list")}</h1>
          <p className="mt-1 text-[15px] text-slate">{t("index.subtitle")}</p>
        </div>
        <SearchButton />
      </div>
      <IndexList title={t("index.explore")} entries={explore} className="mt-[22px]" />
      <IndexList title={t("index.yours")} entries={yours} className="mt-6" />
      <IndexList title={t("index.more")} entries={more} className="mt-6" />
      <IndexHintCard />
      <TrustFootnote className="py-7" />
    </Screen>
  );
}

// MARK: - Sub-lists

interface Section {
  title: string | null;
  entries: IndexEntry[];
}

export function IndexGroupScreen() {
  const { group } = useParams<{ group: IndexGroup }>();
  const { t, f, language } = useLex();
  const user = useUser();
  const theme = useTheme();
  const { core } = legalData;

  const groups: Record<IndexGroup, { title: string; subtitle: string; icon: LucideIcon; hub: LexTab | null }> = {
    library: { title: t("tab.library"), subtitle: t("index.library.sub"), icon: Landmark, hub: "library" },
    students: { title: t("tab.students"), subtitle: t("index.students.sub"), icon: GraduationCap, hub: "students" },
    documents: { title: t("library.documentsForms"), subtitle: t("index.documents.sub"), icon: FileText, hub: null },
    myspace: { title: t("tab.myspace"), subtitle: t("index.myspace.sub"), icon: LayoutGrid, hub: "myspace" },
    settings: { title: t("account.settings"), subtitle: t("index.settings.sub"), icon: Settings, hub: "account" },
    situations: { title: t("myspace.situations"), subtitle: t("index.situations.sub"), icon: Contact, hub: null },
    topics: { title: t("library.topics"), subtitle: t("index.topics.sub"), icon: Tag, hub: null },
  };

  const key: IndexGroup = group && group in groups ? group : "library";
  const meta = groups[key];

  const sections = ((): Section[] => {
    switch (key) {
      case "library": {
        const areas = core.categories.map((category, index) =>
          entry(`cat-${category.id}`, L.categoryName(category, language), L.categoryTagline(category, language), categoryIcon[category.id] ?? BookMarked, index, { kind: "path", path: `/category/${category.id}` }, `${category.actIds.length}`),
        );
        const acts = legalData.orderedActs().map((act, index) =>
          entry(`act-${act.id}`, actDisplayShortName(act), L.actName(act, language), BookMarked, index, { kind: "path", path: `/act/${act.id}` }, act.chapters.length ? `${act.chapters.length}` : null),
        );
        const tools = [
          entry("ipc", "IPC → BNS", t("index.ipc.sub"), ArrowLeftRight, 5, { kind: "path", path: "/ipc-bns" }),
          entry("defs", t("account.definitions"), t("index.definitions.sub"), BookA, 1, { kind: "path", path: "/definitions" }, `${core.definitions.length}`),
          entry("cases", t("account.caseLaws"), t("index.caseLaws.sub"), Quote, 3, { kind: "path", path: "/cases" }, `${core.caseLaws.length}`),
        ];
        return [
          { title: t("index.areas"), entries: areas },
          { title: t("index.acts"), entries: acts },
          { title: t("index.reference"), entries: tools },
        ];
      }
      case "students":
        return [
          {
            title: t("index.learn"),
            entries: [
              entry("quiz", t("students.quizzes"), t("index.quiz.sub"), FileCheck2, 3, { kind: "path", path: "/quiz" }),
              entry("study", t("library.study"), t("index.study.sub"), GraduationCap, 2, { kind: "path", path: "/study" }),
            ],
          },
          {
            title: t("index.reference"),
            entries: [
              entry("defs", t("account.definitions"), t("index.definitions.sub"), BookA, 1, { kind: "path", path: "/definitions" }),
              entry("cases", t("account.caseLaws"), t("index.caseLaws.sub"), Quote, 3, { kind: "path", path: "/cases" }),
              entry("ipc", "IPC → BNS", t("index.ipc.sub"), ArrowLeftRight, 5, { kind: "path", path: "/ipc-bns" }),
            ],
          },
        ];
      case "documents":
        return [
          {
            title: t("index.docKinds"),
            entries: DOCUMENT_KINDS.map((kind, index) => {
              const count = DocumentCatalog.documentsOf(kind).length;
              return entry(`kind-${kind}`, L.documentKindTitle(kind, language), L.documentKindBlurb(kind, language), documentKindIcon[kind], index, { kind: "path", path: `/documents#${kind}` }, count === 1 ? t("index.oneDoc") : f("index.docCount", count));
            }),
          },
        ];
      case "myspace":
        return [
          {
            title: null,
            entries: [
              entry("saved", t("account.saved"), t("index.saved.sub"), Bookmark, 6, { kind: "path", path: "/notes" }, user.saved.length ? `${user.saved.length}` : null),
              entry("recents", t("account.recents"), t("index.recents.sub"), Clock, 0, { kind: "path", path: "/recents" }, user.recents.length ? `${user.recents.length}` : null),
              entry("downloads", t("account.downloads"), t("index.downloads.sub"), Download, 7, { kind: "path", path: "/downloads" }, user.downloads.length ? `${user.downloads.length}` : null),
            ],
          },
        ];
      case "settings":
        return [
          {
            title: t("account.settings"),
            entries: [
              entry("appearance", t("account.appearance"), L.themeModeLabel(user.themeMode, language), SunMoon, 0, { kind: "path", path: "/settings/appearance" }),
              entry("color", t("account.appColor"), theme.accentName, Palette, 5, { kind: "path", path: "/settings/color" }),
              entry("language", t("account.language"), languageNativeName(user.language), Globe, 2, { kind: "path", path: "/settings/language" }),
            ],
          },
          {
            title: t("account.about"),
            entries: [
              entry("privacy", t("account.privacy"), "", Lock, 4, { kind: "path", path: "/legal/privacy" }),
              entry("terms", t("account.terms"), "", FileText, 4, { kind: "path", path: "/legal/terms" }),
              entry("disclaimer", t("account.disclaimer"), "", Info, 4, { kind: "path", path: "/legal/disclaimer" }),
            ],
          },
        ];
      case "situations":
        return [
          {
            title: null,
            entries: core.situations.map((situation, index) =>
              entry(`sit-${situation.id}`, L.situationTitle(situation, language), L.situationBlurb(situation, language), symbolIcon(situation.symbol), index, { kind: "path", path: `/situation/${situation.id}` }, `${situation.sectionIds.length} §`),
            ),
          },
        ];
      case "topics":
        return [
          {
            title: null,
            entries: core.topics.map((topic, index) =>
              entry(`topic-${topic.id}`, L.topicName(topic, language), "", Tag, index, { kind: "path", path: `/topic/${topic.id}` }, `${topic.sectionIds.length} §`),
            ),
          },
        ];
    }
  })();

  const Icon = meta.icon;

  return (
    <Screen>
      <NavBar />
      <div className="flex items-center gap-3.5 rounded-[18px] bg-brand-soft p-4">
        <div className="flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-[14px] bg-on-brand text-brand">
          <Icon className="h-5 w-5" strokeWidth={2.2} />
        </div>
        <div className="min-w-0">
          <h1 className="text-2xl font-bold leading-tight text-ink">{meta.title}</h1>
          <p className="mt-0.5 text-[13px] text-slate">{meta.subtitle}</p>
        </div>
      </div>
      {sections.map((section, index) => (
        <IndexList key={index} title={section.title} entries={section.entries} className={index === 0 ? "mt-[22px]" : "mt-6"} />
      ))}
      {meta.hub ? <HubLink tab={meta.hub} label={f("index.openHub", meta.title)} /> : null}
      <TrustFootnote className="py-7" />
    </Screen>
  );
}

// MARK: - Shared index building blocks

function IndexList({ title, entries, className }: { title: string | null; entries: IndexEntry[]; className?: string }) {
  return (
    <section className={className}>
      {title ? <Overline text={title} className="mb-2.5" /> : null}
      <div className="overflow-hidden rounded-2xl border border-hairline bg-surface">
        {entries.map((item, index) => (
          <div key={item.id}>
            {index > 0 ? <Hairline className="ml-[70px] w-auto" /> : null}
            <IndexRow entry={item} />
          </div>
        ))}
      </div>
    </section>
  );
}

function IndexRow({ entry: item }: { entry: IndexEntry }) {
  const ui = useUI();
  const isGroup = item.target.kind === "group";
  const Icon = item.icon;
  const label: ReactNode = (
    <div className="flex w-full items-center gap-3.5 px-3.5 py-3 text-left">
      <IconTile index={item.pastelIndex}>
        <Icon className="h-4 w-4" strokeWidth={2.2} />
      </IconTile>
      <div className="min-w-0 flex-1">
        <p className="truncate text-[17px] font-semibold leading-snug text-ink">{item.title}</p>
        {item.subtitle ? <p className="line-clamp-2 text-[13px] leading-snug text-slate">{item.subtitle}</p> : null}
      </div>
      {item.trailing ? (
        <span className="shrink-0 rounded-full bg-canvas px-2 py-[3px] text-xs font-semibold tabular text-slate">{item.trailing}</span>
      ) : null}
      {isGroup ? (
        <ChevronsRight className="h-3.5 w-3.5 shrink-0 text-brand" strokeWidth={2.5} />
      ) : (
        <ChevronRight className="h-3.5 w-3.5 shrink-0 text-faint" strokeWidth={2.5} />
      )}
    </div>
  );

  switch (item.target.kind) {
    case "path":
      return (
        <Link to={item.target.path} className="press block">
          {label}
        </Link>
      );
    case "group":
      return (
        <Link to={`/list/${item.target.group}`} className="press block" aria-description="Opens a list">
          {label}
        </Link>
      );
    case "tab": {
      const tab = item.target.tab;
      return (
        <button type="button" onClick={() => ui.openTab(tab)} className="press block w-full">
          {label}
        </button>
      );
    }
    case "evakeel":
      return (
        <button type="button" onClick={ui.openEVakeel} className="press block w-full">
          {label}
        </button>
      );
  }
}

/** "Open the full hub" — switches hubs so a sub-list is never a dead end. */
function HubLink({ tab, label }: { tab: LexTab; label: string }) {
  const ui = useUI();
  return (
    <button
      type="button"
      onClick={() => ui.openTab(tab)}
      className="press mt-6 flex w-full items-center justify-center gap-2 rounded-full bg-brand-soft py-[13px] text-sm font-semibold text-brand"
    >
      {label}
      <ArrowUpRight className="h-3.5 w-3.5" strokeWidth={2.5} />
    </button>
  );
}

/** Footer hint on the root index: search or ask E-Vakeel. */
function IndexHintCard() {
  const { t } = useLex();
  const ui = useUI();
  return (
    <button
      type="button"
      onClick={ui.activateSearch}
      className="press mt-6 flex w-full items-center gap-3 rounded-2xl bg-brand-soft p-3.5 text-left"
    >
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[11px] bg-on-brand text-brand">
        <Search className="h-4 w-4" strokeWidth={2.4} />
      </span>
      <span className="text-[13px] leading-relaxed text-slate">{t("index.hint")}</span>
    </button>
  );
}
