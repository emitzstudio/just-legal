//
//  UIState.swift
//  LexIndia
//
//  Cross-tab UI coordination: selected tab, the universal search overlay,
//  the E-Vakeel assistant overlay, cross-tab navigation into Students
//  Corner, and the plans sheet.
//

import Foundation
import Observation

enum LexTab: Hashable {
    case mySpace
    case library
    case list
    case students
    case account
}

@Observable
final class UIState {
    /// The experience starts at the List — the app-wide index from which
    /// the user chooses where to go.
    var selectedTab: LexTab = .list

    /// Presents the plans sheet from anywhere in the main experience.
    var plansPresented: Bool = false

    /// The universal search overlay — reachable from every hub.
    var searchPresented: Bool = false

    /// The E-Vakeel assistant overlay above the current screen.
    var evakeelPresented: Bool = false

    /// Navigation path of the Students Corner tab, so other tabs can
    /// deep-link into it (e.g. the My Space quiz shortcut).
    var studentsPath: [Destination] = []

    func activateSearch() {
        searchPresented = true
    }

    /// Jumps to the Quiz section inside Students Corner from anywhere.
    func openQuizzes() {
        searchPresented = false
        evakeelPresented = false
        selectedTab = .students
        studentsPath = [.quizzes]
    }

    /// Switches to a hub tab from the List index, closing any overlays.
    func openTab(_ tab: LexTab) {
        searchPresented = false
        evakeelPresented = false
        selectedTab = tab
    }

    func openEVakeel() {
        evakeelPresented = true
    }
}
