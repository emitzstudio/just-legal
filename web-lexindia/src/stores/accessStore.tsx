/**
 * Authentication and entitlement state: account, subscription, the
 * 24-hour trial with its reminder schedule, and dev test access.
 * Persisted locally; designed to be swapped for a production backend.
 * Ported from AccessStore.
 */

import createContextHook from "@nkzw/create-context-hook";
import { useCallback, useEffect, useMemo, useState } from "react";

import {
  DevConfig,
  PlanCatalog,
  TrialReminderSchedule,
  type AuthUser,
  type Entitlement,
  type SubscriptionPlan,
  type TrialReminder,
} from "@/lib/models";
import { loadJSON, saveJSON } from "@/lib/storage";

const STORAGE_KEY = "lexindia.access.v1";

interface AccessSnapshot {
  user: AuthUser | null;
  knownAccount: AuthUser | null;
  entitlement: Entitlement;
  hasUsedTrial: boolean;
  shownReminderIds: string[];
}

const freshSnapshot = (): AccessSnapshot => ({
  user: null,
  knownAccount: null,
  entitlement: { kind: "none" },
  hasUsedTrial: false,
  shownReminderIds: [],
});

const loadSnapshot = (): AccessSnapshot => ({ ...freshSnapshot(), ...(loadJSON<Partial<AccessSnapshot>>(STORAGE_KEY) ?? {}) });

const entitlementActive = (entitlement: Entitlement, now: number): boolean => {
  switch (entitlement.kind) {
    case "none":
      return false;
    case "trial":
    case "subscription":
      return now < new Date(entitlement.end).getTime();
    case "devUnlimited":
      return DevConfig.permanentTestAccessEnabled;
  }
};

