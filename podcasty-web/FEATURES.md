# مميزات موقع Podcasty (الويب)

شرح مختصر لكل خاصية في الموقع، ولأي صفحة/مكوّن في الكود تنتمي.

---

## 1. تسجيل الدخول والمصادقة

- **المسار:** `/login` — `app/login/page.tsx`
- **الـ Provider:** Supabase Auth (Email/Password + OAuth callback في `app/api/auth/callback`).
- **الحماية:** `middleware.ts` يحرس الصفحات الخاصة ويعيد التوجيه إلى `/login` عند عدم وجود جلسة.
- **الجلسة:** تُقرأ سيرفرسايد عبر `getUser()` في `app/lib/supabase.ts`.

## 2. الصفحة الرئيسية (Home)

- **المسار:** `/` — `app/(pages)/page.tsx`
- ترحيب باسم المستخدم، أزرار سريعة لإنشاء بودكاست أو تصفّح البودكاست.
- شبكة "What you can do" تستعرض القدرات: AI Audio، Cover Art، أصوات متعددة، مشغّل مدمج.
- قائمة **Trending** من خلال `fetchTrendingPodcasts()`.

## 3. اكتشاف البودكاست (Discover)

- **المسار:** `/podcasts` — `app/(pages)/podcasts/page.tsx` + `components/Discover.tsx`
- تصفّح كل البودكاستات مع تصنيفات (Categories) من `app/lib/api/categories.ts`.
- بطاقة كل حلقة عبر `components/shared/PodcastCard.tsx`.

## 4. إنشاء بودكاست بالذكاء الاصطناعي

- **المسار:** `/podcasts/create` — `app/(pages)/podcasts/create/page.tsx` + `components/forms/PodcastForm.tsx`
- إدخال *Prompt* + اختيار *Voice* (7 خيارات: Alloy, Coral, Echo, Fable, Onyx, Nova, Shimmer) → إنتاج صوت + غلاف بالـ AI عبر `generatePodcastAction`.
- يدعم تحديد **Chapters** (عنوان + توقيت بداية) قبل النشر.
- النشر يستدعي `createPodcastAction` (يحفظ في الـ Go backend).

## 5. صفحة تفاصيل البودكاست

- **المسار:** `/podcasts/[id]` — `app/(pages)/podcasts/[id]/page.tsx`
- يعرض الغلاف، الوصف، اسم المؤلف، عدد التشغيل، تاريخ النشر، التصنيف.
- أزرار التفاعل في `components/buttons/`:
  - `PlayPodcastButton` — تشغيل/إيقاف.
  - `LikeButton` — إعجاب.
  - `BookmarkButton` — حفظ للاحقاً.
  - `AddToPlaylistButton` — إضافة لقائمة تشغيل.
  - `ShareButton` — مشاركة.
  - `DownloadButton` — تنزيل ملف الصوت.
  - `DeletePodcastButton` — يظهر للمالك فقط.
- **Chapters:** عرض الفصول قابلة للنقر تنقلك إلى الوقت المحدد (`ChaptersList`).
- **Comments:** قسم تعليقات كامل (`CommentsSection`) متصل بـ `app/lib/api/comments.ts`.
- **Metadata/SEO:** `generateMetadata` يولّد Open Graph + Twitter cards لكل حلقة.

## 6. المشغل الدائم (Persistent Player)

- **المكوّن:** `components/shared/PodcastPlayer.tsx`
- يبقى ظاهراً في أسفل الصفحة أثناء التنقل، يحفظ موقع التشغيل ويتابع `play_count`.

## 7. المتابعة والـ Feed

- **المسار:** `/feed` — `app/(pages)/feed/page.tsx`
- يعرض أحدث الحلقات من المستخدمين الذين تتابعهم.
- يجلب البيانات عبر `fetchFeed()` و `fetchFollows()` (في `app/lib/api/feed.ts` و `users.ts`).

## 8. المتابعة (Follow / Unfollow)

- زر `FollowButton` على البروفايلات.
- Server action: `toggleFollowAction` في `app/lib/actions.ts`.

## 9. الإعجابات (Likes)

- زر `LikeButton` على كل بودكاست.
- Server action: `toggleLikeAction` يُحدّث الحالة وعدّاد الإعجابات.

## 10. الإشارات المرجعية (Bookmarks)

- **المسار:** `/bookmarks` — `app/(pages)/bookmarks/page.tsx`
- قائمة الحلقات المحفوظة.
- إضافة/إزالة عبر `toggleBookmarkAction`.

## 11. قوائم التشغيل (Playlists)

