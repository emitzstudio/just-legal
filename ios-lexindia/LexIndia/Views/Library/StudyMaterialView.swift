//
//  StudyMaterialView.swift
//  LexIndia
//
//  The student corner: exam notes, previous year papers and revision
//  material — all downloadable and printable — plus study tools.
//

import SwiftUI

struct StudyMaterialView: View {
    @Environment(UserDataStore.self) private var store

    private let groups: [DocumentKind] = [.examNote, .previousPaper, .revision]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("library.study", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("study.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                ForEach(groups) { kind in
                    documentGroup(kind)
                        .padding(.top, 24)
                }

                toolsBlock
                    .padding(.top, 26)

                Text(LexStrings.t("study.note", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(3)
                    .padding(.top, 24)
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private func documentGroup(_ kind: DocumentKind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                LexOverline(text: kind.groupTitle(store.language))
                Text(kind.groupBlurb(store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            VStack(spacing: 0) {
                ForEach(Array(DocumentCatalog.documents(of: kind).enumerated()), id: \.element.id) { index, document in
                    if index > 0 { LexHairline().padding(.leading, 62) }
                    NavigationLink(value: Destination.document(document.id)) {
                        DocumentRow(document: document, isDownloaded: store.isDownloaded(document.id))
                    }
                    .buttonStyle(LexPressStyle())
                }
            }
            .background(LexColor.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
        }
    }

    private var toolsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            LexOverline(text: LexStrings.t("students.tools", store.language))
            HStack(spacing: 8) {
                toolChip(LexStrings.t("account.definitions", store.language), symbol: "character.book.closed", destination: .definitions)
                toolChip(LexStrings.t("account.caseLaws", store.language), symbol: "text.quote", destination: .caseLaws)
                toolChip("IPC → BNS", symbol: "arrow.left.arrow.right", destination: .ipcBns)
            }
        }
    }

    private func toolChip(_ title: String, symbol: String, destination: Destination) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(LexFont.sans(12, .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(LexColor.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(LexColor.brandSoft)
            .clipShape(Capsule())
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
    }
}
