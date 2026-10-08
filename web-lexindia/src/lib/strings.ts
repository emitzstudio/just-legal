/**
 * Central interface-string table keyed by language — ported from
 * LexStrings on iOS. Official statutory text is NEVER translated here.
 */

import stringsData from "@/data/strings.json";
import type { AppLanguage } from "./models";

const tables = stringsData as { en: Record<string, string>; hi: Record<string, string> };

/** Resolves a key for the given language, falling back to English. */
export function t(key: string, language: AppLanguage): string {
  if (language !== "en") {
    const value = tables[language]?.[key];
    if (value !== undefined) return value;
  }
  return tables.en[key] ?? key;
}

/** Format-string variant — the key's value carries %d / %@ placeholders. */
export function f(key: string, language: AppLanguage, ...args: (string | number)[]): string {
  let index = 0;
  return t(key, language).replace(/%[d@]/g, () => {
    const value = args[index];
    index += 1;
    return value === undefined ? "" : String(value);
  });
}
