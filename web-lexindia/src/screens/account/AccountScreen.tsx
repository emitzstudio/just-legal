/**
 * Profile, membership, credits, saved content, settings and sign out —
 * clear hierarchy, not a dashboard.
 */

import {
  ArrowLeftRight,
  ArrowRight,
  BookA,
  Bookmark,
  ChevronRight,
  Clock,
  Diamond,
  Download,
  FileText,
  Globe,
  History,
  Info,
  Lock,
  LogOut,
  Palette,
  Pencil,
  Quote,
  SunMoon,
  type LucideIcon,
} from "lucide-react";
import { useState, type ReactNode } from "react";
import { Link } from "react-router-dom";

import { ConfirmDialog } from "@/components/lex/ConfirmDialog";
import { Hairline, Overline, SearchButton, TrustFootnote } from "@/components/lex/primitives";
import { Screen } from "@/components/shell/Screen";
import * as L from "@/lib/localize";
import { languageNativeName } from "@/lib/models";
import { useAccess } from "@/stores/accessStore";
import { useTheme } from "@/stores/themeStore";
import { useUI } from "@/stores/uiStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

export function AccountScreen() {
  const { t, language } = useLex();
  const user = useUser();
  const access = useAccess();
  const theme = useTheme();
  const ui = useUI();
  const [showRename, setShowRename] = useState<boolean>(false);
  const [confirmSignOut, setConfirmSignOut] = useState<boolean>(false);

  return (
    <Screen>
      <div className="flex items-center gap-3 pt-3.5">
        <h1 className="flex-1 text-[34px] font-bold leading-tight text-ink">{t("account.title")}</h1>
        <SearchButton />
      </div>

      <button
        type="button"
        onClick={() => setShowRename(true)}
        className="press mt-[18px] flex w-full items-center gap-3.5 text-left"
        aria-label={`Edit name, currently ${user.profileName}`}
      >
        <span className="flex h-[52px] w-[52px] shrink-0 items-center justify-center rounded-full bg-brand text-[22px] font-bold text-on-brand">
          {user.profileName.slice(0, 1).toUpperCase()}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-[19px] font-semibold text-ink">{user.profileName}</span>
          <span className="block truncate text-[13px] text-slate">{access.user?.email ?? "Tap to edit your name"}</span>
        </span>
        <Pencil className="h-4 w-4 text-slate" />
      </button>

      <MembershipCard onOpen={() => ui.setPlansPresented(true)} />

      <Group title={t("account.credits")}>
        <ActionRow
          title={t("account.credits.balance")}
          value={`${user.credits} ${t("account.credits.left")}`}
          icon={Diamond}
          onClick={() => ui.setCreditsPresented(true)}
        />
        <Hairline className="ml-4 w-auto" />
        <NavRow title={t("account.credits.history")} icon={History} to="/credits" />
      </Group>
      <p className="mt-1.5 pl-1 text-[11px] text-slate">{t("account.credits.note")}</p>

      <Group title={t("account.yourLibrary")}>
        <NavRow title={t("account.saved")} value={user.saved.length ? `${user.saved.length}` : undefined} icon={Bookmark} to="/notes" />
        <Hairline className="ml-4 w-auto" />
        <NavRow title={t("account.recents")} icon={Clock} to="/recents" />
        <Hairline className="ml-4 w-auto" />
        <NavRow title={t("account.downloads")} value={user.downloads.length ? `${user.downloads.length}` : undefined} icon={Download} to="/downloads" />
      </Group>

      <Group title={t("account.studyTools")}>
        <NavRow title={t("account.definitions")} icon={BookA} to="/definitions" />
        <Hairline className="ml-4 w-auto" />
        <NavRow title={t("account.caseLaws")} icon={Quote} to="/cases" />
        <Hairline className="ml-4 w-auto" />
        <NavRow title="IPC → BNS" icon={ArrowLeftRight} to="/ipc-bns" />
      </Group>

      <Group title={t("account.settings")}>
        <NavRow title={t("account.appearance")} value={L.themeModeLabel(user.themeMode, language)} icon={SunMoon} to="/settings/appearance" />
        <Hairline className="ml-4 w-auto" />
        <NavRow title={t("account.appColor")} value={theme.accentName} icon={Palette} to="/settings/color" />
        <Hairline className="ml-4 w-auto" />
        <NavRow title={t("account.language")} value={languageNativeName(user.language)} icon={Globe} to="/settings/language" />
      </Group>

      <Group title={t("account.about")}>
        <NavRow title={t("account.privacy")} icon={Lock} to="/legal/privacy" />
        <Hairline className="ml-4 w-auto" />
        <NavRow title={t("account.terms")} icon={FileText} to="/legal/terms" />
        <Hairline className="ml-4 w-auto" />
        <NavRow title={t("account.disclaimer")} icon={Info} to="/legal/disclaimer" />
      </Group>

      <Group title={t("account.session")}>
        <ActionRow title={t("account.signout")} icon={LogOut} onClick={() => setConfirmSignOut(true)} />
      </Group>

      <div className="space-y-1.5 pb-6 pt-7">
        <TrustFootnote />
        <p className="text-center text-[11px] text-slate">LexIndia 1.0</p>
      </div>

      <ConfirmDialog
        open={showRename}
        title={t("account.yourName")}
        message={t("account.name.note")}
        textField={{ placeholder: t("common.name"), initial: user.profileName }}
        confirmLabel={t("common.save")}
        cancelLabel={t("common.cancel")}
        onConfirm={(value) => {
          user.setName(value);
          setShowRename(false);
        }}
        onCancel={() => setShowRename(false)}
      />
      <ConfirmDialog
        open={confirmSignOut}
        title={t("account.signoutTitle")}
        message={t("account.local.note")}
        confirmLabel={t("account.signout")}
        cancelLabel={t("common.cancel")}
        destructive
        onConfirm={() => {
          setConfirmSignOut(false);
          access.signOut();
        }}
        onCancel={() => setConfirmSignOut(false)}
      />
    </Screen>
  );
}

