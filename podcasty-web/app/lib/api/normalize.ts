/**
 * Normalizers for API responses.
 *
 * PostgREST embeds related rows as either an object or an array, depending on
 * cardinality and how the query is written. We have a many-to-one relationship
 * between podcasts and users, so the embedded `users` field should always be a
 * single row — but the response shape isn't guaranteed by the type system, so
 * we coerce it here at the boundary instead of forcing every consumer to
 * handle the union.
 */

import type { Podcast, PodcastAuthor } from "@/app/types";

const EMPTY_AUTHOR: PodcastAuthor = { username: "", avatar_url: "" };

type RawAuthor = PodcastAuthor | PodcastAuthor[] | null | undefined;

export function normalizeAuthor(users: RawAuthor): PodcastAuthor {
  if (!users) return EMPTY_AUTHOR;
  if (Array.isArray(users)) return users[0] ?? EMPTY_AUTHOR;
  return users;
}

// Loose input shape — what the API might return before normalization.
type RawPodcast = Omit<Podcast, "users"> & { users: RawAuthor };

export function normalizePodcast(podcast: RawPodcast): Podcast {
  return {
    ...podcast,
    users: normalizeAuthor(podcast.users),
  };
}

export function normalizePodcasts(podcasts: RawPodcast[]): Podcast[] {
  return podcasts.map(normalizePodcast);
}
