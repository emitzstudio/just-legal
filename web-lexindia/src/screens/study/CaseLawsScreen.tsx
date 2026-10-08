/** Landmark judgments with principles, summaries and linked provisions. */

import { Quote } from "lucide-react";
import { useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";

import { CaseLawRow, EmptyState, FilterField, Hairline, Overline, PageHeader, ReadAloudControl, SectionRow } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import { actDisplayShortName } from "@/lib/models";
import { useLex } from "@/stores/useLex";

export function CaseLawsScreen() {
  const { t } = useLex();
  const [query, setQuery] = useState<string>("");
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    const sorted = [...legalData.core.caseLaws].sort((a, b) => b.year - a.year);
    if (!q) return sorted;
    return sorted.filter((c) => c.title.toLowerCase().includes(q) || c.principle.toLowerCase().includes(q));
  }, [query]);

  return (
    <Screen>
      <NavBar fallback="/library" />
      <PageHeader title={t("account.caseLaws")} subtitle={t("cases.sub")} />
      <div className="mt-3.5">
        <FilterField value={query} onChange={setQuery} placeholder={t("cases.search")} inputMode="search" />
      </div>
      {filtered.length === 0 ? (
        <EmptyState icon={<Quote className="h-6 w-6" />} title={t("cases.emptyTitle")} message={t("cases.emptySub")} />
      ) : (
        <div className="mt-1.5 pb-6">
          {filtered.map((caseLaw, index) => (
            <div key={caseLaw.id}>
              {index > 0 ? <Hairline /> : null}
              <Link to={`/cases/${caseLaw.id}`} className="press block">
                <CaseLawRow title={caseLaw.title} court={caseLaw.court} year={caseLaw.year} principle={caseLaw.principle} />
              </Link>
            </div>
          ))}
        </div>
      )}
    </Screen>
  );
}

export function CaseLawDetailScreen() {
  const { id = "" } = useParams();
  const { t } = useLex();
  const caseLaw = legalData.caseLaw(id);

  if (!caseLaw) {
    return (
      <Screen>
        <NavBar fallback="/cases" />
        <EmptyState icon={<Quote className="h-6 w-6" />} title={t("act.notFound.title")} message={t("cases.notFound")} />
      </Screen>
    );
  }

  const related = caseLaw.relatedSectionIds.map((sid) => legalData.section(sid)).filter(Boolean);

  return (
    <Screen>
      <NavBar fallback="/cases" />
      <div className="pt-2">
        <div className="flex items-center justify-between">
          <Overline text={t("cases.one")} color="var(--saffron-deep)" />
          <ReadAloudControl id={caseLaw.id} text={`${caseLaw.title}. ${caseLaw.court}, ${caseLaw.year}. Key principle: ${caseLaw.principle}. ${caseLaw.summary}`} />
        </div>
        <h1 className="mt-1.5 text-[25px] font-bold leading-tight text-ink">{caseLaw.title}</h1>
        <p className="mt-1.5 text-[13px] text-slate">
          {caseLaw.court} · {caseLaw.year}
        </p>
      </div>
      <div className="mt-[22px] flex overflow-hidden rounded bg-surface">
        <span className="w-1 shrink-0 bg-saffron" />
        <div className="px-4 py-3.5">
          <Overline text={t("cases.principle")} color="var(--saffron-deep)" />
          <p className="mt-2 text-[17px] font-semibold leading-relaxed text-ink">{caseLaw.principle}</p>
        </div>
      </div>
      <Overline text={t("cases.summary")} className="mt-6" />
      <p className="mt-2 text-[15px] leading-[1.7] text-ink">{caseLaw.summary}</p>
      {related.length ? (
        <div className="mt-[26px]">
          <Overline text={t("cases.related")} />
          {related.map((section, index) =>
            section ? (
              <div key={section.id}>
                {index > 0 ? <Hairline /> : null}
                <Link to={`/read/${section.actId}/${section.id}`} className="press block">
                  <SectionRow number={section.number} title={section.title} subtitle={legalData.act(section.actId) ? actDisplayShortName(legalData.act(section.actId)!) : null} />
                </Link>
              </div>
            ) : null,
          )}
        </div>
      ) : null}
      <p className="pb-6 pt-6 text-xs text-slate">{t("cases.note")}</p>
    </Screen>
  );
}
