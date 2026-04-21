"use client";
import { signInWithGoogle } from "@/app/lib/auth";
import { Button } from "@/components/ui/button";
import { useState } from "react";

const LoginButton = () => {
  const [isLoading, setIsLoading] = useState(false);

  const handleSignIn = async () => {
    try {
      setIsLoading(true);
      const url = await signInWithGoogle();
      if (url) {
        window.location.href = url;
      }
    } catch (error) {
      console.error('Sign in error:', error);
      setIsLoading(false);
    }
  };

  return (
    <Button
      onClick={handleSignIn}
      disabled={isLoading}
      size="lg"
      className="bg-app-accent text-app-accent-fg hover:opacity-90 font-semibold px-8 text-base">
      {isLoading ? "Signing in..." : "Continue with Google"}
    </Button>
  );
};

export default LoginButton;
