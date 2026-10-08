/**
 * Screen scaffolding: the content column shared by every screen, and the
 * navigation bar for pushed screens (back button + inline title), which
 * is the web counterpart of the standard NavigationStack back.
 */

import { ChevronLeft } from "lucide-react";
import { type ReactNode, useCallback } from "react";
import { useLocation, useNavigate } from "react-router-dom";

import { cn } from "@/lib/utils";

export function Screen({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={cn("mx-auto w-full max-w-[640px] px-[22px] pb-28 lg:max-w-[720px] lg:px-8 lg:pb-16", className)}>
      {children}
    </div>
  );
}

/** Goes back when there is history, otherwise to the fallback hub. */
export function useBack(fallback: string = "/") {
  const navigate = useNavigate();
  const location = useLocation();
  return useCallback(() => {
    const state = location.state as { fromApp?: boolean } | null;
    if (state?.fromApp || window.history.length > 1) navigate(-1);
    else navigate(fallback, { replace: true });
  }, [navigate, location.state, fallback]);
}

export function NavBar({
  title,
  trailing,
  fallback = "/",
}: {
  title?: string;
  trailing?: ReactNode;
  fallback?: string;
}) {
  const back = useBack(fallback);
  return (
    <header className="sticky top-0 z-20 -mx-[22px] mb-1 flex h-12 items-center gap-2 bg-canvas/85 px-3 backdrop-blur-xl lg:-mx-8 lg:px-5">
      <button
        type="button"
        onClick={back}
        aria-label="Back"
        className="press flex h-9 items-center gap-0.5 rounded-full pl-1 pr-3 text-[15px] font-medium text-brand"
      >
        <ChevronLeft className="h-5 w-5" strokeWidth={2.5} />
      </button>
      <h2 className="min-w-0 flex-1 truncate text-center text-[15px] font-semibold text-ink">{title ?? ""}</h2>
      <div className="flex min-w-[36px] items-center justify-end gap-1">{trailing}</div>
    </header>
  );
}
