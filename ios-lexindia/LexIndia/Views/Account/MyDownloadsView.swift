//
//  MyDownloadsView.swift
//  LexIndia
//
//  PDFs the user has downloaded to this device — open, share, print
//  or remove. Bare Acts never appear here; they live in the library.
//

import SwiftUI

struct MyDownloadsView: View {
    @Environment(UserDataStore.self) private var store

    var body: some View {
        Group {
            if store.downloads.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        LexEmptyState(
                            symbol: "arrow.down.circle",
                            title: LexStrings.t("downloads.emptyTitle", store.language),
                            message: LexStrings.t("downloads.emptySub", store.language)
                        )
                        NavigationLink(value: Destination.documents) {
                            Text(LexStrings.t("downloads.browse", store.language))
                        }
                        .buttonStyle(LexPrimaryButtonStyle())
                        .padding(.horizontal, 40)
                    }
                    .padding(.top, 30)
                }
            } else {
                List {
                    ForEach(store.downloads) { record in
                        if let document = DocumentCatalog.document(record.documentId) {
                            NavigationLink(value: Destination.document(document.id)) {
                                row(document, record: record)
                            }
                            .listRowBackground(LexColor.canvas)
                            .listRowSeparatorTint(LexColor.hairline)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    PDFBuilder.deleteFile(record.fileName)
                                    store.removeDownload(record.documentId)
                                } label: {
                                    Label(LexStrings.t("docs.remove", store.language), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationTitle(LexStrings.t("account.downloads", store.language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ document: LexDocument, record: DownloadRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: document.kind.symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.brand)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.brandSoft))
            VStack(alignment: .leading, spacing: 2) {
                Text(LexLocalize.docTitle(document, store.language))
                    .font(LexFont.sans(15, .medium))
                    .foregroundStyle(LexColor.ink)
                    .lineLimit(2)
                Text("\(document.kind.groupTitle(store.language)) · \(LexLocalize.date(record.date, store.language))")
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
        }
        .padding(.vertical, 5)
    }
}
