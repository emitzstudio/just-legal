/**
 * The floating E-Vakeel button: a glowing accent circle above the app.
 * One pointer gesture handles everything — the circle sticks to the
 * finger the instant a drag starts, springs to the nearest edge on
 * release, remembers its dock, and a plain tap opens the assistant.
 */

import { useCallback, useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from "react";
import { useLocation } from "react-router-dom";

import { useUI } from "@/stores/uiStore";
import { useUser } from "@/stores/userStore";

import { EVakeelFace } from "./EVakeelLogo";

const DIAMETER = 58;
const MARGIN = 18;
const DRAG_THRESHOLD = 6;
/** Keeps the circle clear of the tab bar on phones. */
const BOTTOM_RESERVE = 110;
const TOP_RESERVE = 76;

export function EVakeelFloatingButton() {
  const ui = useUI();
  const user = useUser();
  const location = useLocation();
  const [viewport, setViewport] = useState<{ width: number; height: number }>(() => ({
    width: window.innerWidth,
    height: window.innerHeight,
  }));
  const [dragPoint, setDragPoint] = useState<{ x: number; y: number } | null>(null);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [isPressed, setIsPressed] = useState<boolean>(false);
  const touchStart = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
  const pointerStart = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
  const lastMove = useRef<{ x: number; t: number }[]>([]);

  useEffect(() => {
    const onResize = () => setViewport({ width: window.innerWidth, height: window.innerHeight });
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  const isWide = viewport.width >= 1024;
  const leftReserve = isWide ? 232 : 0;

  const restingPoint = {
    x: user.evakeelDockOnRight ? viewport.width - MARGIN - DIAMETER / 2 : leftReserve + MARGIN + DIAMETER / 2,
    y: Math.min(Math.max(viewport.height * user.evakeelDockY, 90), viewport.height - (isWide ? 60 : 130)),
  };

  const clamped = useCallback(
    (point: { x: number; y: number }) => ({
      x: Math.min(Math.max(point.x, leftReserve + DIAMETER / 2 + 6), viewport.width - DIAMETER / 2 - 6),
      y: Math.min(Math.max(point.y, TOP_RESERVE), Math.max(viewport.height - (isWide ? 40 : BOTTOM_RESERVE), TOP_RESERVE)),
    }),
    [viewport, leftReserve, isWide],
  );

  const onPointerDown = (event: ReactPointerEvent<HTMLButtonElement>) => {
    event.currentTarget.setPointerCapture(event.pointerId);
    setIsPressed(true);
    touchStart.current = dragPoint ?? restingPoint;
    pointerStart.current = { x: event.clientX, y: event.clientY };
    lastMove.current = [{ x: event.clientX, t: performance.now() }];
  };

  const onPointerMove = (event: ReactPointerEvent<HTMLButtonElement>) => {
    if (!isPressed) return;
    const dx = event.clientX - pointerStart.current.x;
    const dy = event.clientY - pointerStart.current.y;
    const distance = Math.hypot(dx, dy);
    if (!isDragging && distance > DRAG_THRESHOLD) setIsDragging(true);
    if (!isDragging && distance <= DRAG_THRESHOLD) return;
    lastMove.current = [...lastMove.current.slice(-4), { x: event.clientX, t: performance.now() }];
    setDragPoint(clamped({ x: touchStart.current.x + dx, y: touchStart.current.y + dy }));
  };

  const onPointerUp = (event: ReactPointerEvent<HTMLButtonElement>) => {
    event.currentTarget.releasePointerCapture(event.pointerId);
    setIsPressed(false);
    const wasDragging = isDragging;
    setIsDragging(false);
    if (!wasDragging) {
      ui.openEVakeel();
      return;
    }
    // Project a little momentum so a flick lands on the side the finger was heading toward.
    const samples = lastMove.current;
    const first = samples[0];
    const last = samples[samples.length - 1];
    const velocity = samples.length > 1 && last.t > first.t ? (last.x - first.x) / (last.t - first.t) : 0;
    const projectedX = event.clientX + velocity * 160;
    const endY = touchStart.current.y + (event.clientY - pointerStart.current.y);
    const snapRight = projectedX > leftReserve + (viewport.width - leftReserve) / 2;
    user.setEVakeelDock(snapRight, endY / Math.max(viewport.height, 1));
    setDragPoint(null);
  };

  const point = dragPoint ?? restingPoint;
  const scale = isDragging ? 1.1 : isPressed ? 0.92 : 1;

  // Hidden while the assistant is open and during a quiz (a focused,
  // full-screen flow on iOS too).
  if (ui.evakeelPresented || location.pathname === "/quiz/play") return null;

  return (
    <button
      type="button"
      aria-label="E-Vakeel, your digital legal assistant. Drag to reposition."
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
      className="fixed z-40 touch-none select-none rounded-full"
      style={{
        left: point.x - DIAMETER / 2,
        top: point.y - DIAMETER / 2,
        width: DIAMETER,
        height: DIAMETER,
        transform: `scale(${scale})`,
        transition: isDragging ? "transform 200ms" : "left 400ms cubic-bezier(0.2, 0.9, 0.3, 1.2), top 400ms cubic-bezier(0.2, 0.9, 0.3, 1.2), transform 200ms",
        filter: "drop-shadow(0 5px 12px color-mix(in srgb, var(--brand) 45%, transparent))",
      }}
    >
      <span
        className="absolute inset-0 rounded-full anim-glow"
        style={{ backgroundColor: "var(--brand)", filter: "blur(12px)" }}
        aria-hidden="true"
      />
      <span className="relative block">
        <EVakeelFace diameter={DIAMETER} />
      </span>
    </button>
  );
}
