import Logo from "@/components/shared/Logo";
import RigthSidebar from "@/components/shared/RigthSidebar";
import MobileNav from "@/components/shared/NavMobile";
import LeftSidebar from "@/components/shared/LeftSidebar";
import { Suspense } from "react";
import LoaderSpinner from "./loading";
import { getUser } from "../lib/supabase";
import { redirect } from "next/navigation";
import { ThemeToggle } from "@/components/shared/ThemeToggle";

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
        <main className="flex-1">
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
