import Logo from "@/components/shared/Logo";
import RigthSidebar from "@/components/shared/RigthSidebar";
import MobileNav from "@/components/shared/NavMobile";
import LeftSidebar from "@/components/shared/LeftSidebar";
import { Suspense } from "react";
import LoaderSpinner from "./loading";
import { getUser } from "../lib/supabase";
import { redirect } from "next/navigation";
import { ThemeToggle } from "@/components/shared/ThemeToggle";

// Every route in this group is behind auth and reads cookies, so there is
// nothing to prerender. Opting out here keeps Next from attempting a static
// render and surfacing DYNAMIC_SERVER_USAGE at build time.
export const dynamic = "force-dynamic";

export default async function GroupedLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const user = await getUser();
  if(!user) redirect("/login");
  return (
    <>
      <LeftSidebar />
        {" "}
        <main className="flex-1 min-w-0">
          <div className="flex px-4 h-16 items-center justify-between lg:hidden border-b border-app-border bg-app-surface/90 backdrop-blur-sm">
            <Logo />
            <div className="flex items-center gap-1">
              <ThemeToggle iconOnly />
              <MobileNav />
            </div>
          </div>
          <Suspense fallback={<LoaderSpinner />}>{children}</Suspense>
        </main>
      <RigthSidebar />
    </>
  );
}
