/**
 * First-run gate: create an account or sign in. Preview authentication —
 * accounts live in this browser until the production backend arrives.
 */

import { Mail, User } from "lucide-react";
import { useState, type FormEvent } from "react";

import { AccentDiamond, Hairline, PrimaryButton, TrustFootnote } from "@/components/lex/primitives";
import { cn } from "@/lib/utils";
import { useAccess } from "@/stores/accessStore";
import { useLex } from "@/stores/useLex";
import { useUser } from "@/stores/userStore";

type AuthMode = "register" | "signIn";

const isValidEmail = (value: string) => value.includes("@") && value.includes(".") && value.length >= 6 && !value.includes(" ");

/** Renders "**bold**" segments of a string as emphasis. */
function Markdownish({ text }: { text: string }) {
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  return (
    <>
      {parts.map((part, index) =>
        part.startsWith("**") ? (
          <strong key={index} className="font-semibold text-brand">
            {part.slice(2, -2)}
          </strong>
        ) : (
          <span key={index}>{part}</span>
        ),
      )}
    </>
  );
}

export function AuthScreen() {
  const { t } = useLex();
  const access = useAccess();
  const user = useUser();
  const [mode, setMode] = useState<AuthMode>("register");
  const [name, setName] = useState<string>("");
  const [email, setEmail] = useState<string>("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [focused, setFocused] = useState<"name" | "email" | null>(null);

  const submit = (event?: FormEvent) => {
    event?.preventDefault();
    const trimmedName = name.trim();
    const trimmedEmail = email.trim().toLowerCase();
    if (!isValidEmail(trimmedEmail)) {
      setErrorMessage(t("auth.err.email"));
      return;
    }
    if (mode === "register") {
      if (!trimmedName) {
        setErrorMessage(t("auth.err.name"));
        return;
      }
      setErrorMessage(null);
      user.setName(trimmedName);
      access.register(trimmedName, trimmedEmail);
    } else if (access.signIn(trimmedEmail)) {
      setErrorMessage(null);
    } else {
      setErrorMessage(t("auth.err.notFound"));
    }
  };

  const switchMode = (next: AuthMode) => {
    setMode(next);
    setErrorMessage(null);
  };

  return (
    <div className="min-h-screen bg-canvas">
      <form onSubmit={submit} className="mx-auto w-full max-w-[520px] px-[22px] pb-6 pt-7 anim-rise">
        <div className="rounded-3xl bg-brand p-[22px] text-on-brand">
          <div className="flex items-center justify-between">
            <span className="flex h-16 w-16 items-center justify-center rounded-full bg-on-brand font-statute text-3xl font-bold text-brand">
              §
            </span>
            <AccentDiamond size={8} color="var(--on-brand)" />
          </div>
          <h1 className="mt-4 text-[34px] font-bold leading-tight">LexIndia</h1>
          <p className="mt-1.5 text-[15px] leading-relaxed opacity-80">{t("auth.tagline")}</p>
        </div>

        <div className="mt-7 flex rounded-xl bg-surface p-1" role="tablist">
          {(["register", "signIn"] as AuthMode[]).map((option) => (
            <button
              key={option}
              type="button"
              role="tab"
              aria-selected={mode === option}
              onClick={() => switchMode(option)}
              className={cn(
                "flex-1 rounded-lg py-2 text-[13px] font-semibold transition-colors",
                mode === option ? "bg-canvas text-ink shadow-sm" : "text-slate",
              )}
            >
              {t(option === "register" ? "auth.register" : "auth.signin")}
            </button>
          ))}
        </div>

        <div className="mt-3.5 overflow-hidden rounded-[14px] border border-hairline bg-surface">
          {mode === "register" ? (
            <>
              <label className="flex items-center gap-3 px-4 py-[15px]">
                <User className={cn("h-4 w-4 shrink-0", focused === "name" ? "text-brand" : "text-slate")} />
                <input
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                  onFocus={() => setFocused("name")}
                  onBlur={() => setFocused(null)}
                  placeholder={t("account.yourName")}
                  autoComplete="name"
                  className="min-w-0 flex-1 bg-transparent text-base text-ink outline-none"
                />
              </label>
              <Hairline className="ml-[46px] w-auto" />
            </>
          ) : null}
          <label className="flex items-center gap-3 px-4 py-[15px]">
            <Mail className={cn("h-4 w-4 shrink-0", focused === "email" ? "text-brand" : "text-slate")} />
            <input
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              onFocus={() => setFocused("email")}
              onBlur={() => setFocused(null)}
              placeholder={t("auth.email")}
              type="email"
              inputMode="email"
              autoComplete="email"
              autoCapitalize="none"
              className="min-w-0 flex-1 bg-transparent text-base text-ink outline-none"
            />
          </label>
        </div>

        {errorMessage ? <p className="mt-3 text-[13px] font-medium text-saffron-deep anim-fade">{errorMessage}</p> : null}

        <PrimaryButton type="submit" className="mt-[18px]">
          {t(mode === "register" ? "auth.register" : "auth.signin")}
        </PrimaryButton>

        <button
          type="button"
          onClick={() => switchMode(mode === "register" ? "signIn" : "register")}
          className="mt-4 w-full text-center text-sm text-slate"
        >
          <Markdownish text={t(mode === "register" ? "auth.toggle.toSignin" : "auth.toggle.toRegister")} />
        </button>

        <div className="mt-[34px] space-y-1.5">
          <p className="text-center text-xs leading-relaxed text-slate">{t("auth.preview.note")}</p>
          <TrustFootnote />
        </div>
      </form>
    </div>
  );
}
