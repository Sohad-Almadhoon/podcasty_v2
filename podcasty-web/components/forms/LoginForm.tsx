"use client";

import { useState } from "react";
import { signInWithGoogle, signInWithGithub, signInWithOtp, verifyOtp } from "@/app/lib/auth";
import { Button } from "@/components/ui/button";
import { FcGoogle } from "react-icons/fc";
import { FaGithub } from "react-icons/fa";
import { HiOutlineMail } from "react-icons/hi";
import { BiArrowBack } from "react-icons/bi";
import { useRouter } from "next/navigation";

type View = "main" | "email" | "otp";

const LoginForm = () => {
  const [view, setView] = useState<View>("main");
  const [email, setEmail] = useState("");
  const [otpCode, setOtpCode] = useState("");
  const [isLoading, setIsLoading] = useState<string | null>(null);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);
  const router = useRouter();

  const handleGoogleSignIn = async () => {
    try {
      setIsLoading("google");
      setMessage(null);
      const url = await signInWithGoogle();
      if (url) {
        window.location.href = url;
      }
    } catch {
      setMessage({ type: "error", text: "Failed to sign in with Google" });
      setIsLoading(null);
    }
  };

  const handleGithubSignIn = async () => {
    try {
      setIsLoading("github");
      setMessage(null);
      const url = await signInWithGithub();
      if (url) {
        window.location.href = url;
      }
    } catch {
      setMessage({ type: "error", text: "Failed to sign in with GitHub" });
      setIsLoading(null);
    }
  };

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    try {
      setIsLoading("otp");
      setMessage(null);
      const result = await signInWithOtp(email);
      if (result.success) {
        setMessage({ type: "success", text: result.message });
        setView("otp");
      } else {
        setMessage({ type: "error", text: result.message });
      }
    } catch {
      setMessage({ type: "error", text: "Failed to send verification code" });
    } finally {
      setIsLoading(null);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otpCode.trim()) return;
    try {
      setIsLoading("verify");
      setMessage(null);
      const result = await verifyOtp(email, otpCode);
      if (result.success) {
        router.push("/podcasts");
      } else {
        setMessage({ type: "error", text: result.message || "Verification failed" });
      }
    } catch {
      setMessage({ type: "error", text: "Failed to verify code" });
    } finally {
      setIsLoading(null);
    }
  };

  if (view === "otp") {
    return (
      <div className="space-y-5">
        <button
          onClick={() => { setView("email"); setMessage(null); setOtpCode(""); }}
          className="flex items-center gap-1.5 text-sm text-app-subtle hover:text-app-text transition-colors"
        >
          <BiArrowBack className="text-lg" />
          Back
        </button>

        <div>
          <h3 className="text-lg font-semibold text-app-text">Check your email</h3>
          <p className="text-sm text-app-subtle mt-1">
            We sent a 6-digit code to <span className="text-app-text font-medium">{email}</span>
          </p>
        </div>

        {message && (
          <div className={`text-sm px-3 py-2 rounded-lg ${message.type === "error" ? "bg-red-500/10 text-red-500" : "bg-green-500/10 text-green-500"}`}>
            {message.text}
          </div>
        )}

        <form onSubmit={handleVerifyOtp} className="space-y-4">
          <input
            type="text"
            inputMode="numeric"
            maxLength={6}
            placeholder="Enter 6-digit code"
            value={otpCode}
            onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ""))}
            className="w-full h-12 px-4 rounded-xl bg-app-surface border border-app-border text-app-text text-center text-lg tracking-[0.3em] font-mono placeholder:tracking-normal placeholder:text-sm placeholder:text-app-subtle focus:outline-none focus:ring-2 focus:ring-app-accent/50 focus:border-app-accent transition-all"
            autoFocus
          />
          <Button
            type="submit"
            disabled={isLoading === "verify" || otpCode.length < 6}
            className="w-full h-12 bg-app-accent text-app-accent-fg hover:opacity-90 font-semibold rounded-xl text-sm"
          >
            {isLoading === "verify" ? "Verifying..." : "Verify & Sign In"}
          </Button>
        </form>

        <button
          onClick={() => handleSendOtp({ preventDefault: () => {} } as React.FormEvent)}
          disabled={isLoading === "otp"}
          className="text-sm text-app-subtle hover:text-app-accent transition-colors w-full text-center"
        >
          Didn&apos;t receive it? Resend code
        </button>
      </div>
    );
  }

  if (view === "email") {
    return (
      <div className="space-y-5">
        <button
          onClick={() => { setView("main"); setMessage(null); setEmail(""); }}
          className="flex items-center gap-1.5 text-sm text-app-subtle hover:text-app-text transition-colors"
        >
          <BiArrowBack className="text-lg" />
          All sign in options
        </button>

        <div>
          <h3 className="text-lg font-semibold text-app-text">Sign in with email</h3>
          <p className="text-sm text-app-subtle mt-1">We&apos;ll send you a one-time verification code</p>
        </div>

        {message && (
          <div className={`text-sm px-3 py-2 rounded-lg ${message.type === "error" ? "bg-red-500/10 text-red-500" : "bg-green-500/10 text-green-500"}`}>
            {message.text}
          </div>
        )}

        <form onSubmit={handleSendOtp} className="space-y-4">
          <input
            type="email"
            placeholder="you@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full h-12 px-4 rounded-xl bg-app-surface border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:ring-2 focus:ring-app-accent/50 focus:border-app-accent transition-all text-sm"
            autoFocus
            required
          />
          <Button
            type="submit"
            disabled={isLoading === "otp" || !email.trim()}
            className="w-full h-12 bg-app-accent text-app-accent-fg hover:opacity-90 font-semibold rounded-xl text-sm"
          >
            {isLoading === "otp" ? "Sending..." : "Send Verification Code"}
          </Button>
        </form>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {message && (
        <div className={`text-sm px-3 py-2 rounded-lg ${message.type === "error" ? "bg-red-500/10 text-red-500" : "bg-green-500/10 text-green-500"}`}>
          {message.text}
        </div>
      )}

      {/* OAuth buttons */}
      <Button
        onClick={handleGoogleSignIn}
        disabled={isLoading === "google"}
        variant="outline"
        className="w-full h-12 rounded-xl border-app-border bg-app-surface hover:bg-app-raised text-app-text font-medium text-sm gap-3 transition-all"
      >
        <FcGoogle className="text-xl" />
        {isLoading === "google" ? "Connecting..." : "Continue with Google"}
      </Button>

      <Button
        onClick={handleGithubSignIn}
        disabled={isLoading === "github"}
        variant="outline"
        className="w-full h-12 rounded-xl border-app-border bg-app-surface hover:bg-app-raised text-app-text font-medium text-sm gap-3 transition-all"
      >
        <FaGithub className="text-xl" />
        {isLoading === "github" ? "Connecting..." : "Continue with GitHub"}
      </Button>

      {/* Divider */}
      <div className="relative my-2">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-app-border" />
        </div>
        <div className="relative flex justify-center text-xs">
          <span className="bg-app-bg px-3 text-app-subtle">or</span>
        </div>
      </div>

      {/* Email OTP */}
      <Button
        onClick={() => { setView("email"); setMessage(null); }}
        variant="outline"
        className="w-full h-12 rounded-xl border-app-border bg-app-surface hover:bg-app-raised text-app-text font-medium text-sm gap-3 transition-all"
      >
        <HiOutlineMail className="text-xl text-app-muted" />
        Continue with Email
      </Button>
    </div>
  );
};

export default LoginForm;
