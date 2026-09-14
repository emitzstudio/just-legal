//
//  TrialReminderCard.swift
//  LexIndia
//
//  A polished, once-per-milestone reminder shown during the 24-hour trial.
//  Encouraging, never spammy — each scheduled reminder appears exactly once.
//

import SwiftUI

struct TrialReminderCard: View {
    @Environment(UserDataStore.self) private var store

    let reminder: TrialReminder
    let remaining: TimeInterval?
    let onSeePlans: () -> Void
    let onDismiss: () -> Void

    private var remainingLine: String {
        guard let remaining else { return LexStrings.t("trial.keep", store.language) }
        return LexStrings.f("trial.endsLine", store.language, LexLocalize.remaining(remaining, store.language))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                AccentDiamond(size: 7, color: LexColor.onBrand)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 3) {
                    Text(LexLocalize.reminderTitle(id: reminder.id, fallback: reminder.title, store.language))
                        .font(LexFont.display(16, .semibold))
                        .foregroundStyle(LexColor.onBrand)
                    Text(remainingLine)
                        .font(LexFont.sans(13))
                        .foregroundStyle(LexColor.onBrand.opacity(0.8))
                        .lineSpacing(2)
                }
                Spacer(minLength: 4)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LexColor.onBrand.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(LexColor.onBrand.opacity(0.12)))
                        .contentShape(Circle())
                }
                .buttonStyle(LexPressStyle())
                .accessibilityLabel("Dismiss reminder")
            }
            HStack(spacing: 10) {
                Button(action: onSeePlans) {
                    Text(LexStrings.t("myspace.seePlans", store.language))
                        .font(LexFont.sans(14, .semibold))
                        .foregroundStyle(LexColor.brand)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(LexColor.onBrand))
                }
                .buttonStyle(LexPressStyle())
                Button(action: onDismiss) {
                    Text(LexStrings.t("common.notNow", store.language))
                        .font(LexFont.sans(14, .medium))
                        .foregroundStyle(LexColor.onBrand.opacity(0.75))
                        .padding(.vertical, 9)
                }
                .buttonStyle(LexPressStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [LexColor.brand, LexColor.brandDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 18))
        .shadow(color: LexColor.brandDeep.opacity(0.35), radius: 18, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reminder.title). \(remainingLine)")
    }
}