- **القائمة:** `/playlists` — `app/(pages)/playlists/page.tsx`
- **التفاصيل:** `/playlists/[id]` — يعرض الحلقات داخل القائمة عبر `fetchPlaylistItems`.
- إنشاء قائمة جديدة من `CreatePlaylistModal`.
- إضافة/إزالة بودكاست من `AddToPlaylistModal` (`createPlaylistAction`, `addToPlaylistAction`).

## 12. السلاسل (Series)

- **القائمة:** `/series` — `app/(pages)/series/page.tsx`
- **التفاصيل:** `/series/[id]` — ينظّم الحلقات في مواسم وأرقام حلقات.
- إنشاء سلسلة عبر `CreateSeriesButton` → `createSeriesAction`.
- إضافة حلقة لسلسلة عبر `addEpisodeToSeriesAction` مع تحديد `season_number` و `episode_number`.

## 13. لوحة المتصدرين (Leaderboard)

- **المسار:** `/leaderboard` — `app/(pages)/leaderboard/page.tsx`
- منصة تتويج لأفضل 3 + قائمة Top 20 مرتبة حسب إجمالي مرات التشغيل.
- البيانات من `fetchLeaderboard({ sort_by: 'plays' })`.

## 14. التحليلات (Analytics)

- **المسار:** `/analytics` — `app/(pages)/analytics/page.tsx`
- لوحة خاصة بالمستخدم تعرض إجماليات: عدد البودكاستات، التشغيل، الإعجابات، التعليقات، المستمعين الفريدين.
- رسوم بيانية للتشغيل عبر الزمن (`AnalyticsCharts`) باستخدام `fetchPodcastAnalytics` لكل حلقة.

## 15. صفحة البروفايل

- **المسار:** `/profile/[id]` — `app/(pages)/profile/[id]/page.tsx`
- معلومات المستخدم، عدد المتابعين/المتابَعين، الشارات (`UserBadges`).
- شبكة بودكاستات المستخدم.
- زر تعديل البروفايل (`EditProfileButton`) للمالك، وزر متابعة للزائر.
- لمالك الحساب: زر حذف لكل بودكاست.

## 16. إعدادات الإشعارات (Email)

- **المسار:** `/settings/notifications` — `app/(pages)/settings/notifications/page.tsx`
- التحكّم في إيميلات: تعليق جديد، متابع جديد، إعجاب جديد، الملخّص الأسبوعي.
- يحفظ التفضيلات عبر `updateNotificationPreferencesAction`.

## 17. التنقل (Sidebars + Mobile Nav)

- `components/shared/LeftSidebar.tsx` — الروابط الرئيسية.
- `components/shared/RigthSidebar.tsx` — اقتراحات/مستخدمون.
- `components/shared/NavMobile.tsx` — تنقّل سفلي للشاشات الصغيرة.
- `SidebarLinks.tsx` — قائمة الروابط المشتركة.

## 18. الثيم (Light / Dark)

- `components/shared/ThemeToggle.tsx` + موفّر الثيم في `app/providers/`.
- الألوان عبر متغيّرات Tailwind (`bg-app-*`, `text-app-*`).

## 19. تجربة الاستخدام أثناء "Cold Start"

- `app/(pages)/loading.tsx` يعرض Loader مع لافتة "warming up" إذا تأخّرت أول استجابة من الـ backend (Render free tier).

## 20. الـ SEO وميتا البيانات

- **Metadata API** مفعّل لصفحات الحلقات: عنوان ووصف وصورة Open Graph + Twitter Cards من بيانات البودكاست نفسه.

---

## مرجع سريع للـ API Modules

| ملف | المسؤولية |
|------|-----------|
| `app/lib/api/podcasts.ts` | CRUD البودكاست، Trending |
| `app/lib/api/playlists.ts` | قوائم التشغيل وعناصرها |
| `app/lib/api/series.ts` | السلاسل والحلقات |
| `app/lib/api/likes.ts` | إعجابات |
| `app/lib/api/bookmarks.ts` | الحفظ للاحقاً |
| `app/lib/api/users.ts` | بروفايلات، متابعة، حلقات المستخدم |
| `app/lib/api/feed.ts` | feed المتابَعين |
| `app/lib/api/leaderboard.ts` | المتصدرون |
| `app/lib/api/analytics.ts` | إحصائيات |
| `app/lib/api/comments.ts` | تعليقات |
| `app/lib/api/categories.ts` | تصنيفات |
| `app/lib/api/notifications.ts` | تفضيلات الإشعارات |
| `app/lib/api/generation.ts` | توليد صوت/غلاف بالـ AI |
| `app/lib/actions.ts` | Server Actions تغلّف الكل وتعمل `revalidatePath` |
