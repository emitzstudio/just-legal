/** A real-life situation as a discovery path into the legal dataset; and the popular-topic screen. */

import { CircleHelp } from "lucide-react";
import { Link, useParams } from "react-router-dom";

import { symbolIcon } from "@/components/lex/icons";
import { BenchDivider, EmptyState, Hairline, Overline, SectionRow } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { actDisplayShortName } from "@/lib/models";
import { useLex } from "@/stores/useLex";

export function SituationScreen() {
  const { id = "" } = useParams();
  const { t, language } = useLex();
  const situation = legalData.situation(id);

  if (!situation) {
    return (
      <Screen>
        <NavBar fallback="/library" />
        <EmptyState icon={<CircleHelp className="h-6 w-6" />} title={t("act.notFound.title")} message={t("situation.notFound")} />
      </Screen>
    );
  }

  const Icon = symbolIcon(situation.symbol);
  const definitions = situation.definitionIds.map((definitionId) => legalData.definition(definitionId)).filter(Boolean);

  return (
    <Screen>
      <NavBar fallback="/library" />
      <div className="pt-2">
        <span className="flex h-12 w-12 items-center justify-center rounded-[14px] bg-saffron-soft text-saffron-deep">
          <Icon className="h-5 w-5" strokeWidth={2.2} />
        </span>
        <h1 className="mt-2.5 text-[30px] font-bold leading-tight text-ink">{L.situationTitle(situation, language)}</h1>
        <p className="mt-2.5 text-[15px] leading-relaxed text-slate">{situation.intro}</p>
      </div>
      <BenchDivider className="my-[22px]" />
      <Overline text={t("situation.relevant")} />
      <div>
        {situation.sectionIds.map((sectionId, index) => {
          const section = legalData.section(sectionId);
          if (!section) return null;
          return (
            <div key={sectionId}>
              {index > 0 ? <Hairline /> : null}
              <Link to={`/read/${section.actId}/${section.id}`} className="press block">
                <SectionRow number={section.number} title={section.title} subtitle={legalData.act(section.actId) ? actDisplayShortName(legalData.act(section.actId)!) : null} />
              </Link>
            </div>
          );
        })}
      </div>
      {definitions.length ? (
        <div className="mt-[26px]">
          <Overline text={t("situation.terms")} />
          {definitions.map((definition, index) =>
            definition ? (
              <div key={definition.id}>
                {index > 0 ? <Hairline /> : null}
                <div className="py-3">
                  <p className="text-base font-semibold text-ink">{definition.term}</p>
                  <p className="mt-1 text-sm leading-relaxed text-slate">{definition.meaning}</p>
                </div>
              </div>
            ) : null,
          )}
        </div>
      ) : null}
      <p className="pb-6 pt-6 text-xs text-slate">{t("situation.note")}</p>
    </Screen>
  );
}

export function TopicScreen() {
  const { id = "" } = useParams();
  const { t, language } = useLex();
  const topic = legalData.topic(id);

  if (!topic) {
    return (
      <Screen>
        <NavBar fallback="/library" />
        <EmptyState icon={<CircleHelp className="h-6 w-6" />} title={t("act.notFound.title")} message={t("topic.notFound")} />
      </Screen>
    );
  }

  return (
    <Screen>
      <NavBar fallback="/library" />
      <h1 className="pt-2 text-[30px] font-bold leading-tight text-ink">{L.topicName(topic, language)}</h1>
      <p className="mt-1 text-sm text-slate">{t("situation.provisions")}</p>
      <BenchDivider className="my-5" />
      <div className="pb-6">
        {topic.sectionIds.map((sectionId, index) => {
          const section = legalData.section(sectionId);
          if (!section) return null;
          return (
            <div key={sectionId}>
              {index > 0 ? <Hairline /> : null}
              <Link to={`/read/${section.actId}/${section.id}`} className="press block">
                <SectionRow number={section.number} title={section.title} subtitle={legalData.act(section.actId) ? actDisplayShortName(legalData.act(section.actId)!) : null} />
              </Link>
            </div>
          );
        })}
      </div>
    </Screen>
  );
}
