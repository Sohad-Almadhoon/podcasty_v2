import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/leaderboard_service.dart';
import '../widgets/app_drawer.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardUser> _users = [];
  bool _isLoading = true;
  String _orderBy = 'plays';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final users = await LeaderboardService.fetchLeaderboard(
        limit: 50,
        orderBy: _orderBy,
      );
      if (mounted) setState(() { _users = users; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _statValue(LeaderboardUser u) {
    switch (_orderBy) {
      case 'podcasts':
        return '${u.podcastCount}';
      case 'likes':
        return '${u.totalLikes}';
      default:
        return '${u.totalViews}';
    }
  }

  String get _statLabel {
    switch (_orderBy) {
      case 'podcasts':
        return 'podcasts';
      case 'likes':
        return 'likes';
      default:
        return 'plays';
    }
  }

  int _totalForCurrent() {
    switch (_orderBy) {
      case 'podcasts':
        return _users.fold<int>(0, (s, u) => s + u.podcastCount);
      case 'likes':
        return _users.fold<int>(0, (s, u) => s + u.totalLikes);
      default:
        return _users.fold<int>(0, (s, u) => s + u.totalViews);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            // Filter chips
            _FilterChips(
              current: _orderBy,
              onChanged: (v) {
                setState(() => _orderBy = v);
                _load();
              },
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_users.isEmpty)
              _EmptyState(orderBy: _orderBy)
            else ...[
              // Summary card
              _SummaryCard(
                creators: _users.length,
                total: _totalForCurrent(),
                label: _statLabel,
              ),
              const SizedBox(height: 16),

              // Podium (renders gracefully even with 1 or 2 users)
              _Podium(users: _users, statValue: _statValue, statLabel: _statLabel),
              const SizedBox(height: 16),

              if (_users.length > 3) ...[
                Text(
                  'EVERYONE ELSE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.4,
                        color: colors.outline,
                      ),
                ),
                const SizedBox(height: 8),
                ..._users.skip(3).toList().asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LeaderCard(
                          user: e.value,
                          rank: e.key + 4,
                          statValue: _statValue(e.value),
                          statLabel: _statLabel,
                        ),
                      ),
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _FilterChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;
    final items = const [
      ('plays', 'Top Plays', Icons.play_arrow_rounded),
      ('podcasts', 'Most Podcasts', Icons.podcasts_rounded),
      ('likes', 'Most Liked', Icons.favorite_rounded),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label, icon) = items[i];
          final selected = key == current;
          return GestureDetector(
            onTap: () => onChanged(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? primary : Colors.transparent,
                border: Border.all(color: selected ? primary : colors.outline),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(children: [
                Icon(icon, size: 14, color: selected ? Colors.white : colors.onSurface),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : colors.onSurface,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int creators;
  final int total;
  final String label;
  const _SummaryCard({required this.creators, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _SummaryStat(value: '$creators', label: 'creators'),
        Container(width: 1, height: 28, color: colors.outline),
        _SummaryStat(value: '$total', label: 'total $label'),
      ]),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  const _SummaryStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardUser> users;
  final String Function(LeaderboardUser) statValue;
  final String statLabel;
  const _Podium({required this.users, required this.statValue, required this.statLabel});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    final hasFirst = users.isNotEmpty;
    final hasSecond = users.length >= 2;
    final hasThird = users.length >= 3;

    return SizedBox(
      height: 240,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: hasSecond
              ? _PodiumItem(
                  user: users[1], rank: 2, height: 150,
                  color: const Color(0xFFC0C0C0),
                  statValue: statValue(users[1]), statLabel: statLabel,
                )
              : const _PodiumPlaceholder(rank: 2, height: 150),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: hasFirst
              ? _PodiumItem(
                  user: users[0], rank: 1, height: 180,
                  color: const Color(0xFFFFD700),
                  statValue: statValue(users[0]), statLabel: statLabel,
                )
              : const _PodiumPlaceholder(rank: 1, height: 180),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: hasThird
              ? _PodiumItem(
                  user: users[2], rank: 3, height: 120,
                  color: const Color(0xFFCD7F32),
                  statValue: statValue(users[2]), statLabel: statLabel,
                )
              : const _PodiumPlaceholder(rank: 3, height: 120),
        ),
      ]),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardUser user;
  final int rank;
  final double height;
  final Color color;
  final String statValue;
  final String statLabel;

  const _PodiumItem({
    required this.user,
    required this.rank,
    required this.height,
    required this.color,
    required this.statValue,
    required this.statLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile', arguments: user.id),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        CircleAvatar(
          radius: rank == 1 ? 34 : 26,
          backgroundColor: color,
          child: CircleAvatar(
            radius: rank == 1 ? 31 : 23,
            backgroundImage: user.imageUrl != null ? CachedNetworkImageProvider(user.imageUrl!) : null,
            backgroundColor: colors.surface,
            child: user.imageUrl == null
                ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: rank == 1 ? 20 : 16, fontWeight: FontWeight.bold))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(user.name, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('$statValue $statLabel', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: height * 0.4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [color, color.withAlpha(140)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text('#$rank', style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5,
            )),
          ),
        ),
      ]),
    );
  }
}

class _PodiumPlaceholder extends StatelessWidget {
  final int rank;
  final double height;
  const _PodiumPlaceholder({required this.rank, required this.height});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      CircleAvatar(
        radius: rank == 1 ? 34 : 26,
        backgroundColor: colors.surface,
        child: Icon(Icons.person_outline_rounded, color: colors.outline, size: rank == 1 ? 28 : 22),
      ),
      const SizedBox(height: 8),
      Text('—', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.outline)),
      const SizedBox(height: 2),
      Text('open spot', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.outline)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        height: height * 0.4,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outline),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Center(
          child: Text('#$rank',
              style: TextStyle(color: colors.outline, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
        ),
      ),
    ]);
  }
}

class _LeaderCard extends StatelessWidget {
  final LeaderboardUser user;
  final int rank;
  final String statValue;
  final String statLabel;
  const _LeaderCard({
    required this.user,
    required this.rank,
    required this.statValue,
    required this.statLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(context, '/profile', arguments: user.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            SizedBox(
              width: 30,
              child: Text('#$rank',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.outline)),
            ),
            CircleAvatar(
              radius: 22,
              backgroundImage: user.imageUrl != null ? CachedNetworkImageProvider(user.imageUrl!) : null,
              backgroundColor: Theme.of(context).primaryColor,
              child: user.imageUrl == null
                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('${user.podcastCount} podcasts · ${user.totalLikes} likes',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(statValue,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
              Text(statLabel, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String orderBy;
  const _EmptyState({required this.orderBy});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;
    String headline;
    String hint;
    switch (orderBy) {
      case 'podcasts':
        headline = 'No creators yet';
        hint = 'Be the first to publish a podcast and claim the top spot.';
        break;
      case 'likes':
        headline = 'No likes yet';
        hint = 'Like podcasts you enjoy — top creators will show up here.';
        break;
      default:
        headline = 'No plays yet';
        hint = 'Once people start listening, the leaderboard fills up here.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            color: primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.emoji_events_rounded, size: 44, color: primary),
        ),
        const SizedBox(height: 18),
        Text(headline, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.outline),
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/create-podcast'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create a podcast'),
        ),
      ]),
    );
  }
}
