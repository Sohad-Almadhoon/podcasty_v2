import 'dart:math' as math;
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
  int _plays = 0, _likes = 0, _comments = 0, _bookmarks = 0;
  Map<String, int> _playsByDay = {};

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
      int p = 0, l = 0, c = 0, b = 0;
      final map = <String, Analytics>{};
      final daily = <String, int>{};
      for (final pod in podcasts) {
        try {
          final a = await AnalyticsService.fetchAnalytics(pod.id);
          map[pod.id] = a;
          p += a.views; l += a.likes; c += a.comments; b += a.bookmarks;
          a.viewsByDay?.forEach((day, count) {
            daily[day] = (daily[day] ?? 0) + count;
          });
        } catch (_) {
          p += pod.views; l += pod.likes;
        }
      }
      if (mounted) setState(() {
        _podcasts = podcasts;
        _analytics = map;
        _plays = p; _likes = l; _comments = c; _bookmarks = b;
        _playsByDay = daily;
        _isLoading = false;
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
                  if (_podcasts.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text('TOP PODCASTS BY PLAYS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
                    const SizedBox(height: 10),
                    _ChartCard(child: _TopPodcastsBars(
                      podcasts: _podcasts,
                      analytics: _analytics,
                    )),
                  ],

                  if (_likes + _comments + _bookmarks > 0) ...[
                    const SizedBox(height: 28),
                    Text('ENGAGEMENT MIX',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
                    const SizedBox(height: 10),
                    _ChartCard(child: _EngagementDonut(
                      likes: _likes,
                      comments: _comments,
                      bookmarks: _bookmarks,
                    )),
                  ],

                  if (_playsByDay.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text('PLAYS OVER TIME',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
                    const SizedBox(height: 10),
                    _ChartCard(child: _PlaysLineChart(playsByDay: _playsByDay)),
                  ],

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

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _TopPodcastsBars extends StatelessWidget {
  final List<Podcast> podcasts;
  final Map<String, Analytics> analytics;
  const _TopPodcastsBars({required this.podcasts, required this.analytics});

  int _plays(Podcast p) => analytics[p.id]?.views ?? p.views;

  @override
  Widget build(BuildContext context) {
    final sorted = [...podcasts]..sort((a, b) => _plays(b).compareTo(_plays(a)));
    final top = sorted.take(5).toList();
    final maxValue = top.isEmpty ? 0 : _plays(top.first);
    final colors = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < top.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(children: [
            SizedBox(
              width: 110,
              child: Text(
                top[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final ratio = maxValue == 0 ? 0.0 : _plays(top[i]) / maxValue;
                return Stack(children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.outline.withAlpha(60),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ]);
              }),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              child: Text(
                '${_plays(top[i])}',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

class _EngagementDonut extends StatelessWidget {
  final int likes;
  final int comments;
  final int bookmarks;
  const _EngagementDonut({required this.likes, required this.comments, required this.bookmarks});

  @override
  Widget build(BuildContext context) {
    const likeColor = Color(0xFFEC4899);
    const commentColor = Color(0xFF16A34A);
    const bookmarkColor = Color(0xFF3B82F6);
    final total = likes + comments + bookmarks;

    return Row(children: [
      SizedBox(
        width: 120,
        height: 120,
        child: CustomPaint(
          painter: _DonutPainter(
            values: [likes.toDouble(), comments.toDouble(), bookmarks.toDouble()],
            colors: const [likeColor, commentColor, bookmarkColor],
            trackColor: Theme.of(context).colorScheme.outline.withAlpha(60),
          ),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$total', style: Theme.of(context).textTheme.titleLarge),
              Text('total', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DonutLegendRow(color: likeColor, label: 'Likes', value: likes),
          const SizedBox(height: 8),
          _DonutLegendRow(color: commentColor, label: 'Comments', value: comments),
          const SizedBox(height: 8),
          _DonutLegendRow(color: bookmarkColor, label: 'Bookmarks', value: bookmarks),
        ]),
      ),
    ]);
  }
}

class _DonutLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _DonutLegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      Text('$value', style: Theme.of(context).textTheme.titleMedium),
    ]);
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color trackColor;
  _DonutPainter({required this.values, required this.colors, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final stroke = 14.0;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    double start = -math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (int i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = (values[i] / total) * 2 * math.pi;
      final p = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors || old.trackColor != trackColor;
}

class _PlaysLineChart extends StatelessWidget {
  final Map<String, int> playsByDay;
  const _PlaysLineChart({required this.playsByDay});

  @override
  Widget build(BuildContext context) {
    final keys = playsByDay.keys.toList()..sort();
    final values = keys.map((k) => playsByDay[k]!).toList();
    final maxV = values.isEmpty ? 0 : values.reduce(math.max);
    final colors = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 140,
        child: CustomPaint(
          size: Size.infinite,
          painter: _LinePainter(
            values: values.map((v) => v.toDouble()).toList(),
            lineColor: primary,
            fillColor: primary.withAlpha(40),
            gridColor: colors.outline.withAlpha(60),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          keys.isNotEmpty ? keys.first : '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text('peak $maxV', style: Theme.of(context).textTheme.bodySmall),
        Text(
          keys.isNotEmpty ? keys.last : '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
    ]);
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  _LinePainter({required this.values, required this.lineColor, required this.fillColor, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;

    final maxV = values.reduce(math.max);
    final safeMax = maxV <= 0 ? 1.0 : maxV;
    final n = values.length;
    final dx = n == 1 ? 0.0 : size.width / (n - 1);

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : dx * i;
      final y = size.height - (values[i] / safeMax) * size.height;
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dot = Paint()..color = lineColor;
    for (final p in points) {
      canvas.drawCircle(p, 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.lineColor != lineColor || old.fillColor != fillColor || old.gridColor != gridColor;
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
