//
//  DocumentsView.swift
//  LexIndia
//
//  The Documents area, organised by purpose. Bare Acts are read inside
//  LexIndia; court forms, exam notes, papers and revision charts can be
//  downloaded to the device as printable PDFs.
//

import SwiftUI

struct DocumentsView: View {
    @Environment(UserDataStore.self) private var store

    private let groups: [DocumentKind] = [.bareAct, .courtForm, .examNote, .previousPaper, .revision]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LexStrings.t("docs.title", store.language))
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("docs.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                policyStrip
                    .padding(.top, 14)

                ForEach(groups) { kind in
                    documentGroup(kind)
                        .padding(.top, 24)
                }

                linksBlock
                    .padding(.top, 24)

                Spacer().frame(height: 28)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var policyStrip: some View {
        HStack(spacing: 8) {
            policyChip(symbol: "book", text: LexStrings.t("docs.policy.bareActs", store.language), tone: LexColor.mintDeep, fill: LexColor.mint)
            policyChip(symbol: "arrow.down.circle", text: LexStrings.t("docs.policy.forms", store.language), tone: LexColor.blueDeep, fill: LexColor.blueSoft)
        }
    }

    // MARK: Important links

    private struct ExternalLink: Identifiable {
        let id: String
        let title: String
        let detailKey: String
        let url: String
    }

    private static let externalLinks: [ExternalLink] = [
        ExternalLink(id: "l-indiacode", title: "India Code", detailKey: "docs.link.indiacode", url: "https://www.indiacode.nic.in"),
        ExternalLink(id: "l-ecourts", title: "eCourts Services", detailKey: "docs.link.ecourts", url: "https://ecourts.gov.in"),
        ExternalLink(id: "l-sci", title: "Supreme Court of India", detailKey: "docs.link.sci", url: "https://www.sci.gov.in"),
        ExternalLink(id: "l-efiling", title: "e-Filing Portal", detailKey: "docs.link.efiling", url: "https://efiling.ecourts.gov.in")
    ]

    private var linksBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                LexOverline(text: LexStrings.t("docs.links", store.language))
                Text(LexStrings.t("docs.links.sub", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
            }
            VStack(spacing: 0) {
                ForEach(Array(Self.externalLinks.enumerated()), id: \.element.id) { index, link in
                    if index > 0 { LexHairline().padding(.leading, 62) }
                    linkRow(link)
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

    @ViewBuilder
    private func linkRow(_ link: ExternalLink) -> some View {
        if let url = URL(string: link.url) {
            Link(destination: url) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LexColor.blueDeep)
                        .frame(width: 38, height: 38)
                        .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.blueSoft))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(link.title)
                            .font(LexFont.sans(15, .medium))
                            .foregroundStyle(LexColor.ink)
                        Text(LexStrings.t(link.detailKey, store.language))
                            .font(LexFont.sans(12))
                            .foregroundStyle(LexColor.slate)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LexColor.faint)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(LexPressStyle())
            .accessibilityLabel("\(link.title). \(LexStrings.t(link.detailKey, store.language)). Opens in browser")
        }
    }

    private func policyChip(symbol: String, text: String, tone: Color, fill: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(LexFont.sans(11, .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(tone)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Capsule().fill(fill))
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
}

// MARK: - Shared document row

struct DocumentRow: View {
    @Environment(UserDataStore.self) private var store

    let document: LexDocument
    var isDownloaded: Bool = false

    private var kindIndex: Int {
        DocumentKind.allCases.firstIndex(of: document.kind) ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.kind.symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.pastel(kindIndex).tone)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 11).fill(LexColor.pastel(kindIndex).fill))
            VStack(alignment: .leading, spacing: 2) {
                Text(LexLocalize.docTitle(document, store.language))
                    .font(LexFont.sans(15, .medium))
                    .foregroundStyle(LexColor.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(LexLocalize.docMeta(document, store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(LexColor.mintDeep)
                    .accessibilityLabel(LexStrings.t("docs.badge.downloaded", store.language))
            }
            Text(document.kind.badgeLabel(store.language))
                .font(LexFont.sans(10, .semibold))
                .foregroundStyle(document.isDownloadable ? LexColor.blueDeep : LexColor.mintDeep)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(document.isDownloadable ? LexColor.blueSoft : LexColor.mint))
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LexColor.faint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}
