import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../services/generation_service.dart';
import '../services/podcasts_service.dart';

class CreatePodcastScreen extends StatefulWidget {
  const CreatePodcastScreen({Key? key}) : super(key: key);

  @override
  State<CreatePodcastScreen> createState() => _CreatePodcastScreenState();
}

class _CreatePodcastScreenState extends State<CreatePodcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _voice = 'alloy';
  String _category = 'Technology';
  bool _generating = false;
  bool _publishing = false;
  String? _audioUrl;
  String? _imageUrl;
  final List<_Chapter> _chapters = [];
  AudioPlayer? _preview;

  final List<String> _voices = ['alloy', 'coral', 'echo', 'fable', 'onyx', 'nova', 'shimmer'];
  final List<String> _categories = [
    'Technology', 'Science', 'Business', 'Health', 'Comedy',
    'True Crime', 'History', 'Education', 'Sports', 'Music',
    'News', 'Politics', 'Gaming', 'Entertainment', 'Arts',
    'Fiction', 'Self-Improvement', 'Society & Culture', 'Food', 'Travel',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _promptCtrl.dispose();
    _descCtrl.dispose();
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a prompt first')));
      return;
    }
    setState(() => _generating = true);
    try {
      final r = await GenerationService.generatePodcastContent(prompt: _promptCtrl.text.trim(), voice: _voice);
      setState(() { _audioUrl = r.audioUrl; _imageUrl = r.imageUrl; });
      _preview?.dispose();
      _preview = AudioPlayer();
      await _preview!.setUrl(r.audioUrl);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI content ready!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  int? _parseTs(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(t)) return double.parse(t).round();
    final parts = t.split(':').map((p) => p.trim()).toList();
    if (parts.any((p) => p.isEmpty || int.tryParse(p) == null)) return null;
    final n = parts.map(int.parse).toList();
    if (n.length == 2) return n[0] * 60 + n[1];
    if (n.length == 3) return n[0] * 3600 + n[1] * 60 + n[2];
    return null;
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioUrl == null || _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generate content first')));
      return;
    }
    for (final c in _chapters) {
      if (c.title.text.trim().isEmpty && c.start.text.trim().isEmpty) continue;
      if (_parseTs(c.start.text) == null || c.title.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid chapter: "${c.title.text}"')));
        return;
      }
    }
    setState(() => _publishing = true);
    try {
      await PodcastsService.createPodcast(
        title: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        audioUrl: _audioUrl!,
        imageUrl: _imageUrl!,
        category: _category,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publish failed: $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Podcast')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Generate AI audio & cover art from your prompt',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            _Label('Podcast Name'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Enter podcast name...'),
              enabled: !_publishing,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 18),

            _Label('Category'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _publishing ? null : (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 18),

            _Label('AI Voice'),
            DropdownButtonFormField<String>(
              initialValue: _voice,
              items: _voices.map((v) => DropdownMenuItem(
                value: v,
                child: Text(v[0].toUpperCase() + v.substring(1)),
              )).toList(),
              onChanged: _publishing ? null : (v) => setState(() => _voice = v!),
            ),
            const SizedBox(height: 18),

            _Label('Prompt'),
            Text('What should the AI generate? Be specific about topic, tone, and style.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            TextFormField(
              controller: _promptCtrl,
              decoration: const InputDecoration(hintText: 'Generate a 5-minute podcast about...'),
              maxLines: 4,
              enabled: !_publishing,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 18),

            _Label('Description'),
            Text('Shown to listeners (NOT sent to AI).',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(hintText: 'This episode explores...'),
              maxLines: 3,
              enabled: !_publishing,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Chapters
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _Label('Chapters (optional)'),
              TextButton.icon(
                onPressed: _publishing ? null : () => setState(() => _chapters.add(_Chapter(
                  title: TextEditingController(), start: TextEditingController(),
                ))),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
              ),
            ]),
            if (_chapters.isNotEmpty)
              Text('Use MM:SS or HH:MM:SS for timestamps',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            ..._chapters.asMap().entries.map((e) {
              final i = e.key;
              final c = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(flex: 3, child: TextField(
                    controller: c.title,
                    decoration: const InputDecoration(hintText: 'Chapter title'),
                    enabled: !_publishing,
                  )),
                  const SizedBox(width: 8),
                  Expanded(flex: 1, child: TextField(
                    controller: c.start,
                    decoration: const InputDecoration(hintText: '0:00'),
                    enabled: !_publishing,
                  )),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: colors.outline),
                    onPressed: _publishing ? null : () => setState(() => _chapters.removeAt(i)),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _generating || _publishing ? null : _generate,
                child: _generating
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text('Generating...'),
                      ])
                    : const Text('Generate AI Content'),
              ),
            ),
            const SizedBox(height: 16),

            // Preview
            if (_imageUrl != null && _audioUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PREVIEW', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.4)),
                  const SizedBox(height: 10),
                  Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: _imageUrl!, width: 72, height: 72, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(width: 72, height: 72, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Audio preview', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          if (_preview?.playing == true) {
                            _preview?.pause();
                          } else {
                            _preview?.play();
                          }
                          setState(() {});
                        },
                        child: Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                            child: Icon(_preview?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text('Tap to play', style: Theme.of(context).textTheme.bodySmall),
                        ]),
                      ),
                    ])),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: _publishing ? null : _publish,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: colors.surface,
                    side: BorderSide(color: colors.outline),
                  ),
                  child: _publishing
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Publishing...'),
                        ])
                      : const Text('Publish Podcast'),
                ),
              ),
            ] else
              Center(
                child: Text('Generate AI content first to publish',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Chapter {
  final TextEditingController title;
  final TextEditingController start;
  _Chapter({required this.title, required this.start});
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
