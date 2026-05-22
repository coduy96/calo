import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
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
  icons: {
    icon: "/favicon.ico",
  },
  alternates: {
    canonical: siteUrl,
  },
};

export const viewport: Viewport = {
  themeColor: "#0a0a0a",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${inter.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col bg-[#0a0a0a] text-neutral-100 font-sans">
        {children}
      </body>
    </html>
  );
}
