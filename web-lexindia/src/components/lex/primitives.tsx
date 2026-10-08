/**
 * Shared LexIndia components: overlines, hairlines, diamonds, dividers,
 * empty states, prepared panels, section rows, close/search buttons,
 * the Read Aloud control and the pastel helpers. Ported from
 * LexComponents on iOS.
 */

import { ChevronRight, Pause, Play, Search, Square, Volume2, X } from "lucide-react";
import { type CSSProperties, type ReactNode } from "react";

import { cn } from "@/lib/utils";
import { useUI } from "@/stores/uiStore";
import { useLex } from "@/stores/useLex";

/** Stable pastel pair for an index (cycles through the eight identities). */
export function pastel(index: number): { fill: string; tone: string } {
  const slot = Math.abs(index) % 8;
  return { fill: `var(--pastel-${slot}-fill)`, tone: `var(--pastel-${slot}-tone)` };
}

export const pastelVars = (index: number): CSSProperties =>
  ({ "--pastel-fill": pastel(index).fill, "--pastel-tone": pastel(index).tone }) as CSSProperties;

/** Small-caps label marking an information type. No letter tracking. */
export function Overline({
  text,
  color,
  className,
}: {
  text: string;
  color?: string;
  className?: string;
}) {
  return (
    <span
      className={cn("block text-[11px] font-semibold uppercase leading-4 text-slate", className)}
      style={color ? { color } : undefined}
    >
      {text}
    </span>
  );
}

/** Fine printed rule. */
export function Hairline({ className }: { className?: string }) {
  return <div className={cn("h-px w-full bg-hairline", className)} aria-hidden="true" />;
}

/** Small rotated saffron square — LexIndia's quiet Indian ornament. */
export function AccentDiamond({ size = 6, color }: { size?: number; color?: string }) {
  return (
    <span
      aria-hidden="true"
      className="inline-block shrink-0 rotate-45"
      style={{ width: size, height: size, backgroundColor: color ?? "var(--saffron)" }}
    />
  );
}

/** Double rule with a centred saffron diamond — the letterhead divider. */
export function BenchDivider({ className }: { className?: string }) {
  return (
    <div className={cn("flex items-center gap-2.5", className)} aria-hidden="true">
      <Hairline />
      <AccentDiamond />
      <Hairline />
    </div>
  );
}

/** The recurring legal-positioning footnote. */
export function TrustFootnote({ className }: { className?: string }) {
  const { t } = useLex();
  return <p className={cn("w-full text-center text-xs text-slate", className)}>{t("trust.footnote")}</p>;
}

/** Consistent circular close for sheets and overlays. */
export function CloseButton({ onClick, label = "Close" }: { onClick: () => void; label?: string }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      className="press flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-hairline bg-canvas text-slate"
    >
      <X className="h-3.5 w-3.5" strokeWidth={3} />
    </button>
  );
}

/** Circular universal-search entry used in every hub header. */
export function SearchButton() {
  const ui = useUI();
  return (
    <button
      type="button"
      onClick={ui.activateSearch}
      aria-label="Search LexIndia"
      className="press flex h-[38px] w-[38px] shrink-0 items-center justify-center rounded-full border border-hairline bg-surface text-ink"
    >
      <Search className="h-4 w-4" strokeWidth={2.5} />
    </button>
  );
}

/** Designed empty state — friendly badge, calm copy. */
export function EmptyState({
  icon,
  title,
  message,
  className,
}: {
  icon: ReactNode;
  title: string;
  message: string;
  className?: string;
}) {
  return (
    <div className={cn("flex w-full flex-col items-center gap-3.5 px-8 py-11 text-center", className)}>
      <div className="flex h-16 w-16 items-center justify-center rounded-full bg-brand-soft text-brand">{icon}</div>
      <h3 className="text-lg font-semibold text-ink">{title}</h3>
      <p className="text-sm leading-relaxed text-slate">{message}</p>
    </div>
  );
}

/** Panel for content that exists in the dataset roadmap but is not yet loaded. */
export function PreparedPanel({ message }: { message: string }) {
  const { t } = useLex();
  return (
    <div
      className="w-full rounded-[14px] bg-saffron-soft p-4"
      style={{ outline: "1px dashed color-mix(in srgb, var(--saffron) 55%, transparent)", outlineOffset: -1 }}
    >
      <Overline text={t("prepared.title")} color="var(--saffron-deep)" />
      <p className="mt-2 text-sm leading-relaxed text-slate">{message}</p>
    </div>
  );
}

/** Compact scannable row for a legal section. */
export function SectionRow({
  number,
  title,
  subtitle,
  showsChevron = true,
  showsGuideBadge = false,
}: {
  number: string;
  title: string;
  subtitle?: string | null;
  showsChevron?: boolean;
  showsGuideBadge?: boolean;
}) {
  const { t } = useLex();
  return (
    <div className="flex w-full items-baseline gap-3.5 py-[13px] text-left">
      <span className="min-w-[46px] text-[19px] font-bold tabular text-brand">{number}</span>
      <div className="min-w-0 flex-1">
        <p className="text-base font-medium leading-snug text-ink">{title}</p>
        {subtitle ? <p className="mt-0.5 text-xs text-slate">{subtitle}</p> : null}
      </div>
      {showsGuideBadge ? (
        <span className="shrink-0 self-center rounded-full bg-mint px-[7px] py-[3px] text-[10px] font-semibold text-mint-deep">
          {t("guide.badge")}
        </span>
      ) : null}
      {showsChevron ? <ChevronRight className="h-3.5 w-3.5 shrink-0 self-center text-faint" strokeWidth={2.5} /> : null}
    </div>
  );
}

