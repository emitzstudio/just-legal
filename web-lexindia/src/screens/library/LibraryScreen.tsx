/**
 * The Law Library — the main content and discovery hub: Laws & Acts,
 * Study material, Legal Updates, Documents, areas of law, real-life
 * situations and popular topics.
 */

import { ArrowLeftRight, BookA, ChevronRight, FileText, GraduationCap, Quote, type LucideIcon } from "lucide-react";
import { type ReactNode } from "react";
import { Link } from "react-router-dom";

import { symbolIcon } from "@/components/lex/icons";
import { Hairline, HubHeader, IconTile, Overline, TrustFootnote, pastel } from "@/components/lex/primitives";
import { Screen } from "@/components/shell/Screen";
import { LegalUpdatesCatalog, legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { actDisplayShortName, sectionHasGuide, type LegalAct, type LegalUpdate } from "@/lib/models";
import { useLex } from "@/stores/useLex";

export function LibraryScreen() {
  const { t, language } = useLex();
  const { core } = legalData;
  const acts = legalData.orderedActs();

  return (
    <Screen>
      <HubHeader title={t("library.title")} subtitle={t("library.subtitle")} />

      <Overline text={t("library.lawsActs")} className="mt-5" />
      <div className="mt-2.5 grid grid-cols-2 gap-3">
        {acts.map((act, index) => (
          <LawTile key={act.id} act={act} index={index} />
        ))}
      </div>

      <Link to="/ipc-bns" className="press mt-3 flex items-center gap-3.5 rounded-2xl bg-brand-soft p-3.5" aria-label="IPC to BNS converter">
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-on-brand text-brand">
          <ArrowLeftRight className="h-4 w-4" strokeWidth={2.5} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-[17px] font-semibold text-brand">IPC → BNS</span>
          <span className="block text-xs text-slate">{t("library.ipc.sub")}</span>
        </span>
        <ChevronRight className="h-3.5 w-3.5 shrink-0 text-brand" strokeWidth={2.5} />
      </Link>

      <section className="mt-7">
        <Overline text={t("library.study")} className="mb-3" />
        <WideCard
          to="/study"
          pastelIndex={2}
          icon={GraduationCap}
          title={t("library.student.title")}
          subtitle={t("library.student.sub")}
          footnote={t("library.student.foot")}
        />
        <div className="mt-3 flex gap-2">
          <ToolChip to="/definitions" icon={BookA} title={t("account.definitions")} />
          <ToolChip to="/cases" icon={Quote} title={t("account.caseLaws")} />
        </div>
      </section>

      <section className="mt-7">
        <div className="mb-2.5 flex items-center justify-between">
          <Overline text={t("library.updates")} />
          <Link to="/updates" className="text-[13px] font-medium text-brand">
            {t("library.allUpdates")}
          </Link>
        </div>
        <div className="flex flex-col gap-2.5">
          {LegalUpdatesCatalog.updates.slice(0, 2).map((update) => (
            <UpdatePreviewCard key={update.id} update={update} />
          ))}
        </div>
      </section>

      <section className="mt-7">
        <Overline text={t("library.documents")} className="mb-3" />
        <WideCard
          to="/documents"
          pastelIndex={7}
          icon={FileText}
          title={t("library.documentsForms")}
          subtitle={t("library.documents.sub")}
          footnote={t("library.documents.foot")}
        />
      </section>

      <section className="mt-7">
        <Overline text={t("library.browseArea")} className="mb-3" />
        <div className="-mx-[22px] flex gap-2 overflow-x-auto px-[22px] no-scrollbar lg:-mx-8 lg:px-8">
          {core.categories.map((category, index) => (
            <Link
              key={category.id}
              to={`/category/${category.id}`}
              className="press shrink-0 rounded-full px-[13px] py-2 text-sm font-medium"
              style={{ backgroundColor: pastel(index).fill, color: pastel(index).tone }}
            >
              {L.categoryName(category, language)}
            </Link>
          ))}
        </div>
      </section>

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
        <Overline text={t("library.topics")} className="mb-3" />
        <TopicChips />
      </section>

      <TrustFootnote className="py-7" />
    </Screen>
  );
}

function LawTile({ act, index }: { act: LegalAct; index: number }) {
  const { t, language } = useLex();
  const loaded = legalData.sectionsInAct(act.id);
  const guided = loaded.filter(sectionHasGuide).length;
  const colors = pastel(index);
  const shortName = actDisplayShortName(act);
  const statusLine =
    loaded.length > 0
      ? act.id === "bns"
        ? `${t("library.badge.fulltext")} · ${loaded.length} §§ · ${t("library.badge.ipcmap")}`
        : guided > 0
          ? `${guided} ${t("library.badge.guided")}`
          : `${loaded.length} ${t("library.badge.sections")}`
      : t("prepared.badge");

  return (
    <Link
      to={`/act/${act.id}`}
      className="press flex flex-col rounded-2xl p-3.5"
      style={{ backgroundColor: colors.fill, color: colors.tone }}
      aria-label={`${L.actName(act, language)}. ${loaded.length ? `${loaded.length} ${t("library.badge.sections")}` : t("prepared.title")}`}
    >
      <div className="flex items-start justify-between">
        <span className="flex h-9 w-9 items-center justify-center rounded-[11px] bg-frost-a text-base font-bold">{shortName.slice(0, 1)}</span>
        <ChevronRight className="h-3.5 w-3.5 opacity-55" strokeWidth={2.5} />
      </div>
      <span className="mt-3 truncate text-[19px] font-bold leading-tight">{shortName}</span>
      <span className="mt-0.5 line-clamp-2 min-h-[2rem] text-xs leading-4 opacity-80">{L.actName(act, language)}</span>
      <span className={`mt-2 self-start truncate rounded-full px-2 py-1 text-[11px] font-semibold ${loaded.length ? "bg-frost-b" : "bg-frost-c opacity-85"}`}>
        {statusLine}
      </span>
    </Link>
  );
}

function WideCard({
  to,
  pastelIndex,
  icon: Icon,
  title,
  subtitle,
  footnote,
}: {
  to: string;
  pastelIndex: number;
  icon: LucideIcon;
  title: string;
  subtitle: string;
  footnote: string;
}) {
  const colors = pastel(pastelIndex);
  return (
    <Link to={to} className="press block rounded-2xl p-3.5" style={{ backgroundColor: colors.fill, color: colors.tone }}>
      <div className="flex items-center gap-3.5">
        <span className="flex h-[42px] w-[42px] shrink-0 items-center justify-center rounded-xl bg-frost-a">
          <Icon className="h-[17px] w-[17px]" strokeWidth={2.2} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-lg font-bold leading-tight">{title}</span>
          <span className="block text-xs font-medium opacity-80">{subtitle}</span>
        </span>
        <ChevronRight className="h-3.5 w-3.5 shrink-0 opacity-60" strokeWidth={2.5} />
      </div>
      <span className="mt-3 inline-block rounded-full bg-frost-b px-2 py-1 text-[11px] font-semibold">{footnote}</span>
    </Link>
  );
}

export function ToolChip({ to, icon: Icon, title }: { to: string; icon: LucideIcon; title: string }) {
  return (
    <Link
      to={to}
      className="press flex flex-1 items-center justify-center gap-1.5 rounded-full bg-brand-soft py-2.5 text-[13px] font-semibold text-brand"
    >
      <Icon className="h-3 w-3 shrink-0" strokeWidth={2.4} />
      <span className="truncate">{title}</span>
    </Link>
  );
}

export function TopicChips() {
  const { language } = useLex();
  return (
    <div className="flex flex-wrap gap-2">
      {legalData.core.topics.map((topic) => (
        <Link
          key={topic.id}
          to={`/topic/${topic.id}`}
          className="press rounded-full bg-brand-soft px-[13px] py-2 text-sm font-medium text-brand"
        >
          {L.topicName(topic, language)}
        </Link>
      ))}
    </div>
  );
}

export function UpdateCategoryChip({ update, children }: { update: LegalUpdate; children?: ReactNode }) {
  const { language } = useLex();
  const colors = pastel(["supreme-court", "high-court", "judgment", "new-law", "amendment", "notification"].indexOf(update.category));
  return (
    <span
      className="inline-flex items-center gap-1.5 rounded-full px-2 py-1 text-[11px] font-semibold"
      style={{ backgroundColor: colors.fill, color: colors.tone }}
    >
      {children}
      {L.updateCategoryLabel(update.category, language)}
    </span>
  );
}

function UpdatePreviewCard({ update }: { update: LegalUpdate }) {
  const { language } = useLex();
  return (
    <Link to={`/updates/${update.id}`} className="press block rounded-2xl border border-hairline bg-surface p-3.5">
      <div className="flex items-center justify-between">
        <UpdateCategoryChip update={update} />
        <span className="text-xs text-slate">{L.updateDate(update, language)}</span>
      </div>
      <p className="mt-2 line-clamp-2 text-base font-semibold leading-snug text-ink">{L.updateTitle(update, language)}</p>
      <p className="mt-1 line-clamp-2 text-[13px] leading-snug text-slate">{L.updateSnippet(update, language)}</p>
    </Link>
  );
}
