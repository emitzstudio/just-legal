/**
 * The student hub: quizzes with the weekly reward, downloadable study
 * resources, study tools, and the roadmap (courses, competitions, moot
 * courts) clearly marked as coming soon.
 */

import { ArrowLeftRight, ArrowRight, BadgeCheck, BookA, BookMarked, Flame, Gift, Medal, Quote, Users } from "lucide-react";
import { Link } from "react-router-dom";

import { DocumentRow } from "@/components/lex/DocumentRow";
import { Hairline, HubHeader, IconTile, Overline, TrustFootnote } from "@/components/lex/primitives";
import { Screen } from "@/components/shell/Screen";
import { DocumentCatalog } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { QuizConfig, type DocumentKind } from "@/lib/models";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { ScalesGlyph } from "@/components/evakeel/EVakeelLogo";
import { ToolChip } from "../library/LibraryScreen";

const resourceKinds: DocumentKind[] = ["exam-note", "previous-paper", "revision"];

export function StudentsCornerScreen() {
  const { t, f, language } = useLex();
  const user = useUser();

  const claimed = !user.isWeeklyQuizRewardAvailable;
  const chipText = claimed
    ? t("quiz.weekly.claimed")
    : user.isRewardStreakComplete
      ? t("quiz.weekly.available")
      : f("quiz.streak.chip", user.quizPerfectStreak, QuizConfig.streakTarget);
  const ChipIcon = claimed ? BadgeCheck : user.isRewardStreakComplete ? Gift : Flame;

  return (
    <Screen>
      <HubHeader title={t("students.title")} subtitle={t("students.subtitle")} />

      <Link
        to="/quiz"
        className="press relative mt-5 block overflow-hidden rounded-[20px] p-[18px] text-on-brand brand-gradient"
        aria-label={`Quiz Challenge. ${chipText}`}
      >
        <div className="flex items-center justify-between">
          <Overline text={t("students.quizzes")} color="color-mix(in srgb, var(--on-brand) 62%, transparent)" />
          <span
            className="inline-flex max-w-[70%] items-center gap-1.5 rounded-full bg-on-brand/90 px-2 py-1 text-[10px] font-bold tabular"
            style={{ color: claimed ? "var(--slate)" : "var(--saffron-deep)" }}
          >
            <ChipIcon className="h-2.5 w-2.5 shrink-0" strokeWidth={3} />
            <span className="truncate">{chipText}</span>
          </span>
        </div>
        <p className="mt-2.5 text-[23px] font-bold leading-tight">{t("quiz.title")}</p>
        <p className="mt-1 text-[13px] opacity-80">{t("students.quiz.sub")}</p>
        <p className="mt-3 flex items-center gap-1.5 text-sm font-semibold">
          {t("students.quiz.cta")}
          <ArrowRight className="h-3 w-3" strokeWidth={2.5} />
        </p>
        <ScalesGlyph className="pointer-events-none absolute -bottom-1 right-2.5 h-[92px] w-[92px] text-on-brand opacity-[0.16]" strokeWidth={3} />
      </Link>

      {resourceKinds.map((kind) => (
        <section key={kind} className="mt-[26px]">
          <Overline text={L.documentKindTitle(kind, language)} />
          <p className="mb-2.5 text-xs text-slate">{L.documentKindBlurb(kind, language)}</p>
          <div className="overflow-hidden rounded-[14px] border border-hairline bg-surface">
            {DocumentCatalog.documentsOf(kind).map((document, index) => (
              <div key={document.id}>
                {index > 0 ? <Hairline className="ml-[62px] w-auto" /> : null}
                <Link to={`/documents/${document.id}`} className="press block">
                  <DocumentRow document={document} isDownloaded={user.isDownloaded(document.id)} />
                </Link>
              </div>
            ))}
          </div>
        </section>
      ))}

      <section className="mt-[26px]">
        <Overline text={t("students.tools")} className="mb-2.5" />
        <div className="flex gap-2">
          <ToolChip to="/definitions" icon={BookA} title={t("account.definitions")} />
          <ToolChip to="/cases" icon={Quote} title={t("account.caseLaws")} />
          <ToolChip to="/ipc-bns" icon={ArrowLeftRight} title="IPC → BNS" />
        </div>
      </section>

      <section className="mt-7">
        <Overline text={t("students.coming")} className="mb-2.5" />
        <div className="overflow-hidden rounded-[14px] border border-hairline bg-surface">
          <ComingRow icon={<BookMarked className="h-3.5 w-3.5" strokeWidth={2.2} />} titleKey="students.courses" subKey="students.courses.sub" index={0} />
          <Hairline className="ml-[62px] w-auto" />
          <ComingRow icon={<Medal className="h-3.5 w-3.5" strokeWidth={2.2} />} titleKey="students.competitions" subKey="students.competitions.sub" index={2} />
          <Hairline className="ml-[62px] w-auto" />
          <ComingRow icon={<Users className="h-3.5 w-3.5" strokeWidth={2.2} />} titleKey="students.moot" subKey="students.moot.sub" index={5} />
        </div>
      </section>

      <TrustFootnote className="py-7" />
    </Screen>
  );
}

function ComingRow({ icon, titleKey, subKey, index }: { icon: React.ReactNode; titleKey: string; subKey: string; index: number }) {
  const { t } = useLex();
  return (
    <div className="flex items-center gap-3 px-3 py-[11px]">
      <IconTile index={index} size={38} radius={11}>
        {icon}
      </IconTile>
      <div className="min-w-0 flex-1">
        <p className="text-[15px] font-medium text-ink">{t(titleKey)}</p>
        <p className="text-xs text-slate">{t(subKey)}</p>
      </div>
      <span className="shrink-0 rounded-full border border-hairline bg-canvas px-2 py-1 text-[10px] font-semibold text-slate">{t("common.comingSoon")}</span>
    </div>
  );
}
