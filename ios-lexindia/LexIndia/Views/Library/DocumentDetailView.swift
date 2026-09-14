//
//  DocumentDetailView.swift
//  LexIndia
//
//  One document. Bare Acts open inside LexIndia and are never
//  downloadable; other documents follow Open → Download → Device
//  storage → Share → Print with a generated PDF.
//

import SwiftUI
import UIKit

struct DocumentDetailView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    let documentId: String

    @State private var showPDF: Bool = false
    @State private var downloadTick: Int = 0

    var body: some View {
        if let document = DocumentCatalog.document(documentId) {
            content(document)
                .sensoryFeedback(.success, trigger: downloadTick)
                .onAppear {
                    // Regenerate the file if the record survived a reinstall.
                    if store.isDownloaded(document.id), !PDFBuilder.fileExists(document.fileName) {
                        _ = generatePDF(document)
                    }
                }
        } else {
            LexEmptyState(
                symbol: "doc",
                title: LexStrings.t("act.notFound.title", store.language),
                message: LexStrings.t("docs.notFound", store.language)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LexColor.canvas.ignoresSafeArea())
        }
    }

    private func content(_ document: LexDocument) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header(document)

                if document.kind == .bareAct {
                    bareActBlock(document)
                        .padding(.top, 20)
                } else {
                    downloadBlock(document)
                        .padding(.top, 20)
                    previewBlock(document)
                        .padding(.top, 26)
                }

                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPDF) {
            pdfSheet(document)
        }
    }

    // MARK: Header

    private func header(_ document: LexDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                LexOverline(text: document.kind.groupTitle(store.language), color: LexColor.saffronDeep)
                Spacer()
                Text(document.kind.accessLabel(store.language))
                    .font(LexFont.sans(10, .semibold))
                    .foregroundStyle(document.isDownloadable ? LexColor.blueDeep : LexColor.mintDeep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(document.isDownloadable ? LexColor.blueSoft : LexColor.mint))
            }
            Text(LexLocalize.docTitle(document, store.language))
                .font(LexFont.display(25, .bold))
                .foregroundStyle(LexColor.ink)
            Text(LexLocalize.docSummary(document, store.language))
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(4)
            Text(LexLocalize.docMeta(document, store.language))
                .font(LexFont.sans(12))
                .foregroundStyle(LexColor.slate)
        }
        .padding(.top, 10)
    }

    // MARK: Bare Act — read in app only

    @ViewBuilder
    private func bareActBlock(_ document: LexDocument) -> some View {
        if let actId = document.actId {
            VStack(alignment: .leading, spacing: 14) {
                NavigationLink(value: Destination.act(actId)) {
                    HStack(spacing: 8) {
                        Image(systemName: "book")
                            .font(.system(size: 15, weight: .semibold))
                        Text(LexStrings.t("docs.readInApp", store.language))
                    }
                }
                .buttonStyle(LexPrimaryButtonStyle())

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LexColor.mintDeep)
                        .padding(.top, 1)
                    Text(LexStrings.t("docs.bareact.note", store.language))
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                        .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LexColor.mint.opacity(0.55))
                .clipShape(.rect(cornerRadius: 12))

                let sections = data.sections(inAct: actId)
                if !sections.isEmpty {
                    HStack(spacing: 8) {
                        statChip("\(sections.count) \(LexStrings.t("library.badge.sections", store.language))")
                        statChip("\(sections.filter(\.hasGuide).count) \(LexStrings.t("library.badge.guided", store.language))")
                    }
                }
            }
        }
    }

    private func statChip(_ text: String) -> some View {
        Text(text)
            .font(LexFont.sans(12, .medium))
            .foregroundStyle(LexColor.slate)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(LexColor.surface))
            .overlay(Capsule().strokeBorder(LexColor.hairline, lineWidth: 1))
    }

    // MARK: Downloadable document

    @ViewBuilder
    private func downloadBlock(_ document: LexDocument) -> some View {
        if store.isDownloaded(document.id) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LexColor.mintDeep)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(LexStrings.t("docs.saved", store.language))
                            .font(LexFont.sans(14, .semibold))
                            .foregroundStyle(LexColor.ink)
                        if let record = store.downloadRecord(document.id) {
                            Text(LexStrings.f("docs.downloadedLine", store.language, LexLocalize.dateTime(record.date, store.language)))
                                .font(LexFont.sans(12))
                                .foregroundStyle(LexColor.slate)
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .background(LexColor.mint.opacity(0.55))
                .clipShape(.rect(cornerRadius: 12))

                Button {
                    if ensureFile(document) != nil { showPDF = true }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 15, weight: .semibold))
                        Text(LexStrings.t("docs.openPdf", store.language))
                    }
                }
                .buttonStyle(LexPrimaryButtonStyle())

                HStack(spacing: 10) {
                    ShareLink(item: PDFBuilder.fileURL(document.fileName)) {
                        secondaryLabel(symbol: "square.and.arrow.up", text: LexStrings.t("docs.share", store.language), tone: LexColor.brand, fill: LexColor.brandSoft)
                    }
                    Button {
                        if let url = ensureFile(document) { printPDF(url, title: document.title) }
                    } label: {
                        secondaryLabel(symbol: "printer", text: LexStrings.t("docs.print", store.language), tone: LexColor.brand, fill: LexColor.brandSoft)
                    }
                    .buttonStyle(LexPressStyle())
                    Button {
                        PDFBuilder.deleteFile(document.fileName)
                        store.removeDownload(document.id)
                    } label: {
                        secondaryLabel(symbol: "trash", text: LexStrings.t("docs.remove", store.language), tone: LexColor.slate, fill: LexColor.surface, bordered: true)
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    download(document)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text(LexStrings.t("docs.downloadPdf", store.language))
                    }
                }
                .buttonStyle(LexPrimaryButtonStyle())
                Text(LexStrings.t("docs.download.note", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(3)
            }
        }
    }

    // MARK: Content preview

    private func previewBlock(_ document: LexDocument) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                LexOverline(text: LexStrings.t("docs.readHere", store.language))
                Spacer()
                ReadAloudControl(
                    id: document.id,
                    text: "\(document.title). \(document.body.joined(separator: " "))"
                )
                .id(document.id)
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(document.body.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.ink)
                        .lineSpacing(4)
                        .lexTranslatable(paragraph)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
        }
    }

    // MARK: PDF sheet

    @ViewBuilder
    private func pdfSheet(_ document: LexDocument) -> some View {
        NavigationStack {
            PDFKitView(url: PDFBuilder.fileURL(document.fileName))
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(LexLocalize.docTitle(document, store.language))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(LexStrings.t("common.done", store.language)) {
                            showPDF = false
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            printPDF(PDFBuilder.fileURL(document.fileName), title: document.title)
                        } label: {
                            Image(systemName: "printer")
                        }
                        ShareLink(item: PDFBuilder.fileURL(document.fileName)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }

    // MARK: Shared pieces

    private func secondaryLabel(symbol: String, text: String, tone: Color, fill: Color, bordered: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(LexFont.sans(14, .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(tone)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(fill)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(bordered ? LexColor.hairline : Color.clear, lineWidth: 1)
        )
    }

    /// System print dialog for the generated PDF.
    private func printPDF(_ url: URL, title: String) {
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = title
        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = url
        controller.present(animated: true)
    }

    // MARK: Actions

    private func download(_ document: LexDocument) {
        guard generatePDF(document) != nil else { return }
        store.recordDownload(DownloadRecord(documentId: document.id, fileName: document.fileName, date: Date()))
        downloadTick += 1
    }

    private func ensureFile(_ document: LexDocument) -> URL? {
        if PDFBuilder.fileExists(document.fileName) {
            return PDFBuilder.fileURL(document.fileName)
        }
        return generatePDF(document)
    }

    private func generatePDF(_ document: LexDocument) -> URL? {
        PDFBuilder.makePDF(
            title: document.title,
            subtitle: "\(document.kind.groupTitle(store.language)) · \(LexLocalize.docMeta(document, store.language))",
            paragraphs: document.body,
            fileName: document.fileName
        )
    }
}
