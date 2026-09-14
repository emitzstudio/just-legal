//
//  LexComponents.swift
//  LexIndia
//
//  Shared components: overlines, hairlines, dividers, empty states,
//  prepared panels, section rows, close/search buttons, the Read Aloud
//  control and the selective-translation modifier.
//

import SwiftUI
import Translation

/// Small-caps label marking an information type. Natural spacing — no
/// letter tracking, so titles never read as "P e t t y".
struct LexOverline: View {
    let text: String
    var color: Color = LexColor.slate

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
    }
}

/// Fine printed rule.
struct LexHairline: View {
    var body: some View {
        Rectangle()
            .fill(LexColor.hairline)
            .frame(height: 0.8)
    }
}

/// Small rotated saffron square — LexIndia's quiet Indian ornament.
struct AccentDiamond: View {
    var size: CGFloat = 6
    var color: Color = LexColor.saffron

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
    }
}

/// Double rule with a centred saffron diamond — the letterhead divider.
struct BenchDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            LexHairline()
            AccentDiamond()
            LexHairline()
        }
        .accessibilityHidden(true)
    }
}

/// The recurring legal-positioning footnote.
struct TrustFootnote: View {
    @Environment(UserDataStore.self) private var store

    var body: some View {
        Text(LexStrings.t("trust.footnote", store.language))
            .font(LexFont.sans(12))
            .foregroundStyle(LexColor.slate)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }
}

/// Consistent circular close for sheets and overlays.
struct LexCloseButton: View {
    var action: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(LexColor.slate)
                .frame(width: 32, height: 32)
                .background(Circle().fill(LexColor.canvas))
                .overlay(Circle().strokeBorder(LexColor.hairline, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("Close")
    }
}

/// Circular universal-search entry used in every hub header.
struct LexSearchButton: View {
    @Environment(UIState.self) private var ui

    var body: some View {
        Button {
            ui.activateSearch()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LexColor.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(LexColor.surface))
                .overlay(Circle().strokeBorder(LexColor.hairline, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(LexPressStyle())
        .accessibilityLabel("Search LexIndia")
    }
}

/// Designed empty state — friendly badge, calm copy.
struct LexEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(LexColor.brand)
                .frame(width: 64, height: 64)
                .background(Circle().fill(LexColor.brandSoft))
            Text(title)
                .font(LexFont.display(18, .semibold))
                .foregroundStyle(LexColor.ink)
            Text(message)
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.slate)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 44)
    }
}

/// Panel for content that exists in the dataset roadmap but is not yet loaded.
struct PreparedPanel: View {
    @Environment(UserDataStore.self) private var store

    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LexOverline(text: LexStrings.t("prepared.title", store.language), color: LexColor.saffronDeep)
            Text(message)
                .font(LexFont.sans(14))
                .foregroundStyle(LexColor.slate)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(LexColor.saffronSoft)
        .clipShape(.rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LexColor.saffron.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
    }
}

/// Compact scannable row for a legal section.
struct SectionRowView: View {
    @Environment(UserDataStore.self) private var rowStore

    let number: String
    let title: String
    var subtitle: String? = nil
    var showsChevron: Bool = true
    /// Marks sections that carry a hand-written plain-language guide.
    var showsGuideBadge: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(number)
                .font(LexFont.display(19, .bold).monospacedDigit())
                .foregroundStyle(LexColor.brand)
                .frame(minWidth: 46, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LexFont.sans(16, .medium))
                    .foregroundStyle(LexColor.ink)
                    .multilineTextAlignment(.leading)
                if let subtitle {
                    Text(subtitle)
                        .font(LexFont.sans(12))
                        .foregroundStyle(LexColor.slate)
                }
            }
            Spacer(minLength: 8)
            if showsGuideBadge {
                Text(LexStrings.t("guide.badge", rowStore.language))
                    .font(LexFont.sans(10, .semibold))
                    .foregroundStyle(LexColor.mintDeep)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(LexColor.mint))
                    .accessibilityLabel("Plain-language guide available")
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LexColor.faint)
            }
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

/// Shared case-law row used in Library, Search and Case Laws screens.
struct CaseLawRow: View {
    let caseLaw: CaseLaw

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caseLaw.title)
                    .font(LexFont.display(16, .semibold))
                    .foregroundStyle(LexColor.ink)
                    .multilineTextAlignment(.leading)
                Text("\(caseLaw.court) · \(String(caseLaw.year))")
                    .font(LexFont.sans(12))
                    .foregroundStyle(LexColor.slate)
                Text(caseLaw.principle)
                    .font(LexFont.sans(13))
                    .foregroundStyle(LexColor.slate)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LexColor.faint)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Read Aloud

/// Subtle speaker control for information pages. Idle: "Listen" chip.
/// Playing: pause/resume plus stop. One page at a time.
struct ReadAloudControl: View {
    @Environment(SpeechService.self) private var speech
    @Environment(UserDataStore.self) private var store

    /// Stable identity of the page's content.
    let id: String
    /// What gets spoken.
    let text: String

    private var isActive: Bool { speech.activeId == id }

    var body: some View {
        HStack(spacing: 6) {
            Button {
                speech.toggle(id: id, text: text)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: mainSymbol)
                        .font(.system(size: 12, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                    if !isActive {
                        Text(LexStrings.t("readaloud.listen", store.language))
                            .font(LexFont.sans(12, .semibold))
                    }
                }
                .foregroundStyle(isActive ? LexColor.onBrand : LexColor.brand)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Capsule().fill(isActive ? LexColor.brand : LexColor.brandSoft))
                .contentShape(Capsule())
            }
            .buttonStyle(LexPressStyle())
            .accessibilityLabel(isActive ? (speech.isPaused ? "Resume reading" : "Pause reading") : "Read this page aloud")

            if isActive {
                Button {
                    speech.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LexColor.slate)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(LexColor.surface))
                        .overlay(Circle().strokeBorder(LexColor.hairline, lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(LexPressStyle())
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(LexStrings.t("readaloud.stop", store.language))
            }
        }
        .animation(.spring(duration: 0.3), value: isActive)
        .animation(.easeOut(duration: 0.15), value: speech.isPaused)
    }

    private var mainSymbol: String {
        guard isActive else { return "speaker.wave.2" }
        return speech.isPaused ? "play.fill" : "pause.fill"
    }
}

// MARK: - Selective translation

/// Long-press a readable block → "Translate to Hindi" → the system
/// translation sheet translates ONLY that content. The global language
/// setting is untouched.
private struct LexTranslatableModifier: ViewModifier {
    @Environment(UserDataStore.self) private var store

    let text: String

    @State private var presented: Bool = false

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    presented = true
                } label: {
                    Label(LexStrings.t("translate.action", store.language), systemImage: "translate")
                }
            }
            .translationPresentation(isPresented: $presented, text: text)
    }
}

extension View {
    /// Adds the selective "Translate to Hindi" long-press action to a
    /// readable block, translating only that content.
    func lexTranslatable(_ text: String) -> some View {
        modifier(LexTranslatableModifier(text: text))
    }
}

/// Wrapping layout for topic chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let width = maxWidth == .infinity ? max(x - spacing, 0) : maxWidth
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
