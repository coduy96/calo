"use client";
import * as React from "react";
import type { SlideAccent, Theme } from "@/lib/types";

type AccentProps = {
  cW: number;
  cH: number;
  theme: Theme;
  inverted: boolean;
  accent: SlideAccent;
};

// All accents pull palette from theme. `unit` = smaller dimension for stable type sizing.
function useUnit(cW: number, cH: number) {
  return Math.min(cW, cH);
}

function toneToColors(tone: string | undefined, theme: Theme, inverted: boolean) {
  switch (tone) {
    case "accent":
      return { bg: theme.accent, fg: "#FFFFFF" };
    case "dark":
      return { bg: theme.bgAlt, fg: theme.fgAlt };
    case "light":
      return { bg: "#FFFFFF", fg: theme.fg };
    case "ghost":
      return {
        bg: inverted ? "rgba(255,255,255,0.08)" : "rgba(20,8,2,0.05)",
        fg: inverted ? theme.fgAlt : theme.fg,
      };
    default:
      return inverted
        ? { bg: "#FFFFFF", fg: theme.bgAlt }
        : { bg: "#FFFFFF", fg: theme.fg };
  }
}

function ChipIcon({ name, size, color }: { name: string; size: number; color: string }) {
  const s = size;
  const stroke = color;
  switch (name) {
    case "spark":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M12 2v6M12 16v6M2 12h6M16 12h6M5 5l4 4M15 15l4 4M19 5l-4 4M9 15l-4 4" stroke={stroke} strokeWidth={2.2} strokeLinecap="round" />
        </svg>
      );
    case "heart":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill={stroke} aria-hidden>
          <path d="M12 21s-7-4.35-9.5-9C.5 7.5 4 3 8 5c2 1 3 3 4 3s2-2 4-3c4-2 7.5 2.5 5.5 7-2.5 4.65-9.5 9-9.5 9z" />
        </svg>
      );
    case "check":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M5 12l5 5L20 7" stroke={stroke} strokeWidth={3} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      );
    case "fire":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill={stroke} aria-hidden>
          <path d="M12 2c0 4-5 5-5 11a5 5 0 0 0 10 0c0-2-1-3-2-4 0 2-1 3-2 3 0-3 2-5-1-10z" />
        </svg>
      );
    case "leaf":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill={stroke} aria-hidden>
          <path d="M5 21c0-9 7-16 16-16 0 9-7 16-16 16zM5 21l8-8" stroke={stroke} strokeWidth={1.5} fill="none" strokeLinecap="round" />
        </svg>
      );
    case "bell":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2H4.5L6 16zM10 21a2 2 0 0 0 4 0" stroke={stroke} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      );
    case "voice":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill="none" aria-hidden>
          <rect x={9} y={3} width={6} height={12} rx={3} stroke={stroke} strokeWidth={2} />
          <path d="M5 11a7 7 0 0 0 14 0M12 18v3" stroke={stroke} strokeWidth={2} strokeLinecap="round" />
        </svg>
      );
    case "camera":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M3 8h4l2-3h6l2 3h4v11H3V8z" stroke={stroke} strokeWidth={2} strokeLinejoin="round" />
          <circle cx={12} cy={13} r={3.5} stroke={stroke} strokeWidth={2} />
        </svg>
      );
    case "barcode":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M3 5v14M6 5v14M9 5v14M12 5v14M15 5v14M18 5v14M21 5v14" stroke={stroke} strokeWidth={1.6} strokeLinecap="round" />
        </svg>
      );
    case "health":
      return (
        <svg width={s} height={s} viewBox="0 0 24 24" fill={stroke} aria-hidden>
          <path d="M12 21c-5-4-9-7-9-12 0-3 3-5 5.5-5 1.5 0 2.5 1 3.5 2 1-1 2-2 3.5-2C18 4 21 6 21 9c0 5-4 8-9 12z" />
        </svg>
      );
    default:
      return null;
  }
}

