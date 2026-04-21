import 'package:flutter/material.dart';
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
      final podcasts = <Podcast>[];
      for (final podcastId in playlist.podcastIds) {
        try {
          final podcast = await PodcastsService.fetchPodcastByIdPublic(podcastId);
          podcasts.add(podcast);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _podcasts = podcasts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeFromPlaylist(String podcastId, int index) async {
    if (_playlist == null) return;

    final podcast = _podcasts[index];
    setState(() => _podcasts.removeAt(index));

    try {
      await PlaylistsService.removeFromPlaylist(_playlist!.id, podcastId);
    } catch (e) {
      if (mounted) {
        setState(() => _podcasts.insert(index, podcast));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist?.name ?? 'Playlist'),
      ),
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
                        'Add podcasts to this playlist from podcast details',
                        style: Theme.of(context).textTheme.bodyMedium,
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
