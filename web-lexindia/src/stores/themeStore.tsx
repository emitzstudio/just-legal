/**
 * The accent + appearance store. Keeps the chosen app colour, derives the
 * palette through the theme engine and applies the resolved tokens plus
 * the light/dark class to <html>, so every component reads the same CSS
 * variables the design system defines.
 */

import createContextHook from "@nkzw/create-context-hook";
import { useCallback, useEffect, useMemo, useState } from "react";

import { loadJSON, removeKey, saveJSON } from "@/lib/storage";
import { useUser } from "@/stores/userStore";
import {
  ACCENT_PRESETS,
  SIGNATURE_HEX,
  applyPalette,
  hexToCss,
  monochromePalette,
  signaturePalette,
  type AccentPreset,
  type DerivedPalette,
} from "@/lib/themeEngine";

const STORAGE_KEY = "lexindia.accent.v1";

const systemPrefersDark = (): boolean =>
  typeof window !== "undefined" && window.matchMedia("(prefers-color-scheme: dark)").matches;

export const [ThemeProvider, useTheme] = createContextHook(() => {
  const { themeMode } = useUser();
  /** null means the LexIndia Violet default (hand-tuned colourful pairs). */
  const [accentHex, setAccentHex] = useState<number | null>(() => loadJSON<number | null>(STORAGE_KEY));
  const [systemDark, setSystemDark] = useState<boolean>(systemPrefersDark);

  useEffect(() => {
    const query = window.matchMedia("(prefers-color-scheme: dark)");
    const onChange = () => setSystemDark(query.matches);
    query.addEventListener("change", onChange);
    return () => query.removeEventListener("change", onChange);
  }, []);

  const isDark = themeMode === "dark" || (themeMode === "system" && systemDark);

  const palette: DerivedPalette = useMemo(
    () => (accentHex === null ? signaturePalette : monochromePalette(accentHex)),
    [accentHex],
  );

  useEffect(() => {
    document.documentElement.classList.toggle("dark", isDark);
    document.documentElement.style.colorScheme = isDark ? "dark" : "light";
    applyPalette(palette, isDark);
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", isDark ? "#120b21" : "#fcfafc");
  }, [palette, isDark]);

  const setAccent = useCallback((hex: number | null) => {
    setAccentHex(hex);
    if (hex === null) removeKey(STORAGE_KEY);
    else saveJSON(STORAGE_KEY, hex);
  }, []);

  const selectPreset = useCallback(
    (preset: AccentPreset) => setAccent(preset.hex === SIGNATURE_HEX ? null : preset.hex),
    [setAccent],
  );

  const setCustom = useCallback((hex: number) => setAccent(hex === SIGNATURE_HEX ? null : hex), [setAccent]);

  const reset = useCallback(() => setAccent(null), [setAccent]);

  const isSelected = useCallback(
    (preset: AccentPreset) => (accentHex === null ? preset.hex === SIGNATURE_HEX : accentHex === preset.hex),
    [accentHex],
  );

  /** Preset name, or "Custom" when picked from the wheel. */
  const accentName = useMemo(() => {
    if (accentHex === null) return ACCENT_PRESETS[0].name;
    return ACCENT_PRESETS.find((preset) => preset.hex === accentHex)?.name ?? "Custom";
  }, [accentHex]);

  /** The currently selected accent as a plain CSS colour. */
  const currentColor = hexToCss(accentHex ?? SIGNATURE_HEX);

  return {
    accentHex,
    isDefault: accentHex === null,
    isDark,
    accentName,
    currentColor,
    palette,
    presets: ACCENT_PRESETS,
    selectPreset,
    setCustom,
    reset,
    isSelected,
  };
});
