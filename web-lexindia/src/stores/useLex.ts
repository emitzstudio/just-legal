/** Convenience hook: the interface language plus bound string helpers. */

import { useCallback } from "react";

import { f as format, t as translate } from "@/lib/strings";
import { useUser } from "@/stores/userStore";

export function useLex() {
  const { language } = useUser();
  const t = useCallback((key: string) => translate(key, language), [language]);
  const f = useCallback((key: string, ...args: (string | number)[]) => format(key, language, ...args), [language]);
  return { language, t, f };
}
