//
//  ContentView.swift
//  LexIndia
//
//  Root flow: sign in → access gate → the main experience.
//  Hosts typed navigation destinations, the universal search overlay,
//  the floating E-Vakeel assistant and the trial reminders.
//

import SwiftUI

enum LegalPageKind: String, Hashable {
    case privacy
    case terms
    case disclaimer
}

enum Destination: Hashable {
    case category(String)
    case act(String)
    case chapter(String)
    case reader(actId: String, sectionId: String)
    case situation(String)
    case topic(String)
    case definitions
    case caseLaws
    case caseLaw(String)
    case ipcBns
    case notes
    case recents
    case creditHistory
    case legalPage(LegalPageKind)
    case legalUpdates
    case legalUpdate(String)
    case documents
    case document(String)
    case studyMaterial
    case downloads
    case language
    case appearance
    case appColor
    case quizzes
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var legalData = LegalDataService()
    @State private var userStore = UserDataStore()
    @State private var uiState = UIState()
    @State private var access = AccessStore()
    @State private var speech = SpeechService()

    private enum FlowPhase {
        case auth
        case paywall
        case main
    }

    private var phase: FlowPhase {
        if !access.isAuthenticated { return .auth }
        if !access.hasAccess { return .paywall }
        return .main
    }

    var body: some View {
        ZStack {
            switch phase {
            case .auth:
                AuthView()
                    .transition(.opacity)
            case .paywall:
                PaywallView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.32), value: phase)
        .tint(LexColor.brand)
        .environment(legalData)
        .environment(userStore)
        .environment(uiState)
        .environment(access)
        .environment(speech)
        .preferredColorScheme(userStore.themeMode.colorScheme)
        .onChange(of: access.hasAccess) { wasActive, isActive in
            // Entering the main experience starts at the Law Library hub.
            if !wasActive && isActive {
                uiState.selectedTab = .library
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                access.tick()
            }
        }
    }
}

// MARK: - Main tab experience

private struct MainTabView: View {
    @Environment(AccessStore.self) private var access
    @Environment(UIState.self) private var uiState
    @Environment(UserDataStore.self) private var store
    @Environment(SpeechService.self) private var speech

    var body: some View {
        @Bindable var ui = uiState
        TabView(selection: $ui.selectedTab) {
            Tab(LexStrings.t("tab.myspace", store.language), systemImage: "square.grid.2x2", value: LexTab.mySpace) {
                NavigationStack { MySpaceView().lexDestinations() }
            }
            Tab(LexStrings.t("tab.library", store.language), systemImage: "building.columns", value: LexTab.library) {
                NavigationStack { LibraryView().lexDestinations() }
            }
            Tab(LexStrings.t("tab.students", store.language), systemImage: "graduationcap", value: LexTab.students) {
                NavigationStack(path: $ui.studentsPath) { StudentsCornerView().lexDestinations() }
            }
            Tab(LexStrings.t("tab.account", store.language), systemImage: "person.crop.circle", value: LexTab.account) {
                NavigationStack { AccountView().lexDestinations() }
            }
        }
        .tint(LexColor.brand)
        .overlay(alignment: .bottom) {
            if let reminder = access.activeReminder, !uiState.evakeelPresented {
                TrialReminderCard(
                    reminder: reminder,
                    remaining: access.trialRemaining,
                    onSeePlans: {
                        access.dismissReminder()
                        uiState.plansPresented = true
                    },
                    onDismiss: {
                        access.dismissReminder()
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 58)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.45), value: access.activeReminder)
        .overlay {
            // The floating E-Vakeel assistant — draggable, above every screen.
            EVakeelFloatingLayer()
        }
        .overlay {
            if uiState.evakeelPresented {
                EVakeelOverlay()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(3)
            }
        }
        .animation(.spring(duration: 0.42), value: uiState.evakeelPresented)
        .fullScreenCover(isPresented: $ui.searchPresented) {
            UniversalSearchView()
        }
        .sheet(isPresented: $ui.plansPresented) {
            SubscriptionSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(LexColor.surface)
        }
        .onChange(of: uiState.selectedTab) { _, _ in
            speech.stop()
        }
        .task {
            access.tick()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(20))
                access.tick()
            }
        }
    }
}

extension View {
    func lexDestinations() -> some View {
        navigationDestination(for: Destination.self) { destination in
            DestinationView(destination: destination)
        }
    }
}

struct DestinationView: View {
    let destination: Destination

    var body: some View {
        switch destination {
        case .category(let id):
            CategoryDetailView(categoryId: id)
        case .act(let id):
            ActDetailView(actId: id)
        case .chapter(let id):
            ChapterSectionsView(chapterId: id)
        case .reader(let actId, let sectionId):
            SectionReaderView(actId: actId, startSectionId: sectionId)
        case .situation(let id):
            SituationDetailView(situationId: id)
        case .topic(let id):
            TopicSectionsView(topicId: id)
        case .definitions:
            DefinitionsView()
        case .caseLaws:
            CaseLawsView()
        case .caseLaw(let id):
            CaseLawDetailView(caseLawId: id)
        case .ipcBns:
            IPCBNSView()
        case .notes:
            NotesView()
        case .recents:
            RecentlyViewedView()
        case .creditHistory:
            CreditHistoryView()
        case .legalPage(let kind):
            LegalPageView(kind: kind)
        case .legalUpdates:
            LegalUpdatesView()
        case .legalUpdate(let id):
            LegalUpdateDetailView(updateId: id)
        case .documents:
            DocumentsView()
        case .document(let id):
            DocumentDetailView(documentId: id)
        case .studyMaterial:
            StudyMaterialView()
        case .downloads:
            MyDownloadsView()
        case .language:
            LanguageSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .appColor:
            AppColorSettingsView()
        case .quizzes:
            QuizSetupView()
        }
    }
}

#Preview {
    ContentView()
}
