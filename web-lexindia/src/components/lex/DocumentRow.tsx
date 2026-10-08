/** Shared document row used by Documents, Study material, Students Corner and Search. */

import { CheckCircle2, ChevronRight } from "lucide-react";

import { documentKindIcon } from "@/components/lex/icons";
import { IconTile } from "@/components/lex/primitives";
import * as L from "@/lib/localize";
import { documentKindIndex, documentKindIsDownloadable, type LexDocument } from "@/lib/models";
import { useLex } from "@/stores/useLex";

export function DocumentRow({ document, isDownloaded = false }: { document: LexDocument; isDownloaded?: boolean }) {
  const { t, language } = useLex();
  const Icon = documentKindIcon[document.kind];
  const downloadable = documentKindIsDownloadable(document.kind);
  return (
    <div className="flex w-full items-center gap-3 px-3 py-[11px] text-left">
      <IconTile index={documentKindIndex(document.kind)} size={38} radius={11}>
        <Icon className="h-3.5 w-3.5" strokeWidth={2.2} />
      </IconTile>
      <div className="min-w-0 flex-1">
        <p className="line-clamp-2 text-[15px] font-medium leading-snug text-ink">{L.docTitle(document, language)}</p>
        <p className="truncate text-xs text-slate">{L.docMeta(document, language)}</p>
      </div>
      {isDownloaded ? (
        <CheckCircle2 className="h-3.5 w-3.5 shrink-0 text-mint-deep" aria-label={t("docs.badge.downloaded")} />
      ) : null}
      <span
        className={`shrink-0 rounded-full px-[7px] py-[3px] text-[10px] font-semibold ${downloadable ? "bg-blue-soft text-blue-deep" : "bg-mint text-mint-deep"}`}
      >
        {L.documentKindBadge(document.kind, language)}
      </span>
      <ChevronRight className="h-3 w-3 shrink-0 text-faint" strokeWidth={2.5} />
    </div>
  );
}
