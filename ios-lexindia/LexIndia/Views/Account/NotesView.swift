//
//  NotesView.swift
//  LexIndia
//
//  Saved sections with personal notes: open, edit, delete, search.
//

import SwiftUI

struct NotesView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store

    @State private var query: String = ""
    @State private var editingItem: SavedItem?
    @State private var pushTarget: ReaderTarget?

    private var filtered: [SavedItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return store.saved }
        return store.saved.filter { item in
            guard let section = data.section(item.sectionId) else { return false }
            return section.title.lowercased().contains(q)
                || section.number.lowercased().hasPrefix(q)
                || item.note.lowercased().contains(q)
        }
    }

    var body: some View {
        Group {
            if store.saved.isEmpty {
                VStack {
                    LexEmptyState(
                        symbol: "bookmark",
                        title: LexStrings.t("notes.emptyTitle", store.language),
                        message: LexStrings.t("notes.emptySub", store.language)
                    )
                    Spacer()
                }
            } else {
                List {
                    ForEach(filtered) { item in
                        if let section = data.section(item.sectionId) {
                            Button {
                                editingItem = item
                            } label: {
                                noteRow(item: item, section: section)
                            }
                            .buttonStyle(LexPressStyle())
                            .listRowBackground(LexColor.canvas)
                            .listRowSeparatorTint(LexColor.hairline)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.removeSaved(item.sectionId)
                                } label: {
                                    Label(LexStrings.t("common.delete", store.language), systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    pushTarget = ReaderTarget(actId: section.actId, sectionId: section.id)
                                } label: {
                                    Label(LexStrings.t("common.open", store.language), systemImage: "book")
                                }
                                .tint(LexColor.brand)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .searchable(text: $query, prompt: LexStrings.t("notes.search", store.language))
            }
        }
        .background(LexColor.canvas.ignoresSafeArea())
        .navigationTitle(LexStrings.t("account.saved", store.language))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingItem) { item in
            NoteEditorSheet(item: item) { target in
                editingItem = nil
                Task {
                    try? await Task.sleep(for: .milliseconds(380))
                    pushTarget = target
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(LexColor.surface)
        }
        .navigationDestination(item: $pushTarget) { target in
            SectionReaderView(actId: target.actId, startSectionId: target.sectionId)
        }
    }

    private func noteRow(item: SavedItem, section: LegalSection) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(section.number)
                    .font(LexFont.display(18, .semibold).monospacedDigit())
                    .foregroundStyle(LexColor.brand)
                Text(section.title)
                    .font(LexFont.sans(15, .medium))
                    .foregroundStyle(LexColor.ink)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(LexColor.saffronDeep)
            }
            Text(data.act(section.actId).map { LexLocalize.actName($0, store.language) } ?? "")
                .font(LexFont.sans(12))
                .foregroundStyle(LexColor.slate)
            if item.note.isEmpty {
                Text(LexStrings.t("notes.add", store.language))
                    .font(LexFont.sans(13))
                    .italic()
                    .foregroundStyle(LexColor.slate.opacity(0.7))
            } else {
                Text(item.note)
                    .font(LexFont.sans(14))
                    .foregroundStyle(LexColor.ink)
                    .lineLimit(2)
            }
            Text(LexStrings.f("notes.savedOn", store.language, LexLocalize.date(item.savedAt, store.language)))
                .font(LexFont.sans(11))
                .foregroundStyle(LexColor.slate.opacity(0.8))
        }
        .padding(.vertical, 6)
    }
}

struct NoteEditorSheet: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: SavedItem
    let onOpenSection: (ReaderTarget) -> Void

    @State private var noteText: String = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let section = data.section(item.sectionId) {
                VStack(alignment: .leading, spacing: 4) {
                    LexOverline(text: LexStrings.t("notes.your", store.language), color: LexColor.saffronDeep)
                    Text("\(section.number) · \(section.title)")
                        .font(LexFont.display(20, .semibold))
                        .foregroundStyle(LexColor.ink)
                    Text(data.act(section.actId).map { LexLocalize.actName($0, store.language) } ?? "")
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.slate)
                }
                .padding(.top, 24)

                TextEditor(text: $noteText)
                    .font(LexFont.sans(15))
                    .foregroundStyle(LexColor.ink)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 140, maxHeight: 220)
                    .background(LexColor.canvas)
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(LexColor.hairline, lineWidth: 1)
                    )
                    .focused($noteFocused)
                    .padding(.top, 16)
                    .accessibilityLabel("Note text")

                Button(LexStrings.t("notes.saveNote", store.language)) {
                    store.updateNote(for: item.sectionId, note: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .buttonStyle(LexPrimaryButtonStyle())
                .padding(.top, 16)

                Button {
                    onOpenSection(ReaderTarget(actId: section.actId, sectionId: section.id))
                } label: {
                    HStack(spacing: 5) {
                        Text(LexStrings.t("evakeel.openSection", store.language))
                            .font(LexFont.sans(15, .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(LexColor.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(LexPressStyle())
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .background(LexColor.surface)
        .onAppear {
            noteText = item.note
            if item.note.isEmpty { noteFocused = true }
        }
    }
}
