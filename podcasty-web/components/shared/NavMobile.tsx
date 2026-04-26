import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { AiOutlineMenu } from "react-icons/ai";
import SidebarLinks from "./SidebarLinks";
import Link from "next/link";
import { BiLogIn, BiSolidUserVoice } from "react-icons/bi";
import { getUser } from "@/app/lib/supabase";
import LogoutButton from "../buttons/LogoutButton";
import { VisuallyHidden} from '@radix-ui/react-visually-hidden';

const MobileNav = async () => {
  const user = await getUser();

  return (
    <Sheet>
      <SheetTrigger asChild>
        <AiOutlineMenu className="text-app-text text-3xl cursor-pointer" />
      </SheetTrigger>
      <SheetContent side="left" className="border-r border-app-border bg-app-bg w-72 p-0 flex flex-col">
        <SheetTitle>
          <VisuallyHidden>Menu</VisuallyHidden>
        </SheetTitle>

        <nav className="flex-1 overflow-y-auto px-3 pt-12 pb-4">
          <SheetClose asChild>
            <div className="flex flex-col gap-0.5">
              <SidebarLinks compact />
            </div>
          </SheetClose>
        </nav>

        <div className="border-t border-app-border px-3 py-3 flex flex-col gap-2">
          {user ? (
            <>
              <SheetClose asChild>
                <Link
                  href={`/profile/${user.id}`}
                  className="text-app-muted hover:text-app-text flex items-center gap-2.5 px-2.5 py-2 rounded-lg hover:bg-app-raised transition-colors text-xs font-medium">
                  <BiSolidUserVoice className="text-sm" /> My Profile
                </Link>
              </SheetClose>
              <LogoutButton />
            </>
          ) : (
            <SheetClose asChild>
              <Link
                href={`/login`}
                className="text-app-muted hover:text-app-text flex items-center gap-2.5 px-2.5 py-2 rounded-lg hover:bg-app-raised transition-colors text-xs font-medium">
                <BiLogIn className="text-sm" /> Login
              </Link>
            </SheetClose>
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
};

export default MobileNav;
