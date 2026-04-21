import 'package:flutter/material.dart';
import '../models/podcast.dart';
import '../services/podcasts_service.dart';
import '../services/categories_service.dart';
import '../widgets/podcast_card.dart';
import '../widgets/app_drawer.dart';

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({Key? key}) : super(key: key);

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  List<Podcast> _podcasts = [];
  List<String> _categories = ['All'];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        setState(() => _selectedCategory = args);
      }
      _load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoriesService.fetchCategoriesPublic();
      if (mounted) setState(() => _categories = ['All', ...cats.map((c) => c.name)]);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await PodcastsService.fetchPodcastsPublic(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory != 'All' ? _selectedCategory : null,
      );
      if (mounted) setState(() { _podcasts = results; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-podcast'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: Column(children: [
        // ── Search ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search podcasts...',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: colors.outline),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _load(); },
                      child: Icon(Icons.close_rounded, size: 20, color: colors.outline),
                    )
                  : null,
            ),
            onSubmitted: (v) { setState(() => _searchQuery = v); _load(); },
          ),
        ),

        // ── Category chips ──
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () { setState(() => _selectedCategory = cat); _load(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? Theme.of(context).primaryColor : Colors.transparent,
                    border: Border.all(color: selected ? Theme.of(context).primaryColor : colors.outline),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : colors.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ── List ──
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _podcasts.isEmpty
                  ? _EmptyState(
                      icon: Icons.podcasts_rounded,
                      title: 'No podcasts found',
                      subtitle: 'Try a different search or category',
                      actionLabel: 'Create podcast',
                      onAction: () => Navigator.pushNamed(context, '/create-podcast'),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: _podcasts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) => PodcastCard(
                          podcast: _podcasts[i],
                          onTap: () => Navigator.pushNamed(context, '/podcast-detail', arguments: _podcasts[i].id),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon, required this.title, required this.subtitle,
    this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}
