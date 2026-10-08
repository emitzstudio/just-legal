/**
 * Locally persisted user state: profile, credits, saved sections and
 * notes, recents, search history, downloads, the E-Vakeel conversation,
 * quiz rewards and interface preferences. Ported from UserDataStore.
 */

import createContextHook from "@nkzw/create-context-hook";
import { useCallback, useEffect, useMemo, useState } from "react";

import {
  QuizConfig,
  type AppLanguage,
  type CreditTransaction,
  type DownloadRecord,
  type EVakeelRecord,
  type RecentItem,
  type SavedItem,
  type ThemeMode,
  type UserSnapshot,
} from "@/lib/models";
import { currentWeekId, loadJSON, saveJSON, uuid } from "@/lib/storage";

const STORAGE_KEY = "lexindia.user.v1";
const WELCOME_CREDITS = 24;

const freshSnapshot = (): UserSnapshot => ({
  profileName: "Arjun",
  credits: WELCOME_CREDITS,
  creditHistory: [{ id: uuid(), date: new Date().toISOString(), delta: WELCOME_CREDITS, reason: "Welcome credits" }],
  isSubscribed: false,
  planName: null,
  subscribedAt: null,
  saved: [],
  recents: [],
  recentSearches: [],
  savedDefinitionIds: [],
  downloads: [],
  language: "en",
  themeMode: "system",
  evakeelRecords: [],
  quizWeeklyClaimWeek: null,
  quizzesPlayed: 0,
  quizPerfectStreak: 0,
  evakeelDockOnRight: true,
  evakeelDockY: 0.58,
});

const loadSnapshot = (): UserSnapshot => {
  const stored = loadJSON<Partial<UserSnapshot>>(STORAGE_KEY);
  if (!stored) return freshSnapshot();
  return { ...freshSnapshot(), ...stored, creditHistory: stored.creditHistory ?? [] };
};

