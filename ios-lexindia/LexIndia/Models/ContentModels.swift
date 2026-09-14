//
//  ContentModels.swift
//  LexIndia
//
//  Models for the content ecosystem: legal updates, documents and the
//  interface language. Shaped so mock catalogs can later be replaced by
//  a production editorial backend without UI changes.
//

import Foundation

// MARK: - Interface language

/// Supported interface languages. Add new Indian languages here — the
/// settings screen, storage and string tables pick them up automatically.
nonisolated enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case hindi = "hi"

    var id: String { rawValue }

    /// Name in the language itself.
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी"
        }
    }

    /// English reference name.
    var englishName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "Hindi"
        }
    }
}

// MARK: - Appearance

/// Interface appearance. `.system` follows the iPhone's light/dark setting
/// and is the default for everyone.
nonisolated enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var detail: String {
        switch self {
        case .system: return "Match your iPhone appearance"
        case .light: return "Bright canvas, deep bold ink"
        case .dark: return "Deep purple canvas, light ink"
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    /// Localized display name.
    func label(_ language: AppLanguage) -> String {
        LexStrings.t("theme.\(rawValue)", language)
    }

    /// Localized description line.
    func detail(_ language: AppLanguage) -> String {
        LexStrings.t("theme.\(rawValue).detail", language)
    }
}

// MARK: - Legal updates

/// Editorial category of a legal update.
nonisolated enum UpdateCategory: String, CaseIterable, Identifiable, Hashable {
    case supremeCourt = "supreme-court"
    case highCourt = "high-court"
    case judgment = "judgment"
    case newLaw = "new-law"
    case amendment = "amendment"
    case notification = "notification"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .supremeCourt: return "Supreme Court"
        case .highCourt: return "High Courts"
        case .judgment: return "Judgments"
        case .newLaw: return "New laws"
        case .amendment: return "Amendments"
        case .notification: return "Notifications"
        }
    }

    var symbol: String {
        switch self {
        case .supremeCourt: return "building.columns"
        case .highCourt: return "building.2"
        case .judgment: return "text.quote"
        case .newLaw: return "sparkles"
        case .amendment: return "square.and.pencil"
        case .notification: return "bell"
        }
    }

    /// Stable pastel identity per category.
    var pastelIndex: Int {
        UpdateCategory.allCases.firstIndex(of: self) ?? 0
    }
}

/// One LexIndia editorial summary. The production pipeline will follow
/// Source → Review → LexIndia summary → Publish; for now entries are
/// demo content clearly marked in the UI.
nonisolated struct LegalUpdate: Identifiable, Hashable {
    let id: String
    let category: UpdateCategory
    let title: String
    /// Editorial source line, e.g. "LexIndia Desk · demo summary".
    let source: String
    let dateLabel: String
    /// One-line list summary.
    let snippet: String
    /// Full summary paragraphs.
    let body: [String]
    /// Sections in the library this update relates to.
    let relatedSectionIds: [String]
}

// MARK: - Documents

/// What a document is for — drives grouping and whether it can leave the app.
nonisolated enum DocumentKind: String, CaseIterable, Identifiable, Hashable {
    case bareAct = "bare-act"
    case courtForm = "court-form"
    case examNote = "exam-note"
    case previousPaper = "previous-paper"
    case revision = "revision"

    var id: String { rawValue }

    var groupTitle: String {
        switch self {
        case .bareAct: return "Bare Acts"
        case .courtForm: return "Court forms"
        case .examNote: return "Exam notes"
        case .previousPaper: return "Previous year papers"
        case .revision: return "Revision material"
        }
    }

    var groupBlurb: String {
        switch self {
        case .bareAct: return "Official texts — read inside LexIndia"
        case .courtForm: return "Practical formats — download and print"
        case .examNote: return "LexIndia notes for exam preparation"
        case .previousPaper: return "Practice papers for self-testing"
        case .revision: return "Compact charts for a final read"
        }
    }

    /// Bare Acts stay inside LexIndia; everything else can be downloaded.
    var isDownloadable: Bool { self != .bareAct }

    var badgeLabel: String { isDownloadable ? "PDF" : "Read in app" }

    /// Localized long-form access label for detail headers.
    func accessLabel(_ language: AppLanguage) -> String {
        LexStrings.t(isDownloadable ? "docs.downloadPdf" : "docs.readInApp", language)
    }

    var symbol: String {
        switch self {
        case .bareAct: return "building.columns"
        case .courtForm: return "doc.text"
        case .examNote: return "graduationcap"
        case .previousPaper: return "doc.on.doc"
        case .revision: return "checklist"
        }
    }
}

/// One document in the Documents area. Bare Acts point at an Act in the
/// library; downloadable documents carry their content for reading and
/// for the generated PDF.
nonisolated struct LexDocument: Identifiable, Hashable {
    let id: String
    let kind: DocumentKind
    let title: String
    let summary: String
    /// Meta line, e.g. "2 pages · Updated Aug 2026".
    let meta: String
    /// For Bare Acts: the Act to open in the reader.
    let actId: String?
    /// Content paragraphs (reading view + generated PDF).
    let body: [String]

    var isDownloadable: Bool { kind.isDownloadable }
    var fileName: String { "\(id).pdf" }
}
