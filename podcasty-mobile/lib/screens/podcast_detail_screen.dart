import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/podcast.dart';
import '../providers/audio_provider.dart';
import '../providers/auth_provider.dart';
import '../services/podcasts_service.dart';
import '../services/likes_service.dart';
import '../services/bookmarks_service.dart';
import '../services/api_client.dart';
import '../services/comments_service.dart';
import '../services/playlists_service.dart';
import '../services/users_service.dart';
import '../models/playlist.dart';
import '../widgets/podcast_card.dart';

class PodcastDetailScreen extends StatefulWidget {
  const PodcastDetailScreen({Key? key}) : super(key: key);

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  Podcast? _podcast;
  List<Comment> _comments = [];
  List<Podcast> _related = [];
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likeCount = 0;
  List<Playlist> _playlistsContaining = [];
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = ModalRoute.of(context)?.settings.arguments as String?;
      if (id != null) _load(id);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String id) async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final results = await Future.wait([
        PodcastsService.fetchPodcastByIdPublic(id),
        CommentsService.fetchComments(id).catchError((_) => <Comment>[]),
        LikesService.getLikeStatus(id).catchError((_) => (liked: false, count: 0)),
        if (auth.isLoggedIn)
          BookmarksService.getBookmarkStatus(id).catchError((_) => false)
        else
          Future<bool>.value(false),
        if (auth.isLoggedIn)
          PlaylistsService.fetchPlaylists().catchError((_) => <Playlist>[])
        else
          Future<List<Playlist>>.value(<Playlist>[]),
      ]);
      final podcast = results[0] as Podcast;
      final comments = results[1] as List<Comment>;
      final likeStatus = results[2] as ({bool liked, int count});
      final bookmarked = results[3] as bool;
      final playlists = results[4] as List<Playlist>;
      final related = await UsersService.fetchUserPodcasts(podcast.authorId)
          .then((l) => l.where((p) => p.id != podcast.id).toList())
          .catchError((_) => <Podcast>[]);
      if (mounted) {
        setState(() {
          _podcast = podcast;
          _comments = comments;
          _related = related;
          _isLiked = likeStatus.liked;
          _likeCount = likeStatus.count > 0 ? likeStatus.count : podcast.likes;
          _isBookmarked = bookmarked;
          _playlistsContaining = playlists.where((pl) => pl.podcastIds.contains(id)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_podcast == null) return;
    final wasLiked = _isLiked;
    // Optimistic flip — server stays the source of truth on conflict.
    setState(() {
      _isLiked = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
    });
    try {
      if (wasLiked) {
        await LikesService.unlikePodcast(_podcast!.id);
      } else {
        await LikesService.likePodcast(_podcast!.id);
      }
    } on ApiException catch (e) {
      // 409 → already liked; 404 → already unliked. Either way the desired end
      // state matches the server, so silently re-sync from the status endpoint
      // instead of bouncing the optimistic toggle.
      if (e.statusCode == 409 || e.statusCode == 404) {
        await _syncLikeStatus();
      } else {
        if (mounted) {
          setState(() {
            _isLiked = wasLiked;
            _likeCount += wasLiked ? 1 : -1;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likeCount += wasLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (_podcast == null) return;
    final wasBookmarked = _isBookmarked;
    setState(() => _isBookmarked = !wasBookmarked);
    try {
      if (wasBookmarked) {
        await BookmarksService.removeBookmark(_podcast!.id);
      } else {
        await BookmarksService.addBookmark(_podcast!.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isBookmarked ? 'Saved' : 'Removed from bookmarks')),
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode == 409 || e.statusCode == 404) {
        await _syncBookmarkStatus();
      } else {
        if (mounted) {
          setState(() => _isBookmarked = wasBookmarked);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBookmarked = wasBookmarked);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _syncLikeStatus() async {
    if (_podcast == null) return;
    try {
      final s = await LikesService.getLikeStatus(_podcast!.id);
      if (mounted) setState(() { _isLiked = s.liked; _likeCount = s.count; });
    } catch (_) {}
  }

  Future<void> _syncBookmarkStatus() async {
    if (_podcast == null) return;
    try {
      final b = await BookmarksService.getBookmarkStatus(_podcast!.id);
      if (mounted) setState(() => _isBookmarked = b);
    } catch (_) {}
  }

  Future<void> _addComment() async {
    if (_podcast == null || _commentCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final c = await CommentsService.createComment(_podcast!.id, _commentCtrl.text.trim());
      setState(() { _comments.insert(0, c); _commentCtrl.clear(); });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(String id) async {
    try {
      await CommentsService.deleteComment(id);
      setState(() => _comments.removeWhere((c) => c.id == id));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deletePodcast() async {
    if (_podcast == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete podcast?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await PodcastsService.deletePodcast(_podcast!.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _showPlaylistSheet() async {
    if (_podcast == null) return;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PlaylistSheet(podcastId: _podcast!.id),
    );
    if (changed == true && _podcast != null) {
      try {
        final pls = await PlaylistsService.fetchPlaylists();
        if (mounted) {
          setState(() {
            _playlistsContaining = pls.where((pl) => pl.podcastIds.contains(_podcast!.id)).toList();
          });
        }
      } catch (_) {}
    }
  }

  void _share() {
    if (_podcast == null) return;
    Share.share('Check out "${_podcast!.title}" on Podcasty!\n${_podcast!.audioUrl}', subject: _podcast!.title);
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final colors = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;
    final isOwner = auth.userId == _podcast?.authorId;

    if (_isLoading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_podcast == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Not found')));

    final p = _podcast!;
    final playing = audio.currentPodcast?.id == p.id && audio.isPlaying;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Cover ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: p.imageUrl, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: colors.surface),
                    errorWidget: (_, __, ___) => Container(color: colors.surface, child: const Icon(Icons.music_note, size: 48)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withAlpha(180)],
                      ),
                    ),
                  ),
                  // Play button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        audio.playPodcast(p);
                        PodcastsService.incrementPlayCount(p.id).catchError((_) {});
                      },
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──
                  Text(p.title, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 10),

                  // ── Author ──
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile', arguments: p.authorId),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: p.authorImage != null ? CachedNetworkImageProvider(p.authorImage!) : null,
                          child: p.authorImage == null ? Text(p.authorName.isNotEmpty ? p.authorName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12)) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(p.authorName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Stats ──
                  Row(children: [
                    _Pill(icon: Icons.headphones_rounded, label: '${p.views} plays'),
                    const SizedBox(width: 8),
                    _Pill(icon: Icons.favorite_rounded, label: '$_likeCount'),
                    const SizedBox(width: 8),
                    _Pill(icon: Icons.chat_bubble_outline_rounded, label: '${_comments.length}'),
                  ]),
                  const SizedBox(height: 16),

                  // ── Actions ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionIcon(
                          icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          color: _isLiked ? Colors.red : null,
                          onTap: _toggleLike,
                        ),
                        _ActionIcon(
                          icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                          color: _isBookmarked ? primary : null,
                          onTap: _toggleBookmark,
                        ),
                        _ActionIcon(
                          icon: _playlistsContaining.isNotEmpty
                              ? Icons.playlist_add_check_rounded
                              : Icons.playlist_add_rounded,
                          color: _playlistsContaining.isNotEmpty ? primary : null,
                          onTap: _showPlaylistSheet,
                        ),
                        _ActionIcon(icon: Icons.share_rounded, onTap: _share),
                      ],
                    ),
                  ),

                  if (_playlistsContaining.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _playlistsContaining
                          .map((pl) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.playlist_play_rounded, size: 13, color: primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    pl.name,
                                    style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w600),
                                  ),
                                ]),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Info chips ──
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (p.category.isNotEmpty) _InfoChip(icon: Icons.category_rounded, label: p.category),
                    _InfoChip(icon: Icons.calendar_today_rounded, label: DateFormat('MMM d, yyyy').format(p.createdAt)),
                  ]),
                  const SizedBox(height: 24),

                  // ── Description ──
                  Text('About', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2, color: colors.outline, fontSize: 11,
                  )),
                  const SizedBox(height: 8),
                  Text(p.description, style: Theme.of(context).textTheme.bodyLarge),

                  Divider(height: 48, color: colors.outline),

                  // ── Comments ──
                  Text('Comments (${_comments.length})', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  if (auth.isLoggedIn)
                    Row(children: [
                      Expanded(child: TextField(
                        controller: _commentCtrl,
                        decoration: const InputDecoration(hintText: 'Write a comment...'),
                        maxLines: null,
                      )),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _submitting ? null : _addComment,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10)),
                          child: _submitting
                              ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  const SizedBox(height: 16),

                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No comments yet', style: Theme.of(context).textTheme.bodySmall)),
                    ),

                  ..._comments.map((c) => _CommentTile(
                    comment: c,
                    isOwner: auth.userId == c.userId,
                    onDelete: () => _deleteComment(c.id),
                  )),

                  // ── Related ──
                  if (_related.isNotEmpty) ...[
                    Divider(height: 48, color: colors.outline),
                    Text('MORE BY ${p.authorName.toUpperCase()}', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.2, color: colors.outline, fontSize: 11,
                    )),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _related.length.clamp(0, 5),
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (ctx, i) => SizedBox(
                          width: 250,
                          child: PodcastCard(
                            podcast: _related[i],
                            onTap: () => Navigator.pushNamed(context, '/podcast-detail', arguments: _related[i].id),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Owner controls ──
                  if (isOwner) ...[
                    Divider(height: 48, color: colors.outline),
                    Text('OWNER CONTROLS', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.2, color: colors.outline, fontSize: 11,
                    )),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deletePodcast,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete podcast'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small widgets ──

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: colors.outline),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: colors.onSurface, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isOwner;
  final VoidCallback onDelete;
  const _CommentTile({required this.comment, required this.isOwner, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: comment.userImage != null ? CachedNetworkImageProvider(comment.userImage!) : null,
          child: comment.userImage == null ? Text(comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 11)) : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(comment.userName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 8),
            Text(DateFormat('MMM d').format(comment.createdAt), style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            if (isOwner) GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close_rounded, size: 16, color: Theme.of(context).colorScheme.outline),
            ),
          ]),
          const SizedBox(height: 4),
          Text(comment.content, style: Theme.of(context).textTheme.bodyMedium),
        ])),
      ]),
    );
  }
}

