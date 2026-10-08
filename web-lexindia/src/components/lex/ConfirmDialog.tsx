/**
 * The LexIndia alert / confirmation sheet — the web counterpart of the
 * iOS confirmationDialog and alert, with an optional text field.
 */

import { useEffect, useState, type ReactNode } from "react";

import { cn } from "@/lib/utils";

export interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message?: ReactNode;
  confirmLabel: string;
  cancelLabel: string;
  destructive?: boolean;
  /** When set, shows a text field whose value is passed to onConfirm. */
  textField?: { placeholder: string; initial: string };
  onConfirm: (value: string) => void;
  onCancel: () => void;
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel,
  cancelLabel,
  destructive = false,
  textField,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  const [value, setValue] = useState<string>(textField?.initial ?? "");

  useEffect(() => {
    if (open) setValue(textField?.initial ?? "");
  }, [open, textField?.initial]);

  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") onCancel();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onCancel]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[70] flex items-end justify-center sm:items-center" role="dialog" aria-modal="true" aria-labelledby="lex-dialog-title">
      <button type="button" aria-label="Dismiss" onClick={onCancel} className="absolute inset-0 bg-black/45 anim-fade" />
      <div className="relative m-3 w-full max-w-sm rounded-3xl border border-hairline bg-surface p-5 shadow-float anim-rise">
        <h2 id="lex-dialog-title" className="text-[17px] font-semibold text-ink">
          {title}
        </h2>
        {message ? <div className="mt-2 text-sm leading-relaxed text-slate">{message}</div> : null}
        {textField ? (
          <input
            autoFocus
            value={value}
            onChange={(event) => setValue(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") onConfirm(value);
            }}
            placeholder={textField.placeholder}
            className="mt-4 w-full rounded-xl border border-hairline bg-canvas px-3.5 py-2.5 text-[15px] text-ink outline-none focus:border-brand"
          />
        ) : null}
        <div className="mt-5 flex flex-col gap-2">
          <button
            type="button"
            onClick={() => onConfirm(value)}
            className={cn(
              "press-soft w-full rounded-[14px] py-3 text-[15px] font-semibold",
              destructive ? "bg-pastel-4 text-white" : "bg-brand text-on-brand",
            )}
            style={destructive ? { backgroundColor: "var(--pastel-4-tone)" } : undefined}
          >
            {confirmLabel}
          </button>
          <button
            type="button"
            onClick={onCancel}
            className="press-soft w-full rounded-[14px] bg-canvas py-3 text-[15px] font-medium text-ink"
          >
            {cancelLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

/** Bottom sheet container for membership, credits, definitions and notes. */
export function Sheet({
  open,
  onClose,
  children,
  label,
  tall = false,
}: {
  open: boolean;
  onClose: () => void;
  children: ReactNode;
  label: string;
  tall?: boolean;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center sm:items-center" role="dialog" aria-modal="true" aria-label={label}>
      <button type="button" aria-label="Close" onClick={onClose} className="absolute inset-0 bg-black/45 anim-fade" />
      <div
        className={cn(
          "relative flex w-full max-w-[560px] flex-col overflow-hidden rounded-t-3xl bg-surface shadow-float anim-sheet sm:m-4 sm:rounded-3xl",
          tall ? "h-[92dvh] sm:h-[88vh]" : "max-h-[88dvh] sm:max-h-[84vh]",
        )}
      >
        <div className="flex shrink-0 justify-center pt-2.5" aria-hidden="true">
          <span className="h-[5px] w-9 rounded-full bg-hairline" />
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-[22px] no-scrollbar">{children}</div>
      </div>
    </div>
  );
}
