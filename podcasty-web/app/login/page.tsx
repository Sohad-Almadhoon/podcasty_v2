import { redirect } from "next/navigation";
import { getUser } from "../lib/supabase";
import LoginForm from "@/components/forms/LoginForm";

const LoginPage = async () => {
  const user = await getUser();

  if (user) {
    redirect("/podcasts");
  }

  return (
    <div suppressHydrationWarning className="min-h-screen w-full flex bg-app-bg">
      {/* Left panel - branding */}
      <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden bg-gradient-to-br from-app-accent/20 via-app-bg to-app-accent/5">
        <div className="absolute inset-0">
          <div className="absolute top-20 left-20 w-72 h-72 bg-app-accent/10 rounded-full blur-3xl" />
          <div className="absolute bottom-32 right-16 w-96 h-96 bg-app-accent/5 rounded-full blur-3xl" />
          <div className="absolute top-1/2 left-1/3 w-48 h-48 bg-app-accent/8 rounded-full blur-2xl" />
        </div>
        <div className="relative z-10 flex flex-col justify-center px-16">
          <div className="flex items-center gap-3 mb-8">
            <div className="flex items-center justify-center w-14 h-14 bg-app-accent rounded-2xl shadow-lg">
              <span className="text-white text-2xl">🎙</span>
            </div>
            <h1 className="text-4xl font-bold text-app-text tracking-tight">Podcasty</h1>
          </div>
          <p className="text-xl text-app-muted leading-relaxed max-w-md mb-8">
            Create, discover, and share AI-powered podcasts with a community of listeners.
          </p>
          <div className="space-y-4">
            <div className="flex items-center gap-3 text-app-subtle">
              <div className="w-8 h-8 rounded-lg bg-app-accent/10 flex items-center justify-center">
                <span className="text-app-accent text-sm">✦</span>
              </div>
              <span className="text-sm">AI-powered podcast generation</span>
            </div>
            <div className="flex items-center gap-3 text-app-subtle">
              <div className="w-8 h-8 rounded-lg bg-app-accent/10 flex items-center justify-center">
                <span className="text-app-accent text-sm">♫</span>
              </div>
              <span className="text-sm">Thousands of podcasts to explore</span>
            </div>
            <div className="flex items-center gap-3 text-app-subtle">
              <div className="w-8 h-8 rounded-lg bg-app-accent/10 flex items-center justify-center">
                <span className="text-app-accent text-sm">★</span>
              </div>
              <span className="text-sm">Build your audience and grow</span>
            </div>
          </div>
        </div>
      </div>

      {/* Right panel - login form */}
      <div className="w-full lg:w-1/2 flex flex-col items-center justify-center px-6 sm:px-12">
        <div className="w-full max-w-sm">
          {/* Mobile branding */}
          <div className="flex flex-col items-center gap-3 mb-10 lg:hidden">
            <div className="flex items-center justify-center w-14 h-14 bg-app-accent rounded-2xl shadow-lg">
              <span className="text-white text-2xl">🎙</span>
            </div>
            <h1 className="text-3xl font-bold text-app-text tracking-tight">Podcasty</h1>
            <p className="text-app-subtle text-sm text-center">Create and discover AI-powered podcasts</p>
          </div>

          <div className="lg:mb-8">
            <h2 className="text-2xl font-bold text-app-text hidden lg:block">Welcome back</h2>
            <p className="text-app-subtle text-sm mt-1 hidden lg:block">Sign in to your account to continue</p>
          </div>

          <LoginForm />

          <p className="text-xs text-app-subtle text-center mt-8">
            By signing in, you agree to our Terms of Service and Privacy Policy.
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
