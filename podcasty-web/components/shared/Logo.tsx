import Link from 'next/link';
import React from 'react';
import { Mic2 } from 'lucide-react';

const Logo = () => {
  return (
    <Link href="/" className="flex items-center gap-2.5 px-4 py-5">
      <div className="flex items-center justify-center w-8 h-8 bg-app-accent rounded-lg">
        <Mic2 className="w-4 h-4 text-app-accent-fg" />
      </div>
      <span className="font-bold text-app-text text-lg tracking-tight">
        Podcastify
      </span>
    </Link>
  );
};

export default Logo;