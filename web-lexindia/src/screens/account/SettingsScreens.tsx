/**
 * Appearance (Automatic / Light / Dark), App colour (presets + custom
 * wheel) and Language settings, plus the legal pages.
 */

import { Bookmark, Check, CheckCircle2, Moon, PlusCircle, RotateCcw, Sun, SunMoon, type LucideIcon } from "lucide-react";
import { useParams } from "react-router-dom";

import { AccentDiamond, BenchDivider, Hairline, Overline, PageHeader, TrustFootnote, pastel } from "@/components/lex/primitives";
import { NavBar, Screen } from "@/components/shell/Screen";
import legalPagesData from "@/data/legalPages.json";
import * as L from "@/lib/localize";
import { APP_LANGUAGES, THEME_MODES, languageEnglishName, languageNativeName, type LegalPageKind, type ThemeMode } from "@/lib/models";
import { cssToHex, hexToCss } from "@/lib/themeEngine";
import { cn } from "@/lib/utils";
import { useTheme } from "@/stores/themeStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

const modeIcons: Record<ThemeMode, LucideIcon> = { system: SunMoon, light: Sun, dark: Moon };

export function AppearanceScreen() {
  const { t, language } = useLex();
  const user = useUser();
  return (
    <Screen>
      <NavBar fallback="/account" />
      <PageHeader title={t("appearance.title")} subtitle={t("appearance.sub")} />
      <div className="mt-5 overflow-hidden rounded-[14px] border border-hairline bg-surface">
        {THEME_MODES.map((mode, index) => {
          const selected = user.themeMode === mode;
          const Icon = modeIcons[mode];
          return (
            <div key={mode}>
              {index > 0 ? <Hairline className="ml-4 w-auto" /> : null}
              <button type="button" onClick={() => user.setThemeMode(mode)} aria-pressed={selected} className="press flex w-full items-center gap-3 px-4 py-[13px] text-left">
                <span className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-full", selected ? "bg-brand text-on-brand" : "bg-canvas text-slate")}>
                  <Icon className="h-4 w-4" strokeWidth={2.4} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-base font-semibold text-ink">{L.themeModeLabel(mode, language)}</span>
                  <span className="block text-xs text-slate">{L.themeModeDetail(mode, language)}</span>
                </span>
                {selected ? <CheckCircle2 className="h-[18px] w-[18px] shrink-0 text-brand" fill="var(--brand)" stroke="var(--on-brand)" /> : null}
              </button>
            </div>
          );
        })}
      </div>
      <InfoPanel title={t("appearance.how")} body1={t("appearance.body1")} body2={t("appearance.body2")} tone="blue" />
      <div className="h-7" />
    </Screen>
  );
}

export function AppColorScreen() {
  const { t } = useLex();
  const theme = useTheme();
  return (
    <Screen>
      <NavBar fallback="/account" />
      <PageHeader title={t("appcolor.title")} subtitle={t("appcolor.sub")} />

      <div className="mt-[18px] rounded-[18px] p-[18px] text-on-brand brand-gradient transition-colors duration-300">
        <div className="flex items-center justify-between">
          <Overline text={theme.accentName} color="color-mix(in srgb, var(--on-brand) 65%, transparent)" />
          <AccentDiamond size={6} color="var(--on-brand)" />
        </div>
        <p className="mt-3 text-2xl font-bold">LexIndia</p>
        <div className="mt-3 flex items-center gap-2">
          <span className="rounded-full bg-white/[0.18] px-2.5 py-1.5 text-xs font-semibold">{t("reader.section")} 318</span>
          <span className="rounded-full bg-white/[0.18] px-2.5 py-1.5 text-xs font-semibold">{t("guide.badge")}</span>
          <span className="flex-1" />
          <Bookmark className="h-3.5 w-3.5" fill="currentColor" />
        </div>
      </div>

      <div className="mt-3 rounded-[14px] border border-hairline bg-surface p-3.5">
        <Overline text={t("appcolor.family")} className="mb-2.5" />
        <div className="flex gap-1.5">
          {Array.from({ length: 8 }, (_, index) => (
            <span
              key={index}
              className="h-[26px] flex-1 rounded-full transition-colors duration-300"
              style={{ backgroundColor: pastel(index).fill, boxShadow: `inset 0 0 0 1px color-mix(in srgb, ${pastel(index).tone} 40%, transparent)` }}
            />
          ))}
        </div>
      </div>

      <Overline text={t("appcolor.presets")} className="mt-[26px]" />
      <div className="mt-3 grid grid-cols-4 gap-3.5">
        {theme.presets.map((preset) => {
          const selected = theme.isSelected(preset);
          return (
            <button key={preset.id} type="button" onClick={() => theme.selectPreset(preset)} aria-pressed={selected} className="press flex flex-col items-center gap-[7px]">
              <span className="relative flex h-[54px] w-[54px] items-center justify-center">
                {selected ? <span className="absolute inset-0 rounded-full border-2 border-ink" /> : null}
                <span className="flex h-11 w-11 items-center justify-center rounded-full" style={{ backgroundColor: hexToCss(preset.hex) }}>
                  {selected ? <Check className="h-3.5 w-3.5 text-white" strokeWidth={3.5} /> : null}
                </span>
              </span>
              <span className={cn("w-full truncate text-center text-[10px] font-medium", selected ? "text-ink" : "text-slate")}>{preset.name}</span>
            </button>
          );
        })}
      </div>

      <Overline text={t("appcolor.custom")} className="mt-[26px]" />
      <label className="mt-2.5 flex cursor-pointer items-center gap-3 rounded-[14px] border border-hairline bg-surface px-4 py-[13px]">
        <span className="min-w-0 flex-1">
          <span className="block text-[15px] font-medium text-ink">{t("appcolor.custom")}</span>
          <span className="block text-xs text-slate">{t("appcolor.custom.pick")}</span>
        </span>
        <span className="relative h-9 w-9 overflow-hidden rounded-full border border-hairline" style={{ backgroundColor: theme.currentColor }}>
          <input
            type="color"
            value={theme.currentColor}
            onChange={(event) => {
              const hex = cssToHex(event.target.value);
              if (hex !== null) theme.setCustom(hex);
            }}
            aria-label={t("appcolor.custom")}
            className="absolute inset-0 h-full w-full cursor-pointer opacity-0"
          />
        </span>
      </label>

      {!theme.isDefault ? (
        <button type="button" onClick={theme.reset} className="press mt-[18px] flex w-full items-center justify-center gap-2 rounded-[13px] bg-brand-soft py-[13px] text-sm font-semibold text-brand">
          <RotateCcw className="h-3.5 w-3.5" strokeWidth={2.5} />
          {t("appcolor.reset")}
        </button>
      ) : null}

      <div className="mb-7 mt-[22px] rounded-xl bg-blue-soft p-3.5">
        <Overline text={t("appcolor.preview")} color="var(--blue-deep)" />
        <p className="mt-2 text-[13px] leading-relaxed text-slate">{t("appcolor.note")}</p>
      </div>
    </Screen>
  );
}

