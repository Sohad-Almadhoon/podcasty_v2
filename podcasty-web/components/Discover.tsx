"use client";
import { Podcast, PodcastCategory } from "@/app/types";
import { PODCAST_CATEGORIES } from "@/app/constants";
import Link from "next/link";
import React, { useState, useEffect } from "react";
import PodcastCard from "./shared/PodcastCard";
import LoaderSpinner from "@/app/(pages)/loading";
import { fetchPodcasts, type PodcastSort } from "@/app/lib/api/public";
import { Search, SlidersHorizontal } from "lucide-react";

const useDebounce = <T,>(value: T, delay = 300) => {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
};

const SORT_OPTIONS: { value: PodcastSort; label: string }[] = [
  { value: "newest", label: "Newest" },
  { value: "oldest", label: "Oldest" },
  { value: "most_played", label: "Most Played" },
  { value: "most_liked", label: "Most Liked" },
];

const Discover = () => {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<PodcastCategory | "">("");
  const [sort, setSort] = useState<PodcastSort>("newest");
  const [minDuration, setMinDuration] = useState(""); // minutes
  const [maxDuration, setMaxDuration] = useState(""); // minutes
  const [dateFrom, setDateFrom] = useState("");
  const [showFilters, setShowFilters] = useState(false);
  const [podcasts, setPodcasts] = useState<Podcast[]>([]);
  const [loading, setLoading] = useState(false);

  const debouncedSearch = useDebounce(searchQuery);
  const debouncedMinDuration = useDebounce(minDuration);
  const debouncedMaxDuration = useDebounce(maxDuration);

  useEffect(() => {
    const loadPodcasts = async () => {
      setLoading(true);
      try {
        const minSec = debouncedMinDuration ? parseInt(debouncedMinDuration, 10) * 60 : undefined;
        const maxSec = debouncedMaxDuration ? parseInt(debouncedMaxDuration, 10) * 60 : undefined;
        const data = await fetchPodcasts({
          search: debouncedSearch || undefined,
          category: selectedCategory || undefined,
          sort,
          min_duration: Number.isFinite(minSec) ? minSec : undefined,
          max_duration: Number.isFinite(maxSec) ? maxSec : undefined,
          date_from: dateFrom || undefined,
        });
        setPodcasts(data);
      } catch (error) {
        console.error("Error fetching podcasts:", error);
        setPodcasts([]);
      } finally {
        setLoading(false);
      }
    };

    loadPodcasts();
  }, [debouncedSearch, selectedCategory, sort, debouncedMinDuration, debouncedMaxDuration, dateFrom]);

  const resetFilters = () => {
    setSearchQuery("");
    setSelectedCategory("");
    setSort("newest");
    setMinDuration("");
    setMaxDuration("");
    setDateFrom("");
  };

  const hasActiveFilters =
    !!searchQuery ||
    !!selectedCategory ||
    sort !== "newest" ||
    !!minDuration ||
    !!maxDuration ||
    !!dateFrom;

  return (
    <div>
      <div className="flex flex-col sm:flex-row gap-2 sm:gap-3 mb-3">
        <div className="relative flex-1 min-w-0">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-app-subtle pointer-events-none" />
          <input
            type="text"
            placeholder="Search podcasts..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="h-11 sm:h-10 w-full pl-10 pr-4 rounded-lg bg-app-surface border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-muted transition-colors text-base sm:text-sm"
          />
        </div>
        <div className="flex gap-2 sm:gap-3">
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value as PodcastCategory | "")}
            className="h-11 sm:h-10 px-3 sm:px-4 rounded-lg flex-1 sm:flex-none sm:w-48 min-w-0 bg-app-surface border border-app-border text-app-text focus:outline-none focus:border-app-muted transition-colors text-base sm:text-sm"
          >
            <option value="">All Categories</option>
            {PODCAST_CATEGORIES.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>
          <button
            type="button"
            onClick={() => setShowFilters((v) => !v)}
            className="h-11 sm:h-10 px-3 sm:px-4 rounded-lg inline-flex items-center gap-2 bg-app-surface border border-app-border text-app-text hover:border-app-muted transition-colors text-sm shrink-0"
          >
            <SlidersHorizontal className="w-4 h-4" />
            <span className="hidden sm:inline">Filters</span>
          </button>
        </div>
      </div>

      {showFilters && (
        <div className="rounded-lg border border-app-border bg-app-surface p-4 mb-6 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-app-subtle uppercase tracking-wider">Sort by</label>
            <select
              value={sort}
              onChange={(e) => setSort(e.target.value as PodcastSort)}
              className="h-9 px-3 w-full rounded-lg bg-app-bg border border-app-border text-app-text focus:outline-none focus:border-app-muted text-sm"
            >
              {SORT_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-app-subtle uppercase tracking-wider">Min length (min)</label>
            <input
              type="number"
              min={0}
              value={minDuration}
              onChange={(e) => setMinDuration(e.target.value)}
              placeholder="0"
              className="h-9 px-3 w-full rounded-lg bg-app-bg border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-muted text-sm"
            />
          </div>
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-app-subtle uppercase tracking-wider">Max length (min)</label>
            <input
              type="number"
              min={0}
              value={maxDuration}
              onChange={(e) => setMaxDuration(e.target.value)}
              placeholder="∞"
              className="h-9 px-3 w-full rounded-lg bg-app-bg border border-app-border text-app-text placeholder:text-app-subtle focus:outline-none focus:border-app-muted text-sm"
            />
          </div>
          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-app-subtle uppercase tracking-wider">Published after</label>
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="h-9 px-3 w-full rounded-lg bg-app-bg border border-app-border text-app-text focus:outline-none focus:border-app-muted text-sm"
            />
          </div>
          {hasActiveFilters && (
            <div className="sm:col-span-2 lg:col-span-4 flex justify-end">
              <button
                type="button"
                onClick={resetFilters}
                className="text-xs text-app-accent hover:underline"
              >
                Reset filters
              </button>
            </div>
          )}
        </div>
      )}

      {loading && <LoaderSpinner />}

      <div className="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-4">
        {podcasts.length > 0
          ? podcasts.map((podcast) => (
              <Link href={`/podcasts/${podcast.id}`} key={podcast.id}>
                <PodcastCard podcast={podcast} />
              </Link>
            ))
          : !loading && <p className="text-app-subtle text-sm">No podcasts found.</p>}
      </div>
    </div>
  );
};

export default Discover;