export const [AccessProvider, useAccess] = createContextHook(() => {
  const [state, setState] = useState<AccessSnapshot>(loadSnapshot);
  /** The reminder currently presented, if any. Transient — not persisted. */
  const [activeReminder, setActiveReminder] = useState<TrialReminder | null>(null);
  /** Clock the UI reads for countdowns; refreshed by tick(). */
  const [now, setNow] = useState<number>(() => Date.now());

  useEffect(() => {
    saveJSON(STORAGE_KEY, state);
  }, [state]);

  // MARK: Derived state

  const isAuthenticated = state.user !== null;
  const hasAccess = entitlementActive(state.entitlement, now);

  const accessExpired = useMemo(() => {
    const { entitlement } = state;
    switch (entitlement.kind) {
      case "trial":
      case "subscription":
        return now >= new Date(entitlement.end).getTime();
      case "none":
        return false;
      case "devUnlimited":
        return !DevConfig.permanentTestAccessEnabled;
    }
  }, [state, now]);

  const expiredEntitlementWasTrial = state.entitlement.kind === "trial" && accessExpired;
  const isOnTrial = state.entitlement.kind === "trial" && hasAccess;
  const isDevAccess = state.entitlement.kind === "devUnlimited" && hasAccess;

  /** Seconds left in the trial, when one is running. */
  const trialRemaining: number | null =
    state.entitlement.kind === "trial" ? Math.max(0, (new Date(state.entitlement.end).getTime() - now) / 1000) : null;

  const subscriptionInfo = useMemo((): { plan: SubscriptionPlan; start: string; end: string } | null => {
    const { entitlement } = state;
    if (entitlement.kind !== "subscription") return null;
    const plan = PlanCatalog.plan(entitlement.planId);
    if (!plan || now >= new Date(entitlement.end).getTime()) return null;
    return { plan, start: entitlement.start, end: entitlement.end };
  }, [state, now]);

  // MARK: Authentication (preview — local only)

  const register = useCallback((name: string, email: string) => {
    const account: AuthUser = {
      name: name.trim().slice(0, 24),
      email: email.trim().toLowerCase(),
      joinedAt: new Date().toISOString(),
    };
    setState((previous) => ({ ...previous, user: account, knownAccount: account }));
  }, []);

  /** Signs into the account previously created on this device. */
  const signIn = useCallback(
    (email: string): boolean => {
      const normalized = email.trim().toLowerCase();
      if (!state.knownAccount || state.knownAccount.email !== normalized) return false;
      setState((previous) => ({ ...previous, user: previous.knownAccount }));
      return true;
    },
    [state.knownAccount],
  );

  const signOut = useCallback(() => {
    setActiveReminder(null);
    setState((previous) => ({ ...previous, user: null }));
  }, []);

  // MARK: Entitlements

  const startTrial = useCallback(() => {
    const start = Date.now();
    setNow(start);
    setActiveReminder(null);
    setState((previous) => ({
      ...previous,
      entitlement: { kind: "trial", start: new Date(start).toISOString(), end: new Date(start + 24 * 3600 * 1000).toISOString() },
      hasUsedTrial: true,
      shownReminderIds: [],
    }));
  }, []);

  const activateSubscription = useCallback((plan: SubscriptionPlan) => {
    const start = new Date();
    const end = new Date(start);
    end.setMonth(end.getMonth() + plan.months);
    setNow(start.getTime());
    setActiveReminder(null);
    setState((previous) => ({
      ...previous,
      entitlement: { kind: "subscription", planId: plan.id, start: start.toISOString(), end: end.toISOString() },
    }));
  }, []);

  /** Demo cancellation — access ends immediately in this preview. */
  const cancelSubscription = useCallback(() => {
    setActiveReminder(null);
    setState((previous) => ({ ...previous, entitlement: { kind: "none" } }));
  }, []);

  /** DEVELOPMENT ONLY — permanent test access, gated by DevConfig. */
  const activateDevAccess = useCallback(() => {
    if (!DevConfig.permanentTestAccessEnabled) return;
    setActiveReminder(null);
    setState((previous) => ({ ...previous, entitlement: { kind: "devUnlimited" } }));
  }, []);

  const endDevAccess = useCallback(() => {
    setState((previous) =>
      previous.entitlement.kind === "devUnlimited" ? { ...previous, entitlement: { kind: "none" } } : previous,
    );
  }, []);

  // MARK: Clock & reminders

  /**
   * Refreshes the clock, expires entitlements and surfaces the next due
   * trial reminder. Each scheduled reminder is shown at most once.
   */
  const tick = useCallback(() => {
    const current = Date.now();
    setNow(current);
    setState((previous) => {
      const { entitlement } = previous;
      if (entitlement.kind !== "trial" || current >= new Date(entitlement.end).getTime()) {
        setActiveReminder(null);
        return previous;
      }
      let shouldPresent = false;
      setActiveReminder((reminder) => {
        shouldPresent = reminder === null;
        return reminder;
      });
      const elapsedMinutes = Math.floor((current - new Date(entitlement.start).getTime()) / 60000);
      const shown = new Set(previous.shownReminderIds);
      const due = TrialReminderSchedule.filter((reminder) => reminder.offsetMinutes <= elapsedMinutes && !shown.has(reminder.id));
      if (due.length === 0 || !shouldPresent) return previous;
      const latest = due.reduce((best, reminder) => (reminder.offsetMinutes > best.offsetMinutes ? reminder : best));
      setActiveReminder(latest);
      return { ...previous, shownReminderIds: [...shown, ...due.map((reminder) => reminder.id)] };
    });
  }, []);

  const dismissReminder = useCallback(() => setActiveReminder(null), []);

  useEffect(() => {
    tick();
    const interval = window.setInterval(tick, 20000);
    const onVisibility = () => {
      if (document.visibilityState === "visible") tick();
    };
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      window.clearInterval(interval);
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, [tick]);

  return {
    user: state.user,
    knownAccount: state.knownAccount,
    entitlement: state.entitlement,
    hasUsedTrial: state.hasUsedTrial,
    activeReminder,
    now,
    isAuthenticated,
    hasAccess,
    accessExpired,
    expiredEntitlementWasTrial,
    isOnTrial,
    isDevAccess,
    trialRemaining,
    subscriptionInfo,
    register,
    signIn,
    signOut,
    startTrial,
    activateSubscription,
    cancelSubscription,
    activateDevAccess,
    endDevAccess,
    tick,
    dismissReminder,
  };
});

/** "21h 34m", "58m" or "under a minute". */
export function remainingLabel(seconds: number): string {
  const totalMinutes = Math.floor(seconds / 60);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours > 0) return `${hours}h ${minutes}m`;
  if (minutes > 0) return `${minutes}m`;
  return "under a minute";
}
