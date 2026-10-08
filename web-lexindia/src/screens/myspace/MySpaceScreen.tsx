/**
 * The user's personal area — "everything that belongs to me": continue
 * reading, legal categories, recents, saved sections and notes,
 * downloads, membership status and the quiz shortcut.
 */

import {
  ArrowLeftRight,
  ArrowRight,
  BookA,
  Bookmark,
  ChevronRight,
  Download,
  FileCheck2,
  GraduationCap,
  Hourglass,
  Award,
  Quote,
  Search,
  type LucideIcon,
} from "lucide-react";
import { Link } from "react-router-dom";

import { documentKindIcon, symbolIcon } from "@/components/lex/icons";
import { AccentDiamond, Hairline, IconTile, Overline, SectionRow, TrustFootnote } from "@/components/lex/primitives";
import { Screen } from "@/components/shell/Screen";
import { DocumentCatalog, legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { actDisplayShortName, type LegalSection } from "@/lib/models";
import { remainingLabel, useAccess } from "@/stores/accessStore";
import { useUI } from "@/stores/uiStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { TopicChips } from "../library/LibraryScreen";

const greetingKey = (): string => {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 12) return "greeting.morning";
  if (hour >= 12 && hour < 17) return "greeting.afternoon";
  return "greeting.evening";
};

