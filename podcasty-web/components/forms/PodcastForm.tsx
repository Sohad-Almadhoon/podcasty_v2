"use client";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { useRouter } from "next/navigation";
import { getUser } from "@/app/lib/supabase";
import { generatePodcastAction, createPodcastAction } from "@/app/lib/actions";
import { AiVoice, PodcastCategory } from "@/app/types";
import { PODCAST_CATEGORIES } from "@/app/constants";
import Image from "next/image";
import { toast } from "sonner";
import BackButton from "@/components/buttons/BackButton";

export default function PodcastForm() {
  const {
    register,
    handleSubmit,
    formState: { errors },
    getValues,
  } = useForm<{
    podcast_name: string;
    prompt: string;
    description: string;
    ai_voice: AiVoice;
    category: PodcastCategory;
  }>();

  const [generatedPodcast, setGeneratedPodcast] = useState<{
    imageUrl: string;
    audioUrl: string;
  } | null>(null);
  const [chapters, setChapters] = useState<{ title: string; start: string }[]>([]);
  const [loading, setLoading] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const router = useRouter();
  const [userId, setUserId] = useState<string | null>(null);

  useEffect(() => {
    const fetchUserId = async () => {
      const user = await getUser();
      if (user) {
        setUserId(user.id);
      }
    };

    fetchUserId();
  }, []);

  const generateAIContent = async (aiPrompt: string, aiVoice: AiVoice) => {
    setLoading(true);
    try {
      const result = await generatePodcastAction({
        prompt: aiPrompt,
        voice: aiVoice,
      });

      if (result.success && result.imageUrl && result.audioUrl) {
        setGeneratedPodcast({
          imageUrl: result.imageUrl,
          audioUrl: result.audioUrl,
        });
        toast.success("AI content generated!", {
          description: "Your audio and cover art are ready.",
        });
      } else {
        console.error("Error generating AI content:", result.error);
        toast.error("Generation failed", {
          description: result.error || "There was an error generating the AI content. Please try again.",
        });
      }
    } catch (error) {
      console.error("Error generating AI content:", error);
      toast.error("Generation failed", {
        description: "There was an error generating the AI content. Please try again.",
      });
    } finally {
      setLoading(false);
    }
  };

  const parseTimestamp = (input: string): number | null => {
    const trimmed = input.trim();
    if (!trimmed) return null;
    // Plain number = seconds
    if (/^\d+(\.\d+)?$/.test(trimmed)) return parseFloat(trimmed);
    // MM:SS or HH:MM:SS
    const parts = trimmed.split(":").map((p) => p.trim());
    if (parts.some((p) => p === "" || isNaN(Number(p)))) return null;
    const nums = parts.map(Number);
    if (nums.length === 2) return nums[0] * 60 + nums[1];
    if (nums.length === 3) return nums[0] * 3600 + nums[1] * 60 + nums[2];
    return null;
  };

  const onSubmit = async (data: {
    podcast_name: string;
    description: string;
    ai_voice: string;
    category: PodcastCategory;
  }) => {
    if (!generatedPodcast || !userId) return;

    // Build & validate chapters
    const parsedChapters: { title: string; start: number }[] = [];
    for (const ch of chapters) {
      if (!ch.title.trim() && !ch.start.trim()) continue; // skip empty rows
      const start = parseTimestamp(ch.start);
      if (start === null || !ch.title.trim()) {
        toast.error("Invalid chapter", {
          description: `Chapter "${ch.title || "(untitled)"}" needs a title and a valid timestamp (e.g. 1:23 or 01:23:45).`,
        });
        return;
      }
      parsedChapters.push({ title: ch.title.trim(), start });
    }
    // Sort by start time so they appear in order
    parsedChapters.sort((a, b) => a.start - b.start);

    setPublishing(true);
    try {
      const result = await createPodcastAction({
        ...data,
        image_url: generatedPodcast.imageUrl,
        audio_url: generatedPodcast.audioUrl,
        chapters: parsedChapters,
      });

      if (result.success) {
        toast.success("Podcast published!", {
          description: "Your podcast is now live.",
        });
        router.push("/podcasts");
      } else {
        toast.error("Publish failed", {
          description: result.error || "There was an error creating the podcast. Please try again.",
        });
      }
    } catch (error) {
      console.error("Error creating podcast:", error);
      toast.error("Publish failed", {
        description: "There was an error creating the podcast. Please try again.",
      });
    } finally {
      setPublishing(false);
    }
  };

  return (
    <div className="py-10 px-6">
      <div className="w-full max-w-lg">
        <div className="mb-4">
          <BackButton />
        </div>
        <h1 className="text-2xl font-bold text-app-text mb-1">Create Podcast</h1>
        <p className="text-app-subtle text-sm mb-8">Generate AI audio &amp; cover art from your prompt</p>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-app-muted">Podcast Name</label>
            <input
              {...register("podcast_name", { required: "Podcast Name is required" })}
              placeholder="Enter podcast name..."
              disabled={publishing}
              className="h-10 px-3 w-full rounded-lg bg-app-surface border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-muted transition-colors text-sm disabled:opacity-50 disabled:cursor-not-allowed"
            />
            {errors.podcast_name && (
              <p className="text-red-400 text-xs">{errors.podcast_name.message}</p>
            )}
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-app-muted">Category</label>
            <select
              {...register("category", { required: "Please select a category" })}
              disabled={publishing}
              className="h-10 px-3 w-full rounded-lg bg-app-surface border border-app-border text-app-text focus:outline-none focus:border-app-muted transition-colors text-sm disabled:opacity-50 disabled:cursor-not-allowed">
              <option value="">Select a category...</option>
              {PODCAST_CATEGORIES.map((cat) => (
                <option key={cat} value={cat}>
                  {cat}
                </option>
              ))}
            </select>
            {errors.category && (
              <p className="text-red-400 text-xs">{errors.category.message}</p>
            )}
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-app-muted">AI Voice</label>
            <select
              {...register("ai_voice", { required: "Please select a voice" })}
              disabled={publishing}
              className="h-10 px-3 w-full rounded-lg bg-app-surface border border-app-border text-app-text focus:outline-none focus:border-app-muted transition-colors text-sm disabled:opacity-50 disabled:cursor-not-allowed">
              <option value="alloy">Alloy</option>
              <option value="coral">Coral</option>
              <option value="echo">Echo</option>
              <option value="fable">Fable</option>
              <option value="onyx">Onyx</option>
              <option value="nova">Nova</option>
              <option value="shimmer">Shimmer</option>
            </select>
            {errors.ai_voice && (
              <p className="text-red-400 text-xs">{errors.ai_voice.message}</p>
            )}
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-app-muted">Prompt</label>
            <p className="text-xs text-app-subtle mb-2">What should the AI generate? Be specific about the topic, tone, and style.</p>
            <textarea
              {...register("prompt", { required: "Prompt is required" })}
              placeholder="Generate a 5-minute podcast about the history of artificial intelligence..."
              disabled={publishing}
              className="px-3 py-2.5 w-full rounded-lg bg-app-surface border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-muted transition-colors text-sm resize-none disabled:opacity-50 disabled:cursor-not-allowed"
              rows={4}
            />
            {errors.prompt && (
              <p className="text-red-400 text-xs">{errors.prompt.message}</p>
            )}
          </div>

          <div className="space-y-1.5">
            <label className="text-sm font-medium text-app-muted">Description</label>
            <p className="text-xs text-app-subtle mb-2">A brief description that will be shown to listeners (this is NOT sent to AI).</p>
            <textarea
              {...register("description", { required: "Description is required" })}
              placeholder="This episode explores the fascinating history of AI..."
              disabled={publishing}
              className="px-3 py-2.5 w-full rounded-lg bg-app-surface border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-muted transition-colors text-sm resize-none disabled:opacity-50 disabled:cursor-not-allowed"
              rows={3}
            />
            {errors.description && (
              <p className="text-red-400 text-xs">{errors.description.message}</p>
            )}
          </div>

          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <label className="text-sm font-medium text-app-muted">Chapters (optional)</label>
              <button
                type="button"
                disabled={publishing}
                onClick={() => setChapters((c) => [...c, { title: "", start: "" }])}
                className="text-xs font-medium text-app-accent hover:underline disabled:opacity-50"
              >
                + Add chapter
              </button>
            </div>
            <p className="text-xs text-app-subtle mb-2">
              Use <code>MM:SS</code> or <code>HH:MM:SS</code> for timestamps. Listeners can click to jump.
            </p>
            {chapters.length > 0 && (
              <div className="space-y-2">
                {chapters.map((ch, i) => (
                  <div key={i} className="flex gap-2">
                    <input
                      type="text"
                      value={ch.title}
                      onChange={(e) =>
                        setChapters((arr) => arr.map((c, j) => (j === i ? { ...c, title: e.target.value } : c)))
                      }
                      placeholder="Chapter title"
                      disabled={publishing}
                      className="h-9 px-3 flex-1 rounded-lg bg-app-surface border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-muted text-sm disabled:opacity-50"
                    />
                    <input
                      type="text"
                      value={ch.start}
                      onChange={(e) =>
                        setChapters((arr) => arr.map((c, j) => (j === i ? { ...c, start: e.target.value } : c)))
                      }
                      placeholder="0:00"
                      disabled={publishing}
                      className="h-9 px-3 w-24 rounded-lg bg-app-surface border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-muted text-sm tabular-nums disabled:opacity-50"
                    />
                    <button
                      type="button"
                      disabled={publishing}
                      onClick={() => setChapters((arr) => arr.filter((_, j) => j !== i))}
                      className="h-9 px-2 rounded-lg border border-app-border text-app-subtle hover:text-app-text hover:border-app-muted text-xs disabled:opacity-50"
                      aria-label="Remove chapter"
                    >
                      ✕
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          <button
            type="button"
            onClick={() => generateAIContent(getValues("prompt"), getValues("ai_voice"))}
            className="w-full h-10 rounded-lg bg-app-accent text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
            disabled={loading || publishing}>
            {loading ? "Generating..." : "Generate AI Content"}
          </button>

          {generatedPodcast && (
            <div className="rounded-lg border border-app-border bg-app-surface p-4">
              <p className="text-sm font-medium text-app-muted mb-3">Generated Content</p>
              <div className="flex items-center gap-4">
                <div className="size-20 relative rounded-lg overflow-hidden shrink-0">
                  <Image
                    src={generatedPodcast.imageUrl}
                    alt="Generated Image"
                    fill
                    objectFit="cover"
                    unoptimized
                  />
                </div>
                <audio
                  src={generatedPodcast.audioUrl}
                  controls
                  className="w-full h-9"
                />
              </div>
            </div>
          )}

          {generatedPodcast ? (
            <button
              type="submit"
              disabled={publishing}
              className="w-full h-10 rounded-lg bg-app-raised border border-app-border text-app-text text-sm font-semibold hover:border-app-muted transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2">
              {publishing && (
                <svg className="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              )}
              {publishing ? "Publishing..." : "Publish Podcast"}
            </button>
          ) : (
            <p className="text-center text-xs text-app-subtle py-2">
              Generate AI content first to publish
            </p>
          )}
        </form>
      </div>
    </div>
  );
}
