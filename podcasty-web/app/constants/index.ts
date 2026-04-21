import {
    AiFillHome,
    AiFillAudio,
    AiOutlineBarChart,
} from "react-icons/ai";
import { BiSearch } from "react-icons/bi";
import { BsBookmarkFill, BsPeopleFill, BsTrophyFill, BsCollectionPlayFill, BsRssFill, BsLayers } from "react-icons/bs";
import { PodcastCategory } from "../types";

export const sidebarLinks = [
    { href: "/", label: "Home", icon: AiFillHome },
    { href: "/podcasts", label: "Discover", icon: BiSearch },
    { href: "/podcasts/create", label: "Create Podcast", icon: AiFillAudio },
    { href: "/feed", label: "Following", icon: BsPeopleFill },
    { href: "/bookmarks", label: "Bookmarks", icon: BsBookmarkFill },
    { href: "/playlists", label: "Playlists", icon: BsCollectionPlayFill },
    { href: "/series", label: "Series", icon: BsLayers },
    { href: "/analytics", label: "Analytics", icon: AiOutlineBarChart },
    { href: "/leaderboard", label: "Leaderboard", icon: BsTrophyFill },
];

export const PODCAST_CATEGORIES: PodcastCategory[] = [
    "Technology",
    "Science",
    "Business",
    "Health",
    "Comedy",
    "True Crime",
    "History",
    "Education",
    "Sports",
    "Music",
    "News",
    "Politics",
    "Gaming",
    "Entertainment",
    "Arts",
    "Fiction",
    "Self-Improvement",
    "Society & Culture",
    "Food",
    "Travel",
];