export function MySpaceScreen() {
  const { t, f, language } = useLex();
  const user = useUser();
  const access = useAccess();
  const ui = useUI();
  const { core } = legalData;

  const membershipTitle = access.subscriptionInfo
    ? `${L.planDuration(access.subscriptionInfo.plan.months, language)} ${t("plan.suffix")}`
    : access.isOnTrial
      ? t("myspace.trial")
      : access.isDevAccess
        ? t("account.testAccess")
        : t("account.noPlan");
  const membershipSub = access.subscriptionInfo
    ? f("myspace.until", L.date(access.subscriptionInfo.end, language))
    : access.isOnTrial && access.trialRemaining !== null
      ? `${t("myspace.trial.endsIn")} ${L.remaining(access.trialRemaining, language)}`
      : access.isDevAccess
        ? t("account.devOnly")
        : t("myspace.seePlans");

  const recent = user.recents[0] ? legalData.section(user.recents[0].sectionId) : undefined;
  const starter = recent ?? legalData.section("bns-318");

  return (
    <Screen>
      <div className="mt-3.5 rounded-[22px] bg-brand p-[18px] text-on-brand">
        <div className="flex items-center justify-between">
          <Overline text={t(greetingKey())} color="color-mix(in srgb, var(--on-brand) 62%, transparent)" />
          <AccentDiamond size={7} color="var(--on-brand)" />
        </div>
        <h1 className="mt-1.5 text-[30px] font-bold leading-tight">{user.profileName}</h1>
        <p className="mt-1 text-sm opacity-80">{t("myspace.tagline")}</p>
        <button
          type="button"
          onClick={ui.activateSearch}
          className="press mt-4 flex w-full items-center gap-2.5 rounded-[13px] bg-surface px-4 py-[13px] text-left text-base text-slate"
          aria-label="Search laws, sections, terms"
        >
          <Search className="h-4 w-4" strokeWidth={2.4} />
          <span>{t("myspace.searchPlaceholder")}</span>
        </button>
      </div>

      {access.isOnTrial ? (
        <button
          type="button"
          onClick={() => ui.setPlansPresented(true)}
          className="press mt-3 flex w-full items-center gap-3 rounded-[14px] bg-saffron-soft px-3.5 py-[11px] text-left"
        >
          <Hourglass className="h-4 w-4 shrink-0 text-saffron-deep" />
          <span className="min-w-0 flex-1">
            <span className="block text-sm font-semibold text-ink">{t("myspace.trial")}</span>
            {access.trialRemaining !== null ? (
              <span className="block text-xs text-slate">
                {t("myspace.trial.endsIn")} {remainingLabel(access.trialRemaining)}
              </span>
            ) : null}
          </span>
          <span className="text-[13px] font-semibold text-brand">{t("myspace.seePlans")}</span>
          <ChevronRight className="h-3 w-3 text-brand" strokeWidth={2.5} />
        </button>
      ) : null}

      <div className="mt-3 grid grid-cols-2 gap-3">
        <StatusCard
          overline={t("myspace.membership")}
          icon={Award}
          pastelIndex={0}
          title={membershipTitle}
          sub={membershipSub}
          onClick={() => ui.setPlansPresented(true)}
        />
        <StatusCard
          overline={t("myspace.quiz.title")}
          icon={FileCheck2}
          pastelIndex={3}
          title={t("students.quizzes")}
          sub={t(user.isWeeklyQuizRewardAvailable ? "myspace.quiz.available" : "myspace.quiz.claimed")}
          onClick={ui.openQuizzes}
        />
      </div>

      <section className="mt-[26px]">
        <Overline text={t("myspace.studyTools")} className="mb-2.5" />
        <div className="grid grid-cols-2 gap-3">
          <StudyToolTile to="/definitions" icon={BookA} pastelIndex={1} title={t("account.definitions")} subtitle={t("myspace.tool.defs")} />
          <StudyToolTile to="/cases" icon={Quote} pastelIndex={3} title={t("account.caseLaws")} subtitle={t("myspace.tool.cases")} />
          <StudyToolTile to="/ipc-bns" icon={ArrowLeftRight} pastelIndex={5} title="IPC → BNS" subtitle={t("myspace.tool.ipc")} />
          <StudyToolTile to="/study" icon={GraduationCap} pastelIndex={2} title={t("library.study")} subtitle={t("myspace.tool.study")} />
        </div>
      </section>

      <section className="mt-[26px]">
        <Overline text={t("myspace.categories")} />
        <p className="mb-2.5 text-xs text-slate">{t("myspace.categories.sub")}</p>
        <div className="grid grid-cols-2 gap-3">
          {core.categories.map((category, index) => (
            <Link
              key={category.id}
              to={`/category/${category.id}`}
              className="press flex items-center gap-2.5 rounded-[14px] border border-hairline bg-surface p-3"
            >
              <IconTile index={index} size={34} radius={10}>
                <span className="text-[15px] font-bold">{category.name.slice(0, 1)}</span>
              </IconTile>
              <span className="min-w-0">
                <span className="block truncate text-sm font-semibold text-ink">{L.categoryName(category, language)}</span>
                <span className="block truncate text-[11px] text-slate">{L.categoryTagline(category, language)}</span>
              </span>
            </Link>
          ))}
        </div>
      </section>

      <section className="mt-[26px]">
        <div className="mb-2.5 flex items-center justify-between">
          <Overline text={t("myspace.browseCodes")} />
          <button type="button" onClick={() => ui.openTab("library")} className="text-[13px] font-medium text-brand" aria-label="All laws, opens the Law Library">
            {t("myspace.allLaws")}
          </button>
        </div>
        <div className="-mx-[22px] flex gap-2 overflow-x-auto px-[22px] no-scrollbar lg:-mx-8 lg:px-8">
          {legalData.orderedActs().map((act) => (
            <Link
              key={act.id}
              to={`/act/${act.id}`}
              className="press shrink-0 rounded-full border border-hairline bg-surface px-[15px] py-[9px] text-sm font-semibold text-ink"
              aria-label={L.actName(act, language)}
            >
              {actDisplayShortName(act)}
            </Link>
          ))}
        </div>
      </section>

      {starter ? (
        <ContinueCard
          overline={t(recent ? "myspace.continueReading" : "myspace.startClassic")}
          section={starter}
          subtitle={legalData.act(starter.actId) ? L.actName(legalData.act(starter.actId)!, language) : ""}
        />
      ) : null}

      <section className="mt-7">
        <Overline text={t("myspace.situations")} className="mb-1" />
        {core.situations.map((situation, index) => {
          const Icon = symbolIcon(situation.symbol);
          return (
            <div key={situation.id}>
              {index > 0 ? <Hairline /> : null}
              <Link to={`/situation/${situation.id}`} className="press flex items-center gap-3.5 py-[13px]">
                <IconTile index={index}>
                  <Icon className="h-4 w-4" strokeWidth={2.2} />
                </IconTile>
                <span className="min-w-0 flex-1">
                  <span className="block text-[17px] font-semibold text-ink">{L.situationTitle(situation, language)}</span>
                  <span className="mt-0.5 line-clamp-2 block text-[13px] text-slate">{L.situationBlurb(situation, language)}</span>
                </span>
                <ChevronRight className="h-3.5 w-3.5 shrink-0 text-faint" strokeWidth={2.5} />
              </Link>
            </div>
          );
        })}
      </section>

      <section className="mt-7">
        <Overline text={t("myspace.topics")} className="mb-3" />
        <TopicChips />
      </section>

      {user.recents.length > 0 ? (
        <section className="mt-7">
          <BlockHeader title={t("myspace.recents")} to="/recents" />
          {user.recents.slice(0, 3).map((item, index) => {
            const section = legalData.section(item.sectionId);
            if (!section) return null;
            return (
              <div key={item.sectionId}>
                {index > 0 ? <Hairline /> : null}
                <Link to={`/read/${section.actId}/${section.id}`} className="press block">
                  <SectionRow number={section.number} title={section.title} subtitle={legalData.act(section.actId) ? actDisplayShortName(legalData.act(section.actId)!) : null} />
                </Link>
              </div>
            );
          })}
        </section>
      ) : null}

      <section className="mt-7">
        <BlockHeader title={t("myspace.saved")} to="/notes" />
        {user.saved.length === 0 ? (
          <HintRow icon={Bookmark} text={t("myspace.hint.saved")} />
        ) : (
          user.saved.slice(0, 3).map((item, index) => {
            const section = legalData.section(item.sectionId);
            if (!section) return null;
            return (
              <div key={item.sectionId}>
                {index > 0 ? <Hairline /> : null}
                <Link to={`/read/${section.actId}/${section.id}`} className="press block">
                  <SectionRow
                    number={section.number}
                    title={section.title}
                    subtitle={item.note || (legalData.act(section.actId) ? actDisplayShortName(legalData.act(section.actId)!) : null)}
                  />
                </Link>
              </div>
            );
          })
        )}
      </section>

      <section className="mt-7">
        <BlockHeader title={t("myspace.downloads")} to="/downloads" />
        {user.downloads.length === 0 ? (
          <Link to="/documents" className="press block">
            <HintRow icon={Download} text={t("myspace.hint.downloads")} />
          </Link>
        ) : (
          user.downloads.slice(0, 3).map((record, index) => {
            const document = DocumentCatalog.document(record.documentId);
            if (!document) return null;
            const Icon = documentKindIcon[document.kind];
            return (
              <div key={record.documentId}>
                {index > 0 ? <Hairline /> : null}
                <Link to={`/documents/${document.id}`} className="press flex items-center gap-3 py-2.5">
                  <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[11px] bg-brand-soft text-brand">
                    <Icon className="h-3.5 w-3.5" strokeWidth={2.2} />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-[15px] font-medium text-ink">{L.docTitle(document, language)}</span>
                    <span className="block text-xs text-slate">
                      {L.documentKindTitle(document.kind, language)} · {L.date(record.date, language)}
                    </span>
                  </span>
                  <ChevronRight className="h-3.5 w-3.5 shrink-0 text-faint" strokeWidth={2.5} />
                </Link>
              </div>
            );
          })
        )}
      </section>

      <TrustFootnote className="pb-5 pt-8" />
    </Screen>
  );
}

