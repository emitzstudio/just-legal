//
//  SectionReaderView.swift
//  LexIndia
//
//  The signature reading environment: horizontal swipe between sections,
//  visible previous/next controls, and the Understand More sheet.
//

import SwiftUI

struct ReaderTarget: Identifiable, Hashable {
    let actId: String
    let sectionId: String
    var id: String { sectionId }
}

struct SectionReaderView: View {
    @Environment(LegalDataService.self) private var data
    @Environment(UserDataStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let actId: String
    let startSectionId: String

    @State private var currentId: String
    @State private var showUnderstand: Bool = false
    @State private var pushTarget: ReaderTarget?
    @State private var toast: String?

    init(actId: String, startSectionId: String) {
        self.actId = actId
        self.startSectionId = startSectionId
        _currentId = State(initialValue: startSectionId)
    }

    private var sections: [LegalSection] {
        data.sections(inAct: actId)
    }

    private var currentSection: LegalSection? {
        data.section(currentId)
    }

    private var neighbors: (previous: LegalSection?, next: LegalSection?) {
        guard let currentSection else { return (nil, nil) }
        return data.neighbors(of: currentSection)
    }

    var body: some View {
        TabView(selection: $currentId) {
            ForEach(sections) { section in
                SectionPageView(
                    section: section,
                    onNavigate: { targetId in navigate(to: targetId) },
                    onToggleSave: { toggleSave(section) }
                )
                .tag(section.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(LexColor.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(data.act(actId)?.displayShortName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    if let previous = neighbors.previous { navigate(to: previous.id) }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(neighbors.previous == nil)
                .accessibilityLabel(neighbors.previous.map { "Previous, Section \($0.number)" } ?? "No previous section")

                Button {
                    if let next = neighbors.next { navigate(to: next.id) }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(neighbors.next == nil)
                .accessibilityLabel(neighbors.next.map { "Next, Section \($0.number)" } ?? "No next section")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            UnderstandMoreBar(section: currentSection) {
                showUnderstand = true
            }
        }
        .sheet(isPresented: $showUnderstand) {
            if let section = currentSection {
                UnderstandMoreSheet(section: section) { targetId in
                    openFromSheet(targetId)
                }
                .presentationDetents([.fraction(0.52), .large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
                .presentationBackground(LexColor.surface)
            }
        }
        .navigationDestination(item: $pushTarget) { target in
            SectionReaderView(actId: target.actId, startSectionId: target.sectionId)
        }
        .sensoryFeedback(.selection, trigger: currentId)
        .onChange(of: currentId) { _, newValue in
            store.recordVisit(newValue)
        }
        .task {
            store.recordVisit(startSectionId)
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastView(text: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 6)
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: toast)
    }

    private func navigate(to sectionId: String) {
        guard data.section(sectionId) != nil else { return }
        if reduceMotion {
            currentId = sectionId
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentId = sectionId
            }
        }
    }

    private func openFromSheet(_ sectionId: String) {
        guard let target = data.section(sectionId) else { return }
        showUnderstand = false
        if target.actId == actId {
            navigate(to: sectionId)
        } else {
            Task {
                try? await Task.sleep(for: .milliseconds(380))
                pushTarget = ReaderTarget(actId: target.actId, sectionId: target.id)
            }
        }
    }

    private func toggleSave(_ section: LegalSection) {
        let nowSaved = store.toggleSaved(section.id)
        showToast(nowSaved ? "Saved to My Notes" : "Removed from My Notes")
    }

    private func showToast(_ text: String) {
        toast = text
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if toast == text { toast = nil }
        }
    }
}

private struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(LexFont.sans(13, .medium))
            .foregroundStyle(LexColor.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(LexColor.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(LexColor.hairline, lineWidth: 1)
            )
    }
}

/// Collapsed sheet edge: the visible "Understand more" affordance.
struct UnderstandMoreBar: View {
    @Environment(UserDataStore.self) private var store

    let section: LegalSection?
    let onOpen: () -> Void

    private var previewLine: String {
        guard let section else { return "" }
        let language = store.language
        var parts: [String] = []
        if section.example != nil { parts.append(LexStrings.t("understand.example", language)) }
        if !section.keyPoints.isEmpty { parts.append(LexStrings.t("understand.keypoints", language)) }
        if !section.relatedSectionIds.isEmpty { parts.append(LexStrings.t("understand.related", language)) }
        if !section.definitionIds.isEmpty { parts.append(LexStrings.t("understand.definitions", language)) }
        parts.append(LexStrings.t("reader.cases", language))
        return parts.joined(separator: " · ")
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 8) {
                Capsule()
                    .fill(LexColor.hairline)
                    .frame(width: 38, height: 4.5)
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LexStrings.t("reader.understand", store.language))
                            .font(LexFont.display(17, .semibold))
                            .foregroundStyle(LexColor.ink)
                        if !previewLine.isEmpty {
                            Text(previewLine)
                                .font(LexFont.sans(12))
                                .foregroundStyle(LexColor.slate)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LexColor.brand)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 9)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .background(
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, bottomLeading: 0, bottomTrailing: 0, topTrailing: 20))
                    .fill(LexColor.surface)
            )
            .overlay(
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, bottomLeading: 0, bottomTrailing: 0, topTrailing: 20))
                    .strokeBorder(LexColor.hairline, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(LexPressStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height < -18 { onOpen() }
                }
        )
        .accessibilityLabel("Understand more")
        .accessibilityHint("Opens example, key points, related sections and case laws")
    }
}