function MembershipCard({ onOpen }: { onOpen: () => void }) {
  const { t, f, language } = useLex();
  const access = useAccess();

  const badge = access.isDevAccess ? "DEVELOPMENT" : access.subscriptionInfo ? "ACTIVE" : access.isOnTrial ? "TRIAL" : null;

  let body: ReactNode;
  if (access.subscriptionInfo) {
    const info = access.subscriptionInfo;
    body = (
      <>
        <p className="text-[21px] font-semibold">
          {L.planDuration(info.plan.months, language)} {t("plan.suffix")}
        </p>
        <p className="text-[13px] leading-relaxed opacity-80">{f("account.expiresLine", L.date(info.end, language), info.plan.includedCredits)}</p>
        <ManageLine label={t("account.managePlan")} />
      </>
    );
  } else if (access.isOnTrial) {
    body = (
      <>
        <p className="text-[21px] font-semibold">{t("myspace.trial")}</p>
        {access.trialRemaining !== null ? (
          <p className="text-[13px] opacity-80">{f("account.trial.line", L.remaining(access.trialRemaining, language))}</p>
        ) : null}
        <ManageLine label={t("myspace.seePlans")} />
      </>
    );
  } else if (access.isDevAccess) {
    body = (
      <>
        <p className="text-[21px] font-semibold">{t("account.testAccess")}</p>
        <p className="text-[13px] leading-relaxed opacity-80">{t("account.dev.note")}</p>
        <ManageLine label={t("myspace.seePlans")} />
      </>
    );
  } else {
    body = (
      <>
        <p className="text-sm leading-relaxed opacity-90">{t("account.plus.note")}</p>
        <ManageLine label={t("myspace.seePlans")} />
      </>
    );
  }

  return (
    <button type="button" onClick={onOpen} className="press mt-[22px] block w-full rounded-2xl p-[18px] text-left text-on-brand brand-gradient">
      <div className="flex items-center justify-between">
        <Overline text={t("account.membership")} color="color-mix(in srgb, var(--on-brand) 62%, transparent)" />
        {badge ? <span className="rounded-full bg-on-brand px-2 py-1 text-[10px] font-bold text-saffron">{badge}</span> : null}
      </div>
      <div className="mt-2.5 space-y-2">{body}</div>
    </button>
  );
}

function ManageLine({ label }: { label: string }) {
  return (
    <span className="mt-0.5 inline-flex items-center gap-1 text-sm font-semibold">
      {label}
      <ArrowRight className="h-3 w-3" strokeWidth={2.5} />
    </span>
  );
}

export function Group({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="mt-[22px]">
      <Overline text={title} className="mb-2.5" />
      <div className="overflow-hidden rounded-[14px] border border-hairline bg-surface">{children}</div>
    </section>
  );
}

function RowContent({ title, value, icon: Icon }: { title: string; value?: string; icon: LucideIcon }) {
  return (
    <div className="flex w-full items-center gap-3 px-4 py-[13px] text-left">
      <Icon className="h-4 w-4 shrink-0 text-brand" strokeWidth={2.2} />
      <span className="min-w-0 flex-1 text-[15px] font-medium text-ink">{title}</span>
      {value ? <span className="shrink-0 text-sm tabular text-slate">{value}</span> : null}
      <ChevronRight className="h-3 w-3 shrink-0 text-faint" strokeWidth={2.5} />
    </div>
  );
}

export function NavRow({ title, value, icon, to }: { title: string; value?: string; icon: LucideIcon; to: string }) {
  return (
    <Link to={to} className="press block">
      <RowContent title={title} value={value} icon={icon} />
    </Link>
  );
}

export function ActionRow({ title, value, icon, onClick }: { title: string; value?: string; icon: LucideIcon; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} className="press block w-full">
      <RowContent title={title} value={value} icon={icon} />
    </button>
  );
}
