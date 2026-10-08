/**
 * The timed quiz flow: one question at a time with instant feedback and a
 * live countdown (one minute per question). Finishing opens a full study
 * review — score, stats, the perfect-score streak toward the weekly
 * reward, and every question with the user's answer beside the correct one.
 */

import { CheckCircle2, Gift, Hourglass, Timer, XCircle } from "lucide-react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Navigate, useLocation, useNavigate } from "react-router-dom";

import { ConfirmDialog } from "@/components/lex/ConfirmDialog";
import { CloseButton, Overline, PrimaryButton, pastel } from "@/components/lex/primitives";
import * as L from "@/lib/localize";
import { QuizConfig, quizTopicPastelIndex, type QuizQuestion } from "@/lib/models";
import { QuizEngine } from "@/lib/quiz";
import { cn } from "@/lib/utils";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { QuizStreakMeter } from "./QuizSetupScreen";

const timeString = (seconds: number): string => `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;

export function QuizPlayScreen() {
  const location = useLocation();
  const questions = (location.state as { questions?: QuizQuestion[] } | null)?.questions;
  if (!questions || questions.length === 0) return <Navigate to="/quiz" replace />;
  return <QuizSession initial={questions} />;
}

function QuizSession({ initial }: { initial: QuizQuestion[] }) {
  const { t, f, language } = useLex();
  const user = useUser();
  const navigate = useNavigate();

  const [deck, setDeck] = useState<QuizQuestion[]>(initial);
  const [index, setIndex] = useState<number>(0);
  const [chosen, setChosen] = useState<number | null>(null);
  const [answers, setAnswers] = useState<(number | null)[]>(() => initial.map(() => null));
  const [isFinished, setIsFinished] = useState<boolean>(false);
  const [confirmExit, setConfirmExit] = useState<boolean>(false);
  const [claimedCredits, setClaimedCredits] = useState<number | null>(null);
  const [streakAtResult, setStreakAtResult] = useState<number>(0);
  const [timedOut, setTimedOut] = useState<boolean>(false);
  const [remaining, setRemaining] = useState<number>(QuizConfig.timeLimit(initial.length));
  const [remainingAtFinish, setRemainingAtFinish] = useState<number>(0);
  const [ringProgress, setRingProgress] = useState<number>(0);
  const endDate = useRef<number>(Date.now() + QuizConfig.timeLimit(initial.length) * 1000);
  const finishedRef = useRef<boolean>(false);

  const timeLimit = QuizConfig.timeLimit(deck.length);
  const current = deck[index];

  const correctCount = useMemo(() => deck.reduce((total, question, i) => total + (question.answerIndex === answers[i] ? 1 : 0), 0), [deck, answers]);

  const finish = useCallback(
    (expired: boolean) => {
      if (finishedRef.current) return;
      finishedRef.current = true;
      setTimedOut(expired);
      setRemainingAtFinish(expired ? 0 : Math.max(0, Math.ceil((endDate.current - Date.now()) / 1000)));
      const total = Math.max(deck.length, 1);
      const correct = deck.reduce((sum, question, i) => sum + (question.answerIndex === answers[i] ? 1 : 0), 0);
      const percent = Math.round((correct / total) * 100);
      const isPerfect = correct === deck.length && deck.length > 0;

      user.recordQuizFinished(isPerfect);
      const streakAfter = isPerfect ? Math.min(user.quizPerfectStreak + 1, QuizConfig.streakTarget) : user.quizPerfectStreak < QuizConfig.streakTarget ? 0 : user.quizPerfectStreak;
      const rule = QuizConfig.rule(deck.length);
      let claimed = false;
      if (streakAfter >= QuizConfig.streakTarget && user.isWeeklyQuizRewardAvailable && rule) {
        claimed = user.claimWeeklyQuizReward(rule.credits, `${deck.length} questions, ${percent}%`);
        if (claimed) setClaimedCredits(rule.credits);
      }
      setStreakAtResult(claimed ? 0 : streakAfter);
      setIsFinished(true);
      window.setTimeout(() => setRingProgress(correct / total), 250);
    },
    [deck, answers, user],
  );

  // Countdown — the deadline is a fixed timestamp so ticks stay accurate.
  useEffect(() => {
    if (isFinished) return;
    const interval = window.setInterval(() => {
      const left = Math.max(0, Math.ceil((endDate.current - Date.now()) / 1000));
      setRemaining(left);
      if (left === 0) finish(true);
    }, 200);
    return () => window.clearInterval(interval);
  }, [isFinished, finish]);

  const selectOption = (optionIndex: number) => {
    if (chosen !== null || isFinished || !current) return;
    setChosen(optionIndex);
    setAnswers((previous) => previous.map((value, i) => (i === index ? optionIndex : value)));
  };

  // Advance a second after the answer is revealed (reads the latest answers).
  useEffect(() => {
    if (chosen === null || isFinished) return;
    const timer = window.setTimeout(() => {
      if (index + 1 < deck.length) {
        setIndex(index + 1);
        setChosen(null);
      } else {
        finish(false);
      }
    }, 1000);
    return () => window.clearTimeout(timer);
  }, [chosen, index, deck.length, isFinished, finish]);

  const playAgain = () => {
    const reshuffled = QuizEngine.shuffle(deck);
    finishedRef.current = false;
    setDeck(reshuffled);
    setAnswers(reshuffled.map(() => null));
    setIndex(0);
    setChosen(null);
    setClaimedCredits(null);
    setRingProgress(0);
    setTimedOut(false);
    setRemainingAtFinish(0);
    endDate.current = Date.now() + QuizConfig.timeLimit(reshuffled.length) * 1000;
    setRemaining(QuizConfig.timeLimit(reshuffled.length));
    setIsFinished(false);
  };

  const exit = () => navigate("/quiz", { replace: true });

  if (isFinished) {
    const total = Math.max(deck.length, 1);
    const correct = correctCount;
    const fraction = correct / total;
    const percent = Math.round(fraction * 100);
    const isPerfect = correct === deck.length && deck.length > 0;
    const unanswered = answers.filter((value) => value === null).length;
    const wrong = total - correct - unanswered;
    const ringColor = isPerfect ? "var(--mint-deep)" : fraction >= QuizConfig.passThreshold ? "var(--brand)" : "var(--saffron)";
    const circumference = 2 * Math.PI * 66;
    const streakMessage =
      streakAtResult >= QuizConfig.streakTarget
        ? t(user.isWeeklyQuizRewardAvailable ? "quiz.streak.ready" : "quiz.streak.complete")
        : isPerfect
          ? QuizConfig.streakTarget - streakAtResult === 1
            ? t("quiz.streak.one")
            : f("quiz.streak.need", QuizConfig.streakTarget - streakAtResult)
          : t("quiz.streak.reset");

    return (
      <div className="fixed inset-0 z-40 overflow-y-auto bg-canvas">
        <div className="mx-auto w-full max-w-[640px] px-[22px] pb-7 anim-fade lg:max-w-[720px]">
          <div className="flex items-center justify-between pt-3.5">
            <h1 className="text-2xl font-bold text-ink">{t("quiz.result.title")}</h1>
            <CloseButton onClick={exit} />
          </div>

          <div className="mx-auto mt-[22px] flex h-[156px] w-[156px] items-center justify-center">
            <svg viewBox="0 0 156 156" className="absolute h-[156px] w-[156px] -rotate-90">
              <circle cx="78" cy="78" r="66" fill="none" stroke="var(--hairline)" strokeWidth="12" />
              <circle
                cx="78"
                cy="78"
                r="66"
                fill="none"
                stroke={ringColor}
                strokeWidth="12"
                strokeLinecap="round"
                strokeDasharray={circumference}
                strokeDashoffset={circumference * (1 - ringProgress)}
                style={{ transition: "stroke-dashoffset 1s cubic-bezier(0.2, 0.8, 0.2, 1)" }}
              />
            </svg>
            <div className="text-center">
              <p className="text-[38px] font-bold leading-none tabular text-ink">{percent}%</p>
              <p className="mt-1.5 text-sm tabular text-slate">
                {correct} / {total}
              </p>
            </div>
          </div>

          <p className="mt-4 text-center text-[22px] font-bold text-ink">
            {t(isPerfect ? "quiz.result.perfect" : fraction >= QuizConfig.passThreshold ? "quiz.result.pass" : "quiz.result.fail")}
          </p>

          {timedOut ? (
            <div className="mt-3.5 flex items-start gap-2 rounded-xl bg-saffron-soft p-3">
              <Hourglass className="mt-0.5 h-3 w-3 shrink-0 text-saffron-deep" />
              <p className="text-[13px] leading-relaxed text-ink">{t("quiz.result.timeUp")}</p>
            </div>
          ) : null}

          <div className="mt-[18px] grid grid-cols-2 gap-2.5">
            <StatTile value={`${correct}`} label={t("quiz.result.correct")} fill="var(--mint)" tone="var(--mint-deep)" />
            <StatTile value={`${wrong}`} label={t("quiz.result.incorrect")} fill={pastel(4).fill} tone={pastel(4).tone} />
            {unanswered > 0 ? (
              <StatTile value={`${unanswered}`} label={t("quiz.result.unanswered")} fill="var(--saffron-soft)" tone="var(--saffron-deep)" />
            ) : (
              <StatTile value={`${total}`} label={t("quiz.result.questions")} fill="var(--brand-soft)" tone="var(--brand)" />
            )}
            <StatTile value={timeString(timeLimit - remainingAtFinish)} label={t("quiz.time.used")} fill="var(--blue-soft)" tone="var(--blue-deep)" />
          </div>

          {!timedOut && remainingAtFinish > 0 ? (
            <p className="mt-2 text-xs tabular text-slate">
              {t("quiz.time.left")}: {timeString(remainingAtFinish)}
            </p>
          ) : null}

          <div className={cn("mt-3.5 rounded-2xl border bg-surface p-3.5", claimedCredits !== null ? "border-mint-deep/35" : "border-hairline")}>
            <div className="flex items-baseline justify-between">
              <Overline text={t("quiz.streak.title")} color="var(--saffron-deep)" />
              <span className="text-xs font-semibold tabular text-ink">{f("quiz.streak.progress", streakAtResult, QuizConfig.streakTarget)}</span>
            </div>
            <QuizStreakMeter streak={streakAtResult} className="mt-2.5" />
            {claimedCredits !== null ? (
              <>
                <div className="mt-2.5 flex items-center gap-2 rounded-[10px] bg-mint p-2.5">
                  <Gift className="h-3.5 w-3.5 text-mint-deep" fill="currentColor" />
                  <p className="text-[13px] font-semibold text-ink">
                    +{claimedCredits} {t("quiz.result.rewardAdded")}
                  </p>
                </div>
                <p className="mt-2 text-xs leading-relaxed text-slate">{t("quiz.streak.afterClaim")}</p>
              </>
            ) : (
              <p className="mt-2.5 text-xs leading-relaxed text-slate">{streakMessage}</p>
            )}
          </div>

          <div className="mt-7">
            <Overline text={t("quiz.review.title")} />
            <p className="text-xs text-slate">{t("quiz.review.sub")}</p>
          </div>
          <div className="mt-3 flex flex-col gap-2.5">
            {deck.map((question, questionIndex) => (
              <ReviewCard key={question.id} index={questionIndex} question={question} userAnswer={answers[questionIndex] ?? null} />
            ))}
          </div>

          <div className="mt-6 flex flex-col gap-2.5">
            <button type="button" onClick={playAgain} className="press w-full rounded-[14px] bg-brand-soft py-3.5 text-base font-semibold text-brand">
              {t("quiz.playAgain")}
            </button>
            <PrimaryButton onClick={exit}>{t("common.done")}</PrimaryButton>
          </div>
        </div>
      </div>
    );
  }

  const isLow = remaining <= 60;
  const isCritical = remaining <= 10;
  const progress = (index + (chosen === null ? 0 : 1)) / Math.max(deck.length, 1);

  return (
    <div className="fixed inset-0 z-40 flex flex-col bg-canvas">
      <div className="mx-auto flex w-full max-w-[640px] flex-1 flex-col px-[22px] lg:max-w-[720px]">
        <div className="flex items-center justify-between pt-3.5">
          <CloseButton onClick={() => setConfirmExit(true)} />
          <span className="text-sm font-semibold tabular text-ink">
            {index + 1} / {deck.length}
          </span>
          <span
            className={cn("flex items-center gap-1.5 rounded-full border px-2.5 py-[5px] text-[13px] font-bold tabular transition-colors", isLow ? "border-transparent" : "border-hairline bg-surface text-ink")}
            style={isCritical ? { backgroundColor: pastel(4).fill, color: pastel(4).tone } : isLow ? { backgroundColor: "var(--saffron-soft)", color: "var(--saffron-deep)" } : undefined}
            aria-label={`${t("quiz.time.left")}: ${timeString(remaining)}`}
          >
            <Timer className="h-3 w-3" strokeWidth={2.5} />
            {timeString(remaining)}
          </span>
        </div>
        <div className="mt-3.5 h-[5px] overflow-hidden rounded-full bg-hairline">
          <div className="h-full rounded-full bg-brand transition-[width] duration-400" style={{ width: `${progress * 100}%` }} />
        </div>

        {current ? (
          <div key={current.id} className="flex-1 overflow-y-auto pb-8 pt-[18px] no-scrollbar anim-rise">
            <div className="rounded-2xl border border-hairline bg-surface p-4">
              <div className="flex items-baseline justify-between gap-2">
                <Overline text={`${t("quiz.question")} ${index + 1}`} color="var(--saffron-deep)" />
                <span
                  className="max-w-[150px] truncate rounded-full px-2 py-1 text-[10px] font-semibold"
                  style={{ backgroundColor: pastel(quizTopicPastelIndex(current.topic)).fill, color: pastel(quizTopicPastelIndex(current.topic)).tone }}
                >
                  {L.quizTopicLabel(current.topic, language)}
                </span>
              </div>
              <p className="mt-2 text-xl font-semibold leading-relaxed text-ink">{current.prompt}</p>
            </div>
            <div className="mt-4 flex flex-col gap-2.5">
              {current.options.map((option, optionIndex) => (
                <OptionButton key={optionIndex} index={optionIndex} option={option} isAnswer={optionIndex === current.answerIndex} isChosen={optionIndex === chosen} revealed={chosen !== null} onSelect={() => selectOption(optionIndex)} />
              ))}
            </div>
          </div>
        ) : null}
      </div>

      <ConfirmDialog
        open={confirmExit}
        title={t("quiz.exit.title")}
        message={t("quiz.exit.message")}
        confirmLabel={t("quiz.exit.confirm")}
        cancelLabel={t("common.cancel")}
        destructive
        onConfirm={exit}
        onCancel={() => setConfirmExit(false)}
      />
    </div>
  );
}

const letters = ["A", "B", "C", "D", "E"];

function OptionButton({ index, option, isAnswer, isChosen, revealed, onSelect }: { index: number; option: string; isAnswer: boolean; isChosen: boolean; revealed: boolean; onSelect: () => void }) {
  const wrong = pastel(4);
  const fill = !revealed ? "var(--surface)" : isAnswer ? "var(--mint)" : isChosen ? wrong.fill : "var(--surface)";
  const tone = !revealed ? "var(--ink)" : isAnswer ? "var(--mint-deep)" : isChosen ? wrong.tone : "var(--slate)";
  const highlighted = revealed && (isAnswer || isChosen);
  return (
    <button
      type="button"
      onClick={onSelect}
      disabled={revealed}
      className="press flex w-full items-center gap-3 rounded-[14px] border px-3.5 py-[13px] text-left transition-colors duration-200"
      style={{ backgroundColor: fill, borderColor: revealed && isAnswer ? "color-mix(in srgb, var(--mint-deep) 40%, transparent)" : "var(--hairline)" }}
    >
      <span
        className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[13px] font-bold"
        style={{ backgroundColor: highlighted ? "transparent" : "var(--brand-soft)", color: highlighted ? tone : "var(--brand)", boxShadow: highlighted ? `inset 0 0 0 1px color-mix(in srgb, ${tone} 50%, transparent)` : undefined }}
      >
        {letters[Math.min(index, letters.length - 1)]}
      </span>
      <span className="flex-1 text-[15px] font-medium leading-relaxed" style={{ color: tone }}>
        {option}
      </span>
      {revealed && isAnswer ? <CheckCircle2 className="h-[17px] w-[17px] shrink-0 text-mint-deep" /> : null}
      {revealed && isChosen && !isAnswer ? <XCircle className="h-[17px] w-[17px] shrink-0" style={{ color: wrong.tone }} /> : null}
    </button>
  );
}

function StatTile({ value, label, fill, tone }: { value: string; label: string; fill: string; tone: string }) {
  return (
    <div className="flex flex-col items-center rounded-[14px] py-3" style={{ backgroundColor: fill, color: tone }}>
      <span className="text-xl font-bold tabular">{value}</span>
      <span className="mt-0.5 truncate text-[11px] font-semibold opacity-85">{label}</span>
    </div>
  );
}

function ReviewCard({ index, question, userAnswer }: { index: number; question: QuizQuestion; userAnswer: number | null }) {
  const { t } = useLex();
  const isCorrect = userAnswer === question.answerIndex;
  const statusTone = isCorrect ? "var(--mint-deep)" : pastel(4).tone;
  const statusFill = isCorrect ? "var(--mint)" : pastel(4).fill;
  return (
    <div className="rounded-[14px] border border-hairline bg-surface p-3.5">
      <div className="flex items-center justify-between">
        <span className="rounded-full px-2 py-[3px] text-[11px] font-bold tabular" style={{ backgroundColor: statusFill, color: statusTone }}>
          Q{index + 1}
        </span>
        {isCorrect ? <CheckCircle2 className="h-4 w-4" style={{ color: statusTone }} /> : <XCircle className="h-4 w-4" style={{ color: statusTone }} />}
      </div>
      <p className="mt-2.5 text-sm font-medium leading-relaxed text-ink">{question.prompt}</p>
      <div className="mt-2.5 flex flex-col gap-2">
        {userAnswer !== null ? (
          <AnswerLine label={t("quiz.review.your")} text={question.options[userAnswer]} tone={statusTone} fill={statusFill} />
        ) : (
          <AnswerLine label={t("quiz.review.notAnswered")} text={null} tone="var(--saffron-deep)" fill="var(--saffron-soft)" />
        )}
        {!isCorrect ? <AnswerLine label={t("quiz.review.correct")} text={question.options[question.answerIndex]} tone="var(--mint-deep)" fill="var(--mint)" /> : null}
      </div>
    </div>
  );
}

function AnswerLine({ label, text, tone, fill }: { label: string; text: string | null; tone: string; fill: string }) {
  return (
    <div className="rounded-[10px] p-2.5" style={{ backgroundColor: `color-mix(in srgb, ${fill} 55%, transparent)` }}>
      <p className="text-[10px] font-bold uppercase" style={{ color: tone }}>
        {label}
      </p>
      {text ? <p className="mt-0.5 text-[13px] font-medium leading-snug text-ink">{text}</p> : null}
    </div>
  );
}
