/**
 * The E-Vakeel mark: hand-drawn scales of justice with an AI spark — used
 * on the floating button and in the assistant header.
 */

import { Sparkle } from "lucide-react";

/** Scales of justice drawn as a single stroked path (viewBox 0 0 100 100). */
export function ScalesGlyph({ className, strokeWidth = 4 }: { className?: string; strokeWidth?: number }) {
  return (
    <svg
      viewBox="0 0 100 100"
      className={className}
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <circle cx="50" cy="9" r="4.5" />
      <path d="M50 16 V84" />
      <path d="M33 90 H67" />
      <path d="M14 30 H86" />
      <path d="M22 30 V50 M78 30 V50" />
      <path d="M9 50 Q22 68 35 50" />
      <path d="M65 50 Q78 68 91 50" />
    </svg>
  );
}

/** The circular E-Vakeel face: accent gradient, scales mark, saffron spark. */
export function EVakeelFace({ diameter = 58, showsSpark = true }: { diameter?: number; showsSpark?: boolean }) {
  return (
    <div
      className="relative shrink-0 rounded-full brand-gradient"
      style={{ width: diameter, height: diameter, boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.28)" }}
      aria-hidden="true"
    >
      <div className="absolute inset-0" style={{ padding: diameter * 0.23 }}>
        <ScalesGlyph className="h-full w-full text-on-brand" strokeWidth={4.2} />
      </div>
      {showsSpark ? (
        <Sparkle
          className="absolute text-saffron"
          fill="currentColor"
          style={{ width: diameter * 0.22, height: diameter * 0.22, right: diameter * 0.08, top: diameter * 0.06 }}
        />
      ) : null}
    </div>
  );
}
