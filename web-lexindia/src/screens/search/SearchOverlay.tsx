/**
 * Universal search over the whole product, presented above the current
 * screen. Results are grouped by source; closing returns the user exactly
 * where they were.
 */

import {
  ArrowRight,
  ArrowUpLeft,
  Award,
  Bookmark,
  ChevronRight,
  Clock,
  Download,
  FileCheck2,
  Globe,
  History,
  Palette,
  Search,
  SunMoon,
  Tag,
  type LucideIcon,
} from "lucide-react";
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";

import { DocumentRow } from "@/components/lex/DocumentRow";
import { CaseLawRow, CloseButton, EmptyState, Hairline, Overline, SectionRow } from "@/components/lex/primitives";
import { legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { actDisplayShortName, type IPCMapping, type LegalDefinition } from "@/lib/models";
import { globalSearch, globalSearchEmpty, type SectionHit, type SettingsSearchEntry } from "@/lib/search";
import { cn } from "@/lib/utils";
import { useUI } from "@/stores/uiStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { DefinitionDetailSheet } from "../study/DefinitionsScreen";

const settingsIcons: Record<string, LucideIcon> = {
  appearance: SunMoon,
  language: Globe,
  color: Palette,
  credits: History,
  downloads: Download,
  plans: Award,
  notes: Bookmark,
  recents: Clock,
};

export function SearchOverlay() {
  const { t, language } = useLex();
  const ui = useUI();
  const user = useUser();
  const [query, setQuery] = useState<string>("");
  const [selectedDefinition, setSelectedDefinition] = useState<LegalDefinition | null>(null);
  const [focused, setFocused] = useState<boolean>(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const trimmed = query.trim();
  const results = useMemo(() => globalSearch(trimmed, user.saved), [trimmed, user.saved]);

  useEffect(() => {
    const timer = window.setTimeout(() => inputRef.current?.focus(), 350);
    document.body.style.overflow = "hidden";
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") ui.closeSearch();
    };
    window.addEventListener("keydown", onKey);
    return () => {
      window.clearTimeout(timer);
      document.body.style.overflow = "";
      window.removeEventListener("keydown", onKey);
    };
  }, [ui]);

  const open = (path: string) => {
    user.recordSearch(trimmed);
    ui.go(path);
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-canvas anim-fade" role="dialog" aria-modal="true" aria-label={t("search.title")}>
      <div className="mx-auto flex w-full max-w-[640px] shrink-0 flex-col gap-3 px-[22px] pb-3 pt-3.5 lg:max-w-[720px]">
        <div className="flex items-center justify-between">
          <h1 className="text-[26px] font-bold text-ink">{t("search.title")}</h1>
          <CloseButton onClick={ui.closeSearch} />
        </div>
        <div className={cn("flex items-center gap-2.5 rounded-[13px] border bg-surface px-[15px] py-3 transition-colors", focused ? "border-brand" : "border-hairline")}>
          <Search className="h-4 w-4 shrink-0 text-slate" strokeWidth={2.5} />
          <input
            ref={inputRef}
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            onKeyDown={(event) => {
              if (event.key === "Enter") user.recordSearch(trimmed);
            }}
            placeholder={t("search.placeholder")}
            type="search"
            autoComplete="off"
            className="min-w-0 flex-1 bg-transparent text-base text-ink outline-none [&::-webkit-search-cancel-button]:hidden"
          />
          {query ? (
            <button type="button" onClick={() => setQuery("")} aria-label="Clear search" className="text-faint">
              <span className="flex h-4 w-4 items-center justify-center rounded-full bg-faint/30 text-[10px] font-bold text-canvas">✕</span>
            </button>
          ) : null}
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto no-scrollbar">
        <div className="mx-auto w-full max-w-[640px] px-[22px] lg:max-w-[720px]">
          {!trimmed ? (
            <div className="pt-2">
              {user.recentSearches.length ? (
                <>
                  <div className="flex items-center justify-between pb-0.5">
                    <Overline text={t("search.recent")} />
                    <button type="button" onClick={user.clearSearches} className="text-[13px] font-medium text-brand">
                      {t("common.clear")}
                    </button>
                  </div>
                  {user.recentSearches.map((recent) => (
                    <button key={recent} type="button" onClick={() => setQuery(recent)} className="press flex w-full items-center gap-[11px] py-[11px] text-left">
                      <Clock className="h-3.5 w-3.5 text-slate" />
                      <span className="flex-1 text-[15px] text-ink">{recent}</span>
                      <ArrowUpLeft className="h-3 w-3 text-faint" strokeWidth={2.5} />
                    </button>
                  ))}
                  <div className="h-6" />
                </>
              ) : null}
              <Overline text={t("search.popular")} className="mb-3" />
              <div className="flex flex-wrap gap-2">
                {legalData.core.popularSearches.map((term) => (
                  <button key={term} type="button" onClick={() => setQuery(term)} className="press rounded-full border border-hairline bg-surface px-[13px] py-2 text-sm font-medium text-ink">
                    {term}
                  </button>
                ))}
              </div>
              <p className="pb-6 pt-7 text-[13px] leading-relaxed text-slate">{t("search.hint")}</p>
            </div>
          ) : globalSearchEmpty(results) ? (
            <EmptyState icon={<Search className="h-6 w-6" />} title={t("search.noResults")} message={t("search.noResults.sub")} className="pt-10" />
          ) : (
            <div className="pb-8">
              {results.core.acts.length || results.core.sections.length || results.core.topics.length ? (
                <Group title={t("search.group.library")}>
                  {results.core.acts.map((act) => (
                    <div key={act.id}>
                      <button type="button" onClick={() => open(`/act/${act.id}`)} className="press block w-full py-[11px] text-left">
                        <span className="block text-base font-semibold text-ink">{act.name}</span>
                        <span className="block text-[13px] text-slate">{act.extentLabel}</span>
                      </button>
                      <Hairline />
                    </div>
                  ))}
                  {results.core.sections.map((hit, index) => (
                    <div key={hit.section.id}>
                      {index > 0 ? <Hairline /> : null}
                      <button type="button" onClick={() => open(`/read/${hit.section.actId}/${hit.section.id}`)} className="press block w-full">
                        <SectionHitRow hit={hit} />
                      </button>
                    </div>
                  ))}
                  {results.core.topics.map((topic) => (
                    <div key={topic.id}>
                      <Hairline />
                      <button type="button" onClick={() => open(`/topic/${topic.id}`)} className="press flex w-full items-center gap-3 py-[11px] text-left">
                        <Tag className="h-3.5 w-3.5 shrink-0 text-brand" />
                        <span className="min-w-0 flex-1">
                          <span className="block text-base font-semibold text-ink">{topic.name}</span>
                          <span className="block text-[13px] text-slate">
                            {topic.sectionIds.length} {t("search.linkedSections")}
                          </span>
                        </span>
                        <ChevronRight className="h-3.5 w-3.5 text-faint" strokeWidth={2.5} />
                      </button>
                    </div>
                  ))}
                </Group>
              ) : null}

              {results.core.mappings.length ? (
                <Group title={t("search.group.ipc")}>
                  {results.core.mappings.map((mapping, index) => (
                    <div key={mapping.id}>
                      {index > 0 ? <Hairline /> : null}
                      <MappingRow mapping={mapping} onOpen={open} />
                    </div>
                  ))}
                </Group>
              ) : null}

              {results.core.definitions.length ? (
                <Group title={t("search.group.terms")}>
                  {results.core.definitions.map((definition, index) => (
                    <div key={definition.id}>
                      {index > 0 ? <Hairline /> : null}
                      <button type="button" onClick={() => setSelectedDefinition(definition)} className="press block w-full py-[11px] text-left">
                        <span className="block text-base font-semibold text-ink">{definition.term}</span>
                        <span className="mt-0.5 line-clamp-2 block text-[13px] text-slate">{definition.meaning}</span>
                      </button>
                    </div>
                  ))}
                </Group>
              ) : null}

              {results.core.caseLaws.length ? (
                <Group title={t("search.group.cases")}>
                  {results.core.caseLaws.map((caseLaw, index) => (
                    <div key={caseLaw.id}>
                      {index > 0 ? <Hairline /> : null}
                      <button type="button" onClick={() => open(`/cases/${caseLaw.id}`)} className="press block w-full">
                        <CaseLawRow title={caseLaw.title} court={caseLaw.court} year={caseLaw.year} principle={caseLaw.principle} />
                      </button>
                    </div>
                  ))}
                </Group>
              ) : null}

              {results.documents.length ? (
                <Group title={t("search.group.documents")}>
                  {results.documents.map((document, index) => (
                    <div key={document.id}>
                      {index > 0 ? <Hairline /> : null}
                      <button type="button" onClick={() => open(`/documents/${document.id}`)} className="press block w-full">
                        <DocumentRow document={document} isDownloaded={user.isDownloaded(document.id)} />
                      </button>
                    </div>
                  ))}
                </Group>
              ) : null}

              {results.studentDocs.length || results.quizzesMatch ? (
                <Group title={t("search.group.students")}>
                  {results.quizzesMatch ? (
                    <>
                      <button type="button" onClick={() => open("/quiz")} className="press flex w-full items-center gap-3 py-2.5 text-left">
                        <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[11px] bg-brand-soft text-brand">
                          <FileCheck2 className="h-3.5 w-3.5" strokeWidth={2.2} />
                        </span>
                        <span className="min-w-0 flex-1">
                          <span className="block text-[15px] font-medium text-ink">{t("quiz.title")}</span>
                          <span className="block text-xs text-slate">{t("students.quiz.sub")}</span>
                        </span>
                        <ChevronRight className="h-3.5 w-3.5 text-faint" strokeWidth={2.5} />
                      </button>
                      {results.studentDocs.length ? <Hairline /> : null}
                    </>
                  ) : null}
                  {results.studentDocs.map((document, index) => (
                    <div key={document.id}>
                      {index > 0 ? <Hairline /> : null}
                      <button type="button" onClick={() => open(`/documents/${document.id}`)} className="press block w-full">
                        <DocumentRow document={document} isDownloaded={user.isDownloaded(document.id)} />
                      </button>
                    </div>
                  ))}
                </Group>
              ) : null}

              {results.updates.length ? (
                <Group title={t("search.group.updates")}>
                  {results.updates.map((update, index) => (
                    <div key={update.id}>
                      {index > 0 ? <Hairline /> : null}
                      <button type="button" onClick={() => open(`/updates/${update.id}`)} className="press block w-full py-[11px] text-left">
                        <span className="line-clamp-2 block text-[15px] font-medium text-ink">{L.updateTitle(update, language)}</span>
                        <span className="block text-xs text-slate">
                          {L.updateCategoryLabel(update.category, language)} · {L.updateDate(update, language)}
                        </span>
                      </button>
                    </div>
                  ))}
                </Group>
              ) : null}

              {results.savedSections.length ? (
                <Group title={t("search.group.myspace")}>
                  {results.savedSections.map((section, index) => (
                    <div key={section.id}>
                      {index > 0 ? <Hairline /> : null}
                      <button type="button" onClick={() => open(`/read/${section.actId}/${section.id}`)} className="press block w-full">
                        <SectionRow number={section.number} title={section.title} subtitle={legalData.act(section.actId) ? actDisplayShortName(legalData.act(section.actId)!) : null} />
                      </button>
                    </div>
                  ))}
                </Group>
              ) : null}

              {results.settings.length ? (
                <Group title={t("search.group.settings")}>
                  {results.settings.map((entry, index) => (
                    <div key={entry.id}>
                      {index > 0 ? <Hairline /> : null}
                      <SettingsRow entry={entry} onOpen={open} />
                    </div>
                  ))}
                </Group>
              ) : null}
            </div>
          )}
        </div>
      </div>

      {selectedDefinition ? (
        <DefinitionDetailSheet
          definition={selectedDefinition}
          onClose={() => setSelectedDefinition(null)}
          onOpenSection={(sectionId) => {
            setSelectedDefinition(null);
            const section = legalData.section(sectionId);
            if (section) open(`/read/${section.actId}/${section.id}`);
          }}
        />
      ) : null}
    </div>
  );
}

function Group({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="pt-[22px]">
      <Overline text={title} color="var(--saffron-deep)" className="mb-0.5" />
      {children}
    </section>
  );
}

function SectionHitRow({ hit }: { hit: SectionHit }) {
  return (
    <div className="flex items-baseline gap-3.5 py-3 text-left">
      <span className="min-w-[46px] text-xl font-semibold tabular text-brand">{hit.section.number}</span>
      <div className="min-w-0 flex-1">
        <p className="text-base font-medium leading-snug text-ink">{hit.section.title}</p>
        <p className="text-xs text-slate">{legalData.act(hit.section.actId)?.name ?? ""}</p>
        {hit.reason ? <p className="text-xs font-medium text-saffron-deep">{hit.reason}</p> : null}
      </div>
      <ChevronRight className="h-3.5 w-3.5 shrink-0 self-center text-faint" strokeWidth={2.5} />
    </div>
  );
}

function MappingRow({ mapping, onOpen }: { mapping: IPCMapping; onOpen: (path: string) => void }) {
  const section = mapping.sectionId ? legalData.section(mapping.sectionId) : undefined;
  const content = (
    <div className="flex items-center gap-3 py-[11px] text-left">
      <div className="min-w-0 flex-1">
        <p className="flex items-center gap-2 text-[15px] font-semibold tabular">
          <span className="text-ink">IPC {mapping.ipc}</span>
          <ArrowRight className="h-3 w-3 text-saffron-deep" strokeWidth={2.5} />
          <span className="text-brand">BNS {mapping.bnsLabel}</span>
        </p>
        <p className="line-clamp-2 text-[13px] text-slate">{mapping.ipcTitle}</p>
      </div>
      {section ? <ChevronRight className="h-3.5 w-3.5 shrink-0 text-faint" strokeWidth={2.5} /> : null}
    </div>
  );
  return section ? (
    <button type="button" onClick={() => onOpen(`/read/${section.actId}/${section.id}`)} className="press block w-full">
      {content}
    </button>
  ) : (
    content
  );
}

function SettingsRow({ entry, onOpen }: { entry: SettingsSearchEntry; onOpen: (path: string) => void }) {
  const { t } = useLex();
  const ui = useUI();
  const Icon = settingsIcons[entry.icon] ?? SunMoon;
  return (
    <button
      type="button"
      onClick={() => {
        if (entry.path) onOpen(entry.path);
        else {
          ui.closeSearch();
          ui.setPlansPresented(true);
        }
      }}
      className="press flex w-full items-center gap-3 py-3 text-left"
    >
      <Icon className="h-3.5 w-3.5 shrink-0 text-brand" strokeWidth={2.2} />
      <span className="flex-1 text-[15px] font-medium text-ink">{t(entry.titleKey)}</span>
      <ChevronRight className="h-3 w-3 text-faint" strokeWidth={2.5} />
    </button>
  );
}
