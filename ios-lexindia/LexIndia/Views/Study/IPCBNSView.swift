//
//  IPCBNSView.swift
//  LexIndia
//
//  Old IPC section → new BNS provision. Browse in numerical order or
//  search a number; the mapping itself is the hero.
//

import SwiftUI

struct IPCBNSView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @State private var query: String = ""

    /// All mappings in proper IPC numerical sequence.
    private var ordered: [IPCMapping] {
        data.core.ipcMappings.sorted {
            let a = Int($0.ipc.prefix(while: { $0.isNumber })) ?? Int.max
            let b = Int($1.ipc.prefix(while: { $0.isNumber })) ?? Int.max
            if a != b { return a < b }
            return $0.ipc < $1.ipc
        }
    }

    private var filtered: [IPCMapping] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return ordered }
        return ordered.filter {
            $0.ipc.lowercased().contains(q)
                || $0.ipcTitle.lowercased().contains(q)
                || $0.bnsLabel.lowercased().contains(q)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IPC → BNS")
                        .font(LexFont.display(30, .bold))
                        .foregroundStyle(LexColor.ink)
                    Text(LexStrings.t("library.ipc.sub", store.language))
                        .font(LexFont.sans(14))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 8)

                searchField
                    .padding(.top, 14)

                if filtered.isEmpty {
                    LexEmptyState(
                        symbol: "arrow.left.arrow.right",
                        title: LexStrings.t("ipc.emptyTitle", store.language),
                        message: LexStrings.t("ipc.emptySub", store.language)
                    )
                } else {
                    HStack {
                        LexOverline(text: query.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? LexStrings.t("ipc.all", store.language)
                                    : "\(filtered.count) \(store.language == .hindi ? LexStrings.t("ipc.matches", store.language) : (filtered.count == 1 ? "match" : "matches"))")
                        Spacer()
                    }
                    .padding(.top, 20)

                    VStack(spacing: 10) {
                        ForEach(filtered) { mapping in
                            mappingCard(mapping)
                        }
                    }
                    .padding(.top, 10)
                }

                Text(LexStrings.t("ipc.note", store.language))
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(3)
                    .padding(.top, 22)
                    .padding(.bottom, 26)
            }
            .padding(.horizontal, 22)
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.18), value: filtered.count)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LexColor.slate)
            TextField(LexStrings.t("ipc.search", store.language), text: $query)
                .font(LexFont.sans(15))
                .foregroundStyle(LexColor.ink)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(LexColor.faint)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(LexColor.surface)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(LexColor.hairline, lineWidth: 1)
        )
    }

    // MARK: Mapping card — the mapping is the hero

    @ViewBuilder
    private func mappingCard(_ mapping: IPCMapping) -> some View {
        if let sectionId = mapping.sectionId, let section = data.section(sectionId) {
            NavigationLink(value: Destination.reader(actId: section.actId, sectionId: section.id)) {
                cardContent(mapping, openable: true)
            }
            .buttonStyle(LexPressStyle())
            .accessibilityLabel("IPC \(mapping.ipc), \(mapping.ipcTitle), is now BNS \(mapping.bnsLabel). Opens the section")
        } else {
            cardContent(mapping, openable: false)
                .accessibilityLabel("IPC \(mapping.ipc), \(mapping.ipcTitle), is now BNS \(mapping.bnsLabel)")
        }
    }

    private func cardContent(_ mapping: IPCMapping, openable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    LexOverline(text: "IPC")
                    Text(mapping.ipc)
                        .font(LexFont.display(27, .bold).monospacedDigit())
                        .foregroundStyle(LexColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(LexColor.saffronDeep)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(LexColor.saffronSoft))

                VStack(alignment: .trailing, spacing: 3) {
                    LexOverline(text: "BNS", color: LexColor.brand)
                    Text(mapping.bnsLabel)
                        .font(LexFont.display(27, .bold).monospacedDigit())
                        .foregroundStyle(LexColor.brand)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Text(mapping.ipcTitle)
                .font(LexFont.sans(14, .medium))
                .foregroundStyle(LexColor.ink)
                .multilineTextAlignment(.leading)

            if let note = mapping.note {
                Text(note)
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
            }

            HStack(spacing: 4) {
                if openable {
                    Text(LexStrings.t("ipc.open", store.language))
                        .font(LexFont.sans(13, .semibold))
                        .foregroundStyle(LexColor.brand)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(LexColor.brand)
                } else {
                    Text(LexStrings.t("ipc.preparing", store.language))
                        .font(LexFont.sans(12, .medium))
                        .foregroundStyle(LexColor.saffronDeep)
                }
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
        .contentShape(Rectangle())
    }
}
