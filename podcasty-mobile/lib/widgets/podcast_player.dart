import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_provider.dart';

class PodcastPlayer extends StatelessWidget {
  const PodcastPlayer({Key? key}) : super(key: key);

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context);
    final podcast = audio.currentPodcast;
    if (podcast == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: audio.progress,
              backgroundColor: colors.outline.withAlpha(60),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              minHeight: 3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: podcast.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(10)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.music_note, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podcast.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${podcast.authorName}  ·  ${_fmt(audio.position)} / ${_fmt(audio.duration)}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Controls
                _PlayerBtn(icon: Icons.replay_10_rounded, size: 22, onTap: audio.skipBackward),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: audio.togglePlayPause,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                    child: Icon(
                      audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _PlayerBtn(icon: Icons.forward_10_rounded, size: 22, onTap: audio.skipForward),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _PlayerBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: size, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
