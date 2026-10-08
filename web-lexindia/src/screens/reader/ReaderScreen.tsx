/**
 * The signature reading environment: horizontal swipe between sections,
 * visible previous/next controls, and the Understand More sheet.
 */

import { ArrowRight, Bookmark, ChevronLeft, ChevronRight, ChevronUp } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";

import { AccentDiamond, BenchDivider, EmptyState, Hairline, Overline, PreparedPanel, ReadAloudControl } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { actDisplayShortName, sectionHasGuide, sectionHasOfficialText, type LegalSection } from "@/lib/models";
import { cn } from "@/lib/utils";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { UnderstandMoreSheet } from "./UnderstandMoreSheet";

export function ReaderScreen() {
  const { actId = "", sectionId = "" } = useParams();
  const navigate = useNavigate();
  const { t } = useLex();
  const user = useUser();
  const sections = legalData.sectionsInAct(actId);
  const act = legalData.act(actId);
  const [currentId, setCurrentId] = useState<string>(sectionId);
  const [showUnderstand, setShowUnderstand] = useState<boolean>(false);
  const [toast, setToast] = useState<string | null>(null);
  const toastTimer = useRef<number | null>(null);
  const touchStart = useRef<{ x: number; y: number } | null>(null);

  useEffect(() => {
    setCurrentId(sectionId);
  }, [sectionId]);

  const current = legalData.section(currentId);

  useEffect(() => {
    if (current) user.recordVisit(current.id);
    window.scrollTo({ top: 0 });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentId]);

  const navigateTo = useCallback(
    (targetId: string) => {
      const target = legalData.section(targetId);
      if (!target) return;
      if (target.actId === actId) {
        setCurrentId(targetId);
        navigate(`/read/${actId}/${targetId}`, { replace: true });
      } else {
        navigate(`/read/${target.actId}/${target.id}`);
      }
    },
    [actId, navigate],
  );

  const neighbors = current ? legalData.neighbors(current) : { previous: null, next: null };

  const showToast = (text: string) => {
    setToast(text);
    if (toastTimer.current) window.clearTimeout(toastTimer.current);
    toastTimer.current = window.setTimeout(() => setToast(null), 1600);
  };

  const toggleSave = () => {
    if (!current) return;
    const saved = user.toggleSaved(current.id);
    showToast(saved ? "Saved to My Notes" : "Removed from My Notes");
  };

  // Horizontal swipe between sections (touch), mirroring the page TabView.
  const onTouchStart = (event: React.TouchEvent) => {
    const touch = event.touches[0];
    touchStart.current = { x: touch.clientX, y: touch.clientY };
  };
  const onTouchEnd = (event: React.TouchEvent) => {
    if (!touchStart.current) return;
    const touch = event.changedTouches[0];
    const dx = touch.clientX - touchStart.current.x;
    const dy = touch.clientY - touchStart.current.y;
    touchStart.current = null;
    if (Math.abs(dx) < 64 || Math.abs(dy) > Math.abs(dx) * 0.8) return;
    if (dx < 0 && neighbors.next) navigateTo(neighbors.next.id);
    if (dx > 0 && neighbors.previous) navigateTo(neighbors.previous.id);
  };

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if (showUnderstand) return;
      if (event.key === "ArrowRight" && neighbors.next) navigateTo(neighbors.next.id);
      if (event.key === "ArrowLeft" && neighbors.previous) navigateTo(neighbors.previous.id);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [neighbors.next, neighbors.previous, navigateTo, showUnderstand]);

  if (!current || !act) {
    return (
      <Screen>
        <NavBar fallback="/library" />
        <EmptyState icon={<Bookmark className="h-6 w-6" />} title={t("act.notFound.title")} message={t("act.notFound.act")} />
      </Screen>
    );
  }

  return (
    <div onTouchStart={onTouchStart} onTouchEnd={onTouchEnd} className="min-h-screen">
      <Screen className="pb-36 lg:pb-32">
        <NavBar
          title={actDisplayShortName(act)}
          fallback={`/act/${actId}`}
          trailing={
            <>
              <button
                type="button"
                disabled={!neighbors.previous}
                onClick={() => neighbors.previous && navigateTo(neighbors.previous.id)}
                aria-label={neighbors.previous ? `Previous, Section ${neighbors.previous.number}` : "No previous section"}
                className="press flex h-9 w-9 items-center justify-center rounded-full text-brand disabled:opacity-30"
              >
                <ChevronLeft className="h-5 w-5" strokeWidth={2.5} />
              </button>
              <button
                type="button"
                disabled={!neighbors.next}
                onClick={() => neighbors.next && navigateTo(neighbors.next.id)}
                aria-label={neighbors.next ? `Next, Section ${neighbors.next.number}` : "No next section"}
                className="press flex h-9 w-9 items-center justify-center rounded-full text-brand disabled:opacity-30"
              >
                <ChevronRight className="h-5 w-5" strokeWidth={2.5} />
              </button>
            </>
          }
        />
        <SectionPage key={current.id} section={current} onNavigate={navigateTo} onToggleSave={toggleSave} />
        <span className="sr-only">{sections.length} sections in this Act</span>
      </Screen>

      <UnderstandMoreBar section={current} onOpen={() => setShowUnderstand(true)} />

      {showUnderstand ? (
        <UnderstandMoreSheet
          section={current}
          onClose={() => setShowUnderstand(false)}
          onOpenSection={(targetId) => {
            setShowUnderstand(false);
            window.setTimeout(() => navigateTo(targetId), 200);
          }}
        />
      ) : null}

      {toast ? (
        <div className="pointer-events-none fixed inset-x-0 top-14 z-50 flex justify-center anim-rise" role="status">
          <span className="rounded-full border border-hairline bg-surface px-4 py-2 text-[13px] font-medium text-ink shadow-lg">{toast}</span>
        </div>
      ) : null}
    </div>
  );
}

