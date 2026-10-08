/**
 * The Documents area, organised by purpose. Bare Acts are read inside
 * LexIndia; court forms, exam notes, papers and revision charts can be
 * downloaded as printable PDFs. Also hosts Study material (students'
 * subset) and the document detail page.
 */

import { ArrowLeftRight, ArrowUpRight, BookA, BookOpen, CheckCircle2, Download, FileText, Globe, Lock, Printer, Quote, Share2, Trash2 } from "lucide-react";
import { useEffect, useLayoutEffect } from "react";
import { Link, useLocation, useParams } from "react-router-dom";

import { DocumentRow } from "@/components/lex/DocumentRow";
import { EmptyState, Hairline, Overline, PageHeader, PrimaryButton, ReadAloudControl } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { DocumentCatalog, legalData } from "@/lib/legalData";
import * as L from "@/lib/localize";
import { DOCUMENT_KINDS, documentFileName, sectionHasGuide, type DocumentKind, type LexDocument } from "@/lib/models";
import { PDFBuilder } from "@/lib/pdf";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

import { ToolChip } from "./LibraryScreen";

const externalLinks = [
  { id: "l-indiacode", title: "India Code", detailKey: "docs.link.indiacode", url: "https://www.indiacode.nic.in" },
  { id: "l-ecourts", title: "eCourts Services", detailKey: "docs.link.ecourts", url: "https://ecourts.gov.in" },
  { id: "l-sci", title: "Supreme Court of India", detailKey: "docs.link.sci", url: "https://www.sci.gov.in" },
  { id: "l-efiling", title: "e-Filing Portal", detailKey: "docs.link.efiling", url: "https://efiling.ecourts.gov.in" },
];

function DocumentGroup({ kind }: { kind: DocumentKind }) {
  const { language } = useLex();
  const user = useUser();
  return (
    <section id={kind} className="mt-6 scroll-mt-16">
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
  );
}

export function DocumentsScreen() {
  const { t } = useLex();
  const location = useLocation();

  useLayoutEffect(() => {
    const target = location.hash ? document.getElementById(location.hash.slice(1)) : null;
    if (target) target.scrollIntoView({ block: "start" });
  }, [location.hash]);

  return (
    <Screen>
      <NavBar fallback="/library" />
      <PageHeader title={t("docs.title")} subtitle={t("docs.sub")} />
      <div className="mt-3.5 flex gap-2">
        <span className="flex flex-1 items-center justify-center gap-1.5 rounded-full bg-mint py-2 text-[11px] font-semibold text-mint-deep">
          <BookOpen className="h-3 w-3" strokeWidth={2.5} />
          <span className="truncate">{t("docs.policy.bareActs")}</span>
        </span>
        <span className="flex flex-1 items-center justify-center gap-1.5 rounded-full bg-blue-soft py-2 text-[11px] font-semibold text-blue-deep">
          <Download className="h-3 w-3" strokeWidth={2.5} />
          <span className="truncate">{t("docs.policy.forms")}</span>
        </span>
      </div>
      {DOCUMENT_KINDS.map((kind) => (
        <DocumentGroup key={kind} kind={kind} />
      ))}
      <section className="mt-6">
        <Overline text={t("docs.links")} />
        <p className="mb-2.5 text-xs text-slate">{t("docs.links.sub")}</p>
        <div className="overflow-hidden rounded-[14px] border border-hairline bg-surface">
          {externalLinks.map((link, index) => (
            <div key={link.id}>
              {index > 0 ? <Hairline className="ml-[62px] w-auto" /> : null}
              <a
                href={link.url}
                target="_blank"
                rel="noopener noreferrer"
                className="press flex items-center gap-3 px-3 py-[11px]"
                aria-label={`${link.title}. ${t(link.detailKey)}. Opens in browser`}
              >
                <span className="flex h-[38px] w-[38px] shrink-0 items-center justify-center rounded-[11px] bg-blue-soft text-blue-deep">
                  <Globe className="h-3.5 w-3.5" strokeWidth={2.2} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[15px] font-medium text-ink">{link.title}</span>
                  <span className="block truncate text-xs text-slate">{t(link.detailKey)}</span>
                </span>
                <ArrowUpRight className="h-3.5 w-3.5 shrink-0 text-faint" strokeWidth={2.5} />
              </a>
            </div>
          ))}
        </div>
      </section>
      <div className="h-7" />
    </Screen>
  );
}

