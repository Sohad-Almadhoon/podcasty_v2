import Discover from "@/components/Discover";
import { Mic2 } from "lucide-react";
import Link from "next/link";

const Podcasts = async () => {
  return (
    <div className="min-h-screen">
      <div className="border-b border-app-border px-6 py-8">
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">Library</p>
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-app-text">Discover Podcasts</h1>
          <Link
            href="/podcasts/create"
            className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-app-accent text-white text-xs font-semibold hover:opacity-90 transition-opacity">
            <Mic2 className="w-3.5 h-3.5" /> Create
          </Link>
        </div>
      </div>
      <div className="px-6 py-8">
        <Discover />
      </div>
    </div>
  );
};

export default Podcasts;