class _PlaylistSheet extends StatefulWidget {
  final String podcastId;
  const _PlaylistSheet({required this.podcastId});

  @override
  State<_PlaylistSheet> createState() => _PlaylistSheetState();
}

class _PlaylistSheetState extends State<_PlaylistSheet> {
  List<Playlist> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pls = await PlaylistsService.fetchPlaylists();
      if (mounted) setState(() { _playlists = pls; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _addExisting(Playlist pl) async {
    if (pl.podcastIds.contains(widget.podcastId)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Already in ${pl.name}')));
      return;
    }
    try {
      await PlaylistsService.addToPlaylist(pl.id, widget.podcastId);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to ${pl.name}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _createAndAdd() async {
    final result = await showDialog<_NewPlaylistResult>(
      context: context,
      builder: (ctx) => const _NewPlaylistDialog(),
    );
    if (result == null || result.name.trim().isEmpty) return;
    try {
      final pl = await PlaylistsService.createPlaylist(
        name: result.name.trim(),
        description: result.description.trim().isEmpty ? null : result.description.trim(),
      );
      await PlaylistsService.addToPlaylist(pl.id, widget.podcastId);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created "${pl.name}" and added')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add to Playlist', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
            title: Text('Create new playlist', style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text('Add this podcast to a new playlist', style: Theme.of(context).textTheme.bodySmall),
            onTap: _createAndAdd,
          ),
          const Divider(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No playlists yet', style: Theme.of(context).textTheme.bodyMedium)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _playlists.length,
                itemBuilder: (ctx, i) {
                  final pl = _playlists[i];
                  final inPlaylist = pl.podcastIds.contains(widget.podcastId);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.playlist_play_rounded, color: primary, size: 22),
                    ),
                    title: Text(pl.name, style: Theme.of(context).textTheme.titleSmall),
                    subtitle: Text('${pl.podcastIds.length} episodes', style: Theme.of(context).textTheme.bodySmall),
                    trailing: inPlaylist
                        ? Icon(Icons.check_circle_rounded, color: primary, size: 22)
                        : const Icon(Icons.add_rounded, size: 22),
                    onTap: () => _addExisting(pl),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}

class _NewPlaylistResult {
  final String name;
  final String description;
  _NewPlaylistResult(this.name, this.description);
}

class _NewPlaylistDialog extends StatefulWidget {
  const _NewPlaylistDialog();

  @override
  State<_NewPlaylistDialog> createState() => _NewPlaylistDialogState();
}

class _NewPlaylistDialogState extends State<_NewPlaylistDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New playlist'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(labelText: 'Description (optional)'),
          maxLines: 2,
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) return;
            Navigator.pop(context, _NewPlaylistResult(_nameCtrl.text, _descCtrl.text));
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
