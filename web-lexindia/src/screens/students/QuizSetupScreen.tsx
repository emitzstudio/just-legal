/**
 * Configure a quiz: pick one or more topics, choose 20/50/100 questions,
 * see the perfect-score streak toward the weekly reward, start. Reward
 * amounts and the streak target come from QuizConfig.
 */

import { ArrowLeftRight, BadgeCheck, BookA, Check, ClipboardList, FileSearch, Flame, Gift, Info, Landmark, Play, Quote, ShieldHalf, Signature, type LucideIcon } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import { Overline, PrimaryButton, pastel } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import * as L from "@/lib/localize";
import { QUIZ_TOPICS, QuizConfig, quizTopicPastelIndex, type QuizRewardRule, type QuizTopic } from "@/lib/models";
import { QuizEngine } from "@/lib/quiz";
import { cn } from "@/lib/utils";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

const topicIcons: Record<QuizTopic, LucideIcon> = {
  bns: ShieldHalf,
  ipcBns: ArrowLeftRight,
  bnss: ClipboardList,
  evidence: FileSearch,
  constitution: Landmark,
  contract: Signature,
  definitions: BookA,
  cases: Quote,
};

export function QuizSetupScreen() {
  const { t, f, language } = useLex();
  const user = useUser();
  const navigate = useNavigate();
  const [selectedTopics, setSelectedTopics] = useState<Set<QuizTopic>>(() => new Set<QuizTopic>(["bns", "ipcBns"]));
  const [selectedCount, setSelectedCount] = useState<number>(20);

  const poolCount = useMemo(() => QuizEngine.poolCount(selectedTopics), [selectedTopics]);
  const canStart = selectedTopics.size > 0 && poolCount >= selectedCount;

  const toggleTopic = (topic: QuizTopic) => {
    setSelectedTopics((previous) => {
      const next = new Set(previous);
      if (next.has(topic)) next.delete(topic);
      else next.add(topic);
      return next;
    });
  };

  const start = () => {
    const questions = QuizEngine.makeQuiz(selectedTopics, selectedCount);
    if (questions.length !== selectedCount) return;
    navigate("/quiz/play", { state: { questions } });
  };

  const claimed = !user.isWeeklyQuizRewardAvailable;
  const complete = user.isRewardStreakComplete;
  const BannerIcon = claimed ? BadgeCheck : complete ? Gift : Flame;
  const bannerMessage = claimed
    ? t(complete ? "quiz.streak.complete" : "quiz.weekly.claimed")
    : complete
      ? t("quiz.streak.ready")
      : QuizConfig.streakTarget - user.quizPerfectStreak === 1
        ? t("quiz.streak.one")
        : f("quiz.streak.need", QuizConfig.streakTarget - user.quizPerfectStreak);

  return (
    <Screen>
      <NavBar fallback="/students" />
      <div className="pt-2">
        <h1 className="text-[30px] font-bold leading-tight text-ink">{t("quiz.title")}</h1>
        <p className="mt-1 text-sm text-slate">{t("quiz.subtitle")}</p>
      </div>

      <div
        className={cn("mt-4 rounded-[14px] border bg-surface p-3.5", complete && !claimed ? "border-mint-deep/35" : "border-hairline")}
      >
        <div className="flex items-center gap-3">
          <span
            className="flex h-[38px] w-[38px] shrink-0 items-center justify-center rounded-[11px]"
            style={{
              backgroundColor: claimed ? "var(--canvas)" : complete ? "var(--mint)" : "var(--saffron-soft)",
              color: claimed ? "var(--slate)" : complete ? "var(--mint-deep)" : "var(--saffron-deep)",
            }}
          >
            <BannerIcon className="h-4 w-4" strokeWidth={2.5} />
          </span>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-ink">{t("quiz.streak.title")}</p>
            <p className="text-xs tabular text-slate">{f("quiz.streak.progress", user.quizPerfectStreak, QuizConfig.streakTarget)}</p>
          </div>
        </div>
        <QuizStreakMeter streak={user.quizPerfectStreak} className="mt-2.5" />
        <p className="mt-2.5 text-xs leading-relaxed text-ink">{bannerMessage}</p>
        <p className="mt-1.5 text-[11px] tabular text-slate">{QuizConfig.lengths.map((rule) => `${rule.questionCount} → +${rule.credits}`).join(" · ")}</p>
      </div>

      <div className="mt-6">
        <Overline text={t("quiz.topics")} />
        <p className="text-xs text-slate">{t("quiz.topics.hint")}</p>
      </div>
      <div className="mt-2.5 flex flex-wrap gap-2">
        {QUIZ_TOPICS.map((topic) => {
          const isSelected = selectedTopics.has(topic);
          const colors = pastel(quizTopicPastelIndex(topic));
          const Icon = topicIcons[topic];
          return (
            <button
              key={topic}
              type="button"
              onClick={() => toggleTopic(topic)}
              aria-pressed={isSelected}
              className={cn("press flex items-center gap-1.5 rounded-full px-3 py-[9px] text-[13px] font-semibold transition-colors", !isSelected && "border border-hairline bg-surface text-slate")}
              style={isSelected ? { backgroundColor: colors.fill, color: colors.tone } : undefined}
            >
              {isSelected ? <Check className="h-3 w-3" strokeWidth={3} /> : <Icon className="h-3 w-3" strokeWidth={2.5} />}
              {L.quizTopicLabel(topic, language)}
            </button>
          );
        })}
      </div>

      <Overline text={t("quiz.length")} className="mt-[26px]" />
      <div className="mt-2.5 flex gap-2.5">
        {QuizConfig.lengths.map((rule) => (
          <LengthCard key={rule.questionCount} rule={rule} selected={selectedCount === rule.questionCount} available={poolCount >= rule.questionCount} onSelect={() => setSelectedCount(rule.questionCount)} />
        ))}
      </div>
      <p className="mt-2.5 text-xs text-slate">
        {Math.min(poolCount, 999)} {t("quiz.available")}
      </p>

      {selectedTopics.size === 0 ? (
        <Hint text={t("quiz.needTopics")} />
      ) : poolCount < selectedCount ? (
        <Hint text={t("quiz.pool.short")} />
      ) : null}

      <PrimaryButton className="mt-[18px]" onClick={start} disabled={!canStart}>
        <Play className="h-3.5 w-3.5" fill="currentColor" />
        {t("quiz.start")}
      </PrimaryButton>

      <p className="pb-7 pt-3.5 text-xs leading-relaxed text-slate">{t("quiz.weekly.rule")}</p>
    </Screen>
  );
}

