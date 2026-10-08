/**
 * Credit balance, usage stats, buying more (with confirmation) and the
 * full credit history. This is the ONLY place the balance is shown.
 */

import { AlertCircle, History } from "lucide-react";
import { useState } from "react";

import { ConfirmDialog, Sheet } from "@/components/lex/ConfirmDialog";
import { CloseButton, EmptyState, Hairline, Overline } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import * as L from "@/lib/localize";
import { CreditPackCatalog, type CreditPack, type CreditTransaction } from "@/lib/models";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

export function BuyCreditsSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { t, f } = useLex();
  const user = useUser();
  const [confirming, setConfirming] = useState<CreditPack | null>(null);

  const purchase = (pack: CreditPack) => {
    user.addCredits(pack.amount, `Purchased ${pack.amount} credits (₹${pack.priceINR})`);
    setConfirming(null);
    window.setTimeout(onClose, 500);
  };

  return (
    <>
      <Sheet open={open} onClose={onClose} label={t("account.credits.balance")}>
        <div className="flex items-start gap-3 pt-[22px]">
          <div className="min-w-0 flex-1">
            <h2 className="text-[26px] font-bold leading-tight text-ink">{t("account.credits.balance")}</h2>
            <p className="mt-1 text-sm leading-relaxed text-slate">{t("credits.explainer")}</p>
          </div>
          <CloseButton onClick={onClose} />
        </div>

        <div className="mt-[18px] flex rounded-2xl bg-brand-soft py-4">
          <Stat value={`${user.credits}`} label={t("credits.remaining")} tone="var(--brand)" />
          <span className="my-auto h-[34px] w-px" style={{ backgroundColor: "color-mix(in srgb, var(--brand) 12%, transparent)" }} />
          <Stat value={`${user.creditsUsed}`} label={t("credits.used")} tone="var(--ink)" />
          <span className="my-auto h-[34px] w-px" style={{ backgroundColor: "color-mix(in srgb, var(--brand) 12%, transparent)" }} />
          <Stat value={`${user.creditsAdded}`} label={t("credits.added")} tone="var(--ink)" />
        </div>

        {user.credits === 0 ? (
          <div className="mt-3.5 flex items-start gap-2.5 rounded-[14px] bg-saffron-soft p-3.5">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-saffron-deep" />
            <p className="text-[13px] leading-relaxed text-ink">{t("credits.out")}</p>
          </div>
        ) : user.isLowOnCredits ? (
          <p className="mt-3.5 text-[13px] font-medium text-saffron-deep">{t("credits.low")}</p>
        ) : null}

        <Overline text={t("credits.buyMore")} className="mt-6" />
        <div className="mt-2.5 flex flex-col gap-2.5">
          {CreditPackCatalog.map((pack) => (
            <button
              key={pack.id}
              type="button"
              onClick={() => setConfirming(pack)}
              className="press flex w-full items-center gap-3 rounded-[14px] border border-hairline bg-canvas px-4 py-[15px] text-left"
              aria-label={`${pack.amount} credits for ₹${pack.priceINR}`}
            >
              <span className="min-w-0 flex-1">
                <span className="block text-lg font-semibold tabular text-ink">
                  {pack.amount} {t("quiz.reward.per")}
                </span>
                {pack.note ? <Overline text={t(pack.note)} color="var(--saffron-deep)" /> : null}
              </span>
              <span className="text-[17px] font-semibold text-brand">₹{pack.priceINR}</span>
            </button>
          ))}
        </div>
        <p className="mt-3.5 text-xs text-slate">{t("credits.demo")}</p>

        {user.creditHistory.length ? (
          <div className="mt-[26px]">
            <Overline text={t("credits.recent")} className="mb-1" />
            {user.creditHistory.slice(0, 4).map((transaction, index) => (
              <div key={transaction.id}>
                {index > 0 ? <Hairline /> : null}
                <TransactionRow transaction={transaction} />
              </div>
            ))}
          </div>
        ) : null}
        <div className="h-8" />
      </Sheet>
      <ConfirmDialog
        open={confirming !== null}
        title={t("credits.demoTitle")}
        message={confirming ? f("credits.becomes", user.credits + confirming.amount) : undefined}
        confirmLabel={confirming ? f("credits.addPack", confirming.amount, `₹${confirming.priceINR}`) : ""}
        cancelLabel={t("common.cancel")}
        onConfirm={() => confirming && purchase(confirming)}
        onCancel={() => setConfirming(null)}
      />
    </>
  );
}

function Stat({ value, label, tone }: { value: string; label: string; tone: string }) {
  return (
    <div className="flex flex-1 flex-col items-center">
      <span className="text-[22px] font-bold tabular" style={{ color: tone }}>
        {value}
      </span>
      <span className="text-xs text-slate">{label}</span>
    </div>
  );
}

export function TransactionRow({ transaction }: { transaction: CreditTransaction }) {
  const { language } = useLex();
  return (
    <div className="flex items-center gap-3 py-2.5">
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm text-ink">{transaction.reason}</p>
        <p className="text-xs text-slate">{L.dateTime(transaction.date, language)}</p>
      </div>
      <span className={`text-[15px] font-semibold tabular ${transaction.delta > 0 ? "text-mint-deep" : "text-slate"}`}>
        {transaction.delta > 0 ? `+${transaction.delta}` : transaction.delta}
      </span>
    </div>
  );
}

export function CreditHistoryScreen() {
  const { t, f } = useLex();
  const user = useUser();
  return (
    <Screen>
      <NavBar fallback="/account" />
      <h1 className="pt-2 text-[28px] font-bold leading-tight text-ink">{t("account.credits.history")}</h1>
      <p className="mt-1 text-sm tabular text-slate">{f("credits.summary", user.credits, user.creditsUsed, user.creditsAdded)}</p>
      {user.creditHistory.length === 0 ? (
        <EmptyState icon={<History className="h-6 w-6" />} title={t("credits.emptyTitle")} message={t("credits.emptySub")} className="pt-10" />
      ) : (
        <div className="mt-[18px] pb-8">
          {user.creditHistory.map((transaction, index) => (
            <div key={transaction.id}>
              {index > 0 ? <Hairline /> : null}
              <TransactionRow transaction={transaction} />
            </div>
          ))}
        </div>
      )}
    </Screen>
  );
}