export function StudyMaterialScreen() {
  const { t } = useLex();
  return (
    <Screen>
      <NavBar fallback="/students" />
      <PageHeader title={t("library.study")} subtitle={t("study.sub")} />
      {(["exam-note", "previous-paper", "revision"] as DocumentKind[]).map((kind) => (
        <DocumentGroup key={kind} kind={kind} />
      ))}
      <section className="mt-[26px]">
        <Overline text={t("students.tools")} className="mb-2.5" />
        <div className="flex gap-2">
          <ToolChip to="/definitions" icon={BookA} title={t("account.definitions")} />
          <ToolChip to="/cases" icon={Quote} title={t("account.caseLaws")} />
          <ToolChip to="/ipc-bns" icon={ArrowLeftRight} title="IPC → BNS" />
        </div>
      </section>
      <p className="pb-7 pt-6 text-xs leading-relaxed text-slate">{t("study.note")}</p>
    </Screen>
  );
}

// MARK: - Document detail

export function DocumentDetailScreen() {
  const { id = "" } = useParams();
  const { t, f, language } = useLex();
  const user = useUser();
  const document = DocumentCatalog.document(id);

  const generate = (doc: LexDocument) =>
    PDFBuilder.makePDF(doc.title, `${L.documentKindTitle(doc.kind, language)} · ${L.docMeta(doc, language)}`, doc.body, documentFileName(doc));

  /** Makes sure the PDF exists before an open/share/print action. */
  const ensure = async (doc: LexDocument): Promise<boolean> =>
    PDFBuilder.fileExists(documentFileName(doc)) ? true : (await generate(doc)) !== null;

  useEffect(() => {
    // Regenerate the file if the record survived a reload.
    if (document && user.isDownloaded(document.id) && !PDFBuilder.fileExists(documentFileName(document))) void generate(document);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [document?.id]);

  if (!document) {
    return (
      <Screen>
        <NavBar fallback="/documents" />
        <EmptyState icon={<FileText className="h-6 w-6" />} title={t("act.notFound.title")} message={t("docs.notFound")} />
      </Screen>
    );
  }

  const downloadable = document.kind !== "bare-act";
  const record = user.downloadRecord(document.id);
  const fileName = documentFileName(document);

  const download = async () => {
    if (!(await generate(document))) return;
    user.recordDownload({ documentId: document.id, fileName, date: new Date().toISOString() });
    PDFBuilder.saveToDevice(fileName);
  };

  const withFile = (action: () => void) => async () => {
    if (await ensure(document)) action();
  };

  return (
    <Screen>
      <NavBar fallback="/documents" />
      <div className="pt-2.5">
        <div className="flex items-center justify-between">
          <Overline text={L.documentKindTitle(document.kind, language)} color="var(--saffron-deep)" />
          <span className={`rounded-full px-2 py-1 text-[10px] font-semibold ${downloadable ? "bg-blue-soft text-blue-deep" : "bg-mint text-mint-deep"}`}>
            {L.documentKindAccessLabel(document.kind, language)}
          </span>
        </div>
        <h1 className="mt-2 text-[25px] font-bold leading-tight text-ink">{L.docTitle(document, language)}</h1>
        <p className="mt-2 text-sm leading-relaxed text-slate">{L.docSummary(document, language)}</p>
        <p className="mt-2 text-xs text-slate">{L.docMeta(document, language)}</p>
      </div>

      {document.kind === "bare-act" && document.actId ? (
        <div className="mt-5 space-y-3.5">
          <Link to={`/act/${document.actId}`} className="block">
            <PrimaryButton>
              <BookOpen className="h-4 w-4" strokeWidth={2.5} />
              {t("docs.readInApp")}
            </PrimaryButton>
          </Link>
          <div className="flex items-start gap-2.5 rounded-xl bg-mint/55 p-3">
            <Lock className="mt-0.5 h-3.5 w-3.5 shrink-0 text-mint-deep" />
            <p className="text-xs leading-relaxed text-slate">{t("docs.bareact.note")}</p>
          </div>
          {legalData.sectionsInAct(document.actId).length ? (
            <div className="flex gap-2">
              <StatChip text={`${legalData.sectionsInAct(document.actId).length} ${t("library.badge.sections")}`} />
              <StatChip text={`${legalData.sectionsInAct(document.actId).filter(sectionHasGuide).length} ${t("library.badge.guided")}`} />
            </div>
          ) : null}
        </div>
      ) : (
        <>
          <div className="mt-5">
            {record ? (
              <div className="space-y-3">
                <div className="flex items-center gap-2.5 rounded-xl bg-mint/55 p-3">
                  <CheckCircle2 className="h-4 w-4 shrink-0 text-mint-deep" />
                  <div>
                    <p className="text-sm font-semibold text-ink">{t("docs.saved")}</p>
                    <p className="text-xs text-slate">{f("docs.downloadedLine", L.dateTime(record.date, language))}</p>
                  </div>
                </div>
                <PrimaryButton onClick={withFile(() => PDFBuilder.open(fileName))}>
                  <FileText className="h-4 w-4" strokeWidth={2.5} />
                  {t("docs.openPdf")}
                </PrimaryButton>
                <div className="flex gap-2.5">
                  <SecondaryButton icon={Share2} text={t("docs.share")} onClick={withFile(() => void PDFBuilder.share(fileName, document.title))} />
                  <SecondaryButton icon={Printer} text={t("docs.print")} onClick={withFile(() => PDFBuilder.print(fileName))} />
                  <SecondaryButton
                    icon={Trash2}
                    text={t("docs.remove")}
                    muted
                    onClick={() => {
                      PDFBuilder.deleteFile(fileName);
                      user.removeDownload(document.id);
                    }}
                  />
                </div>
              </div>
            ) : (
              <div className="space-y-2.5">
                <PrimaryButton onClick={() => void download()}>
                  <Download className="h-4 w-4" strokeWidth={2.5} />
                  {t("docs.downloadPdf")}
                </PrimaryButton>
                <p className="text-xs leading-relaxed text-slate">{t("docs.download.note")}</p>
              </div>
            )}
          </div>
          <section className="mt-[26px]">
            <div className="flex items-center justify-between">
              <Overline text={t("docs.readHere")} />
              <ReadAloudControl id={document.id} text={`${document.title}. ${document.body.join(" ")}`} />
            </div>
            <div className="mt-3 space-y-3 rounded-2xl border border-hairline bg-surface p-4">
              {document.body.map((paragraph, index) => (
                <p key={index} className="text-sm leading-relaxed text-ink">
                  {paragraph}
                </p>
              ))}
            </div>
          </section>
        </>
      )}
      <div className="h-8" />
    </Screen>
  );
}

function StatChip({ text }: { text: string }) {
  return <span className="rounded-full border border-hairline bg-surface px-2.5 py-1.5 text-xs font-medium text-slate">{text}</span>;
}

function SecondaryButton({
  icon: Icon,
  text,
  onClick,
  muted = false,
}: {
  icon: typeof Share2;
  text: string;
  onClick: () => void;
  muted?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`press flex flex-1 items-center justify-center gap-1.5 rounded-xl py-3 text-sm font-semibold ${muted ? "border border-hairline bg-surface text-slate" : "bg-brand-soft text-brand"}`}
    >
      <Icon className="h-3.5 w-3.5 shrink-0" strokeWidth={2.5} />
      <span className="truncate">{text}</span>
    </button>
  );
}