export function LanguageScreen() {
  const { t } = useLex();
  const user = useUser();
  return (
    <Screen>
      <NavBar fallback="/account" />
      <PageHeader title={t("language.title")} subtitle={t("language.sub")} />
      <div className="mt-5 overflow-hidden rounded-[14px] border border-hairline bg-surface">
        {APP_LANGUAGES.map((language, index) => {
          const selected = user.language === language;
          const native = languageNativeName(language);
          const english = languageEnglishName(language);
          return (
            <div key={language}>
              {index > 0 ? <Hairline className="ml-4 w-auto" /> : null}
              <button type="button" onClick={() => user.setLanguage(language)} aria-pressed={selected} aria-label={english} className="press flex w-full items-center gap-3 px-4 py-[13px] text-left">
                <span className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-base font-bold", selected ? "bg-brand text-on-brand" : "bg-canvas text-slate")}>{native.slice(0, 1)}</span>
                <span className="min-w-0 flex-1">
                  <span className="block text-base font-semibold text-ink">{native}</span>
                  {native !== english ? <span className="block text-xs text-slate">{english}</span> : null}
                </span>
                {selected ? <CheckCircle2 className="h-[18px] w-[18px] shrink-0 text-brand" fill="var(--brand)" stroke="var(--on-brand)" /> : null}
              </button>
            </div>
          );
        })}
      </div>
      <InfoPanel title={t("language.how")} body1={t("language.body1")} body2={t("language.body2")} tone="saffron" />
      <p className="flex items-center gap-2 pb-7 pt-4 text-xs text-slate">
        <PlusCircle className="h-3.5 w-3.5" />
        {t("language.more")}
      </p>
    </Screen>
  );
}

function InfoPanel({ title, body1, body2, tone }: { title: string; body1: string; body2: string; tone: "blue" | "saffron" }) {
  return (
    <div className={cn("mt-5 rounded-xl p-3.5", tone === "blue" ? "bg-blue-soft" : "bg-saffron-soft")}>
      <Overline text={title} color={tone === "blue" ? "var(--blue-deep)" : "var(--saffron-deep)"} />
      <p className="mt-2 text-[13px] leading-relaxed text-slate">{body1}</p>
      <p className="mt-2 text-[13px] font-semibold leading-relaxed text-ink">{body2}</p>
    </div>
  );
}

export function LegalPageScreen() {
  const { kind = "privacy" } = useParams<{ kind: LegalPageKind }>();
  const { t, language } = useLex();
  const pages = legalPagesData as Record<"en" | "hi", Record<LegalPageKind, string[]>>;
  const safeKind: LegalPageKind = kind === "terms" || kind === "disclaimer" ? kind : "privacy";
  const titleKey = safeKind === "privacy" ? "account.privacy" : safeKind === "terms" ? "account.terms" : "account.disclaimer";
  const paragraphs = pages[language][safeKind];
  return (
    <Screen>
      <NavBar fallback="/account" />
      <h1 className="pt-2 text-[28px] font-bold leading-tight text-ink">{t(titleKey)}</h1>
      <BenchDivider className="my-[18px]" />
      <div className="space-y-4">
        {paragraphs.map((paragraph, index) => (
          <p key={index} className="text-[15px] leading-[1.7] text-ink">
            {paragraph}
          </p>
        ))}
      </div>
      <TrustFootnote className="pb-6 pt-8" />
    </Screen>
  );
}
