import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/podcast.dart';
import '../providers/auth_provider.dart';
import '../services/podcasts_service.dart';
import '../services/analytics_service.dart';
import '../widgets/app_drawer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Podcast> _podcasts = [];
  Map<String, Analytics> _analytics = {};
  bool _isLoading = true;
  int _plays = 0, _likes = 0, _comments = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId == null) { setState(() => _isLoading = false); return; }
    try {
      final podcasts = await PodcastsService.fetchPodcasts(userId: auth.userId);
      int p = 0, l = 0, c = 0;
      final map = <String, Analytics>{};
      for (final pod in podcasts) {
        try {
          final a = await AnalyticsService.fetchAnalytics(pod.id);
          map[pod.id] = a;
          p += a.views; l += a.likes; c += a.comments;
        } catch (_) {
          p += pod.views; l += pod.likes;
        }
      }
      if (mounted) setState(() {
        _podcasts = podcasts; _analytics = map; _plays = p; _likes = l; _comments = c; _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  Text('OVERVIEW', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(title: 'Total Plays', value: '$_plays', icon: Icons.headphones_rounded, color: const Color(0xFF3B82F6)),
                      _StatCard(title: 'Likes', value: '$_likes', icon: Icons.favorite_rounded, color: const Color(0xFFEC4899)),
                      _StatCard(title: 'Comments', value: '$_comments', icon: Icons.chat_bubble_rounded, color: const Color(0xFF16A34A)),
                      _StatCard(title: 'Podcasts', value: '${_podcasts.length}', icon: Icons.podcasts_rounded, color: Theme.of(context).primaryColor),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('PER PODCAST', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
                  const SizedBox(height: 10),
                  if (_podcasts.isEmpty)
                    _EmptyCard(
                      icon: Icons.podcasts_rounded,
                      title: 'No podcasts yet',
                      subtitle: 'Create your first podcast to see analytics',
                      actionLabel: 'Create',
                      onAction: () => Navigator.pushNamed(context, '/create-podcast'),
                    )
                  else
                    ..._podcasts.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PodcastRow(podcast: p, analytics: _analytics[p.id]),
                        )),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(30), borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 2),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _PodcastRow extends StatelessWidget {
  final Podcast podcast;
  final Analytics? analytics;
  const _PodcastRow({required this.podcast, this.analytics});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(podcast.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Mini(icon: Icons.headphones_rounded, value: '${analytics?.views ?? podcast.views}', label: 'Plays'),
            _Mini(icon: Icons.favorite_rounded, value: '${analytics?.likes ?? podcast.likes}', label: 'Likes'),
            _Mini(icon: Icons.chat_bubble_rounded, value: '${analytics?.comments ?? 0}', label: 'Comments'),
            _Mini(icon: Icons.bookmark_rounded, value: '${analytics?.bookmarks ?? 0}', label: 'Saves'),
          ]),
        ]),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Mini({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      Icon(icon, size: 16, color: colors.outline),
      const SizedBox(height: 5),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyCard({required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    );
  }
}
