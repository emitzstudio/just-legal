/**
 * A polished, once-per-milestone reminder shown during the 24-hour trial.
 * Encouraging, never spammy — each scheduled reminder appears exactly once.
 */

import { X } from "lucide-react";

import { AccentDiamond } from "@/components/lex/primitives";
import { reminderTitle, remaining as remainingLabel } from "@/lib/localize";
import type { TrialReminder } from "@/lib/models";
import { useLex } from "@/stores/useLex";

export function TrialReminderCard({
  reminder,
  remaining,
  onSeePlans,
  onDismiss,
}: {
  reminder: TrialReminder;
  remaining: number | null;
  onSeePlans: () => void;
  onDismiss: () => void;
}) {
  const { t, f, language } = useLex();
  const remainingLine =
    remaining === null ? t("trial.keep") : f("trial.endsLine", remainingLabel(remaining, language));

  return (
    <div
      className="w-full rounded-[18px] p-4 text-on-brand brand-gradient anim-rise"
      style={{ boxShadow: "0 8px 18px color-mix(in srgb, var(--brand-deep) 35%, transparent)" }}
      role="status"
    >
      <div className="flex items-start gap-2.5">
        <span className="pt-1.5">
          <AccentDiamond size={7} color="var(--on-brand)" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-base font-semibold">{reminderTitle(reminder.id, reminder.title, language)}</p>
          <p className="mt-0.5 text-[13px] leading-snug opacity-80">{remainingLine}</p>
        </div>
        <button
          type="button"
          onClick={onDismiss}
          aria-label="Dismiss reminder"
          className="press flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-on-brand/10 opacity-70"
        >
          <X className="h-3 w-3" strokeWidth={3} />
        </button>
      </div>
      <div className="mt-3 flex items-center gap-2.5">
        <button
          type="button"
          onClick={onSeePlans}
          className="press rounded-full bg-on-brand px-4 py-2 text-sm font-semibold text-brand"
        >
          {t("myspace.seePlans")}
        </button>
        <button type="button" onClick={onDismiss} className="press py-2 text-sm font-medium opacity-75">
          {t("common.notNow")}
        </button>
      </div>
    </div>
  );
}
