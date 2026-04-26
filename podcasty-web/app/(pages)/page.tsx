import Link from "next/link";
import { getUser } from "../lib/supabase";
import LoaderSpinner from "./loading";
import { fetchTrendingPodcasts } from "../lib/api-client";
import Image from "next/image";
import { Mic2, Sparkles, Headphones, ArrowRight, Wand2, Radio } from "lucide-react";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";

export default async function Home() {
  const user = await getUser();
  if (!user) return <LoaderSpinner />;
  
  // Fetch trending podcasts from Go backend
  let trending: any[] = [];
  try {
    trending = await fetchTrendingPodcasts();
  } catch (error) {
    console.error('Failed to fetch trending podcasts:', error);
  }

  const features = [
    { icon: Wand2, title: "AI-Generated Audio", desc: "Type a prompt, get a full podcast episode with a natural AI voice." },
    { icon: Sparkles, title: "Cover Art", desc: "DALL·E 3 generates a unique cover image for every podcast automatically." },
    { icon: Radio, title: "7 Voice Styles", desc: "Choose from Alloy, Coral, Echo, Fable, Onyx, Nova or Shimmer." },
    { icon: Headphones, title: "Stream Instantly", desc: "Built-in audio player with progress tracking and play counts." },
  ];

  return (
    <main className="flex-1 min-h-screen">
      {/* Hero */}
      <section className="border-b border-app-border px-6 py-12">
        <Badge variant="outline" className="border-app-border text-app-muted mb-4">
          AI-Powered Podcasting
        </Badge>
        <h1 className="text-4xl font-bold tracking-tight text-app-text mb-2">
          Welcome back,{" "}
          <span className="text-app-accent">{user.user_metadata.full_name?.split(" ")[0]}</span>
        </h1>
        <p className="text-app-muted text-sm max-w-md mb-8">
          Turn any idea into a professional podcast episode with AI-generated audio and cover art — in under a minute.
        </p>
        <div className="flex flex-wrap gap-3">
          <Link
            href="/podcasts/create"
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity shadow-app-md">
            <Mic2 className="w-4 h-4" /> Create a Podcast
          </Link>
          <Link
            href="/podcasts"
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-app-surface border border-app-border text-app-text text-sm font-semibold hover:bg-app-raised transition-colors">
            Browse All <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </section>

      {/* Features grid */}
      <section className="border-b border-app-border px-6 py-10">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-6">What you can do</p>
        <div className="grid sm:grid-cols-2 gap-4">
          {features.map(({ icon: Icon, title, desc }) => (
            <div key={title} className="rounded-xl border border-app-border bg-app-surface p-5 hover:border-app-muted hover:shadow-app transition-all">
              <div className="flex items-center justify-center w-9 h-9 rounded-lg bg-app-raised mb-3">
                <Icon className="w-4 h-4 text-app-accent" />
              </div>
              <p className="text-sm font-semibold text-app-text mb-1">{title}</p>
              <p className="text-xs text-app-subtle leading-relaxed">{desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Trending */}
      {trending.length > 0 && (
        <section className="px-6 py-10">
          <div className="flex items-center justify-between mb-6">
            <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest">Trending now</p>
            <Link href="/podcasts" className="text-xs text-app-accent hover:underline flex items-center gap-1">
              View all <ArrowRight className="w-3 h-3" />
            </Link>
          </div>
          <ul className="space-y-1">
            {trending.map((p, i) => (
              <Link key={p.id} href={`/podcasts/${p.id}`}>
                <li className="flex items-center gap-4 px-3 py-3 rounded-lg hover:bg-app-raised transition-colors group">
                  <span className="text-xs text-app-subtle w-4 shrink-0 font-mono">{i + 1}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-app-text truncate">{p.podcast_name}</p>
                    <p className="text-xs text-app-subtle">{(p.users as any)?.username}</p>
                  </div>
                  <div className="flex items-center gap-1 text-xs text-app-subtle">
                    <Headphones className="w-3 h-3" /> {p.play_count}
                  </div>
                </li>
              </Link>
            ))}
          </ul>
        </section>
      )}

      {/* Quick-start CTA */}
      <section className="mx-6 mb-10 rounded-xl border border-app-border bg-app-surface p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <p className="text-sm font-semibold text-app-text">Ready to create?</p>
          <p className="text-xs text-app-subtle mt-0.5">Your next podcast is one prompt away.</p>
        </div>
        <Link
          href="/podcasts/create"
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-app-accent text-white text-xs font-semibold hover:opacity-90 transition-opacity shrink-0">
          <Sparkles className="w-3.5 h-3.5" /> Get started
        </Link>
      </section>
    </main>
  );
}
