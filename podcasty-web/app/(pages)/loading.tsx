"use client";

import { useEffect, useState } from "react";
import { Loader } from "lucide-react";

const WARMUP_THRESHOLD_MS = 2000;

const LoaderSpinner = () => {
  const [warming, setWarming] = useState(false);

  useEffect(() => {
    const t = setTimeout(() => setWarming(true), WARMUP_THRESHOLD_MS);
    return () => clearTimeout(t);
  }, []);

  return (
    <div className="flex flex-col items-center justify-center h-screen w-full gap-6 px-6">
      <Loader className="animate-spin text-orange-1" size={60} />
      {warming && (
        <div className="max-w-md text-center rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-3">
          <p className="text-sm font-medium text-amber-600 dark:text-amber-400">
            Waking server up
          </p>
          <p className="text-xs text-amber-700/80 dark:text-amber-300/80 mt-1">
            First request after a while takes ~30s on the free tier.
          </p>
        </div>
      )}
    </div>
  );
};

export default LoaderSpinner;