function StatusCard({
  overline,
  icon: Icon,
  pastelIndex,
  title,
  sub,
  onClick,
}: {
  overline: string;
  icon: LucideIcon;
  pastelIndex: number;
  title: string;
  sub: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="press flex flex-col gap-2 rounded-2xl border border-hairline bg-surface p-3.5 text-left"
      aria-label={`${overline}: ${title}. ${sub}`}
    >
      <div className="flex items-center justify-between">
        <IconTile index={pastelIndex} size={30} radius={9}>
          <Icon className="h-3.5 w-3.5" strokeWidth={2.2} />
        </IconTile>
        <ChevronRight className="h-3 w-3 text-faint" strokeWidth={2.5} />
      </div>
      <span className="truncate text-[19px] font-bold tabular text-ink">{title}</span>
      <span>
        <Overline text={overline} />
        <span className="block truncate text-xs text-slate">{sub}</span>
      </span>
    </button>
  );
}

function StudyToolTile({
  to,
  icon: Icon,
  pastelIndex,
  title,
  subtitle,
}: {
  to: string;
  icon: LucideIcon;
  pastelIndex: number;
  title: string;
  subtitle: string;
}) {
  return (
    <Link to={to} className="press flex flex-col gap-2.5 rounded-2xl border border-hairline bg-surface p-[13px]">
      <div className="flex items-start justify-between">
        <IconTile index={pastelIndex} size={34} radius={10}>
          <Icon className="h-3.5 w-3.5" strokeWidth={2.2} />
        </IconTile>
        <ChevronRight className="h-3 w-3 text-faint" strokeWidth={2.5} />
      </div>
      <span>
        <span className="block truncate text-base font-semibold text-ink">{title}</span>
        <span className="block truncate text-[11px] text-slate">{subtitle}</span>
      </span>
    </Link>
  );
}

function ContinueCard({ overline, section, subtitle }: { overline: string; section: LegalSection; subtitle: string }) {
  return (
    <Link to={`/read/${section.actId}/${section.id}`} className="press mt-[26px] block rounded-2xl border border-hairline bg-surface p-4">
      <Overline text={overline} />
      <div className="mt-2.5 flex items-baseline gap-3.5">
        <span className="text-[28px] font-bold tabular text-brand">{section.number}</span>
        <span className="min-w-0 flex-1">
          <span className="line-clamp-2 block text-lg font-semibold leading-snug text-ink">{section.title}</span>
          <span className="mt-0.5 block text-[13px] text-slate">{subtitle}</span>
        </span>
        <ArrowRight className="h-4 w-4 shrink-0 self-center text-brand" strokeWidth={2.5} />
      </div>
    </Link>
  );
}

function BlockHeader({ title, to }: { title: string; to: string }) {
  const { t } = useLex();
  return (
    <div className="mb-1 flex items-center justify-between">
      <Overline text={title} />
      <Link to={to} className="text-[13px] font-medium text-brand">
        {t("common.seeAll")}
      </Link>
    </div>
  );
}

function HintRow({ icon: Icon, text }: { icon: LucideIcon; text: string }) {
  return (
    <div className="flex items-center gap-3 py-2">
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[11px] bg-surface text-slate">
        <Icon className="h-4 w-4" strokeWidth={2.2} />
      </span>
      <span className="text-[13px] leading-relaxed text-slate">{text}</span>
    </div>
  );
}