// MARK: - One reading page

function SectionPage({
  section,
  onNavigate,
  onToggleSave,
}: {
  section: LegalSection;
  onNavigate: (id: string) => void;
  onToggleSave: () => void;
}) {
  const { t, language } = useLex();
  const user = useUser();
  const act = legalData.act(section.actId);
  const chapter = legalData.chapter(section.chapterId);
  const neighbors = legalData.neighbors(section);
  const saved = user.isSaved(section.id);
  const hasGuide = sectionHasGuide(section);

  const ipcChip = ((): string | null => {
    if (!section.ipcLabel) return null;
    const paren = section.ipcLabel.indexOf("(");
    if (paren < 0) return section.ipcLabel;
    const trimmed = section.ipcLabel.slice(0, paren).trim();
    return trimmed || section.ipcLabel;
  })();

  const spoken = [
    `Section ${section.number}. ${section.title}.`,
    sectionHasOfficialText(section) ? section.officialText : "",
    `In simple words: ${section.explanation}`,
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <article className="anim-fade">
      <div className="flex items-center gap-2 pt-1.5">
        <Overline text={t("reader.section")} color="var(--saffron-deep)" />
        <span className="flex-1" />
        <ReadAloudControl id={section.id} text={spoken} />
        <button
          type="button"
          onClick={onToggleSave}
          aria-label={saved ? "Remove bookmark" : "Save section"}
          className={cn("press flex h-11 w-11 items-center justify-center rounded-full", saved ? "text-saffron-deep" : "text-slate")}
        >
          <Bookmark className="h-5 w-5" fill={saved ? "currentColor" : "none"} strokeWidth={2} />
        </button>
      </div>
      <div className="mt-0.5 flex flex-wrap items-center gap-3">
        <span className="font-statute text-[54px] font-bold leading-none tabular text-brand">{section.number}</span>
        {ipcChip ? (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-saffron-soft px-[11px] py-1.5 text-[13px] font-semibold tabular" aria-label={`Earlier ${ipcChip}, now ${act ? actDisplayShortName(act) : "BNS"} ${section.number}`}>
            <span className="text-saffron-deep">{ipcChip}</span>
            <ArrowRight className="h-2.5 w-2.5 text-saffron-deep opacity-70" strokeWidth={3} />
            <span className="text-brand">
              {act ? actDisplayShortName(act) : "BNS"} {section.number}
            </span>
          </span>
        ) : null}
      </div>
      <h1 className="mt-1 text-[26px] font-bold leading-tight text-ink">{section.title}</h1>
      {act ? <p className="mt-2 text-[15px] font-medium text-brand">{L.actName(act, language)}</p> : null}
      {chapter ? (
        <p className="mt-0.5 text-[13px] text-slate">{L.chapterLine(chapter.numeral, chapter.title, section.actId, language)}</p>
      ) : null}

      <BenchDivider className="my-5" />

      {sectionHasOfficialText(section) && section.officialText ? (
        <section className="rounded-2xl bg-paper p-[18px]">
          <div className="flex items-center justify-between">
            <Overline text={t("reader.official")} color="color-mix(in srgb, var(--on-paper) 55%, transparent)" />
            <AccentDiamond size={5} />
          </div>
          <p className="mt-3 whitespace-pre-line font-statute text-[17px] leading-[1.75] text-on-paper">{section.officialText}</p>
          {section.textNote ? <p className="mt-2.5 text-xs italic leading-relaxed text-on-paper/65">{section.textNote}</p> : null}
        </section>
      ) : (
        <section>
          <Overline text={t("reader.official")} className="mb-3" />
          <PreparedPanel message={section.textNote ?? "The official text of this section is being prepared for LexIndia. Refer to the official Gazette until then."} />
        </section>
      )}

      <section
        className={cn(
          "mt-6 flex overflow-hidden rounded-xl",
          hasGuide ? "bg-blue-soft" : "border border-hairline bg-surface",
        )}
      >
        <span className="w-[3px] shrink-0" style={{ backgroundColor: hasGuide ? "var(--brand)" : "color-mix(in srgb, var(--saffron) 60%, transparent)" }} />
        <div className="px-4 py-[15px]">
          <Overline text={t("reader.simple")} color={hasGuide ? "var(--brand)" : "var(--saffron-deep)"} />
          <p className={cn("mt-2 leading-[1.7]", hasGuide ? "text-base text-ink" : "text-[15px] text-slate")}>{section.explanation}</p>
        </div>
      </section>

      <div className="mt-[26px]">
        <Hairline />
        <div className="flex items-center justify-between py-2.5">
          {neighbors.previous ? (
            <button
              type="button"
              onClick={() => onNavigate(neighbors.previous!.id)}
              className="press flex items-center gap-1 py-2 text-[15px] font-semibold tabular text-brand"
              aria-label={`Previous, Section ${neighbors.previous.number}, ${neighbors.previous.title}`}
            >
              <ChevronLeft className="h-3.5 w-3.5" strokeWidth={2.5} />
              {t("reader.sAbbrev")} {neighbors.previous.number}
            </button>
          ) : (
            <span className="w-16" />
          )}
          <span className="text-[11px] text-slate">{t("reader.swipe")}</span>
          {neighbors.next ? (
            <button
              type="button"
              onClick={() => onNavigate(neighbors.next!.id)}
              className="press flex items-center gap-1 py-2 text-[15px] font-semibold tabular text-brand"
              aria-label={`Next, Section ${neighbors.next.number}, ${neighbors.next.title}`}
            >
              {t("reader.sAbbrev")} {neighbors.next.number}
              <ChevronRight className="h-3.5 w-3.5" strokeWidth={2.5} />
            </button>
          ) : (
            <span className="w-16" />
          )}
        </div>
        <Hairline />
      </div>

      <div className="mt-[22px] space-y-1.5 text-xs text-slate">
        {act ? (
          <p>
            {t("act.source")}: {L.actName(act, language)} — {L.actSource(act, language)} · {L.actEffective(act, language)}
          </p>
        ) : null}
        <p>{t("trust.footnote")}</p>
      </div>
    </article>
  );
}

