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

        <nav className="flex-1 overflow-y-auto px-4 pt-12 pb-4">
          <SheetClose asChild>
            <div className="flex flex-col gap-1">
              <SidebarLinks />
            </div>
          </SheetClose>
        </nav>

        <div className="border-t border-app-border px-4 py-4 flex flex-col gap-3">
          {user ? (
            <>
              <SheetClose asChild>
                <Link
                  href={`/profile/${user.id}`}
                  className="text-app-muted hover:text-app-text flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-app-raised transition-colors text-sm">
                  <BiSolidUserVoice className="text-base" /> My Profile
                </Link>
              </SheetClose>
              <LogoutButton />
            </>
          ) : (
            <SheetClose asChild>
              <Link
                href={`/login`}
                className="text-app-muted hover:text-app-text flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-app-raised transition-colors text-sm">
                <BiLogIn className="text-base" /> Login
              </Link>
            </SheetClose>
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
};

export default MobileNav;
