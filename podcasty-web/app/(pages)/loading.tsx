"use client";

import { Loader } from "lucide-react";

const LoaderSpinner = () => {
  return (
    <div className="flex flex-col items-center justify-center h-screen w-full">
      <Loader className="animate-spin text-orange-1" size={60} />
    </div>
  );
};

export default LoaderSpinner;
