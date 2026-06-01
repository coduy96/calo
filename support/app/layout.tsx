import type { Metadata, Viewport } from "next";
import { Archivo, Hanken_Grotesk } from "next/font/google";
import "./globals.css";

// Landing-page type system (Archivo = heavy display, Hanken Grotesk = body).
// Both are variable fonts, so the full weight axis (incl. 900) is available.
const archivo = Archivo({
  variable: "--font-archivo",
  subsets: ["latin"],
  display: "swap",
});

const hanken = Hanken_Grotesk({
  variable: "--font-hanken",
  subsets: ["latin"],
  display: "swap",
});

const siteUrl = "https://voidpen.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "Voidpen — AI calorie tracking for iOS",
    template: "%s · Voidpen",
  },
  description:
    "Snap a photo, talk to your Coach, hit your goals. Voidpen makes calorie tracking effortless on iPhone with AI photo scanning, voice logging, and HealthKit sync.",
  applicationName: "Voidpen",
  keywords: [
    "calorie tracker",
    "AI nutrition",
    "photo calorie counter",
    "voice food log",
    "macro tracker",
    "iOS calorie app",
  ],
  authors: [{ name: "Co Trinh Hien Duy" }],
  openGraph: {
    type: "website",
    url: siteUrl,
    siteName: "Voidpen",
    title: "Voidpen — AI calorie tracking for iOS",
    description:
      "Snap a photo, talk to your Coach, hit your goals. AI calorie tracking that feels effortless.",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "Voidpen — AI calorie tracking",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Voidpen — AI calorie tracking for iOS",
    description:
      "Snap a photo, talk to your Coach, hit your goals. AI calorie tracking that feels effortless.",
    images: ["/og.png"],
  },
  alternates: {
    canonical: siteUrl,
  },
};

export const viewport: Viewport = {
  themeColor: "#F6EFE4",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${archivo.variable} ${hanken.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col bg-cream text-ink font-sans">
        {children}
      </body>
    </html>
  );
}
