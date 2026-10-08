/**
 * The E-Vakeel chat overlay — the assistant appears above the current
 * screen and returns the user exactly where they were. Credits are
 * charged per answer but the balance is never shown here (only in Account).
 */

import { ArrowLeftRight, ArrowRight, ArrowUp, ArrowUpRight, Ellipsis, Trash2, UserRound } from "lucide-react";
import { useEffect, useRef, useState } from "react";

import { CloseButton, Hairline, Overline, PrimaryButton } from "@/components/lex/primitives";
import { mockReply } from "@/lib/evakeel";
import { legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { EVakeelPricing, type EVakeelRecord } from "@/lib/models";
import { uuid } from "@/lib/storage";
import { cn } from "@/lib/utils";
import { useUI } from "@/stores/uiStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { EVakeelFace } from "./EVakeelLogo";

export function EVakeelOverlay() {
  const { t, language } = useLex();
  const ui = useUI();
  const user = useUser();
  const [input, setInput] = useState<string>("");
  const [isThinking, setIsThinking] = useState<boolean>(false);
  const [needsMoreCredits, setNeedsMoreCredits] = useState<boolean>(false);
  const [menuOpen, setMenuOpen] = useState<boolean>(false);
  const [focused, setFocused] = useState<boolean>(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [user.evakeelRecords.length, isThinking]);

  useEffect(() => {
    document.body.style.overflow = "hidden";
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") ui.closeEVakeel();
    };
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = "";
      window.removeEventListener("keydown", onKey);
    };
  }, [ui]);

  const canSend = input.trim().length > 0 && !isThinking && user.credits > 0;

  const send = async (text?: string) => {
    const question = (text ?? input).trim();
    if (!question || isThinking) return;
    const estimated = EVakeelPricing.estimatedCost(question);
    if (user.credits < estimated) {
      setNeedsMoreCredits(true);
      return;
    }
    setNeedsMoreCredits(false);
    setInput("");
    if (textareaRef.current) textareaRef.current.style.height = "auto";
    user.appendEVakeel({ id: uuid(), role: "user", text: question, lead: null, mappingNote: null, sectionIds: [], cost: 0, advisory: null, date: new Date().toISOString() });
    setIsThinking(true);
    const reply = await mockReply(question);
    if (reply.matched) user.spendCredits(reply.cost, `E-Vakeel — ${question.slice(0, 34)}`);
    user.appendEVakeel({
      id: uuid(),
      role: "assistant",
      text: reply.text,
      lead: reply.lead,
      mappingNote: reply.mappingNote,
      sectionIds: reply.sectionIds,
      cost: reply.matched ? reply.cost : 0,
      advisory: reply.needsAdvocate ? t("evakeel.advocate") : null,
      date: new Date().toISOString(),
    });
    setIsThinking(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center" role="dialog" aria-modal="true" aria-label={t("evakeel.name")}>
      <button type="button" aria-label="Close E-Vakeel" onClick={ui.closeEVakeel} className="absolute inset-0 bg-black/45 anim-fade" />
      <div className="relative flex h-[calc(100dvh-62px)] w-full max-w-[640px] flex-col overflow-hidden rounded-t-[26px] bg-canvas shadow-float anim-sheet lg:h-[calc(100vh-48px)] lg:max-w-[720px]">
        <div className="shrink-0 px-5 pb-3 pt-4">
          <div className="flex items-center gap-3">
            <EVakeelFace diameter={40} showsSpark={false} />
            <div className="min-w-0 flex-1">
              <p className="text-[19px] font-bold leading-tight text-ink">{t("evakeel.name")}</p>
              <p className="text-xs text-slate">{t("evakeel.tagline")}</p>
            </div>
            {user.evakeelRecords.length ? (
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setMenuOpen((open) => !open)}
                  aria-label="More"
                  className="press flex h-8 w-8 items-center justify-center rounded-full border border-hairline bg-surface text-slate"
                >
                  <Ellipsis className="h-3.5 w-3.5" strokeWidth={2.5} />
                </button>
                {menuOpen ? (
                  <button
                    type="button"
                    onClick={() => {
                      user.clearEVakeel();
                      setMenuOpen(false);
                    }}
                    className="press absolute right-0 top-10 z-10 flex items-center gap-2 whitespace-nowrap rounded-xl border border-hairline bg-surface px-3.5 py-2.5 text-sm font-medium shadow-lg anim-fade"
                    style={{ color: "var(--pastel-4-tone)" }}
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                    {t("evakeel.clear")}
                  </button>
                ) : null}
              </div>
            ) : null}
            <CloseButton onClick={ui.closeEVakeel} />
          </div>
          <p className="mt-2.5 text-[11px] leading-relaxed text-slate">{t("evakeel.disclaimer")}</p>
        </div>
        <Hairline className="mx-5 w-auto" />

        <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-2 pt-4 no-scrollbar">
          <div className="flex flex-col gap-5">
            {user.evakeelRecords.length === 0 && !isThinking ? (
              <div className="flex flex-col gap-3.5">
                <div className="rounded-2xl bg-brand-soft p-4">
                  <p className="text-[22px] font-bold text-ink">{t("evakeel.empty.title")}</p>
                  <p className="mt-1.5 text-sm leading-relaxed text-slate">{t("evakeel.empty.message")}</p>
                </div>
                <Overline text={t("evakeel.try")} />
                <div className="flex flex-col gap-2">
                  {L.suggestions(legalData.core.askSuggestions, language)
                    .slice(0, 4)
                    .map((suggestion) => (
                      <button
                        key={suggestion}
                        type="button"
                        onClick={() => send(suggestion)}
                        className="press flex items-center gap-3 rounded-xl border border-hairline bg-surface px-3.5 py-[11px] text-left"
                      >
                        <span className="flex-1 text-sm font-medium text-ink">{suggestion}</span>
                        <ArrowUpRight className="h-3 w-3 shrink-0 text-brand" strokeWidth={2.5} />
                      </button>
                    ))}
                </div>
              </div>
            ) : null}
            {user.evakeelRecords.map((record) => (
              <RecordView key={record.id} record={record} />
            ))}
            {isThinking ? (
              <div className="flex items-center gap-2.5 py-1 text-[13px] italic text-slate" role="status">
                <span className="flex gap-1" aria-hidden="true">
                  {[0, 1, 2].map((dot) => (
                    <span key={dot} className="h-1.5 w-1.5 rounded-full bg-brand" style={{ animation: `lex-pulse 1.2s ${dot * 0.2}s ease-in-out infinite` }} />
                  ))}
                </span>
                {t("evakeel.thinking")}
              </div>
            ) : null}
            <div ref={bottomRef} className="h-px" />
          </div>
        </div>

        <div className="shrink-0 bg-canvas px-5 pb-3 pt-2 safe-bottom">
          {user.credits === 0 ? (
            <div className="rounded-[14px] border border-hairline bg-surface p-3.5">
              <p className="text-[13px] leading-relaxed text-ink">{t("evakeel.outOfCredits")}</p>
              <PrimaryButton
                className="mt-2.5"
                onClick={() => {
                  ui.closeEVakeel();
                  ui.openTab("account");
                }}
              >
                {t("evakeel.manage")}
              </PrimaryButton>
            </div>
          ) : (
            <div>
              {needsMoreCredits ? <p className="mb-2 text-xs font-medium text-saffron-deep">{t("evakeel.needMore")}</p> : null}
              <div className="flex items-end gap-2.5">
                <textarea
                  ref={textareaRef}
                  value={input}
                  rows={1}
                  onChange={(event) => {
                    setInput(event.target.value);
                    event.target.style.height = "auto";
                    event.target.style.height = `${Math.min(event.target.scrollHeight, 112)}px`;
                  }}
                  onFocus={() => setFocused(true)}
                  onBlur={() => setFocused(false)}
                  onKeyDown={(event) => {
                    if (event.key === "Enter" && !event.shiftKey) {
                      event.preventDefault();
                      send();
                    }
                  }}
                  disabled={isThinking}
                  placeholder={t("evakeel.placeholder")}
                  className={cn(
                    "min-h-[46px] flex-1 resize-none rounded-[18px] border bg-surface px-[15px] py-[11px] text-base text-ink outline-none transition-colors",
                    focused ? "border-brand" : "border-hairline",
                  )}
                />
                <button
                  type="button"
                  onClick={() => send()}
                  disabled={!canSend}
                  aria-label="Send question"
                  className={cn(
                    "press-soft mb-1 flex h-9 w-9 shrink-0 items-center justify-center rounded-full transition-colors",
                    canSend ? "bg-brand text-on-brand" : "bg-faint/40 text-canvas",
                  )}
                >
                  <ArrowUp className="h-5 w-5" strokeWidth={2.8} />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function RecordView({ record }: { record: EVakeelRecord }) {
  const { t } = useLex();
  const ui = useUI();

  if (record.role === "user") {
    return (
      <div className="flex justify-end pl-12 anim-rise">
        <p className="rounded-2xl bg-brand-soft px-[15px] py-[11px] text-[15px] leading-relaxed text-ink">{record.text}</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-3 anim-rise">
      {record.mappingNote ? (
        <div className="flex items-start gap-2 rounded-[10px] bg-blue-soft p-3">
          <ArrowLeftRight className="mt-1 h-3 w-3 shrink-0 text-saffron-deep" strokeWidth={2.5} />
          <p className="text-[13px] font-medium leading-relaxed text-ink">{record.mappingNote}</p>
        </div>
      ) : null}
      {record.lead ? <p className="text-xs italic text-slate">{record.lead}</p> : null}
      <p className="whitespace-pre-line text-base leading-[1.65] text-ink">{record.text}</p>
      {record.sectionIds.map((sectionId) => {
        const section = legalData.section(sectionId);
        if (!section) return null;
        return (
          <button
            key={sectionId}
            type="button"
            onClick={() => ui.go(`/read/${section.actId}/${section.id}`)}
            className="press block w-full rounded-[14px] border border-hairline bg-surface p-3.5 text-left"
          >
            <Overline text={t("evakeel.provision")} color="var(--saffron-deep)" />
            <span className="mt-1 block text-[17px] font-semibold leading-snug text-ink">
              {section.number} · {section.title}
            </span>
            <span className="mt-0.5 block text-[13px] text-slate">{legalData.act(section.actId)?.name ?? ""}</span>
            <span className="mt-2 flex items-center gap-1 text-sm font-semibold text-brand">
              {t("evakeel.openSection")}
              <ArrowRight className="h-3 w-3" strokeWidth={2.5} />
            </span>
          </button>
        );
      })}
      {record.advisory ? (
        <div className="flex items-start gap-2.5 rounded-xl bg-saffron-soft p-3">
          <UserRound className="mt-0.5 h-3.5 w-3.5 shrink-0 text-saffron-deep" />
          <p className="text-[13px] font-medium leading-relaxed text-ink">{record.advisory}</p>
        </div>
      ) : null}
      {record.cost === 0 ? (
        <p className="text-[11px] text-saffron-deep">{t("evakeel.noCharge")}</p>
      ) : (
        <p className="text-[11px] text-faint">
          {record.cost} {t(record.cost === 1 ? "evakeel.creditUsed" : "evakeel.creditsUsed")}
        </p>
      )}
    </div>
  );
}
