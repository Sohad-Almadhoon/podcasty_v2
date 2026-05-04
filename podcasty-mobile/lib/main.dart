import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/theme_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/podcasts_screen.dart';
import 'screens/podcast_detail_screen.dart';
import 'screens/create_podcast_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/playlist_detail_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/analytics_screen.dart';
import 'widgets/podcast_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yffktxqtlybexfcsksqd.supabase.co',
    anonKey: 'sb_publishable_W9ZKUpiYlGSRWe1NgT6ILw_CWsdzpEj',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Podcasty',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/': (context) => const MainLayout(child: HomeScreen()),
              '/podcasts': (context) => const MainLayout(child: PodcastsScreen()),
              '/podcast-detail': (context) => const MainLayout(child: PodcastDetailScreen()),
              '/create-podcast': (context) => const MainLayout(child: CreatePodcastScreen()),
              '/feed': (context) => const MainLayout(child: FeedScreen()),
              '/bookmarks': (context) => const MainLayout(child: BookmarksScreen()),
              '/playlists': (context) => const MainLayout(child: PlaylistsScreen()),
              '/playlist-detail': (context) => const MainLayout(child: PlaylistDetailScreen()),
              '/leaderboard': (context) => const MainLayout(child: LeaderboardScreen()),
              '/profile': (context) => const MainLayout(child: ProfileScreen()),
              '/analytics': (context) => const MainLayout(child: AnalyticsScreen()),
            },
          );
        },
      ),
    );
  }
}

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          // Audio Player at bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PodcastPlayer(),
          ),
        ],
      ),
    );
  }
}