function arrowSvg(dir: string, color: string, size: number) {
  // small hand-drawn looking arrow
  const transforms: Record<string, string> = {
    right: "rotate(0deg)",
    left: "rotate(180deg)",
    up: "rotate(-90deg)",
    down: "rotate(90deg)",
    "down-left": "rotate(135deg)",
    "down-right": "rotate(45deg)",
  };
  return (
    <svg
      width={size}
      height={size * 0.6}
      viewBox="0 0 60 36"
      style={{ transform: transforms[dir] || "rotate(0deg)" }}
      aria-hidden
    >
      <path
        d="M2 18 C18 8, 38 8, 54 18"
        stroke={color}
        strokeWidth={3.4}
        strokeLinecap="round"
        fill="none"
      />
      <path d="M50 11l6 7-9 4" stroke={color} strokeWidth={3.4} strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </svg>
  );
}

function Chip({
  text,
  unit,
  bg,
  fg,
  rotate = 0,
  icon,
  arrow,
}: {
  text: string;
  unit: number;
  bg: string;
  fg: string;
  rotate?: number;
  icon?: { name: string; color: string };
  arrow?: { dir: string; color: string };
}) {
  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: unit * 0.014,
        padding: `${unit * 0.018}px ${unit * 0.03}px`,
        borderRadius: 999,
        background: bg,
        color: fg,
        fontFamily: "var(--font-body), Inter, sans-serif",
        fontWeight: 600,
        fontSize: unit * 0.026,
        letterSpacing: -unit * 0.0003,
        boxShadow: "0 18px 36px -14px rgba(20,8,2,0.35), 0 6px 14px -6px rgba(20,8,2,0.18), inset 0 1px 0 rgba(255,255,255,0.6)",
        whiteSpace: "nowrap",
        transform: `rotate(${rotate}deg)`,
        transformOrigin: "center center",
      }}
    >
      {icon && <ChipIcon name={icon.name} size={unit * 0.034} color={icon.color} />}
      <span>{text}</span>
      {arrow && (
        <span style={{ display: "inline-flex", marginLeft: unit * 0.004 }}>
          {arrowSvg(arrow.dir, arrow.color, unit * 0.04)}
        </span>
      )}
    </div>
  );
}

function StatCard({
  value,
  label,
  unit,
  bg,
  fg,
  accent,
  rotate = 0,
}: {
  value: string;
  label: string;
  unit: number;
  bg: string;
  fg: string;
  accent: string;
  rotate?: number;
}) {
  return (
    <div
      style={{
        display: "inline-flex",
        flexDirection: "column",
        alignItems: "flex-start",
        gap: unit * 0.006,
        padding: `${unit * 0.022}px ${unit * 0.03}px`,
        borderRadius: unit * 0.025,
        background: bg,
        color: fg,
        fontFamily: "var(--font-body), Inter, sans-serif",
        boxShadow: "0 22px 44px -16px rgba(20,8,2,0.4), 0 8px 16px -6px rgba(20,8,2,0.18), inset 0 1px 0 rgba(255,255,255,0.6)",
        transform: `rotate(${rotate}deg)`,
      }}
    >
      <div
        style={{
          fontSize: unit * 0.022,
          fontWeight: 600,
          letterSpacing: unit * 0.0008,
          textTransform: "uppercase",
          color: accent,
        }}
      >
        {label}
      </div>
      <div style={{ fontSize: unit * 0.058, fontWeight: 800, lineHeight: 1, letterSpacing: -unit * 0.001, fontFamily: "var(--font-display), Inter, sans-serif" }}>
        {value}
      </div>
    </div>
  );
}

function Sparkle({ size, color }: { size: number; color: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" aria-hidden>
      <path
        d="M16 2c1 6 4 9 10 10-6 1-9 4-10 10-1-6-4-9-10-10 6-1 9-4 10-10z"
        fill={color}
      />
    </svg>
  );
}

