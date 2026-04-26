import './globals.css';
import { ReactNode } from "react";
import type { Viewport } from "next";
import { Montserrat, Dancing_Script } from 'next/font/google';
import PodcastPlayer from '@/components/shared/PodcastPlayer';
import AudioProvider from './providers/AudioProvider';
import { ThemeProvider } from './providers/ThemeProvider';
import { Toaster } from '@/components/ui/sonner';
import NextTopLoader from 'nextjs-toploader';

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
};

const montserrat = Montserrat({
  subsets: ['latin'],
  variable: '--font-montserrat', 
});

const dancingScript = Dancing_Script({
  subsets: ['latin'],
  variable: '--font-dancing-script', 
});
export default function BasicLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${montserrat.variable} ${dancingScript.variable} font-montserrat antialiased`}
        suppressHydrationWarning={true}>
        <NextTopLoader
          color="#9333ea"
          initialPosition={0.08}
          crawlSpeed={200}
          height={3}
          crawl={true}
          showSpinner={false}
          easing="ease"
          speed={200}
          shadow="0 0 10px #9333ea,0 0 5px #9333ea"
        />
        <ThemeProvider>
          <AudioProvider>
            <div className="flex min-h-dvh bg-app-bg">
              {children}
            </div>
            <PodcastPlayer />
          </AudioProvider>
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
