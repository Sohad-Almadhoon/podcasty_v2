import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../models/podcast.dart';
import '../providers/auth_provider.dart';
import '../services/users_service.dart';
import '../services/follows_service.dart';
import '../widgets/podcast_card.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  User? _user;
  List<Podcast> _podcasts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isOwn = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments;
    final userId = (args is String && args.isNotEmpty) ? args : auth.userId;
    _isOwn = userId == auth.userId;

    if (userId == null) { setState(() => _isLoading = false); return; }

    try {
      final results = await Future.wait([
        UsersService.fetchUser(userId),
        UsersService.fetchUserPodcasts(userId),
      ]);
      final user = results[0] as User;
      final podcasts = results[1] as List<Podcast>;
      bool following = false;
      if (!_isOwn && auth.isLoggedIn) {
        following = await FollowsService.isFollowing(userId).catchError((_) => false);
      }
      if (mounted) setState(() {
        _user = user; _podcasts = podcasts; _isFollowing = following; _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;
    try {
      if (_isFollowing) {
        await FollowsService.unfollowUser(_user!.id);
        setState(() => _isFollowing = false);
      } else {
        await FollowsService.followUser(_user!.id);
        setState(() => _isFollowing = true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text(_user?.name ?? 'Profile')),
      drawer: _isOwn ? const AppDrawer() : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.person_off_rounded, size: 48, color: colors.outline),
                    const SizedBox(height: 12),
                    Text('User not found', style: Theme.of(context).textTheme.titleLarge),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Column(children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [primary, primary.withAlpha(160)]),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: colors.surface,
                              backgroundImage: _user?.imageUrl != null ? CachedNetworkImageProvider(_user!.imageUrl!) : null,
                              child: _user?.imageUrl == null
                                  ? Text(_user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                                      style: Theme.of(context).textTheme.displaySmall)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(_user!.name, style: Theme.of(context).textTheme.displaySmall),
                          const SizedBox(height: 4),
                          Text(_user!.email, style: Theme.of(context).textTheme.bodyMedium),
                          if (_user!.bio != null) ...[
                            const SizedBox(height: 10),
                            Text(_user!.bio!, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 20),
                          // Action
                          if (!_isOwn)
                            ElevatedButton.icon(
                              onPressed: _toggleFollow,
                              icon: Icon(_isFollowing ? Icons.check_rounded : Icons.person_add_rounded, size: 18),
                              label: Text(_isFollowing ? 'Following' : 'Follow'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing ? colors.surface : primary,
                                foregroundColor: _isFollowing ? colors.onSurface : Colors.white,
                                side: _isFollowing ? BorderSide(color: colors.outline) : BorderSide.none,
                              ),
                            ),
                        ]),
                      ),
                    ),

                    // Stats
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.outline),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          _Stat(label: 'Podcasts', value: '${_user?.podcastCount ?? _podcasts.length}'),
                          Container(width: 1, height: 28, color: colors.outline),
                          _Stat(label: 'Followers', value: '${_user!.followers}'),
                          Container(width: 1, height: 28, color: colors.outline),
                          _Stat(label: 'Following', value: '${_user!.following}'),
                        ]),
                      ),
                    ),

                    // Tabs
                    SliverToBoxAdapter(
                      child: TabBar(
                        controller: _tabCtrl,
                        tabs: const [Tab(text: 'Podcasts'), Tab(text: 'About')],
                      ),
                    ),

                    // Content
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [_buildPodcastsTab(), _buildAboutTab()],
                      ),
                    ),
                  ]),
                ),
    );
  }

  Widget _buildPodcastsTab() {
    if (_podcasts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.podcasts_rounded, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('No podcasts yet', style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      itemCount: _podcasts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) => PodcastCard(
        podcast: _podcasts[i],
        onTap: () => Navigator.pushNamed(context, '/podcast-detail', arguments: _podcasts[i].id),
      ),
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _InfoRow(label: 'Member since', value: '${_user!.createdAt.month}/${_user!.createdAt.year}'),
        if (_user?.bio != null) ...[
          const SizedBox(height: 16),
          _InfoRow(label: 'Bio', value: _user!.bio!),
        ],
        const SizedBox(height: 16),
        _InfoRow(label: 'Total podcasts', value: '${_podcasts.length}'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 2),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.bodyLarge),
    ]);
  }
}
