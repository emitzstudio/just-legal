/**
 * The five-hub navigation: a bottom tab bar on phones and a slim sidebar
 * on wider screens. Order mirrors iOS — My Space | Law Library | List |
 * Students Corner | Account.
 */

import { GraduationCap, Landmark, LayoutGrid, ListChecks, UserCircle2, type LucideIcon } from "lucide-react";
import { useLocation } from "react-router-dom";

import { cn } from "@/lib/utils";
import { tabForPath, useUI, type LexTab } from "@/stores/uiStore";
import { useLex } from "@/stores/useLex";

const tabs: { id: LexTab; key: string; icon: LucideIcon }[] = [
  { id: "myspace", key: "tab.myspace", icon: LayoutGrid },
  { id: "library", key: "tab.library", icon: Landmark },
  { id: "list", key: "tab.list", icon: ListChecks },
  { id: "students", key: "tab.students", icon: GraduationCap },
  { id: "account", key: "tab.account", icon: UserCircle2 },
];

export function TabBar() {
  const { t } = useLex();
  const ui = useUI();
  const location = useLocation();
  const active = tabForPath(location.pathname);

  return (
    <nav
      aria-label="Main"
      className="fixed inset-x-0 bottom-0 z-30 border-t border-hairline bg-canvas/90 backdrop-blur-xl safe-bottom lg:hidden"
    >
      <ul className="mx-auto flex max-w-xl items-stretch">
        {tabs.map((tab) => {
          const isActive = tab.id === active;
          const Icon = tab.icon;
          return (
            <li key={tab.id} className="flex-1">
              <button
                type="button"
                onClick={() => ui.openTab(tab.id)}
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "flex w-full flex-col items-center gap-1 pb-1.5 pt-2 text-[10px] font-medium transition-colors",
                  isActive ? "text-brand" : "text-slate",
                )}
              >
                <Icon className="h-[22px] w-[22px]" strokeWidth={isActive ? 2.4 : 1.9} />
                <span className="max-w-full truncate px-1">{t(tab.key)}</span>
              </button>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

export function SideBar() {
  const { t } = useLex();
  const ui = useUI();
  const location = useLocation();
  const active = tabForPath(location.pathname);

  return (
    <aside className="fixed inset-y-0 left-0 z-30 hidden w-[232px] flex-col border-r border-hairline bg-canvas px-4 pb-6 pt-7 lg:flex">
      <button type="button" onClick={() => ui.openTab("list")} className="press flex items-center gap-3 px-2 text-left">
        <span className="flex h-10 w-10 items-center justify-center rounded-full bg-brand font-statute text-[22px] font-bold text-on-brand">
          §
        </span>
        <span className="text-[19px] font-bold text-ink">LexIndia</span>
      </button>
      <ul className="mt-8 flex flex-col gap-1">
        {tabs.map((tab) => {
          const isActive = tab.id === active;
          const Icon = tab.icon;
          return (
            <li key={tab.id}>
              <button
                type="button"
                onClick={() => ui.openTab(tab.id)}
                aria-current={isActive ? "page" : undefined}
                className={cn(
                  "press flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-[15px] font-medium transition-colors",
                  isActive ? "bg-brand-soft text-brand" : "text-slate hover:bg-surface hover:text-ink",
                )}
              >
                <Icon className="h-5 w-5" strokeWidth={isActive ? 2.4 : 1.9} />
                <span>{t(tab.key)}</span>
              </button>
            </li>
          );
        })}
      </ul>
      <p className="mt-auto px-3 text-[11px] leading-relaxed text-slate">{t("trust.footnote")}</p>
    </aside>
  );
}