/** Collapsed sheet edge: the visible "Understand more" affordance. */
function UnderstandMoreBar({ section, onOpen }: { section: LegalSection; onOpen: () => void }) {
  const { t } = useLex();
  const parts: string[] = [];
  if (section.example) parts.push(t("understand.example"));
  if (section.keyPoints.length) parts.push(t("understand.keypoints"));
  if (section.relatedSectionIds.length) parts.push(t("understand.related"));
  if (section.definitionIds.length) parts.push(t("understand.definitions"));
  parts.push(t("reader.cases"));

  return (
    <div className="fixed inset-x-0 bottom-[66px] z-30 flex justify-center px-0 lg:bottom-0 lg:pl-[232px]">
      <button
        type="button"
        onClick={onOpen}
        className="press w-full max-w-[640px] rounded-t-[20px] border border-b-0 border-hairline bg-surface px-5 pb-3 pt-2 text-left lg:max-w-[720px]"
        aria-label="Understand more"
        aria-description="Opens example, key points, related sections and case laws"
      >
        <span className="mx-auto mb-2 block h-[4.5px] w-[38px] rounded-full bg-hairline" aria-hidden="true" />
        <span className="flex items-center gap-2.5">
          <span className="min-w-0 flex-1">
            <span className="block text-[17px] font-semibold text-ink">{t("reader.understand")}</span>
            <span className="block truncate text-xs text-slate">{parts.join(" · ")}</span>
          </span>
          <ChevronUp className="h-4 w-4 shrink-0 text-brand" strokeWidth={2.5} />
        </span>
      </button>
    </div>
  );
}
