import NotificationPreferencesForm from "@/components/forms/NotificationPreferencesForm";
import { getNotificationPreferencesAction } from "@/app/lib/actions";
import BackButton from "@/components/buttons/BackButton";

const NotificationSettingsPage = async () => {
  const result = await getNotificationPreferencesAction();
  // If preferences couldn't be loaded (e.g. table not yet migrated), fall back to defaults
  // so the form is still usable rather than showing an error.
  const preferences =
    result.preferences ?? {
      user_id: "",
      email_on_new_comment: true,
      email_on_new_follower: true,
      email_on_new_like: false,
      email_weekly_digest: false,
    };

  return (
    <div className="min-h-screen pb-16">
      <div className="border-b border-app-border px-6 py-8">
        <div className="mb-4">
          <BackButton />
        </div>
        <p className="text-xs font-semibold text-app-subtle uppercase tracking-widest mb-2">
          Settings
        </p>
        <h1 className="text-2xl font-bold text-app-text">Email Notifications</h1>
        <p className="text-sm text-app-muted mt-1 max-w-xl">
          Choose what Podcasty emails you. We&apos;ll only contact you about events you opt in to.
        </p>
      </div>

      <div className="px-6 py-8 max-w-xl">
        {result.error && (
          <div className="mb-4 rounded-lg border border-app-border bg-app-surface px-4 py-3 text-xs text-app-subtle">
            Couldn&apos;t load saved preferences ({result.error}). Showing defaults — your changes will still be saved.
          </div>
        )}
        <NotificationPreferencesForm initial={preferences} />
      </div>
    </div>
  );
};

export default NotificationSettingsPage;
