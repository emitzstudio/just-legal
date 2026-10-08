/**
 * Contextual depth for the current section in two tabs: Understand More
 * (example, key points, terms, related, old-code reference) and Landmark
 * Cases (only cases linked to this section).
 */

import { ArrowLeftRight, BookOpen, CheckCircle2, ChevronDown, Quote } from "lucide-react";
import { useMemo, useState, type ReactNode } from "react";

import { Sheet } from "@/components/lex/ConfirmDialog";
import { CloseButton, EmptyState, Hairline, Overline, SectionRow } from "@/components/lex/primitives";
import { legalData } from "@/lib/legalData";
import { actDisplayShortName, sectionHasGuide, type CaseLaw, type LegalDefinition, type LegalSection } from "@/lib/models";
import { cn } from "@/lib/utils";
import { useLex } from "@/stores/useLex";

type SheetTab = "understand" | "cases";

export function UnderstandMoreSheet({
  section,
  onClose,
  onOpenSection,
}: {
  section: LegalSection;
  onClose: () => void;
  onOpenSection: (sectionId: string) => void;
}) {
  const { t, f } = useLex();
  const [tab, setTab] = useState<SheetTab>("understand");
  const [expandedCase, setExpandedCase] = useState<string | null>(null);
  const [expandedDefinition, setExpandedDefinition] = useState<string | null>(null);

  const linkedCases = useMemo((): CaseLaw[] => {
    const seen = new Set<string>();
    const result: CaseLaw[] = [];
    for (const id of section.caseLawIds) {
      const caseLaw = legalData.caseLaw(id);
      if (caseLaw && !seen.has(caseLaw.id)) {
        seen.add(caseLaw.id);
        result.push(caseLaw);
      }
    }
    for (const caseLaw of legalData.core.caseLaws) {
      if (caseLaw.relatedSectionIds.includes(section.id) && !seen.has(caseLaw.id)) {
        seen.add(caseLaw.id);
        result.push(caseLaw);
      }
    }
    return result;
  }, [section]);

  const related = section.relatedSectionIds.map((id) => legalData.section(id)).filter((item): item is LegalSection => !!item);
  const definitions = section.definitionIds.map((id) => legalData.definition(id)).filter((item): item is LegalDefinition => !!item);
  const mappingNote = legalData.core.ipcMappings.find((mapping) => mapping.sectionId === section.id)?.note ?? null;
  const isBare = !sectionHasGuide(section) && !section.example && section.keyPoints.length === 0 && section.relatedSectionIds.length === 0;

  return (
    <Sheet open onClose={onClose} label="Understand more" tall>
      <div className="flex items-start gap-3 pt-5">
        <div className="min-w-0 flex-1">
          <Overline text={`${t("reader.section")} ${section.number}`} color="var(--saffron-deep)" />
          <h2 className="mt-1 text-xl font-semibold leading-snug text-ink">{section.title}</h2>
        </div>
        <CloseButton onClick={onClose} />
      </div>

      <div className="mt-4 flex rounded-xl bg-canvas p-1" role="tablist">
        {(["understand", "cases"] as SheetTab[]).map((option) => (
          <button
            key={option}
            type="button"
            role="tab"
            aria-selected={tab === option}
            onClick={() => setTab(option)}
            className={cn(
              "flex-1 rounded-lg py-2 text-[13px] font-semibold transition-colors",
              tab === option ? "bg-surface text-ink shadow-sm" : "text-slate",
            )}
          >
            {t(option === "understand" ? "reader.understand" : "reader.cases")}
          </button>
        ))}
      </div>

      {tab === "understand" ? (
        <div className="anim-fade">
          {isBare ? (
            <EmptyState
              icon={<BookOpen className="h-6 w-6" />}
              title="Guide being prepared"
              message={`The plain-language guide for Section ${section.number} — example, key points and related sections — is being prepared for LexIndia. The full official text is on the reading page.`}
              className="pt-6"
            />
          ) : null}

          {section.example ? (
            <Block title={t("understand.example")}>
              <p className="rounded-xl bg-saffron-soft p-3.5 text-[15px] leading-relaxed text-ink">{section.example}</p>
            </Block>
          ) : null}

          {section.keyPoints.length ? (
            <Block title={t("understand.keypoints")}>
              <ul className="space-y-2.5">
                {section.keyPoints.map((point) => (
                  <li key={point} className="flex items-start gap-2.5 text-[15px] leading-relaxed text-ink">
                    <CheckCircle2 className="mt-1 h-4 w-4 shrink-0 text-mint-deep" />
                    <span>{point}</span>
                  </li>
                ))}
              </ul>
            </Block>
          ) : null}

          {section.ipcLabel ? (
            <Block title={t("understand.oldcode")}>
              <div className="rounded-xl bg-blue-soft p-3">
                <p className="flex items-center gap-2 text-sm font-semibold text-ink">
                  <ArrowLeftRight className="h-3 w-3 text-saffron-deep" strokeWidth={2.5} />
                  {t("understand.earlier")} {section.ipcLabel}
                </p>
                {mappingNote ? <p className="mt-1.5 text-[13px] leading-relaxed text-slate">{mappingNote}</p> : null}
              </div>
            </Block>
          ) : null}

          {related.length ? (
            <Block title={t("understand.relatedSections")}>
              {related.map((item, index) => (
                <div key={item.id}>
                  {index > 0 ? <Hairline /> : null}
                  <button type="button" onClick={() => onOpenSection(item.id)} className="press block w-full">
                    <SectionRow
                      number={item.number}
                      title={item.title}
                      subtitle={item.actId === section.actId ? null : legalData.act(item.actId) ? actDisplayShortName(legalData.act(item.actId)!) : null}
                    />
                  </button>
                </div>
              ))}
            </Block>
          ) : null}

          {definitions.length ? (
            <Block title={t("understand.definitions")}>
              {definitions.map((definition, index) => {
                const expanded = expandedDefinition === definition.id;
                return (
                  <div key={definition.id}>
                    {index > 0 ? <Hairline /> : null}
                    <button
                      type="button"
                      onClick={() => setExpandedDefinition(expanded ? null : definition.id)}
                      className="press block w-full py-[11px] text-left"
                    >
                      <span className="flex items-center gap-2">
                        <span className="flex-1 text-base font-semibold text-ink">{definition.term}</span>
                        <ChevronDown className={cn("h-3.5 w-3.5 text-slate transition-transform", expanded && "rotate-180")} strokeWidth={2.5} />
                      </span>
                      {expanded ? (
                        <>
                          <span className="mt-1.5 block text-sm leading-relaxed text-ink">{definition.meaning}</span>
                          {definition.sourceNote ? <span className="mt-1 block text-xs text-saffron-deep">{definition.sourceNote}</span> : null}
                        </>
                      ) : (
                        <span className="mt-1 block truncate text-[13px] text-slate">{definition.meaning}</span>
                      )}
                    </button>
                  </div>
                );
              })}
            </Block>
          ) : null}
        </div>
      ) : (
        <div className="anim-fade">
          {linkedCases.length === 0 ? (
            <EmptyState
              icon={<Quote className="h-6 w-6" />}
              title="No landmark cases yet"
              message={`No cases are linked to Section ${section.number} in LexIndia yet. They appear here as the case library grows.`}
              className="pt-6"
            />
          ) : (
            <Block title={linkedCases.length === 1 ? t("understand.casesOne") : f("understand.casesMany", linkedCases.length)}>
              {linkedCases.map((caseLaw, index) => {
                const expanded = expandedCase === caseLaw.id;
                return (
                  <div key={caseLaw.id}>
                    {index > 0 ? <Hairline /> : null}
                    <button
                      type="button"
                      onClick={() => setExpandedCase(expanded ? null : caseLaw.id)}
                      className="press block w-full py-3 text-left"
                      aria-description={expanded ? "Collapses the case summary" : "Expands the case summary"}
                    >
                      <span className="flex items-start gap-2">
                        <span className="flex-1 text-base font-semibold leading-snug text-ink">{caseLaw.title}</span>
                        <ChevronDown className={cn("mt-1 h-3.5 w-3.5 shrink-0 text-slate transition-transform", expanded && "rotate-180")} strokeWidth={2.5} />
                      </span>
                      <span className="mt-1 block text-xs text-slate">
                        {caseLaw.court} · {caseLaw.year}
                      </span>
                      <span className="mt-1.5 block text-sm leading-relaxed text-ink">{caseLaw.principle}</span>
                      {expanded ? <span className="mt-2 block text-sm leading-relaxed text-slate">{caseLaw.summary}</span> : null}
                    </button>
                  </div>
                );
              })}
            </Block>
          )}
        </div>
      )}

      <p className="pb-8 pt-[26px] text-xs text-slate">{t("trust.footnote")}</p>
    </Sheet>
  );
}

function Block({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="mt-6">
      <Overline text={title} className="mb-[11px]" />
      {children}
    </section>
  );
}
