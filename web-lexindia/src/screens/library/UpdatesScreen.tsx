/**
 * Legal Updates — court news, new laws, amendments and notifications.
 * Currently demo content; the production pipeline is editorial.
 */

import { ArrowRight, Newspaper, Sparkles } from "lucide-react";
import { useState } from "react";
import { Link, useParams } from "react-router-dom";

import { updateCategoryIcon } from "@/components/lex/icons";
import { BenchDivider, EmptyState, Hairline, Overline, PageHeader, ReadAloudControl, SectionRow, pastel } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { LegalUpdatesCatalog, legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { UPDATE_CATEGORIES, actDisplayShortName, updateCategoryPastelIndex, type LegalUpdate, type UpdateCategory } from "@/lib/models";
import { cn } from "@/lib/utils";
import { useLex } from "@/stores/useLex";

function CategoryChip({ update }: { update: LegalUpdate }) {
  const { language } = useLex();
  const colors = pastel(updateCategoryPastelIndex(update.category));
  const Icon = updateCategoryIcon[update.category];
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full px-2 py-1 text-[11px] font-semibold" style={{ backgroundColor: colors.fill, color: colors.tone }}>
      <Icon className="h-2.5 w-2.5" strokeWidth={3} />
      {L.updateCategoryLabel(update.category, language)}
    </span>
  );
}

export function UpdatesScreen() {
  const { t, language } = useLex();
  const [selected, setSelected] = useState<UpdateCategory | null>(null);
  const filtered = LegalUpdatesCatalog.updatesIn(selected);

  return (
    <Screen>
      <NavBar fallback="/library" />
      <PageHeader title={t("updates.title")} subtitle={t("updates.sub")} />
      <div className="mt-3.5 flex items-start gap-2.5 rounded-xl bg-saffron-soft p-3">
        <Sparkles className="mt-0.5 h-3.5 w-3.5 shrink-0 text-saffron-deep" />
        <p className="text-xs leading-relaxed text-slate">{t("updates.preview")}</p>
      </div>
      <div className="-mx-[22px] mt-3.5 flex gap-2 overflow-x-auto px-[22px] no-scrollbar lg:-mx-8 lg:px-8">
        {[null, ...UPDATE_CATEGORIES].map((category) => {
          const isSelected = selected === category;
          const label = category ? L.updateCategoryLabel(category, language) : t("common.all");
          return (
            <button
              key={category ?? "all"}
              type="button"
              onClick={() => setSelected(category)}
              aria-pressed={isSelected}
              className={cn(
                "press shrink-0 rounded-full px-[13px] py-2 text-[13px] font-semibold transition-colors",
                isSelected ? "bg-brand text-on-brand" : "border border-hairline bg-surface text-slate",
              )}
            >
              {label}
            </button>
          );
        })}
      </div>
      <div className="mt-4 flex flex-col gap-2.5">
        {filtered.map((update) => (
          <Link key={update.id} to={`/updates/${update.id}`} className="press block rounded-2xl border border-hairline bg-surface p-4 anim-fade">
            <div className="flex items-center justify-between">
              <CategoryChip update={update} />
              <span className="text-xs text-slate">{L.updateDate(update, language)}</span>
            </div>
            <p className="mt-2 text-[17px] font-semibold leading-snug text-ink">{L.updateTitle(update, language)}</p>
            <p className="mt-1.5 line-clamp-3 text-[13px] leading-relaxed text-slate">{L.updateSnippet(update, language)}</p>
            <p className="mt-2 flex items-center gap-1 text-[13px] font-semibold text-brand">
              {t("updates.read")}
              <ArrowRight className="h-2.5 w-2.5" strokeWidth={2.5} />
            </p>
          </Link>
        ))}
      </div>
      {filtered.length === 0 ? <EmptyState icon={<Newspaper className="h-6 w-6" />} title={t("updates.empty")} message={t("updates.empty.sub")} /> : null}
      <div className="h-7" />
    </Screen>
  );
}

export function UpdateDetailScreen() {
  const { id = "" } = useParams();
  const { t, language } = useLex();
  const update = LegalUpdatesCatalog.update(id);

  if (!update) {
    return (
      <Screen>
        <NavBar fallback="/updates" />
        <EmptyState icon={<Newspaper className="h-6 w-6" />} title={t("act.notFound.title")} message={t("updates.notFound")} />
      </Screen>
    );
  }

  const sections = update.relatedSectionIds.map((sid) => legalData.section(sid)).filter(Boolean);

  return (
    <Screen>
      <NavBar fallback="/updates" />
      <div className="flex items-center justify-between pt-2.5">
        <CategoryChip update={update} />
        <ReadAloudControl id={update.id} text={`${update.title}. ${update.body.join(" ")}`} />
      </div>
      <h1 className="mt-3 text-[25px] font-bold leading-tight text-ink">{L.updateTitle(update, language)}</h1>
      <p className="mt-1.5 text-[13px] text-slate">
        {L.updateSource(update, language)} · {L.updateDate(update, language)}
      </p>
      <BenchDivider className="my-5" />
      <div className="space-y-3.5">
        {update.body.map((paragraph, index) => (
          <p key={index} className="text-[15px] leading-[1.7] text-ink">
            {paragraph}
          </p>
        ))}
      </div>
      {sections.length ? (
        <div className="mt-6">
          <Overline text={t("updates.provisions")} className="mb-1" />
          {sections.map((section, index) =>
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
      <div className="mb-7 mt-6 rounded-xl bg-saffron-soft p-3.5">
        <Overline text={t("updates.previewShort")} color="var(--saffron-deep)" />
        <p className="mt-2 text-xs leading-relaxed text-slate">{t("updates.demo.note")}</p>
      </div>
    </Screen>
  );
}
