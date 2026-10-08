/**
 * The subscription gate shown after sign-in when no access is active:
 * the five plans, the 24-hour free trial, and (development builds only)
 * permanent test access.
 */

import { CheckCircle2, Hourglass, Wrench } from "lucide-react";
import { useState } from "react";

import { ConfirmDialog } from "@/components/lex/ConfirmDialog";
import { AccentDiamond, Overline, PrimaryButton, TrustFootnote } from "@/components/lex/primitives";
import { planDuration } from "@/lib/localize";
import { DevConfig, PlanCatalog, planDurationLabel, planPriceLabel, type SubscriptionPlan } from "@/lib/models";
import { useAccess } from "@/stores/accessStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { PlanSelectionList } from "./PlanSelectionList";

export function PaywallScreen() {
  const { t, f, language } = useLex();
  const access = useAccess();
  const user = useUser();
  const [selectedPlanId, setSelectedPlanId] = useState<string>(PlanCatalog.plans[0].id);
  const [confirmingPlan, setConfirmingPlan] = useState<SubscriptionPlan | null>(null);
  const [confirmSignOut, setConfirmSignOut] = useState<boolean>(false);

  const selectedPlan = PlanCatalog.plan(selectedPlanId);

  const subscribe = (plan: SubscriptionPlan) => {
    user.addCredits(plan.includedCredits, `Included with the ${planDurationLabel(plan)} plan`);
    access.activateSubscription(plan);
    setConfirmingPlan(null);
  };

  return (
    <div className="min-h-screen bg-canvas">
      <div className="mx-auto w-full max-w-[520px] px-[22px] pb-6 pt-[18px] anim-rise">
        <div className="rounded-3xl p-[22px] text-on-brand brand-gradient">
          <div className="flex items-center justify-between">
            <Overline text="LexIndia" color="color-mix(in srgb, var(--on-brand) 62%, transparent)" />
            <AccentDiamond size={7} color="var(--on-brand)" />
          </div>
          <h1 className="mt-2.5 whitespace-pre-line text-[30px] font-bold leading-tight">{t("paywall.hero")}</h1>
          <ul className="mt-4 space-y-2">
            {["paywall.feature1", "paywall.feature2", "paywall.feature3"].map((key) => (
              <li key={key} className="flex items-start gap-2 text-sm">
                <CheckCircle2 className="mt-0.5 h-3.5 w-3.5 shrink-0" fill="currentColor" stroke="var(--brand)" />
                <span className="opacity-90">{t(key)}</span>
              </li>
            ))}
          </ul>
        </div>

        {access.accessExpired ? (
          <div className="mt-4 flex items-start gap-2.5 rounded-[14px] bg-saffron-soft p-3.5">
            <Hourglass className="mt-0.5 h-4 w-4 shrink-0 text-saffron-deep" />
            <p className="text-sm leading-relaxed text-ink">
              {t(access.expiredEntitlementWasTrial ? "paywall.expired.trial" : "paywall.expired.plan")}
            </p>
          </div>
        ) : null}

        <Overline text={t("paywall.choose")} className="mt-[26px]" />
        <div className="mt-3">
          <PlanSelectionList selectedPlanId={selectedPlanId} onSelect={setSelectedPlanId} />
        </div>

        {selectedPlan ? (
          <PrimaryButton className="mt-[18px]" onClick={() => setConfirmingPlan(selectedPlan)}>
            {f("paywall.continue", planPriceLabel(selectedPlan), planDuration(selectedPlan.months, language))}
          </PrimaryButton>
        ) : null}

        {!access.hasUsedTrial ? (
          <button
            type="button"
            onClick={access.startTrial}
            className="press mt-3 w-full rounded-[14px] border border-brand/45 bg-surface py-3 text-center"
            aria-label="Try free for 24 hours. Full access, no payment."
          >
            <span className="block text-base font-semibold text-brand">{t("paywall.try")}</span>
            <span className="mt-0.5 block text-xs text-slate">{t("paywall.try.sub")}</span>
          </button>
        ) : null}

        <p className="mt-3.5 text-center text-xs text-slate">{t("paywall.demo")}</p>

        {DevConfig.permanentTestAccessEnabled ? (
          <div
            className="mt-7 rounded-[14px] bg-surface/60 p-4"
            style={{ outline: "1px dashed color-mix(in srgb, var(--faint) 70%, transparent)", outlineOffset: -1 }}
          >
            <div className="flex items-center gap-2">
              <Wrench className="h-3.5 w-3.5 text-slate" />
              <Overline text={t("account.devOnly")} />
            </div>
            <p className="mt-2.5 text-[13px] leading-relaxed text-slate">{t("paywall.dev.note")}</p>
            <button
              type="button"
              onClick={access.activateDevAccess}
              className="press mt-2.5 w-full rounded-[10px] border border-faint bg-canvas py-[11px] text-sm font-semibold text-ink"
            >
              {t("paywall.dev.cta")}
            </button>
          </div>
        ) : null}

        <div className="mt-[26px] space-y-2 text-center">
          {access.user ? (
            <p className="text-xs text-slate">
              {f("paywall.signedIn", access.user.email)}{" "}
              <button type="button" onClick={() => setConfirmSignOut(true)} className="font-semibold text-brand">
                {t("account.signout")}
              </button>
            </p>
          ) : null}
          <TrustFootnote />
        </div>
      </div>

      <ConfirmDialog
        open={confirmingPlan !== null}
        title={t("paywall.demoTitle")}
        message={confirmingPlan ? f("paywall.includes", confirmingPlan.includedCredits) : undefined}
        confirmLabel={
          confirmingPlan ? f("paywall.start", planDuration(confirmingPlan.months, language), planPriceLabel(confirmingPlan)) : ""
        }
        cancelLabel={t("common.cancel")}
        onConfirm={() => confirmingPlan && subscribe(confirmingPlan)}
        onCancel={() => setConfirmingPlan(null)}
      />
      <ConfirmDialog
        open={confirmSignOut}
        title={t("account.signoutTitle")}
        confirmLabel={t("account.signout")}
        cancelLabel={t("common.cancel")}
        destructive
        onConfirm={() => {
          setConfirmSignOut(false);
          access.signOut();
        }}
        onCancel={() => setConfirmSignOut(false)}
      />
    </div>
  );
}
