import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).primaryColor,
                      image: user?.imageUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(user!.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: user?.imageUrl == null
                        ? const Icon(Icons.mic_rounded, color: Colors.white, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Podcasty',
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.email != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user!.email,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: colors.outline, height: 1),
            const SizedBox(height: 8),
            // ── Nav ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _NavItem(icon: Icons.home_rounded, title: 'Home', route: '/'),
                  _NavItem(icon: Icons.explore_rounded, title: 'Discover', route: '/podcasts'),
                  _NavItem(icon: Icons.add_circle_outline_rounded, title: 'Create Podcast', route: '/create-podcast', push: true),
                  const SizedBox(height: 6),
                  Divider(color: colors.outline, height: 1),
                  const SizedBox(height: 6),
                  _NavItem(icon: Icons.rss_feed_rounded, title: 'Feed', route: '/feed'),
                  _NavItem(icon: Icons.bookmark_outline_rounded, title: 'Bookmarks', route: '/bookmarks'),
                  _NavItem(icon: Icons.playlist_play_rounded, title: 'Playlists', route: '/playlists'),
                  const SizedBox(height: 6),
                  Divider(color: colors.outline, height: 1),
                  const SizedBox(height: 6),
                  _NavItem(icon: Icons.leaderboard_rounded, title: 'Leaderboard', route: '/leaderboard'),
                  _NavItem(icon: Icons.analytics_outlined, title: 'Analytics', route: '/analytics'),
                  _NavItem(icon: Icons.person_outline_rounded, title: 'Profile', route: '/profile'),
                ],
              ),
            ),
            // ── Bottom ──
            Divider(color: colors.outline, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        theme.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 18,
                        color: colors.onSurface,
                      ),
                      const SizedBox(width: 10),
                      Text('Dark mode', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  Switch.adaptive(
                    value: theme.themeMode == ThemeMode.dark,
                    onChanged: (_) => theme.toggleTheme(),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
            if (auth.isLoggedIn)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      // Capture the root navigator BEFORE popping the drawer,
                      // so we still have a valid navigator to redirect with.
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pop(); // close drawer
                      await auth.logout();
                      navigator.pushNamedAndRemoveUntil('/login', (_) => false);
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Log out'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Text('v1.0.0', style: Theme.of(context).textTheme.labelSmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool push;

  const _NavItem({required this.icon, required this.title, required this.route, this.push = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(icon, size: 20),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        onTap: () {
          Navigator.pop(context);
          if (push) {
            Navigator.pushNamed(context, route);
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