export const [UserProvider, useUser] = createContextHook(() => {
  const [state, setState] = useState<UserSnapshot>(loadSnapshot);

  useEffect(() => {
    saveJSON(STORAGE_KEY, state);
  }, [state]);

  const update = useCallback((patch: (previous: UserSnapshot) => Partial<UserSnapshot>) => {
    setState((previous) => ({ ...previous, ...patch(previous) }));
  }, []);

  // MARK: Profile

  const setName = useCallback(
    (name: string) => {
      const trimmed = name.trim();
      if (!trimmed) return;
      update(() => ({ profileName: trimmed.slice(0, 24) }));
    },
    [update],
  );

  // MARK: Saved sections & notes

  const isSaved = useCallback((sectionId: string) => state.saved.some((item) => item.sectionId === sectionId), [state.saved]);

  /** Toggles the bookmark. Returns true when the section is now saved. */
  const toggleSaved = useCallback(
    (sectionId: string): boolean => {
      const currentlySaved = state.saved.some((item) => item.sectionId === sectionId);
      update((previous) => ({
        saved: currentlySaved
          ? previous.saved.filter((item) => item.sectionId !== sectionId)
          : [{ sectionId, note: "", savedAt: new Date().toISOString(), editedAt: null }, ...previous.saved],
      }));
      return !currentlySaved;
    },
    [state.saved, update],
  );

  const savedItem = useCallback(
    (sectionId: string): SavedItem | undefined => state.saved.find((item) => item.sectionId === sectionId),
    [state.saved],
  );

  const updateNote = useCallback(
    (sectionId: string, note: string) => {
      update((previous) => ({
        saved: previous.saved.map((item) =>
          item.sectionId === sectionId ? { ...item, note, editedAt: new Date().toISOString() } : item,
        ),
      }));
    },
    [update],
  );

  const removeSaved = useCallback(
    (sectionId: string) => update((previous) => ({ saved: previous.saved.filter((item) => item.sectionId !== sectionId) })),
    [update],
  );

  // MARK: Saved definitions

  const isDefinitionSaved = useCallback((id: string) => state.savedDefinitionIds.includes(id), [state.savedDefinitionIds]);

  const toggleSavedDefinition = useCallback(
    (id: string) =>
      update((previous) => ({
        savedDefinitionIds: previous.savedDefinitionIds.includes(id)
          ? previous.savedDefinitionIds.filter((item) => item !== id)
          : [id, ...previous.savedDefinitionIds],
      })),
    [update],
  );

  // MARK: Recents & searches

  const recordVisit = useCallback(
    (sectionId: string) =>
      update((previous) => {
        const item: RecentItem = { sectionId, date: new Date().toISOString() };
        return { recents: [item, ...previous.recents.filter((recent) => recent.sectionId !== sectionId)].slice(0, 20) };
      }),
    [update],
  );

  const clearRecents = useCallback(() => update(() => ({ recents: [] })), [update]);

  const recordSearch = useCallback(
    (query: string) => {
      const trimmed = query.trim();
      if (trimmed.length <= 1) return;
      update((previous) => ({
        recentSearches: [
          trimmed,
          ...previous.recentSearches.filter((item) => item.toLowerCase() !== trimmed.toLowerCase()),
        ].slice(0, 8),
      }));
    },
    [update],
  );

  const clearSearches = useCallback(() => update(() => ({ recentSearches: [] })), [update]);

  // MARK: Downloads

  const isDownloaded = useCallback(
    (documentId: string) => state.downloads.some((record) => record.documentId === documentId),
    [state.downloads],
  );

  const downloadRecord = useCallback(
    (documentId: string): DownloadRecord | undefined => state.downloads.find((record) => record.documentId === documentId),
    [state.downloads],
  );

  const recordDownload = useCallback(
    (record: DownloadRecord) =>
      update((previous) => ({
        downloads: [record, ...previous.downloads.filter((item) => item.documentId !== record.documentId)],
      })),
    [update],
  );

  const removeDownload = useCallback(
    (documentId: string) =>
      update((previous) => ({ downloads: previous.downloads.filter((record) => record.documentId !== documentId) })),
    [update],
  );

  // MARK: Interface language & appearance

  const setLanguage = useCallback((language: AppLanguage) => update(() => ({ language })), [update]);
  const setThemeMode = useCallback((themeMode: ThemeMode) => update(() => ({ themeMode })), [update]);

  // MARK: Credits

  const creditsUsed = useMemo(
    () => state.creditHistory.filter((item) => item.delta < 0).reduce((total, item) => total - item.delta, 0),
    [state.creditHistory],
  );
  const creditsAdded = useMemo(
    () => state.creditHistory.filter((item) => item.delta > 0).reduce((total, item) => total + item.delta, 0),
    [state.creditHistory],
  );
  const isLowOnCredits = state.credits > 0 && state.credits <= 5;

  const spendCredits = useCallback(
    (amount: number, reason: string): boolean => {
      if (amount <= 0 || state.credits < amount) return false;
      const transaction: CreditTransaction = { id: uuid(), date: new Date().toISOString(), delta: -amount, reason };
      update((previous) => ({ credits: previous.credits - amount, creditHistory: [transaction, ...previous.creditHistory] }));
      return true;
    },
    [state.credits, update],
  );

  const addCredits = useCallback(
    (amount: number, reason: string) => {
      if (amount <= 0) return;
      const transaction: CreditTransaction = { id: uuid(), date: new Date().toISOString(), delta: amount, reason };
      update((previous) => ({ credits: previous.credits + amount, creditHistory: [transaction, ...previous.creditHistory] }));
    },
    [update],
  );

  // MARK: E-Vakeel conversation

  const appendEVakeel = useCallback(
    (record: EVakeelRecord) =>
      update((previous) => ({ evakeelRecords: [...previous.evakeelRecords, record].slice(-80) })),
    [update],
  );

  const clearEVakeel = useCallback(() => update(() => ({ evakeelRecords: [] })), [update]);

  const setEVakeelDock = useCallback(
    (onRight: boolean, yFraction: number) =>
      update(() => ({ evakeelDockOnRight: onRight, evakeelDockY: Math.min(Math.max(yFraction, 0.12), 0.74) })),
    [update],
  );

  // MARK: Weekly quiz reward

  const isWeeklyQuizRewardAvailable = state.quizWeeklyClaimWeek !== currentWeekId();
  const isRewardStreakComplete = state.quizPerfectStreak >= QuizConfig.streakTarget;

  /**
   * Records a finished quiz and advances the perfect-score streak. A
   * completed streak is kept until the reward is claimed.
   */
  const recordQuizFinished = useCallback(
    (isPerfect: boolean) =>
      update((previous) => {
        let streak = previous.quizPerfectStreak;
        if (isPerfect) streak = Math.min(streak + 1, QuizConfig.streakTarget);
        else if (streak < QuizConfig.streakTarget) streak = 0;
        return { quizzesPlayed: previous.quizzesPlayed + 1, quizPerfectStreak: streak };
      }),
    [update],
  );

  /**
   * Claims the weekly reward once per ISO week — only after the streak is
   * complete. Claiming starts a fresh streak. Evaluated against the
   * freshest state so it composes with recordQuizFinished in one tick.
   */
  const claimWeeklyQuizReward = useCallback(
    (amount: number, quizLabel: string): boolean => {
      let claimed = false;
      setState((previous) => {
        const available = previous.quizWeeklyClaimWeek !== currentWeekId();
        const complete = previous.quizPerfectStreak >= QuizConfig.streakTarget;
        if (!available || !complete || amount <= 0) return previous;
        claimed = true;
        const transaction: CreditTransaction = {
          id: uuid(),
          date: new Date().toISOString(),
          delta: amount,
          reason: `Weekly quiz reward — ${quizLabel}`,
        };
        return {
          ...previous,
          quizWeeklyClaimWeek: currentWeekId(),
          quizPerfectStreak: 0,
          credits: previous.credits + amount,
          creditHistory: [transaction, ...previous.creditHistory],
        };
      });
      return claimed;
    },
    [],
  );

  return {
    ...state,
    setName,
    isSaved,
    toggleSaved,
    savedItem,
    updateNote,
    removeSaved,
    isDefinitionSaved,
    toggleSavedDefinition,
    recordVisit,
    clearRecents,
    recordSearch,
    clearSearches,
    isDownloaded,
    downloadRecord,
    recordDownload,
    removeDownload,
    setLanguage,
    setThemeMode,
    creditsUsed,
    creditsAdded,
    isLowOnCredits,
    spendCredits,
    addCredits,
    appendEVakeel,
    clearEVakeel,
    setEVakeelDock,
    isWeeklyQuizRewardAvailable,
    isRewardStreakComplete,
    recordQuizFinished,
    claimWeeklyQuizReward,
  };
});
