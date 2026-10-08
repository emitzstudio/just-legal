/** Saved sections with personal notes: open, edit, delete, search. */

import { ArrowRight, BookOpen, Bookmark, Trash2 } from "lucide-react";
import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";

import { Sheet } from "@/components/lex/ConfirmDialog";
import { EmptyState, FilterField, Hairline, Overline, PrimaryButton } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import type { SavedItem } from "@/lib/models";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

export function NotesScreen() {
  const { t, f, language } = useLex();
  const user = useUser();
  const navigate = useNavigate();
  const [query, setQuery] = useState<string>("");
  const [editing, setEditing] = useState<SavedItem | null>(null);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return user.saved;
    return user.saved.filter((item) => {
      const section = legalData.section(item.sectionId);
      if (!section) return false;
      return section.title.toLowerCase().includes(q) || section.number.toLowerCase().startsWith(q) || item.note.toLowerCase().includes(q);
    });
  }, [query, user.saved]);

  return (
    <Screen>
      <NavBar title={t("account.saved")} fallback="/myspace" />
      {user.saved.length === 0 ? (
        <EmptyState icon={<Bookmark className="h-6 w-6" />} title={t("notes.emptyTitle")} message={t("notes.emptySub")} className="pt-10" />
      ) : (
        <>
          <div className="pt-2">
            <FilterField value={query} onChange={setQuery} placeholder={t("notes.search")} inputMode="search" />
          </div>
          <div className="mt-2 pb-6">
            {filtered.map((item, index) => {
              const section = legalData.section(item.sectionId);
              if (!section) return null;
              const act = legalData.act(section.actId);
              return (
                <div key={item.sectionId}>
                  {index > 0 ? <Hairline /> : null}
                  <div className="flex items-start gap-2">
                    <button type="button" onClick={() => setEditing(item)} className="press min-w-0 flex-1 py-3 text-left">
                      <span className="flex items-baseline gap-2.5">
                        <span className="text-lg font-semibold tabular text-brand">{section.number}</span>
                        <span className="min-w-0 flex-1 truncate text-[15px] font-medium text-ink">{section.title}</span>
                        <Bookmark className="h-3 w-3 shrink-0 self-center text-saffron-deep" fill="currentColor" />
                      </span>
                      <span className="mt-1 block text-xs text-slate">{act ? L.actName(act, language) : ""}</span>
                      {item.note ? (
                        <span className="mt-1 line-clamp-2 block text-sm text-ink">{item.note}</span>
                      ) : (
                        <span className="mt-1 block text-[13px] italic text-slate/70">{t("notes.add")}</span>
                      )}
                      <span className="mt-1 block text-[11px] text-slate/80">{f("notes.savedOn", L.date(item.savedAt, language))}</span>
                    </button>
                    <div className="flex shrink-0 flex-col gap-1 pt-3">
                      <button
                        type="button"
                        onClick={() => navigate(`/read/${section.actId}/${section.id}`)}
                        aria-label={t("common.open")}
                        className="press flex h-8 w-8 items-center justify-center rounded-full bg-brand-soft text-brand"
                      >
                        <BookOpen className="h-3.5 w-3.5" strokeWidth={2.2} />
                      </button>
                      <button
                        type="button"
                        onClick={() => user.removeSaved(item.sectionId)}
                        aria-label={t("common.delete")}
                        className="press flex h-8 w-8 items-center justify-center rounded-full bg-surface text-slate"
                      >
                        <Trash2 className="h-3.5 w-3.5" strokeWidth={2.2} />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </>
      )}
      {editing ? (
        <NoteEditorSheet
          item={editing}
          onClose={() => setEditing(null)}
          onOpenSection={(actId, sectionId) => {
            setEditing(null);
            window.setTimeout(() => navigate(`/read/${actId}/${sectionId}`), 200);
          }}
        />
      ) : null}
    </Screen>
  );
}

function NoteEditorSheet({ item, onClose, onOpenSection }: { item: SavedItem; onClose: () => void; onOpenSection: (actId: string, sectionId: string) => void }) {
  const { t, language } = useLex();
  const user = useUser();
  const [noteText, setNoteText] = useState<string>(item.note);
  const section = legalData.section(item.sectionId);
  if (!section) return null;
  const act = legalData.act(section.actId);

  return (
    <Sheet open onClose={onClose} label={t("notes.your")}>
      <div className="pt-6">
        <Overline text={t("notes.your")} color="var(--saffron-deep)" />
        <h2 className="mt-1 text-xl font-semibold leading-snug text-ink">
          {section.number} · {section.title}
        </h2>
        <p className="mt-0.5 text-[13px] text-slate">{act ? L.actName(act, language) : ""}</p>
      </div>
      <textarea
        autoFocus={!item.note}
        value={noteText}
        onChange={(event) => setNoteText(event.target.value)}
        aria-label="Note text"
        placeholder={t("notes.add")}
        className="mt-4 min-h-[140px] w-full resize-y rounded-xl border border-hairline bg-canvas p-3 text-[15px] leading-relaxed text-ink outline-none focus:border-brand"
      />
      <PrimaryButton
        className="mt-4"
        onClick={() => {
          user.updateNote(item.sectionId, noteText.trim());
          onClose();
        }}
      >
        {t("notes.saveNote")}
      </PrimaryButton>
      <button type="button" onClick={() => onOpenSection(section.actId, section.id)} className="press mt-1 flex w-full items-center justify-center gap-1.5 py-3 text-[15px] font-semibold text-brand">
        {t("evakeel.openSection")}
        <ArrowRight className="h-3 w-3" strokeWidth={2.5} />
      </button>
      <div className="h-6" />
    </Sheet>
  );
}