function LengthCard({ rule, selected, available, onSelect }: { rule: QuizRewardRule; selected: boolean; available: boolean; onSelect: () => void }) {
  const { t } = useLex();
  return (
    <button
      type="button"
      onClick={onSelect}
      disabled={!available}
      aria-pressed={selected}
      className={cn(
        "press flex flex-1 flex-col items-center rounded-[14px] border bg-surface py-3.5 disabled:opacity-40",
        selected ? "border-brand" : "border-hairline",
      )}
      style={selected ? { borderWidth: 1.6 } : undefined}
    >
      <span className={cn("text-2xl font-bold tabular", selected ? "text-brand" : "text-ink")}>{rule.questionCount}</span>
      <span className={cn("mt-1 truncate text-[11px] font-semibold", selected ? "text-saffron-deep" : "text-slate")}>
        +{rule.credits} {t("quiz.reward.per")}
      </span>
    </button>
  );
}

function Hint({ text }: { text: string }) {
  return (
    <div className="mt-3 flex items-start gap-2 rounded-xl bg-saffron-soft p-3">
      <Info className="mt-0.5 h-3 w-3 shrink-0 text-saffron-deep" />
      <p className="text-[13px] leading-relaxed text-ink">{text}</p>
    </div>
  );
}

/** Segment meter for the perfect-score streak — shared by setup and results. */
export function QuizStreakMeter({ streak, className }: { streak: number; className?: string }) {
  return (
    <div className={cn("flex gap-1.5", className)} role="img" aria-label={`${streak} of ${QuizConfig.streakTarget} perfect scores`}>
      {Array.from({ length: QuizConfig.streakTarget }, (_, step) => (
        <span
          key={step}
          className="h-1.5 flex-1 rounded-full transition-colors duration-300"
          style={{ backgroundColor: step < streak ? "var(--saffron-deep)" : "var(--hairline)" }}
        />
      ))}
    </div>
  );
}
