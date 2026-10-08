/** Recently viewed (the reading trail) and My downloads. */

import { ChevronRight, Clock, Download, Trash2 } from "lucide-react";
import { Link } from "react-router-dom";

import { documentKindIcon } from "@/components/lex/icons";
import { EmptyState, Hairline, PrimaryButton, SectionRow } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { DocumentCatalog, legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { actDisplayShortName } from "@/lib/models";
import { PDFBuilder } from "@/lib/pdf";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

export function RecentsScreen() {
  const { t, language } = useLex();
  const user = useUser();
  return (
    <Screen>
      <NavBar
        title={t("account.recents")}
        fallback="/myspace"
        trailing={
          user.recents.length ? (
            <button type="button" onClick={user.clearRecents} className="press text-sm font-medium text-brand">
              {t("common.clear")}
            </button>
          ) : null
        }
      />
      {user.recents.length === 0 ? (
        <EmptyState icon={<Clock className="h-6 w-6" />} title={t("updates.empty")} message={t("recents.emptySub")} className="pt-10" />
      ) : (
        <div className="pb-8 pt-2">
          {user.recents.map((recent, index) => {
            const section = legalData.section(recent.sectionId);
            if (!section) return null;
            const act = legalData.act(section.actId);
            return (
              <div key={recent.sectionId}>
                {index > 0 ? <Hairline /> : null}
                <Link to={`/read/${section.actId}/${section.id}`} className="press block">
                  <SectionRow number={section.number} title={section.title} subtitle={`${act ? actDisplayShortName(act) : ""} · ${L.dateTime(recent.date, language)}`} />
                </Link>
              </div>
            );
          })}
        </div>
      )}
    </Screen>
  );
}

export function DownloadsScreen() {
  const { t, language } = useLex();
  const user = useUser();
  return (
    <Screen>
      <NavBar title={t("account.downloads")} fallback="/myspace" />
      {user.downloads.length === 0 ? (
        <div className="pt-8">
          <EmptyState icon={<Download className="h-6 w-6" />} title={t("downloads.emptyTitle")} message={t("downloads.emptySub")} />
          <Link to="/documents" className="mx-10 block">
            <PrimaryButton>{t("downloads.browse")}</PrimaryButton>
          </Link>
        </div>
      ) : (
        <div className="pb-8 pt-2">
          {user.downloads.map((record, index) => {
            const document = DocumentCatalog.document(record.documentId);
            if (!document) return null;
            const Icon = documentKindIcon[document.kind];
            return (
              <div key={record.documentId}>
                {index > 0 ? <Hairline /> : null}
                <div className="flex items-center gap-2">
                  <Link to={`/documents/${document.id}`} className="press flex min-w-0 flex-1 items-center gap-3 py-3">
                    <span className="flex h-[38px] w-[38px] shrink-0 items-center justify-center rounded-[11px] bg-brand-soft text-brand">
                      <Icon className="h-3.5 w-3.5" strokeWidth={2.2} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="line-clamp-2 block text-[15px] font-medium leading-snug text-ink">{L.docTitle(document, language)}</span>
                      <span className="block text-xs text-slate">
                        {L.documentKindTitle(document.kind, language)} · {L.date(record.date, language)}
                      </span>
                    </span>
                    <ChevronRight className="h-3.5 w-3.5 shrink-0 text-faint" strokeWidth={2.5} />
                  </Link>
                  <button
                    type="button"
                    onClick={() => {
                      PDFBuilder.deleteFile(record.fileName);
                      user.removeDownload(record.documentId);
                    }}
                    aria-label={t("docs.remove")}
                    className="press flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-surface text-slate"
                  >
                    <Trash2 className="h-3.5 w-3.5" strokeWidth={2.2} />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </Screen>
  );
}