function Scribble({ width, color }: { width: number; color: string }) {
  return (
    <svg width={width} height={width * 0.18} viewBox="0 0 200 36" aria-hidden>
      <path
        d="M4 22 C 30 6, 60 32, 92 18 S 150 8, 196 22"
        stroke={color}
        strokeWidth={5}
        strokeLinecap="round"
        fill="none"
      />
    </svg>
  );
}

function Badge({
  label,
  title,
  unit,
  bg,
  fg,
  accent,
  rotate = 0,
}: {
  label: string;
  title: string;
  unit: number;
  bg: string;
  fg: string;
  accent: string;
  rotate?: number;
}) {
  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: unit * 0.018,
        padding: `${unit * 0.018}px ${unit * 0.026}px ${unit * 0.018}px ${unit * 0.022}px`,
        borderRadius: 999,
        background: bg,
        color: fg,
        boxShadow: "0 22px 44px -16px rgba(20,8,2,0.4), inset 0 1px 0 rgba(255,255,255,0.6)",
        transform: `rotate(${rotate}deg)`,
        fontFamily: "var(--font-body), Inter, sans-serif",
      }}
    >
      <div
        style={{
          width: unit * 0.054,
          height: unit * 0.054,
          borderRadius: unit * 0.014,
          background: accent,
          display: "grid",
          placeItems: "center",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.35)",
        }}
      >
        <svg width={unit * 0.032} height={unit * 0.032} viewBox="0 0 24 24" fill="#FFFFFF" aria-hidden>
          <path d="M12 21c-5-4-9-7-9-12 0-3 3-5 5.5-5 1.5 0 2.5 1 3.5 2 1-1 2-2 3.5-2C18 4 21 6 21 9c0 5-4 8-9 12z" />
        </svg>
      </div>
      <div>
        <div
          style={{
            fontSize: unit * 0.018,
            fontWeight: 700,
            letterSpacing: unit * 0.001,
            textTransform: "uppercase",
            color: accent,
          }}
        >
          {label}
        </div>
        <div style={{ fontSize: unit * 0.03, fontWeight: 700, letterSpacing: -unit * 0.0003 }}>{title}</div>
      </div>
    </div>
  );
}

export function RenderAccent({ cW, cH, theme, inverted, accent }: AccentProps) {
  const unit = useUnit(cW, cH);

  switch (accent.kind) {
    case "chip": {
      const { bg, fg } = toneToColors(accent.tone, theme, inverted);
      return (
        <Positioned x={accent.x} y={accent.y} anchor="center">
          <Chip
            text={accent.text}
            unit={unit}
            bg={bg}
            fg={fg}
            rotate={accent.rotate}
            icon={accent.icon ? { name: accent.icon, color: theme.accent } : undefined}
            arrow={accent.arrowDir ? { dir: accent.arrowDir, color: theme.accent } : undefined}
          />
        </Positioned>
      );
    }
    case "stat": {
      const { bg, fg } = toneToColors(accent.tone ?? "light", theme, inverted);
      return (
        <Positioned x={accent.x} y={accent.y} anchor="center">
          <StatCard
            value={accent.value}
            label={accent.label}
            unit={unit}
            bg={bg}
            fg={fg}
            accent={theme.accent}
            rotate={accent.rotate}
          />
        </Positioned>
      );
    }
    case "sparkle":
      return (
        <Positioned x={accent.x} y={accent.y} anchor="center">
          <Sparkle size={((accent.size ?? 4) / 100) * cW} color={accent.color || theme.accent} />
        </Positioned>
      );
    case "scribble":
      return (
        <Positioned x={accent.x} y={accent.y} anchor="center">
          <div style={{ transform: `rotate(${accent.rotate ?? 0}deg)` }}>
            <Scribble width={(accent.width / 100) * cW} color={accent.color || theme.accent} />
          </div>
        </Positioned>
      );
    case "badge": {
      const colors = toneToColors("light", theme, inverted);
      return (
        <Positioned x={accent.x} y={accent.y} anchor="center">
          <Badge
            label={accent.label}
            title={accent.title}
            unit={unit}
            bg={colors.bg}
            fg={colors.fg}
            accent={theme.accent}
            rotate={accent.rotate}
          />
        </Positioned>
      );
    }
    case "blob": {
      const color = accent.color || theme.accent;
      return (
        <div
          style={{
            position: "absolute",
            left: `${accent.x}%`,
            top: `${accent.y}%`,
            width: `${accent.size}%`,
            aspectRatio: "1 / 1",
            transform: "translate(-50%, -50%)",
            background: color,
            borderRadius: "50%",
            filter: `blur(${cW * 0.06}px)`,
            opacity: accent.opacity ?? 0.35,
            pointerEvents: "none",
          }}
        />
      );
    }
    case "ring": {
      const color = accent.color || theme.accent;
      const w = ((accent.width ?? 0.4) / 100) * cW;
      return (
        <div
          style={{
            position: "absolute",
            left: `${accent.x}%`,
            top: `${accent.y}%`,
            width: `${accent.size}%`,
            aspectRatio: "1 / 1",
            transform: "translate(-50%, -50%)",
            border: `${w}px solid ${color}`,
            borderRadius: "50%",
            opacity: accent.opacity ?? 0.5,
            pointerEvents: "none",
          }}
        />
      );
    }
    default:
      return null;
  }
}

