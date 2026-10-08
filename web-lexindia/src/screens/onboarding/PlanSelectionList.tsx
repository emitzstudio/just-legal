/** The five plans as selectable rows — shared by the paywall and the membership sheet. */

import { CheckCircle2, Circle } from "lucide-react";

import { perMonth, planDuration } from "@/lib/localize";
import { PlanCatalog, planPriceLabel, planSavingsINR, type SubscriptionPlan } from "@/lib/models";
import { cn } from "@/lib/utils";
import { useLex } from "@/stores/useLex";

export function PlanSelectionList({
  selectedPlanId,
  onSelect,
}: {
  selectedPlanId: string;
  onSelect: (planId: string) => void;
}) {
  return (
    <div className="flex flex-col gap-2.5">
      {PlanCatalog.plans.map((plan) => (
        <PlanRow key={plan.id} plan={plan} selected={plan.id === selectedPlanId} onSelect={() => onSelect(plan.id)} />
      ))}
    </div>
  );
}

function PlanRow({ plan, selected, onSelect }: { plan: SubscriptionPlan; selected: boolean; onSelect: () => void }) {
  const { t, f, language } = useLex();
  const savings = planSavingsINR(plan);
  return (
    <button
      type="button"
      onClick={onSelect}
      aria-pressed={selected}
      className={cn(
        "press flex w-full items-center gap-3 rounded-[14px] border px-3.5 py-[13px] text-left transition-colors",
        selected ? "border-brand bg-brand-soft" : plan.isRecommended ? "border-saffron bg-surface" : "border-hairline bg-surface",
      )}
      style={selected ? { borderWidth: 1.5 } : undefined}
    >
      {selected ? (
        <CheckCircle2 className="h-5 w-5 shrink-0 text-brand" fill="var(--brand)" stroke="var(--on-brand)" />
      ) : (
        <Circle className="h-5 w-5 shrink-0 text-faint" />
      )}
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <span className="text-[17px] font-semibold text-ink">{planDuration(plan.months, language)}</span>
          {plan.isRecommended ? (
            <span className="rounded-full bg-saffron px-[7px] py-[3px] text-[9px] font-bold text-white">{t("paywall.best")}</span>
          ) : null}
        </div>
        <p className="mt-0.5 text-xs text-slate">{f("paywall.planLine", perMonth(plan, language), plan.includedCredits)}</p>
      </div>
      <div className="flex flex-col items-end gap-1">
        <span className="text-lg font-bold tabular text-brand">{planPriceLabel(plan)}</span>
        {savings !== null ? (
          <span className="rounded-full bg-mint px-[7px] py-[3px] text-[10px] font-semibold text-mint-deep">{f("paywall.save", savings)}</span>
        ) : null}
      </div>
    </button>
  );
}
