import { DEFAULT_LOCALE } from "./locale";
import type { Device, ProjectState, Slide, SlideAccent } from "./types";

let _id = 0;
export const nid = () => `s_${Date.now().toString(36)}_${(_id++).toString(36)}`;

const en = (s: string) => ({ [DEFAULT_LOCALE]: s });

// Voidpen — calorie tracking with AI vision, AI coach, widgets, Apple Health.
// Narrative arc: hero → differentiator → vision → coach → ecosystem → trust.
function iphoneSlides(): Slide[] {
  // ---- Slide 1: HERO ----
  const s1Accents: SlideAccent[] = [
    { kind: "ring", x: 18, y: 18, size: 14, opacity: 0.35, width: 0.35 },
    { kind: "sparkle", x: 88, y: 16, size: 4 },
    { kind: "sparkle", x: 10, y: 62, size: 3 },
    { kind: "stat", value: "1,625", label: "Calories today", x: 82, y: 56, rotate: 6, tone: "light" },
    { kind: "stat", value: "61", label: "Kcal left", x: 14, y: 78, rotate: -7, tone: "accent" },
    { kind: "scribble", x: 50, y: 33, width: 22, rotate: -3 },
  ];

  // ---- Slide 2: INPUT METHODS ----
  const s2Accents: SlideAccent[] = [
    { kind: "chip", text: "Photo", x: 16, y: 40, rotate: -6, icon: "camera", tone: "light" },
    { kind: "chip", text: "Barcode", x: 84, y: 38, rotate: 5, icon: "barcode", tone: "light" },
    { kind: "chip", text: "Voice", x: 12, y: 62, rotate: 4, icon: "voice", tone: "accent" },
    { kind: "chip", text: "Nutrition Label", x: 87, y: 64, rotate: -4, tone: "light" },
    { kind: "sparkle", x: 28, y: 22, size: 3 },
    { kind: "sparkle", x: 75, y: 80, size: 3 },
  ];

  // ---- Slide 3: AI VISION (device-top) ----
  const s3Accents: SlideAccent[] = [
    { kind: "stat", value: "740", label: "kcal", x: 14, y: 24, rotate: -7, tone: "light" },
    { kind: "stat", value: "56g", label: "Protein", x: 86, y: 30, rotate: 6, tone: "accent" },
    { kind: "chip", text: "Salmon · broccoli · quinoa", x: 50, y: 56, icon: "spark", tone: "dark" },
    { kind: "sparkle", x: 18, y: 14, size: 4 },
    { kind: "sparkle", x: 88, y: 18, size: 3 },
  ];

  // ---- Slide 4: AI COACH (inverted) ----
  const s4Accents: SlideAccent[] = [
    { kind: "blob", x: 90, y: 20, size: 35, opacity: 0.45 },
    { kind: "chip", text: '"How can I hit my protein goal?"', x: 22, y: 48, rotate: -5, tone: "light" },
    { kind: "chip", text: "Greek yogurt + berries", x: 84, y: 60, rotate: 6, icon: "spark", tone: "accent" },
    { kind: "sparkle", x: 14, y: 26, size: 4, color: "#FFB347" },
    { kind: "sparkle", x: 86, y: 80, size: 3, color: "#FFB347" },
    { kind: "scribble", x: 50, y: 92, width: 26, color: "#FFB347" },
  ];

  // ---- Slide 5: WIDGETS ----
  const s5Accents: SlideAccent[] = [
    { kind: "chip", text: "Lock screen", x: 16, y: 30, rotate: -6, icon: "check", tone: "light" },
    { kind: "chip", text: "Home screen", x: 84, y: 30, rotate: 5, icon: "check", tone: "light" },
    { kind: "chip", text: "StandBy", x: 16, y: 70, rotate: 5, icon: "check", tone: "light" },
    { kind: "chip", text: "Apple Watch", x: 84, y: 70, rotate: -5, icon: "check", tone: "accent" },
    { kind: "sparkle", x: 50, y: 18, size: 4 },
  ];

  // ---- Slide 6: APPLE HEALTH ----
  const s6Accents: SlideAccent[] = [
    { kind: "badge", label: "Synced", title: "Apple Health", x: 50, y: 33, rotate: -2 },
    { kind: "chip", text: "Weight", x: 12, y: 58, rotate: -7, icon: "health", tone: "light" },
    { kind: "chip", text: "Calories", x: 88, y: 54, rotate: 6, icon: "fire", tone: "accent" },
    { kind: "chip", text: "Steps · Sleep", x: 14, y: 82, rotate: 6, tone: "light" },
    { kind: "sparkle", x: 8, y: 44, size: 3 },
    { kind: "sparkle", x: 92, y: 70, size: 3 },
  ];

  return [
    {
      id: nid(),
      layout: "hero",
      label: en("MEET VOIDPEN"),
      headline: en("Hit your calories.\nSkip the math."),
      screenshot: "/screenshots/apple/iphone/{locale}/01.png",
      bgStyle: "mesh",
      accents: s1Accents,
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("ANY INPUT"),
      headline: en("Snap, scan, type,\nor just talk."),
      screenshot: "/screenshots/apple/iphone/{locale}/02.png",
      bgStyle: "soft",
      accents: s2Accents,
    },
    {
      id: nid(),
      layout: "device-top",
      label: en("AI VISION"),
      headline: en("Point. Shoot.\nDone counting."),
      screenshot: "/screenshots/apple/iphone/{locale}/03.png",
      bgStyle: "soft",
      accents: s3Accents,
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("AI COACH"),
      headline: en("Ask anything.\nGet a plan."),
      screenshot: "/screenshots/apple/iphone/{locale}/04.png",
      inverted: true,
      bgStyle: "mesh",
      accents: s4Accents,
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("WIDGETS"),
      headline: en("Don't open.\nJust glance."),
      screenshot: "/screenshots/apple/iphone/{locale}/05.png",
      bgStyle: "dots",
      accents: s5Accents,
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("APPLE HEALTH"),
      headline: en("Lives in\nApple Health."),
      screenshot: "/screenshots/apple/iphone/{locale}/06.png",
      bgStyle: "soft",
      accents: s6Accents,
    },
  ];
}

