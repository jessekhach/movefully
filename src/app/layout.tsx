import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/contexts/AuthContext";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Movefully - Personal Training Made Simple",
  description: "A personal training platform focused on making fitness simple, accessible, and focused on overall movement and well-being.",
  manifest: "/manifest.json",
  themeColor: "#f97316", // Warm orange color
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={`${inter.className} bg-orange-50 min-h-screen`}>
        <AuthProvider>
          <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            {children}
          </main>
        </AuthProvider>
      </body>
    </html>
  );
}
