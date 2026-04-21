# API Structure Documentation

The API client has been refactored into a modular, domain-driven structure for better organization and maintainability.

## 📁 Structure

```
app/lib/api/
├── client.ts           # Core API request functions (authenticated & public)
├── index.ts            # Central export file - import from here!
├── public.ts           # Client-side public API (no auth)
│
├── podcasts.ts         # Podcast CRUD operations
├── bookmarks.ts        # Bookmark management
├── likes.ts            # Like/unlike operations
├── playlists.ts        # Playlist management
├── comments.ts         # Comment operations
├── analytics.ts        # Analytics data
├── leaderboard.ts      # Leaderboard data
├── categories.ts       # Category operations
├── users.ts            # User data & user podcasts
├── generation.ts       # AI content generation
└── feed.ts             # Personalized feed
```

## 🎯 Usage

### Server Components & Server Actions

Import from the main API module:

```typescript
import { fetchPodcasts, fetchPodcastById, createPodcast } from '@/app/lib/api';
```

Or import from specific modules:

```typescript
import { fetchPodcasts } from '@/app/lib/api/podcasts';
import { fetchBookmarks } from '@/app/lib/api/bookmarks';
import { likePodcast } from '@/app/lib/api/likes';
```

### Client Components (Public Endpoints)

For client-side components that don't need authentication:

```typescript
import { fetchPodcasts, fetchPodcastById } from '@/app/lib/api/public';
```

### Examples

#### Server Component (with auth)
```typescript
// app/(pages)/podcasts/page.tsx
import { fetchPodcasts } from '@/app/lib/api';

export default async function PodcastsPage() {
  const podcasts = await fetchPodcasts({ limit: 20 });
  
  return <div>{/* render podcasts */}</div>;
}
```

#### Client Component (public)
```typescript
// components/Discover.tsx
"use client";
import { fetchPodcasts } from '@/app/lib/api/public';

export default function Discover() {
  const [podcasts, setPodcasts] = useState([]);
  
  useEffect(() => {
    fetchPodcasts({ search: query }).then(setPodcasts);
  }, [query]);
  
  return <div>{/* render podcasts */}</div>;
}
```

#### Server Action
```typescript
// app/lib/actions.ts
import { createPodcast } from '@/app/lib/api/podcasts';
import { likePodcast } from '@/app/lib/api/likes';

export async function createPodcastAction(data) {
  const podcast = await createPodcast(data);
  revalidatePath('/podcasts');
  return { success: true, id: podcast.id };
}
```

## 📦 Modules

### `podcasts.ts`
- `fetchPodcasts(params?)` - List podcasts with search/filter
- `fetchPodcastById(id)` - Get single podcast
- `fetchTrendingPodcasts()` - Get trending podcasts
- `createPodcast(data)` - Create new podcast
- `deletePodcast(id)` - Delete podcast
- `incrementPlayCount(podcastId)` - Track plays

**Types:** `Podcast`

### `bookmarks.ts`
- `fetchBookmarks()` - Get user's bookmarks
- `addBookmark(podcastId)` - Bookmark a podcast
- `removeBookmark(podcastId)` - Remove bookmark

### `likes.ts`
- `likePodcast(podcastId)` - Like a podcast
- `unlikePodcast(podcastId)` - Unlike a podcast

### `playlists.ts`
- `fetchPlaylists()` - Get user's playlists
- `createPlaylist(data)` - Create playlist
- `addToPlaylist(playlistId, podcastId)` - Add to playlist
- `removeFromPlaylist(playlistId, podcastId)` - Remove from playlist

**Types:** `Playlist`

### `comments.ts`
- `fetchComments(podcastId)` - Get podcast comments
- `createComment(podcastId, content)` - Add comment
- `deleteComment(commentId)` - Delete comment

**Types:** `Comment`

### `analytics.ts`
- `fetchAnalytics(podcastId)` - Get podcast analytics

**Types:** `Analytics`

### `leaderboard.ts`
- `fetchLeaderboard(params?)` - Get top creators

**Types:** `LeaderboardUser`

### `categories.ts`
- `fetchCategories()` - Get all categories

### `users.ts`
- `fetchUser(userId)` - Get user profile
- `fetchUserPodcasts(userId)` - Get user's podcasts

**Types:** `User`

### `generation.ts`
- `generatePodcastContent(data)` - Generate AI audio & cover

### `feed.ts`
- `fetchFeed(params?)` - Get personalized feed

### `client.ts`
Core functions (usually don't import directly):
- `apiRequest<T>(endpoint, options)` - Authenticated requests
- `publicApiRequest<T>(endpoint, options)` - Public requests

## 🔄 Migration from Old API

The old `api-client.ts` and `api-client-public.ts` files are now deprecated but kept for backward compatibility. They re-export everything from the new structure.

### Before
```typescript
import { fetchPodcasts } from '@/app/lib/api-client';
```

### After
```typescript
// Server-side (with auth)
import { fetchPodcasts } from '@/app/lib/api';

// Client-side (public)
import { fetchPodcasts } from '@/app/lib/api/public';
```

## ✨ Benefits

1. **Better Organization** - Each domain in its own file
2. **Easier to Find** - Know exactly where to look for specific API calls
3. **Smaller Bundles** - Only import what you need
4. **Type Safety** - Types are co-located with functions
5. **Maintainability** - Easy to add/modify domain-specific logic
6. **Testability** - Can mock individual modules
7. **Scalability** - Easy to add new domains

## 🔧 Advanced Usage

### Custom API Request

If you need to make a custom authenticated request:

```typescript
import { apiRequest } from '@/app/lib/api/client';

const data = await apiRequest<MyType>('/api/custom-endpoint', {
  method: 'POST',
  data: { foo: 'bar' },
});
```

### Custom Public Request

For custom public (unauthenticated) requests:

```typescript
import { publicApiRequest } from '@/app/lib/api/client';

const data = await publicApiRequest<MyType>('/api/public-endpoint');
```

## 📝 Type Exports

All types are also exported from the main index:

```typescript
import type { 
  Podcast, 
  User, 
  Comment, 
  Playlist,
  Analytics,
  LeaderboardUser 
} from '@/app/lib/api';
```

## 🎨 Best Practices

1. **Use the index** - Import from `@/app/lib/api` for simplicity
2. **Server vs Client** - Use `api` for server, `api/public` for client
3. **Server Actions** - Wrap API calls in server actions for client mutations
4. **Error Handling** - Always wrap API calls in try-catch
5. **Type Safety** - Use the exported types for better IntelliSense

## 📚 Related Files

- `app/lib/actions.ts` - Server actions that use the API
- `app/lib/supabase.ts` - Authentication/session management
- `components/Discover.tsx` - Example of client-side usage
- `app/(pages)/*/page.tsx` - Examples of server-side usage
