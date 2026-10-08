/** Category → the Acts it contains. */

import { BookMarked, ChevronRight } from "lucide-react";
import { Link, useParams } from "react-router-dom";

import { BenchDivider, EmptyState, Hairline } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { useLex } from "@/stores/useLex";

export function CategoryScreen() {
  const { id = "" } = useParams();
  const { t, language } = useLex();
  const category = legalData.category(id);

  if (!category) {
    return (
      <Screen>
        <NavBar fallback="/library" />
        <EmptyState icon={<BookMarked className="h-6 w-6" />} title={t("act.notFound.title")} message={t("act.notFound.category")} />
      </Screen>
    );
  }

  return (
    <Screen>
      <NavBar fallback="/library" />
      <h1 className="pt-2 text-[30px] font-bold leading-tight text-ink">{L.categoryName(category, language)}</h1>
      <p className="mt-1 text-[15px] text-slate">{L.categoryTagline(category, language)}</p>
      <BenchDivider className="my-5" />
      <div className="pb-6">
        {legalData.actsInCategory(id).map((act, index) => {
          const guided = legalData.sectionsInAct(act.id).length;
          return (
            <div key={act.id}>
              {index > 0 ? <Hairline /> : null}
              <Link to={`/act/${act.id}`} className="press flex items-center gap-3 py-4">
                <span className="min-w-0 flex-1">
                  <span className="block text-[19px] font-semibold leading-snug text-ink">{L.actName(act, language)}</span>
                  <span className="mt-1 block text-[13px] text-slate">
                    {L.actExtent(act, language)} · {L.actEffective(act, language)}
                  </span>
                  {guided > 0 ? (
                    <span className="mt-1 block text-xs font-medium text-brand">
                      {guided} {t("act.guidedSections")}
                    </span>
                  ) : (
                    <span className="mt-1 block text-xs font-medium text-saffron-deep">{t("prepared.title")}</span>
                  )}
                </span>
                <ChevronRight className="h-3.5 w-3.5 shrink-0 text-brand" strokeWidth={2.5} />
              </Link>
            </div>
          );
        })}
      </div>
    </Screen>
  );
}
