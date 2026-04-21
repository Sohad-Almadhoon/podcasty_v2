"use client";

import { useState } from "react";
import { toast } from "sonner";
import { updateNotificationPreferencesAction } from "@/app/lib/actions";
import type { NotificationPreferences } from "@/app/lib/api/notifications";

interface Props {
  initial: NotificationPreferences;
}

const TOGGLES: { key: keyof Omit<NotificationPreferences, "user_id">; label: string; description: string }[] = [
  {
    key: "email_on_new_comment",
    label: "New comments",
    description: "Email me when someone comments on a podcast I created.",
  },
  {
    key: "email_on_new_follower",
    label: "New followers",
    description: "Email me when someone follows me.",
  },
  {
    key: "email_on_new_like",
    label: "New likes",
    description: "Email me when someone likes one of my podcasts.",
  },
  {
    key: "email_weekly_digest",
    label: "Weekly digest",
    description: "A weekly summary of plays, likes, and new followers.",
  },
];

const NotificationPreferencesForm = ({ initial }: Props) => {
  const [prefs, setPrefs] = useState({
    email_on_new_comment: initial.email_on_new_comment,
    email_on_new_follower: initial.email_on_new_follower,
    email_on_new_like: initial.email_on_new_like,
    email_weekly_digest: initial.email_weekly_digest,
  });
  const [saving, setSaving] = useState(false);

  const toggle = (key: keyof typeof prefs) => {
    setPrefs((p) => ({ ...p, [key]: !p[key] }));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const result = await updateNotificationPreferencesAction(prefs);
      if (result.success) {
        toast.success("Preferences saved");
      } else {
        toast.error("Could not save", { description: result.error });
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-3">
      {TOGGLES.map(({ key, label, description }) => (
        <div
          key={key}
          className="flex items-start justify-between gap-4 rounded-lg border border-app-border bg-app-surface px-4 py-3"
        >
          <div className="min-w-0">
            <p className="text-sm font-medium text-app-text">{label}</p>
            <p className="text-xs text-app-subtle mt-0.5">{description}</p>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={prefs[key]}
            onClick={() => toggle(key)}
            className={`relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition-colors ${
              prefs[key] ? "bg-app-accent" : "bg-app-raised border border-app-border"
            }`}
          >
            <span
              className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${
                prefs[key] ? "translate-x-6" : "translate-x-1"
              }`}
            />
          </button>
        </div>
      ))}

      <div className="pt-2">
        <button
          type="button"
          onClick={handleSave}
          disabled={saving}
          className="h-10 px-5 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {saving ? "Saving…" : "Save preferences"}
        </button>
      </div>
    </div>
  );
};

export default NotificationPreferencesForm;
