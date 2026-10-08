/**
 * Root flow: sign in → access gate → the main experience. Hosts the
 * routes, the universal search overlay, the floating E-Vakeel assistant,
 * the membership / credits sheets and the trial reminders.
 */

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useEffect } from "react";
import { BrowserRouter, Navigate, Route, Routes, useLocation } from "react-router-dom";

import { EVakeelFloatingButton } from "@/components/evakeel/EVakeelButton";
import { EVakeelOverlay } from "@/components/evakeel/EVakeelOverlay";
import { SideBar, TabBar } from "@/components/shell/TabBar";
import { AccountScreen } from "@/screens/account/AccountScreen";
import { BuyCreditsSheet, CreditHistoryScreen } from "@/screens/account/CreditsScreens";
import { DownloadsScreen, RecentsScreen } from "@/screens/account/LibraryScreens";
import { NotesScreen } from "@/screens/account/NotesScreen";
import { AppColorScreen, AppearanceScreen, LanguageScreen, LegalPageScreen } from "@/screens/account/SettingsScreens";
import { SubscriptionSheet } from "@/screens/account/SubscriptionSheet";
import { IndexGroupScreen, IndexScreen } from "@/screens/index/IndexScreen";
import { ActScreen } from "@/screens/library/ActScreen";
import { CategoryScreen } from "@/screens/library/CategoryScreen";
import { ChapterScreen } from "@/screens/library/ChapterScreen";
import { DocumentDetailScreen, DocumentsScreen, StudyMaterialScreen } from "@/screens/library/DocumentsScreen";
import { LibraryScreen } from "@/screens/library/LibraryScreen";
import { SituationScreen, TopicScreen } from "@/screens/library/SituationScreen";
import { UpdateDetailScreen, UpdatesScreen } from "@/screens/library/UpdatesScreen";
import { MySpaceScreen } from "@/screens/myspace/MySpaceScreen";
import { AuthScreen } from "@/screens/onboarding/AuthScreen";
import { PaywallScreen } from "@/screens/onboarding/PaywallScreen";
import { TrialReminderCard } from "@/screens/onboarding/TrialReminderCard";
import { ReaderScreen } from "@/screens/reader/ReaderScreen";
import { SearchOverlay } from "@/screens/search/SearchOverlay";
import { QuizPlayScreen } from "@/screens/students/QuizPlayScreen";
import { QuizSetupScreen } from "@/screens/students/QuizSetupScreen";
import { StudentsCornerScreen } from "@/screens/students/StudentsCornerScreen";
import { CaseLawDetailScreen, CaseLawsScreen } from "@/screens/study/CaseLawsScreen";
import { DefinitionsScreen } from "@/screens/study/DefinitionsScreen";
import { IPCBNSScreen } from "@/screens/study/IPCBNSScreen";
import { AccessProvider, useAccess } from "@/stores/accessStore";
import { ThemeProvider } from "@/stores/themeStore";
import { UIProvider, useUI } from "@/stores/uiStore";
import { UserProvider } from "@/stores/userStore";

const queryClient = new QueryClient();

function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo({ top: 0 });
  }, [pathname]);
  return null;
}

function MainExperience() {
  const ui = useUI();
  const access = useAccess();

  return (
    <div className="min-h-screen bg-canvas lg:pl-[232px]">
      <SideBar />
      <ScrollToTop />
      <Routes>
        <Route path="/" element={<IndexScreen />} />
        <Route path="/list/:group" element={<IndexGroupScreen />} />
        <Route path="/myspace" element={<MySpaceScreen />} />
        <Route path="/library" element={<LibraryScreen />} />
        <Route path="/students" element={<StudentsCornerScreen />} />
        <Route path="/account" element={<AccountScreen />} />

        <Route path="/category/:id" element={<CategoryScreen />} />
        <Route path="/act/:id" element={<ActScreen />} />
        <Route path="/chapter/:id" element={<ChapterScreen />} />
        <Route path="/read/:actId/:sectionId" element={<ReaderScreen />} />
        <Route path="/situation/:id" element={<SituationScreen />} />
        <Route path="/topic/:id" element={<TopicScreen />} />

        <Route path="/ipc-bns" element={<IPCBNSScreen />} />
        <Route path="/definitions" element={<DefinitionsScreen />} />
        <Route path="/cases" element={<CaseLawsScreen />} />
        <Route path="/cases/:id" element={<CaseLawDetailScreen />} />
        <Route path="/documents" element={<DocumentsScreen />} />
        <Route path="/documents/:id" element={<DocumentDetailScreen />} />
        <Route path="/study" element={<StudyMaterialScreen />} />
        <Route path="/updates" element={<UpdatesScreen />} />
        <Route path="/updates/:id" element={<UpdateDetailScreen />} />

        <Route path="/quiz" element={<QuizSetupScreen />} />
        <Route path="/quiz/play" element={<QuizPlayScreen />} />

        <Route path="/notes" element={<NotesScreen />} />
        <Route path="/recents" element={<RecentsScreen />} />
        <Route path="/downloads" element={<DownloadsScreen />} />
        <Route path="/credits" element={<CreditHistoryScreen />} />
        <Route path="/settings/appearance" element={<AppearanceScreen />} />
        <Route path="/settings/color" element={<AppColorScreen />} />
        <Route path="/settings/language" element={<LanguageScreen />} />
        <Route path="/legal/:kind" element={<LegalPageScreen />} />

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      <TabBar />

      {access.activeReminder && !ui.evakeelPresented ? (
        <div className="pointer-events-none fixed inset-x-0 bottom-[78px] z-30 flex justify-center px-4 lg:bottom-6 lg:pl-[248px]">
          <div className="pointer-events-auto w-full max-w-[560px]">
            <TrialReminderCard
              reminder={access.activeReminder}
              remaining={access.trialRemaining}
              onSeePlans={() => {
                access.dismissReminder();
                ui.setPlansPresented(true);
              }}
              onDismiss={access.dismissReminder}
            />
          </div>
        </div>
      ) : null}

      <EVakeelFloatingButton />
      {ui.evakeelPresented ? <EVakeelOverlay /> : null}
      {ui.searchPresented ? <SearchOverlay /> : null}
      <SubscriptionSheet open={ui.plansPresented} onClose={() => ui.setPlansPresented(false)} />
      <BuyCreditsSheet open={ui.creditsPresented} onClose={() => ui.setCreditsPresented(false)} />
    </div>
  );
}

function Gate() {
  const access = useAccess();
  if (!access.isAuthenticated) return <AuthScreen />;
  if (!access.hasAccess) return <PaywallScreen />;
  return (
    <UIProvider>
      <MainExperience />
    </UIProvider>
  );
}

const App = () => (
  <QueryClientProvider client={queryClient}>
    <UserProvider>
      <ThemeProvider>
        <AccessProvider>
          <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
            <Gate />
          </BrowserRouter>
        </AccessProvider>
      </ThemeProvider>
    </UserProvider>
  </QueryClientProvider>
);

export default App;
