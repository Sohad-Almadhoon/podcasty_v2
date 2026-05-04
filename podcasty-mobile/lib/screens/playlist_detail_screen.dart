import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/podcast.dart';
import '../models/playlist.dart';
import '../services/playlists_service.dart';
import '../services/podcasts_service.dart';
import '../widgets/podcast_card.dart';

class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  Playlist? _playlist;
  List<Podcast> _podcasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playlist = ModalRoute.of(context)?.settings.arguments as Playlist?;
      if (playlist != null) {
        setState(() => _playlist = playlist);
        _loadPodcasts(playlist);
      }
    });
  }

  Future<void> _loadPodcasts(Playlist playlist) async {
    setState(() => _isLoading = true);

    try {
      final podcasts = await PlaylistsService.fetchPlaylistItems(playlist.id);
      if (mounted) {
        setState(() {
          _podcasts = podcasts;
          _playlist = _withPodcastIds(playlist, podcasts.map((p) => p.id).toList());
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load playlist: $e')),
        );
      }
    }
  }

  Future<void> _removeFromPlaylist(String podcastId, int index) async {
    if (_playlist == null) return;

    final podcast = _podcasts[index];
    setState(() {
      _podcasts.removeAt(index);
      _playlist = _withPodcastIds(_playlist!, _playlist!.podcastIds.where((id) => id != podcastId).toList());
    });

    try {
      await PlaylistsService.removeFromPlaylist(_playlist!.id, podcastId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _podcasts.insert(index, podcast);
          _playlist = _withPodcastIds(_playlist!, [..._playlist!.podcastIds, podcastId]);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  Future<void> _openAddSheet() async {
    if (_playlist == null) return;
    final added = await showModalBottomSheet<List<Podcast>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddPodcastsSheet(
        playlistId: _playlist!.id,
        existingIds: _playlist!.podcastIds.toSet(),
      ),
    );
    if (added != null && added.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${added.length} podcast${added.length == 1 ? '' : 's'}')),
      );
      await _loadPodcasts(_playlist!);
    }
  }

  Playlist _withPodcastIds(Playlist src, List<String> ids) => Playlist(
        id: src.id,
        name: src.name,
        description: src.description,
        userId: src.userId,
        podcastIds: ids,
        itemCount: ids.length,
        createdAt: src.createdAt,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist?.name ?? 'Playlist'),
        actions: [
          if (_playlist != null)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add podcasts',
              onPressed: _openAddSheet,
            ),
        ],
      ),
      floatingActionButton: _playlist != null && _podcasts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openAddSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add podcasts'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _podcasts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_play, size: 80, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('Playlist is empty', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Add podcasts" to get started',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _openAddSheet,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add podcasts'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Playlist header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_playlist?.name ?? '', style: Theme.of(context).textTheme.displaySmall),
                          if (_playlist?.description != null) ...[
                            const SizedBox(height: 8),
                            Text(_playlist!.description!, style: Theme.of(context).textTheme.bodyLarge),
                          ],
                          const SizedBox(height: 8),
                          Text('${_podcasts.length} episodes', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                        itemCount: _podcasts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return Dismissible(
                            key: Key(_podcasts[index].id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _removeFromPlaylist(_podcasts[index].id, index),
                            child: PodcastCard(
                              podcast: _podcasts[index],
                              onTap: () {
                                Navigator.pushNamed(context, '/podcast-detail', arguments: _podcasts[index].id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _AddPodcastsSheet extends StatefulWidget {
  final String playlistId;
  final Set<String> existingIds;

  const _AddPodcastsSheet({required this.playlistId, required this.existingIds});

  @override
  State<_AddPodcastsSheet> createState() => _AddPodcastsSheetState();
}

class _AddPodcastsSheetState extends State<_AddPodcastsSheet> {
  final _searchCtrl = TextEditingController();
  List<Podcast> _all = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await PodcastsService.fetchPodcasts(limit: 200);
      if (mounted) setState(() { _all = list; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  List<Podcast> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((p) =>
      p.title.toLowerCase().contains(q) ||
      p.authorName.toLowerCase().contains(q) ||
      p.category.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> _save() async {
    if (_selected.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    final added = <Podcast>[];
    for (final id in _selected) {
      try {
        await PlaylistsService.addToPlaylist(widget.playlistId, id);
        final p = _all.firstWhere((x) => x.id == id);
        added.add(p);
      } catch (_) {
        // Skip individual failures (e.g. duplicates) — keep the rest moving.
      }
    }
    if (mounted) Navigator.pop(context, added);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;
    final filtered = _filtered;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: colors.outline, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                Expanded(
                  child: Text('Add podcasts', style: Theme.of(context).textTheme.titleLarge),
                ),
                if (_selected.isNotEmpty)
                  Text('${_selected.length} selected', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search podcasts',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(child: Text('No podcasts found', style: Theme.of(context).textTheme.bodyMedium))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final p = filtered[i];
                            final inPlaylist = widget.existingIds.contains(p.id);
                            final picked = _selected.contains(p.id);
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: p.imageUrl,
                                  width: 48, height: 48, fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: colors.surface, width: 48, height: 48),
                                  errorWidget: (_, __, ___) => Container(
                                    color: colors.surface, width: 48, height: 48,
                                    child: const Icon(Icons.music_note, size: 20),
                                  ),
                                ),
                              ),
                              title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(p.authorName, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: inPlaylist
                                  ? Icon(Icons.check_circle_rounded, color: primary, size: 22)
                                  : Checkbox(
                                      value: picked,
                                      onChanged: (v) => setState(() {
                                        if (v == true) {
                                          _selected.add(p.id);
                                        } else {
                                          _selected.remove(p.id);
                                        }
                                      }),
                                    ),
                              enabled: !inPlaylist,
                              onTap: inPlaylist
                                  ? null
                                  : () => setState(() {
                                        if (_selected.contains(p.id)) {
                                          _selected.remove(p.id);
                                        } else {
                                          _selected.add(p.id);
                                        }
                                      }),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving || _selected.isEmpty ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_selected.isEmpty ? 'Add' : 'Add ${_selected.length}'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
