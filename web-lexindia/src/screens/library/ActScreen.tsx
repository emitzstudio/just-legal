/** Act → its chapters, as a structured table of contents, with search within the Act. */

import { ArrowLeftRight, BookMarked, ChevronRight, Search } from "lucide-react";
import { useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";

import { EmptyState, FilterField, Hairline, Overline, PreparedPanel, SectionRow } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { actDisplayShortName, sectionHasGuide, type LegalChapter } from "@/lib/models";
import { cn } from "@/lib/utils";
import { useLex } from "@/stores/useLex";

export function ActScreen() {
  const { id = "" } = useParams();
  const { t, language } = useLex();
  const [filter, setFilter] = useState<string>("");
  const act = legalData.act(id);
  const loaded = useMemo(() => legalData.sectionsInAct(id), [id]);
  const guided = loaded.filter(sectionHasGuide).length;

  const query = filter.trim().toLowerCase();
  const matches = useMemo(
    () =>
      query
        ? loaded
            .filter(
              (section) =>
                section.number.toLowerCase().startsWith(query) ||
                section.title.toLowerCase().includes(query) ||
                section.keywords.some((keyword) => keyword.includes(query)),
            )
            .slice(0, 30)
        : [],
    [loaded, query],
  );

  if (!act) {
    return (
      <Screen>
        <NavBar fallback="/library" />
        <EmptyState icon={<BookMarked className="h-6 w-6" />} title={t("act.notFound.title")} message={t("act.notFound.act")} />
      </Screen>
    );
  }

  return (
    <Screen>
      <NavBar title={actDisplayShortName(act)} fallback="/library" />
      <div className="pt-2">
        <Overline text={L.actSource(act, language)} color="var(--saffron-deep)" />
        <h1 className="mt-2 text-[26px] font-bold leading-tight text-ink">{L.actName(act, language)}</h1>
        <p className="mt-2 text-[15px] leading-relaxed text-slate">{L.actSummary(act, language)}</p>
        <div className="mt-3.5 flex flex-wrap gap-2">
          {loaded.length > 0 ? (
            <Chip text={`${t("library.badge.fulltext")} · ${loaded.length} ${t("library.badge.sections")}`} className="bg-mint text-mint-deep" />
          ) : (
            <Chip text={t("prepared.title")} className="bg-saffron-soft text-saffron-deep" />
          )}
          {guided > 0 ? <Chip text={`${guided} ${t("library.badge.guided")}`} className="bg-brand-soft text-brand" /> : null}
          <Chip text={L.actEffective(act, language)} className="border border-hairline bg-surface text-slate" />
        </div>
      </div>

      {act.id === "bns" ? (
        <Link to="/ipc-bns" className="press mt-4 flex items-center gap-3 rounded-[14px] bg-brand-soft p-3" aria-label="IPC to BNS converter">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[11px] bg-on-brand text-brand">
            <ArrowLeftRight className="h-3.5 w-3.5" strokeWidth={2.5} />
          </span>
          <span className="min-w-0 flex-1">
            <span className="block text-[15px] font-semibold text-ink">{t("act.ipcCard.title")}</span>
            <span className="block text-xs text-slate">{t("act.ipcCard.sub")}</span>
          </span>
          <ChevronRight className="h-3.5 w-3.5 shrink-0 text-brand" strokeWidth={2.5} />
        </Link>
      ) : null}

      {loaded.length > 0 ? (
        <div className="mt-4">
          <FilterField value={filter} onChange={setFilter} placeholder={t("act.searchIn")} inputMode="search" />
        </div>
      ) : null}

      {query ? (
        <div className="mt-3">
          {matches.length === 0 ? (
            <EmptyState icon={<Search className="h-6 w-6" />} title={t("act.noMatches")} message={t("act.noMatches.sub")} />
          ) : (
            matches.map((section, index) => (
              <div key={section.id}>
                {index > 0 ? <Hairline /> : null}
                <Link to={`/read/${act.id}/${section.id}`} className="press block">
                  <SectionRow number={section.number} title={section.title} showsGuideBadge={sectionHasGuide(section)} />
                </Link>
              </div>
            ))
          )}
        </div>
      ) : act.chapters.length === 0 ? (
        <div className="mt-[22px]">
          <PreparedPanel message={t("prepared.message")} />
        </div>
      ) : (
        <div className="mt-[22px]">
          <Overline text={t("act.contents")} className="mb-1" />
          {act.chapters.map((chapter, index) => {
            const sections = legalData.sectionsInChapter(chapter.id);
            const guides = sections.filter(sectionHasGuide).length;
            const row = <ChapterRow chapter={chapter} actId={act.id} count={sections.length} guides={guides} />;
            return (
              <div key={chapter.id}>
                {index > 0 ? <Hairline /> : null}
                {sections.length > 0 ? (
                  <Link to={`/chapter/${chapter.id}`} className="press block">
                    {row}
                  </Link>
                ) : (
                  <div className="opacity-60">{row}</div>
                )}
              </div>
            );
          })}
        </div>
      )}

      <p className="pb-6 pt-[26px] text-xs text-slate">
        {t("act.source")}: {L.actSource(act, language)} · {L.actEffective(act, language)}
      </p>
    </Screen>
  );
}

function Chip({ text, className }: { text: string; className?: string }) {
  return <span className={cn("rounded-full px-2.5 py-1.5 text-xs font-medium", className)}>{text}</span>;
}

function ChapterRow({ chapter, actId, count, guides }: { chapter: LegalChapter; actId: string; count: number; guides: number }) {
  const { t, language } = useLex();
  const sectionsWord = language === "hi" ? t("library.badge.sections") : count === 1 ? "section" : "sections";
  let subtitle = count > 0 ? `${chapter.rangeLabel} · ${count} ${sectionsWord}` : `${chapter.rangeLabel} · ${t("act.beingPrepared")}`;
  if (count > 0 && guides > 0) subtitle += ` · ${guides} ${t("library.badge.guided")}`;
  return (
    <div className="flex items-center gap-3 py-[13px] text-left">
      <div className="min-w-0 flex-1">
        <Overline text={`${t("reader.chapter")} ${chapter.numeral}`} color="var(--saffron-deep)" />
        <p className="mt-0.5 text-[17px] font-semibold leading-snug text-ink">{L.chapterTitle(chapter.numeral, chapter.title, actId, language)}</p>
        <p className="mt-0.5 text-xs text-slate">{subtitle}</p>
      </div>
      {count > 0 ? <ChevronRight className="h-3.5 w-3.5 shrink-0 text-brand" strokeWidth={2.5} /> : null}
    </div>
  );
}
