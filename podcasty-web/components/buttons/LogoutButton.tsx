import { signOut } from "@/app/lib/auth";
import { Button } from "@/components/ui/button";

const LogoutButton = () => {
  return (
    <form action={signOut}>
      <Button
        variant="outline"
        size="sm"
        className="w-full border-app-border bg-transparent text-app-muted hover:bg-app-raised hover:text-app-text">
        Sign out
      </Button>
    </form>
  );
};

export default LogoutButton;