function ipadSlides(): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("MEET VOIDPEN"),
      headline: en("Hit your calories.\nSkip the math."),
      screenshot: "/screenshots/apple/ipad/{locale}/01.png",
      bgStyle: "mesh",
      accents: [
        { kind: "ring", x: 14, y: 14, size: 10, opacity: 0.35, width: 0.3 },
        { kind: "sparkle", x: 90, y: 18, size: 3 },
        { kind: "stat", value: "1,625", label: "Calories today", x: 85, y: 60, rotate: 6, tone: "light" },
        { kind: "stat", value: "61", label: "Kcal left", x: 12, y: 78, rotate: -7, tone: "accent" },
      ],
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("ANY INPUT"),
      headline: en("Snap, scan, type,\nor just talk."),
      screenshot: "/screenshots/apple/ipad/{locale}/02.png",
      bgStyle: "soft",
      accents: [
        { kind: "chip", text: "Photo", x: 14, y: 42, rotate: -6, icon: "camera", tone: "light" },
        { kind: "chip", text: "Barcode", x: 86, y: 38, rotate: 5, icon: "barcode", tone: "light" },
        { kind: "chip", text: "Voice", x: 14, y: 60, rotate: 4, icon: "voice", tone: "accent" },
      ],
    },
    {
      id: nid(),
      layout: "device-top",
      label: en("AI COACH"),
      headline: en("Ask anything.\nGet a plan."),
      screenshot: "/screenshots/apple/ipad/{locale}/04.png",
      inverted: true,
      bgStyle: "mesh",
      accents: [
        { kind: "chip", text: '"How do I hit my protein goal?"', x: 18, y: 50, rotate: -4, tone: "light" },
        { kind: "chip", text: "Greek yogurt + berries", x: 84, y: 62, rotate: 6, icon: "spark", tone: "accent" },
        { kind: "sparkle", x: 14, y: 26, size: 3, color: "#FFB347" },
      ],
    },
  ];
}

function androidStarter(): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("MEET VOIDPEN"),
      headline: en("Hit your calories.\nSkip the math."),
      screenshot: "",
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("ANY INPUT"),
      headline: en("Snap, scan, type,\nor just talk."),
      screenshot: "",
    },
  ];
}

function tabletStarter(kind: "7" | "10"): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("MEET VOIDPEN"),
      headline: en(kind === "7" ? "Pocket-sized\npower." : "Made for\nthe big screen."),
      screenshot: "",
    },
    {
      id: nid(),
      layout: "split-landscape",
      label: en("FEATURE 01"),
      headline: en("Wide canvas,\nbigger ideas."),
      screenshot: "",
    },
  ];
}

function fgStarter(): Slide[] {
  return [
    {
      id: nid(),
      layout: "feature-graphic",
      label: {},
      headline: en("Track calories without thinking."),
      screenshot: "",
    },
  ];
}

export const DEFAULT_PROJECT: ProjectState = {
  appName: "Voidpen",
  themeId: "warm-editorial",
  locales: [DEFAULT_LOCALE],
  locale: DEFAULT_LOCALE,
  device: "iphone",
  orientation: "portrait",
  appIcon: "/app-icon.png",
  slidesByDevice: {
    iphone: iphoneSlides(),
    android: androidStarter(),
    ipad: ipadSlides(),
    "android-7": tabletStarter("7"),
    "android-10": tabletStarter("10"),
    "feature-graphic": fgStarter(),
  },
};

export function newSlide(layout: Slide["layout"] = "device-bottom"): Slide {
  return {
    id: nid(),
    layout,
    label: en("NEW"),
    headline: en("Edit this\nheadline."),
    screenshot: "",
  };
}

export function detectPlatform(device: Device): "ios" | "android" {
  return device === "iphone" || device === "ipad" ? "ios" : "android";
}
