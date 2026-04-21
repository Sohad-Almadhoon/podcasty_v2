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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final users = await LeaderboardService.fetchLeaderboard(limit: 20);
      if (mounted) setState(() { _users = users; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.leaderboard_rounded, size: 48, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('No data yet', style: Theme.of(context).textTheme.titleLarge),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      if (_users.length >= 3) _buildPodium(),
                      const SizedBox(height: 20),
                      ..._users.asMap().entries.where((e) => e.key >= 3 || _users.length < 3).map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LeaderCard(user: e.value, rank: e.key + 1),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPodium() {
    return SizedBox(
      height: 240,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _PodiumItem(user: _users[1], rank: 2, height: 150, color: const Color(0xFFC0C0C0))),
        const SizedBox(width: 8),
        Expanded(child: _PodiumItem(user: _users[0], rank: 1, height: 180, color: const Color(0xFFFFD700))),
        const SizedBox(width: 8),
        Expanded(child: _PodiumItem(user: _users[2], rank: 3, height: 120, color: const Color(0xFFCD7F32))),
      ]),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardUser user;
  final int rank;
  final double height;
  final Color color;

  const _PodiumItem({required this.user, required this.rank, required this.height, required this.color});

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
        Text('${user.totalViews} plays', style: Theme.of(context).textTheme.bodySmall),
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

class _LeaderCard extends StatelessWidget {
  final LeaderboardUser user;
  final int rank;
  const _LeaderCard({required this.user, required this.rank});

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
                Text('${user.podcastCount} podcasts', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${user.totalViews}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
              Text('plays', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ]),
        ),
      ),
    );
  }
}
