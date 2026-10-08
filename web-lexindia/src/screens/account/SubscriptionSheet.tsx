/**
 * Membership management inside the app: the five plans, the current
 * entitlement (subscription, trial or dev test access) and cancellation.
 */

import { BadgeCheck, Hourglass, Wrench } from "lucide-react";
import { useState } from "react";

import { ConfirmDialog, Sheet } from "@/components/lex/ConfirmDialog";
import { Hairline, Overline, PrimaryButton } from "@/components/lex/primitives";
import * as L from "@/lib/localize";
import { PlanCatalog, planDurationLabel, planPriceLabel, type SubscriptionPlan } from "@/lib/models";
import { useAccess } from "@/stores/accessStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { PlanSelectionList } from "../onboarding/PlanSelectionList";

export function SubscriptionSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { t, f, language } = useLex();
  const access = useAccess();
  const user = useUser();
  const [selectedPlanId, setSelectedPlanId] = useState<string>(PlanCatalog.plans[0].id);
  const [confirmingPlan, setConfirmingPlan] = useState<SubscriptionPlan | null>(null);
  const [confirmCancel, setConfirmCancel] = useState<boolean>(false);
  const [confirmEndDev, setConfirmEndDev] = useState<boolean>(false);

  const subscribe = (plan: SubscriptionPlan) => {
    user.addCredits(plan.includedCredits, `Included with the ${planDurationLabel(plan)} plan`);
    access.activateSubscription(plan);
    setConfirmingPlan(null);
    window.setTimeout(onClose, 500);
  };

  const selected = PlanCatalog.plan(selectedPlanId);
  const info = access.subscriptionInfo;

  return (
    <>
      <Sheet open={open} onClose={onClose} label={t("sub.membership")} tall>
        <div className="mt-[22px] rounded-[18px] p-5 text-on-brand brand-gradient">
          <Overline text={t("sub.membership")} color="color-mix(in srgb, var(--on-brand) 62%, transparent)" />
          <h2 className="mt-2 text-[30px] font-bold leading-tight">{t("sub.title")}</h2>
          <p className="mt-2 text-sm leading-relaxed opacity-80">{t("sub.tagline")}</p>
        </div>

        {info ? (
          <div className="mt-[22px] space-y-4">
            <div className="flex items-center gap-2.5">
              <BadgeCheck className="h-[18px] w-[18px] text-mint-deep" fill="var(--mint)" />
              <div>
                <p className="text-lg font-semibold text-ink">{f("sub.planActive", L.planDuration(info.plan.months, language))}</p>
                <p className="text-[13px] text-slate">{f("sub.planLine", planPriceLabel(info.plan), info.plan.includedCredits)}</p>
              </div>
            </div>
            <div className="overflow-hidden rounded-[14px] border border-hairline bg-canvas">
              <DetailRow title={t("sub.started")} value={L.date(info.start, language)} />
              <Hairline />
              <DetailRow title={t("sub.expires")} value={L.date(info.end, language)} />
              <Hairline />
              <DetailRow title={t("sub.balance")} value={`${user.credits}`} />
            </div>
            <FeatureList />
            <button type="button" onClick={() => setConfirmCancel(true)} className="press pt-1 text-sm font-medium" style={{ color: "var(--pastel-4-tone)" }}>
              {t("sub.cancel")}
            </button>
          </div>
        ) : (
          <>
            {access.isOnTrial ? (
              <div className="mt-[18px] flex items-start gap-2.5 rounded-[14px] bg-saffron-soft p-3.5">
                <Hourglass className="mt-0.5 h-4 w-4 shrink-0 text-saffron-deep" />
                <div>
                  <p className="text-[15px] font-semibold text-ink">{t("sub.trial.active")}</p>
                  {access.trialRemaining !== null ? (
                    <p className="mt-0.5 text-[13px] leading-relaxed text-slate">{f("sub.trial.endsLine", L.remaining(access.trialRemaining, language))}</p>
                  ) : null}
                </div>
              </div>
            ) : null}
            {access.isDevAccess ? (
              <div className="mt-[18px] rounded-[14px] bg-canvas p-3.5" style={{ outline: "1px dashed color-mix(in srgb, var(--faint) 70%, transparent)", outlineOffset: -1 }}>
                <div className="flex items-center gap-2">
                  <Wrench className="h-3 w-3 text-slate" />
                  <Overline text={t("account.devOnly")} />
                  <span className="flex-1" />
                  <button type="button" onClick={() => setConfirmEndDev(true)} className="text-[13px] font-semibold text-brand">
                    {t("sub.dev.end")}
                  </button>
                </div>
                <p className="mt-2 text-[13px] leading-relaxed text-slate">{t("sub.dev.active")}</p>
              </div>
            ) : null}
            <Overline text={t("sub.plans")} className="mt-6" />
            <div className="mt-3">
              <PlanSelectionList selectedPlanId={selectedPlanId} onSelect={setSelectedPlanId} />
            </div>
            {selected ? (
              <PrimaryButton className="mt-[18px]" onClick={() => setConfirmingPlan(selected)}>
                {f("paywall.continue", planPriceLabel(selected), L.planDuration(selected.months, language))}
              </PrimaryButton>
            ) : null}
            <div className="mt-[26px]">
              <FeatureList />
            </div>
            <p className="mt-4 text-center text-xs text-slate">{t("paywall.demo")}</p>
          </>
        )}
        <div className="h-9" />
      </Sheet>

      <ConfirmDialog
        open={confirmingPlan !== null}
        title={t("paywall.demoTitle")}
        message={confirmingPlan ? f("paywall.includes", confirmingPlan.includedCredits) : undefined}
        confirmLabel={confirmingPlan ? f("paywall.start", L.planDuration(confirmingPlan.months, language), planPriceLabel(confirmingPlan)) : ""}
        cancelLabel={t("common.cancel")}
        onConfirm={() => confirmingPlan && subscribe(confirmingPlan)}
        onCancel={() => setConfirmingPlan(null)}
      />
      <ConfirmDialog
        open={confirmCancel}
        title={t("sub.cancelTitle")}
        message={t("sub.cancelMessage")}
        confirmLabel={t("sub.cancel")}
        cancelLabel={t("sub.keepPlan")}
        destructive
        onConfirm={() => {
          setConfirmCancel(false);
          access.cancelSubscription();
          onClose();
        }}
        onCancel={() => setConfirmCancel(false)}
      />
      <ConfirmDialog
        open={confirmEndDev}
        title={t("sub.dev.endTitle")}
        message={t("sub.dev.endMessage")}
        confirmLabel={t("sub.dev.end")}
        cancelLabel={t("sub.dev.keep")}
        destructive
        onConfirm={() => {
          setConfirmEndDev(false);
          access.endDevAccess();
          onClose();
        }}
        onCancel={() => setConfirmEndDev(false)}
      />
    </>
  );
}

function DetailRow({ title, value }: { title: string; value: string }) {
  return (
    <div className="flex items-center justify-between px-4 py-3">
      <span className="text-sm text-slate">{title}</span>
      <span className="text-sm font-semibold tabular text-ink">{value}</span>
    </div>
  );
}

function FeatureList() {
  const { t } = useLex();
  return (
    <div className="space-y-3">
      <Overline text={t("sub.included")} />
      {["sub.feat1", "sub.feat2", "sub.feat3", "sub.feat4", "sub.feat5"].map((key) => (
        <p key={key} className="flex items-start gap-2.5 text-[15px] leading-relaxed text-ink">
          <BadgeCheck className="mt-1 h-3.5 w-3.5 shrink-0 text-mint-deep" />
          {t(key)}
        </p>
      ))}
    </div>
  );
}
