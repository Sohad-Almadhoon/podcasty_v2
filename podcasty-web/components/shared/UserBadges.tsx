"use client";

import { useEffect, useState } from "react";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

interface BadgeDefinition {
  key: string;
  name: string;
  description: string;
  icon: string;
}

interface EarnedBadge {
  id: string;
  badge_key: string;
  earned_at: string;
  badge: BadgeDefinition;
}

interface BadgeResponse {
  earned: EarnedBadge[];
  catalog: BadgeDefinition[];
}

const UserBadges = ({ userId }: { userId: string }) => {
  const [data, setData] = useState<BadgeResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080";
        const res = await fetch(`${apiUrl}/api/badges?user_id=${userId}`);
        if (res.ok) {
          setData(await res.json());
        }
      } catch {
        // Silently fail — badges are non-critical
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [userId]);

  if (loading || !data) return null;

  const earnedKeys = new Set(data.earned.map((b) => b.badge_key));

  if (data.earned.length === 0) return null;

  return (
    <div className="mt-3">
      <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">
        Badges ({data.earned.length}/{data.catalog.length})
      </p>
      <TooltipProvider delayDuration={200}>
        <div className="flex flex-wrap gap-1.5">
          {data.catalog.map((badge) => {
            const earned = earnedKeys.has(badge.key);
            const earnedBadge = data.earned.find((b) => b.badge_key === badge.key);
            return (
              <Tooltip key={badge.key}>
                <TooltipTrigger asChild>
                  <span
                    className={`inline-flex items-center gap-1 px-2 py-1 rounded-lg border text-xs transition-all cursor-default ${
                      earned
                        ? "border-app-accent/40 bg-app-accent/10 text-app-text"
                        : "border-app-border bg-app-surface text-app-subtle opacity-40 grayscale"
                    }`}
                  >
                    <span className="text-sm">{badge.icon}</span>
                    {badge.name}
                  </span>
                </TooltipTrigger>
                <TooltipContent side="bottom" className="max-w-[200px]">
                  <p className="text-xs font-medium">{badge.name}</p>
                  <p className="text-xs text-muted-foreground">{badge.description}</p>
                  {earned && earnedBadge && (
                    <p className="text-xs text-muted-foreground mt-1">
                      Earned {new Date(earnedBadge.earned_at).toLocaleDateString()}
                    </p>
                  )}
                </TooltipContent>
              </Tooltip>
            );
          })}
        </div>
      </TooltipProvider>
    </div>
  );
};

export default UserBadges;
