"use client";
import { usePathname } from "next/navigation";
import Link from "next/link";
import { sidebarLinks } from "@/app/constants";

const SidebarLinks = ({ compact = false }: { compact?: boolean }) => {
  const pathname = usePathname();

  return (
    <>
      {sidebarLinks.map(({ href, label, icon: Icon }) => (
        <Link
          key={href}
          href={href}
          className={`flex items-center rounded-lg font-medium transition-all duration-200 ${
            compact ? "gap-2.5 px-2.5 py-2 text-xs" : "gap-3 px-3 py-2.5 text-sm"
          } ${
            pathname === href
              ? "bg-app-accent text-white shadow-app"
              : "text-app-muted hover:text-app-text hover:bg-app-raised"
          }`}>
          <Icon className={compact ? "text-sm" : "text-base"} /> {label}
        </Link>
      ))}
    </>
  );
};
export default SidebarLinks;
