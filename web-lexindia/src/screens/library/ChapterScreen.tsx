/** Chapter → its sections, highly scannable. */

import { BookMarked } from "lucide-react";
import { Link, useParams } from "react-router-dom";

import { BenchDivider, EmptyState, Hairline, Overline, SectionRow } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { sectionHasGuide } from "@/lib/models";
import { useLex } from "@/stores/useLex";

export function ChapterScreen() {
  const { id = "" } = useParams();
  const { t, f, language } = useLex();
  const chapter = legalData.chapter(id);
  const actId = legalData.actIdForChapter(id);
  const act = actId ? legalData.act(actId) : undefined;

  if (!chapter || !actId || !act) {
    return (
      <Screen>
        <NavBar fallback="/library" />
        <EmptyState icon={<BookMarked className="h-6 w-6" />} title={t("act.notFound.title")} message={t("chapter.notFound")} />
      </Screen>
    );
  }

  const sections = legalData.sectionsInChapter(id);
  const guides = sections.filter(sectionHasGuide).length;

  return (
    <Screen>
      <NavBar title={`${t("reader.chapter")} ${chapter.numeral}`} fallback={`/act/${actId}`} />
      <div className="pt-2">
        <Overline text={`${t("reader.chapter")} ${chapter.numeral}`} color="var(--saffron-deep)" />
        <h1 className="mt-1.5 text-[25px] font-bold leading-tight text-ink">{L.chapterTitle(chapter.numeral, chapter.title, actId, language)}</h1>
        <p className="mt-1.5 text-[13px] text-slate">
          {L.actName(act, language)} · {chapter.rangeLabel}
        </p>
      </div>
      <BenchDivider className="my-[18px]" />
      <div>
        {sections.map((section, index) => (
          <div key={section.id}>
            {index > 0 ? <Hairline /> : null}
            <Link to={`/read/${actId}/${section.id}`} className="press block">
              <SectionRow
                number={section.number}
                title={section.title}
                subtitle={section.ipcLabel ? `${t("understand.earlier")} ${section.ipcLabel}` : null}
                showsGuideBadge={sectionHasGuide(section)}
              />
            </Link>
          </div>
        ))}
      </div>
      <p className="pb-6 pt-5 text-xs italic text-slate">
        {guides > 0 ? f("chapter.foot.some", sections.length, guides) : f("chapter.foot.none", sections.length)}
      </p>
    </Screen>
  );
}
