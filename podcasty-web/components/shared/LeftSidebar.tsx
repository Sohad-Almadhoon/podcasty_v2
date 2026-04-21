import { BiLogIn, BiSolidUserVoice } from "react-icons/bi";
import Link from "next/link";
import { getUser } from "@/app/lib/supabase";
import SidebarLinks from "./SidebarLinks";
import Logo from "./Logo";
import LogoutButton from "../buttons/LogoutButton";
import { Separator } from "@/components/ui/separator";
import { ThemeToggle } from "./ThemeToggle";

const LeftSidebar = async () => {
  const user = await getUser();

  return (
    <aside className="lg:flex hidden flex-col w-64 min-h-screen border-r border-app-border bg-app-bg">
      <div className="relative flex items-center">
        <Logo />
        <div className="absolute right-2 top-1/2 -translate-y-1/2">
          <ThemeToggle iconOnly />
        </div>
      </div>
      <Separator className="bg-app-border" />
      <div className="flex flex-col flex-1 gap-1 px-3 py-4">
        <SidebarLinks />
      </div>
      <Separator className="bg-app-border" />
      <div className="flex flex-col gap-2 p-3">
        {user ? (
          <>
            <Link
              href={`/profile/${user.id}`}
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-app-muted hover:text-app-text hover:bg-app-raised transition-colors">
              <BiSolidUserVoice className="text-base" /> My Profile
            </Link>
            <LogoutButton />
          </>
        ) : (
          <Link
            href="/login"
            className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-app-muted hover:text-app-text hover:bg-app-raised transition-colors">
            <BiLogIn className="text-base" /> Login
          </Link>
        )}
      </div>
    </aside>
  );
};

export default LeftSidebar;