function Positioned({
  x,
  y,
  anchor = "center",
  children,
}: {
  x: number;
  y: number;
  anchor?: "center" | "top-left";
  children: React.ReactNode;
}) {
  const translate =
    anchor === "center" ? "translate(-50%, -50%)" : "translate(0, 0)";
  return (
    <div
      style={{
        position: "absolute",
        left: `${x}%`,
        top: `${y}%`,
        transform: translate,
        pointerEvents: "none",
        zIndex: 5,
      }}
    >
      {children}
    </div>
  );
}

// Build a background style string for the whole canvas based on bgStyle.
export function buildBackground(
  bgStyle: string | undefined,
  theme: Theme,
  inverted: boolean,
): string {
  const base = inverted ? theme.bgAlt : theme.bg;
  const baseAlt = inverted ? "#0b0b0c" : shade(base, -8);
  switch (bgStyle) {
    case "block":
      return base;
    case "soft":
      return `radial-gradient(120% 90% at 50% 0%, ${shade(base, 4)} 0%, ${base} 60%, ${baseAlt} 100%)`;
    case "dots":
      return `radial-gradient(circle at 25% 30%, ${shade(base, -3)} 1px, transparent 2px) 0 0 / 36px 36px, ${base}`;
    case "mesh":
      return [
        `radial-gradient(60% 50% at 20% 10%, ${withAlpha(theme.accent, 0.35)} 0%, transparent 60%)`,
        `radial-gradient(50% 40% at 100% 0%, ${withAlpha(theme.accent, 0.28)} 0%, transparent 70%)`,
        `radial-gradient(70% 60% at 80% 100%, ${withAlpha(theme.accent, 0.32)} 0%, transparent 65%)`,
        `linear-gradient(160deg, ${base} 0%, ${baseAlt} 100%)`,
      ].join(", ");
    case "gradient":
    default:
      return `linear-gradient(160deg, ${base} 0%, ${baseAlt} 100%)`;
  }
}

function shade(hex: string, percent: number) {
  const c = hex.replace("#", "");
  const num = parseInt(c.length === 3 ? c.split("").map((x) => x + x).join("") : c, 16);
  let r = (num >> 16) & 0xff;
  let g = (num >> 8) & 0xff;
  let b = num & 0xff;
  const amt = Math.round((255 * percent) / 100);
  r = Math.max(0, Math.min(255, r + amt));
  g = Math.max(0, Math.min(255, g + amt));
  b = Math.max(0, Math.min(255, b + amt));
  return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, "0")}`;
}

function withAlpha(hex: string, alpha: number) {
  const c = hex.replace("#", "");
  const full = c.length === 3 ? c.split("").map((x) => x + x).join("") : c;
  const num = parseInt(full, 16);
  const r = (num >> 16) & 0xff;
  const g = (num >> 8) & 0xff;
  const b = num & 0xff;
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}
