/** Glossary of legal terms: browse, search, open, save. */

import { BookA, Bookmark, ChevronRight } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import { Sheet } from "@/components/lex/ConfirmDialog";
import { EmptyState, FilterField, Hairline, Overline, PageHeader, SectionRow } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import { actDisplayShortName, type LegalDefinition } from "@/lib/models";
import { cn } from "@/lib/utils";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

export function DefinitionsScreen() {
  const { t } = useLex();
  return (
    <Screen>
      <NavBar fallback="/library" />
      <PageHeader title={t("account.definitions")} subtitle={t("defs.sub")} />
      <div className="mt-3.5 pb-6">
        <DefinitionsBrowser />
      </div>
    </Screen>
  );
}

/** Reusable glossary list. */
export function DefinitionsBrowser() {
  const { t } = useLex();
  const user = useUser();
  const navigate = useNavigate();
  const [query, setQuery] = useState<string>("");
  const [selected, setSelected] = useState<LegalDefinition | null>(null);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    const sorted = [...legalData.core.definitions].sort((a, b) => a.term.toLowerCase().localeCompare(b.term.toLowerCase()));
    if (!q) return sorted;
    return sorted.filter((d) => d.term.toLowerCase().includes(q) || d.meaning.toLowerCase().includes(q));
  }, [query]);

  return (
    <div>
      <FilterField value={query} onChange={setQuery} placeholder={t("defs.search")} inputMode="search" />
      {filtered.length === 0 ? (
        <EmptyState icon={<BookA className="h-6 w-6" />} title={t("defs.emptyTitle")} message={t("defs.emptySub")} />
      ) : (
        <div className="mt-1.5">
          {filtered.map((definition, index) => (
            <div key={definition.id}>
              {index > 0 ? <Hairline /> : null}
              <button type="button" onClick={() => setSelected(definition)} className="press flex w-full items-center gap-2.5 py-3 text-left">
                <span className="min-w-0 flex-1">
                  <span className="block text-base font-semibold leading-snug text-ink">{definition.term}</span>
                  <span className="mt-0.5 line-clamp-2 block text-[13px] leading-snug text-slate">{definition.meaning}</span>
                </span>
                {user.isDefinitionSaved(definition.id) ? <Bookmark className="h-3 w-3 shrink-0 text-saffron-deep" fill="currentColor" /> : null}
                <ChevronRight className="h-3 w-3 shrink-0 text-faint" strokeWidth={2.5} />
              </button>
            </div>
          ))}
        </div>
      )}
      {selected ? (
        <DefinitionDetailSheet
          definition={selected}
          onClose={() => setSelected(null)}
          onOpenSection={(sectionId) => {
            setSelected(null);
            const section = legalData.section(sectionId);
            if (section) window.setTimeout(() => navigate(`/read/${section.actId}/${section.id}`), 200);
          }}
        />
      ) : null}
    </div>
  );
}

/** Full definition with source note, related provisions and save. */
export function DefinitionDetailSheet({
  definition,
  onClose,
  onOpenSection,
}: {
  definition: LegalDefinition;
  onClose: () => void;
  onOpenSection: (sectionId: string) => void;
}) {
  const { t } = useLex();
  const user = useUser();
  const saved = user.isDefinitionSaved(definition.id);
  const related = definition.relatedSectionIds.map((id) => legalData.section(id)).filter(Boolean);
  const cases = definition.relatedCaseLawIds.map((id) => legalData.caseLaw(id)).filter(Boolean);

  return (
    <Sheet open onClose={onClose} label={definition.term}>
      <div className="flex items-start gap-3 pt-[22px]">
        <div className="min-w-0 flex-1">
          <Overline text={t("defs.one")} color="var(--saffron-deep)" />
          <h2 className="mt-1 text-2xl font-bold leading-tight text-ink">{definition.term}</h2>
        </div>
        <button
          type="button"
          onClick={() => user.toggleSavedDefinition(definition.id)}
          aria-label={saved ? "Remove saved term" : "Save term"}
          className={cn("press flex h-11 w-11 shrink-0 items-center justify-center rounded-full", saved ? "text-saffron-deep" : "text-slate")}
        >
          <Bookmark className="h-[17px] w-[17px]" fill={saved ? "currentColor" : "none"} />
        </button>
      </div>
      <p className="mt-3.5 text-base leading-[1.7] text-ink">{definition.meaning}</p>
      {definition.sourceNote ? <p className="mt-2.5 text-xs font-medium text-saffron-deep">{definition.sourceNote}</p> : null}
      {related.length ? (
        <div className="mt-6">
          <Overline text={t("cases.related")} />
          {related.map((section, index) =>
            section ? (
              <div key={section.id}>
                {index > 0 ? <Hairline /> : null}
                <button type="button" onClick={() => onOpenSection(section.id)} className="press block w-full">
                  <SectionRow number={section.number} title={section.title} subtitle={legalData.act(section.actId) ? actDisplayShortName(legalData.act(section.actId)!) : null} />
                </button>
              </div>
            ) : null,
          )}
        </div>
      ) : null}
      {cases.length ? (
        <div className="mt-5">
          <Overline text={t("cases.one")} />
          {cases.map((caseLaw) =>
            caseLaw ? (
              <div key={caseLaw.id} className="py-2.5">
                <p className="text-[15px] font-semibold text-ink">{caseLaw.title}</p>
                <p className="text-xs text-slate">
                  {caseLaw.court} · {caseLaw.year}
                </p>
                <p className="mt-1 text-[13px] leading-relaxed text-slate">{caseLaw.principle}</p>
              </div>
            ) : null,
          )}
        </div>
      ) : null}
      <div className="h-8" />
    </Sheet>
  );
}
