"use client";
import { usePathname } from "next/navigation";
import Link from "next/link";
import { sidebarLinks } from "@/app/constants";

const SidebarLinks = () => {
  const pathname = usePathname();

  return (
    <>
      {sidebarLinks.map(({ href, label, icon: Icon }) => (
        <Link
          key={href}
          href={href}
          className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 ${
            pathname === href
              ? "bg-app-accent text-white shadow-app"
              : "text-app-muted hover:text-app-text hover:bg-app-raised"
          }`}>
          <Icon className="text-base" /> {label}
        </Link>
      ))}
    </>
  );
};
export default SidebarLinks;
