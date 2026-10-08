/** Old IPC section → new BNS provision. Browse in numerical order or search a number. */

import { ArrowLeftRight, ArrowRight } from "lucide-react";
import { useMemo, useState } from "react";
import { Link } from "react-router-dom";

import { EmptyState, FilterField, Overline, PageHeader } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import { legalData } from "@/lib/legalData";
import type { IPCMapping } from "@/lib/models";
import { useLex } from "@/stores/useLex";

const ipcNumber = (value: string): number => {
  const digits = value.match(/^\d+/);
  return digits ? parseInt(digits[0], 10) : Number.MAX_SAFE_INTEGER;
};

export function IPCBNSScreen() {
  const { t, language } = useLex();
  const [query, setQuery] = useState<string>("");

  const ordered = useMemo(
    () =>
      [...legalData.core.ipcMappings].sort((a, b) => {
        const diff = ipcNumber(a.ipc) - ipcNumber(b.ipc);
        return diff !== 0 ? diff : a.ipc.localeCompare(b.ipc);
      }),
    [],
  );
  const q = query.trim().toLowerCase();
  const filtered = q
    ? ordered.filter((m) => m.ipc.toLowerCase().includes(q) || m.ipcTitle.toLowerCase().includes(q) || m.bnsLabel.toLowerCase().includes(q))
    : ordered;

  return (
    <Screen>
      <NavBar fallback="/library" />
      <PageHeader title="IPC → BNS" subtitle={t("library.ipc.sub")} />
      <div className="mt-3.5">
        <FilterField value={query} onChange={setQuery} placeholder={t("ipc.search")} inputMode="search" />
      </div>
      {filtered.length === 0 ? (
        <EmptyState icon={<ArrowLeftRight className="h-6 w-6" />} title={t("ipc.emptyTitle")} message={t("ipc.emptySub")} />
      ) : (
        <>
          <Overline
            className="mt-5"
            text={q ? `${filtered.length} ${language === "hi" ? t("ipc.matches") : filtered.length === 1 ? "match" : "matches"}` : t("ipc.all")}
          />
          <div className="mt-2.5 flex flex-col gap-2.5">
            {filtered.map((mapping) => (
              <MappingCard key={mapping.id} mapping={mapping} />
            ))}
          </div>
        </>
      )}
      <p className="pb-6 pt-[22px] text-xs leading-relaxed text-slate">{t("ipc.note")}</p>
    </Screen>
  );
}

function MappingCard({ mapping }: { mapping: IPCMapping }) {
  const { t } = useLex();
  const section = mapping.sectionId ? legalData.section(mapping.sectionId) : undefined;
  const content = (
    <div className="rounded-2xl border border-hairline bg-surface p-4 text-left">
      <div className="flex items-center">
        <div className="flex-1">
          <Overline text="IPC" />
          <p className="truncate text-[27px] font-bold leading-tight tabular text-ink">{mapping.ipc}</p>
        </div>
        <span className="flex h-[34px] w-[34px] shrink-0 items-center justify-center rounded-full bg-saffron-soft text-saffron-deep">
          <ArrowRight className="h-4 w-4" strokeWidth={3} />
        </span>
        <div className="flex-1 text-right">
          <Overline text="BNS" color="var(--brand)" />
          <p className="truncate text-[27px] font-bold leading-tight tabular text-brand">{mapping.bnsLabel}</p>
        </div>
      </div>
      <p className="mt-2.5 text-sm font-medium text-ink">{mapping.ipcTitle}</p>
      {mapping.note ? <p className="mt-1.5 text-xs leading-relaxed text-slate">{mapping.note}</p> : null}
      <p className="mt-2.5 flex items-center gap-1 text-[13px] font-semibold">
        {section ? (
          <span className="flex items-center gap-1 text-brand">
            {t("ipc.open")}
            <ArrowRight className="h-2.5 w-2.5" strokeWidth={2.5} />
          </span>
        ) : (
          <span className="text-xs font-medium text-saffron-deep">{t("ipc.preparing")}</span>
        )}
      </p>
    </div>
  );
  return section ? (
    <Link to={`/read/${section.actId}/${section.id}`} className="press block" aria-label={`IPC ${mapping.ipc}, ${mapping.ipcTitle}, is now BNS ${mapping.bnsLabel}. Opens the section`}>
      {content}
    </Link>
  ) : (
    <div aria-label={`IPC ${mapping.ipc}, ${mapping.ipcTitle}, is now BNS ${mapping.bnsLabel}`}>{content}</div>
  );
}
