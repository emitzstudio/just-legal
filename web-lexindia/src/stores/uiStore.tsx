/**
 * Cross-screen UI coordination: the universal search overlay, the
 * E-Vakeel assistant overlay, the plans sheet, the buy-credits sheet and
 * the read-aloud service. Ported from UIState + SpeechService.
 */

import createContextHook from "@nkzw/create-context-hook";
import { useCallback, useEffect, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";

export type LexTab = "myspace" | "library" | "list" | "students" | "account";

export const TAB_PATHS: Record<LexTab, string> = {
  myspace: "/myspace",
  library: "/library",
  list: "/",
  students: "/students",
  account: "/account",
};

/** Which hub a route belongs to, for tab highlighting. */
export function tabForPath(pathname: string): LexTab {
  if (pathname === "/" || pathname.startsWith("/list")) return "list";
  if (pathname.startsWith("/myspace")) return "myspace";
  if (pathname.startsWith("/students") || pathname.startsWith("/quiz")) return "students";
  if (pathname.startsWith("/account") || pathname.startsWith("/settings")) return "account";
  return "library";
}

export const [UIProvider, useUI] = createContextHook(() => {
  const navigate = useNavigate();
  const location = useLocation();

  const [searchPresented, setSearchPresented] = useState<boolean>(false);
  const [evakeelPresented, setEvakeelPresented] = useState<boolean>(false);
  const [plansPresented, setPlansPresented] = useState<boolean>(false);
  const [creditsPresented, setCreditsPresented] = useState<boolean>(false);

  // MARK: Read aloud (AVSpeechSynthesizer → Web Speech API)

  const [speechActiveId, setSpeechActiveId] = useState<string | null>(null);
  const [speechPaused, setSpeechPaused] = useState<boolean>(false);
  const utteranceRef = useRef<SpeechSynthesisUtterance | null>(null);
  const speechSupported = typeof window !== "undefined" && "speechSynthesis" in window;

  const stopSpeech = useCallback(() => {
    if (speechSupported) window.speechSynthesis.cancel();
    utteranceRef.current = null;
    setSpeechActiveId(null);
    setSpeechPaused(false);
  }, [speechSupported]);

  /** Starts reading a page, or toggles pause/resume when already active. */
  const toggleSpeech = useCallback(
    (id: string, text: string) => {
      if (!speechSupported) return;
      const synth = window.speechSynthesis;
      if (speechActiveId === id) {
        if (speechPaused) {
          synth.resume();
          setSpeechPaused(false);
        } else {
          synth.pause();
          setSpeechPaused(true);
        }
        return;
      }
      synth.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      const voices = synth.getVoices();
      utterance.voice =
        voices.find((voice) => voice.lang === "en-IN") ??
        voices.find((voice) => voice.lang === "en-GB") ??
        voices.find((voice) => voice.lang.startsWith("en")) ??
        null;
      utterance.lang = utterance.voice?.lang ?? "en-IN";
      utterance.rate = 0.95;
      utterance.onend = () => {
        if (utteranceRef.current === utterance) {
          utteranceRef.current = null;
          setSpeechActiveId(null);
          setSpeechPaused(false);
        }
      };
      utterance.onerror = utterance.onend;
      utteranceRef.current = utterance;
      setSpeechActiveId(id);
      setSpeechPaused(false);
      synth.speak(utterance);
    },
    [speechActiveId, speechPaused, speechSupported],
  );

  // Changing screens stops any reading, like switching tabs on iOS.
  useEffect(() => {
    stopSpeech();
  }, [location.pathname, stopSpeech]);

  // MARK: Overlays & navigation

  const activateSearch = useCallback(() => setSearchPresented(true), []);
  const closeSearch = useCallback(() => setSearchPresented(false), []);
  const openEVakeel = useCallback(() => setEvakeelPresented(true), []);
  const closeEVakeel = useCallback(() => setEvakeelPresented(false), []);

  /** Switches to a hub, closing any overlays. */
  const openTab = useCallback(
    (tab: LexTab) => {
      setSearchPresented(false);
      setEvakeelPresented(false);
      navigate(TAB_PATHS[tab]);
    },
    [navigate],
  );

  /** Jumps to the Quiz section inside Students Corner from anywhere. */
  const openQuizzes = useCallback(() => {
    setSearchPresented(false);
    setEvakeelPresented(false);
    navigate("/quiz");
  }, [navigate]);

  /** Opens a route and dismisses overlays — used by overlay result rows. */
  const go = useCallback(
    (path: string) => {
      setSearchPresented(false);
      setEvakeelPresented(false);
      navigate(path);
    },
    [navigate],
  );

  return {
    searchPresented,
    evakeelPresented,
    plansPresented,
    creditsPresented,
    setPlansPresented,
    setCreditsPresented,
    activateSearch,
    closeSearch,
    openEVakeel,
    closeEVakeel,
    openTab,
    openQuizzes,
    go,
    speech: {
      supported: speechSupported,
      activeId: speechActiveId,
      isPaused: speechPaused,
      toggle: toggleSpeech,
      stop: stopSpeech,
    },
  };
});
