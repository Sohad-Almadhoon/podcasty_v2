"use client";
import { useTheme } from "next-themes";
import { Moon, Sun } from "lucide-react";
import { useEffect, useState } from "react";

export function ThemeToggle({ iconOnly = false }: { iconOnly?: boolean }) {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);
  if (!mounted) return null;

  return (
    <button
      onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
      title={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
      className={
        iconOnly
          ? "flex items-center justify-center w-8 h-8 rounded-lg text-app-muted hover:text-app-text hover:bg-app-raised transition-colors shrink-0"
          : "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-app-muted hover:text-app-text hover:bg-app-raised transition-colors w-full"
      }
    >
      {theme === "dark" ? (
        <Sun className="w-4 h-4" />
      ) : (
        <Moon className="w-4 h-4" />
      )}
      {!iconOnly && (theme === "dark" ? "Light mode" : "Dark mode")}
    </button>
  );
}