/** Shared case-law row used in Library, Search and Case Laws screens. */
export function CaseLawRow({
  title,
  court,
  year,
  principle,
}: {
  title: string;
  court: string;
  year: number;
  principle: string;
}) {
  return (
    <div className="flex w-full items-center gap-3 py-3 text-left">
      <div className="min-w-0 flex-1">
        <p className="text-base font-semibold leading-snug text-ink">{title}</p>
        <p className="mt-1 text-xs text-slate">
          {court} · {year}
        </p>
        <p className="mt-1 line-clamp-2 text-[13px] leading-snug text-slate">{principle}</p>
      </div>
      <ChevronRight className="h-3.5 w-3.5 shrink-0 text-faint" strokeWidth={2.5} />
    </div>
  );
}

/** Pastel icon tile used by rows and tiles across the hubs. */
export function IconTile({
  index,
  size = 40,
  radius = 12,
  children,
  className,
}: {
  index: number;
  size?: number;
  radius?: number;
  children: ReactNode;
  className?: string;
}) {
  const colors = pastel(index);
  return (
    <div
      className={cn("flex shrink-0 items-center justify-center", className)}
      style={{ width: size, height: size, borderRadius: radius, backgroundColor: colors.fill, color: colors.tone }}
    >
      {children}
    </div>
  );
}

/**
 * Subtle speaker control for information pages. Idle: "Listen" chip.
 * Playing: pause/resume plus stop. One page at a time.
 */
export function ReadAloudControl({ id, text }: { id: string; text: string }) {
  const { speech } = useUI();
  const { t } = useLex();
  if (!speech.supported) return null;
  const isActive = speech.activeId === id;
  return (
    <div className="flex items-center gap-1.5">
      <button
        type="button"
        onClick={() => speech.toggle(id, text)}
        aria-label={isActive ? (speech.isPaused ? "Resume reading" : "Pause reading") : "Read this page aloud"}
        className={cn(
          "press flex h-8 items-center gap-1.5 rounded-full px-3 text-xs font-semibold transition-colors",
          isActive ? "bg-brand text-on-brand" : "bg-brand-soft text-brand",
        )}
      >
        {!isActive ? (
          <Volume2 className="h-3.5 w-3.5" strokeWidth={2.5} />
        ) : speech.isPaused ? (
          <Play className="h-3 w-3" fill="currentColor" strokeWidth={2.5} />
        ) : (
          <Pause className="h-3 w-3" fill="currentColor" strokeWidth={2.5} />
        )}
        {!isActive ? <span>{t("readaloud.listen")}</span> : null}
      </button>
      {isActive ? (
        <button
          type="button"
          onClick={speech.stop}
          aria-label={t("readaloud.stop")}
          className="press flex h-8 w-8 items-center justify-center rounded-full border border-hairline bg-surface text-slate anim-fade"
        >
          <Square className="h-2.5 w-2.5" fill="currentColor" />
        </button>
      ) : null}
    </div>
  );
}

/** Primary call-to-action — vivid accent fill (LexPrimaryButtonStyle). */
export function PrimaryButton({
  children,
  onClick,
  disabled,
  className,
  type = "button",
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  className?: string;
  type?: "button" | "submit";
}) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={cn(
        "press-soft flex w-full items-center justify-center gap-2 rounded-[14px] bg-brand py-3.5 text-base font-semibold text-on-brand transition-[background-color,transform] active:bg-brand-deep disabled:opacity-45",
        className,
      )}
    >
      {children}
    </button>
  );
}

/** Surface card with hairline border — the grouped-rows container. */
export function Card({
  children,
  className,
  radius = 14,
}: {
  children: ReactNode;
  className?: string;
  radius?: number;
}) {
  return (
    <div className={cn("overflow-hidden border border-hairline bg-surface", className)} style={{ borderRadius: radius }}>
      {children}
    </div>
  );
}

/** Rounded search input used across list screens. */
export function FilterField({
  value,
  onChange,
  placeholder,
  inputMode,
  autoFocus,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder: string;
  inputMode?: "search" | "numeric" | "text";
  autoFocus?: boolean;
}) {
  return (
    <div className="flex items-center gap-2.5 rounded-xl border border-hairline bg-surface px-3.5 py-[11px] focus-within:border-brand">
      <Search className="h-4 w-4 shrink-0 text-slate" strokeWidth={2.5} />
      <input
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        inputMode={inputMode}
        autoFocus={autoFocus}
        autoComplete="off"
        className="min-w-0 flex-1 bg-transparent text-[15px] text-ink outline-none"
      />
      {value ? (
        <button type="button" onClick={() => onChange("")} aria-label="Clear search" className="text-faint">
          <X className="h-4 w-4 rounded-full bg-faint/20 p-0.5" strokeWidth={3} />
        </button>
      ) : null}
    </div>
  );
}

/** Hub header: display title, subtitle and the search button. */
export function HubHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div className="flex items-start gap-3 pt-3.5">
      <div className="min-w-0 flex-1">
        <h1 className="text-[34px] font-bold leading-tight text-ink">{title}</h1>
        {subtitle ? <p className="mt-1 text-[15px] text-slate">{subtitle}</p> : null}
      </div>
      <SearchButton />
    </div>
  );
}

/** Pushed-screen header: title and subtitle at the detail scale. */
export function PageHeader({ title, subtitle, size = 30 }: { title: string; subtitle?: string; size?: number }) {
  return (
    <div className="pt-2">
      <h1 className="font-bold leading-tight text-ink" style={{ fontSize: size }}>
        {title}
      </h1>
      {subtitle ? <p className="mt-1 text-sm text-slate">{subtitle}</p> : null}
    </div>
  );
}
