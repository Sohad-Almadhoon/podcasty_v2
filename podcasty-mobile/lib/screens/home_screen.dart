import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/podcast.dart';
import '../models/category.dart';
import '../services/podcasts_service.dart';
import '../services/categories_service.dart';
import '../widgets/podcast_card.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Podcast> _trending = [];
  List<Podcast> _recent = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        PodcastsService.fetchTrendingPodcasts().catchError((_) => <Podcast>[]),
        PodcastsService.fetchPodcastsPublic(limit: 10).catchError((_) => <Podcast>[]),
        CategoriesService.fetchCategoriesPublic().catchError((_) => <Category>[]),
      ]);
      if (mounted) {
        setState(() {
          _trending = results[0] as List<Podcast>;
          _recent = results[1] as List<Podcast>;
          _categories = results[2] as List<Category>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Podcasty', style: GoogleFonts.plusJakartaSans(
              fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            )),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => Navigator.pushNamed(context, '/podcasts')),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(context),
                    const SizedBox(height: 32),
                    _buildSection(context, 'Trending Now', Icons.trending_up_rounded, _trending),
                    const SizedBox(height: 32),
                    _buildSection(context, 'Recently Added', Icons.schedule_rounded, _recent),
                    const SizedBox(height: 32),
                    _buildCategories(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withAlpha(180)],
        ),
        boxShadow: [
          BoxShadow(color: primary.withAlpha(40), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover\nAmazing Podcasts',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI-generated audio from creators worldwide',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/podcasts'),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Explore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/create-podcast'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withAlpha(120)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Podcast> podcasts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        const SizedBox(height: 14),
        if (podcasts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            width: double.infinity,
            child: Column(
              children: [
                Icon(Icons.podcasts_rounded, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text('No podcasts yet', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )
        else
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: podcasts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) => SizedBox(
                width: 280,
                child: PodcastCard(
                  podcast: podcasts[i],
                  onTap: () => Navigator.pushNamed(context, '/podcast-detail', arguments: podcasts[i].id),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context) {
    final catData = <String, _CatInfo>{
      'Technology': _CatInfo(Icons.computer_rounded, const Color(0xFF3B82F6)),
      'Science': _CatInfo(Icons.science_rounded, const Color(0xFF06B6D4)),
      'Business': _CatInfo(Icons.business_rounded, const Color(0xFF8B5CF6)),
      'Health': _CatInfo(Icons.favorite_rounded, const Color(0xFFEC4899)),
      'Comedy': _CatInfo(Icons.sentiment_very_satisfied_rounded, const Color(0xFFF97316)),
      'True Crime': _CatInfo(Icons.gavel_rounded, const Color(0xFF991B1B)),
      'History': _CatInfo(Icons.history_edu_rounded, const Color(0xFF92400E)),
      'Education': _CatInfo(Icons.school_rounded, const Color(0xFF16A34A)),
      'Sports': _CatInfo(Icons.sports_rounded, const Color(0xFF0D9488)),
      'Music': _CatInfo(Icons.music_note_rounded, const Color(0xFF4F46E5)),
      'News': _CatInfo(Icons.newspaper_rounded, const Color(0xFFDC2626)),
      'Politics': _CatInfo(Icons.how_to_vote_rounded, const Color(0xFF475569)),
      'Gaming': _CatInfo(Icons.sports_esports_rounded, const Color(0xFF7C3AED)),
      'Entertainment': _CatInfo(Icons.movie_rounded, const Color(0xFFD97706)),
      'Arts': _CatInfo(Icons.palette_rounded, const Color(0xFF65A30D)),
      'Fiction': _CatInfo(Icons.auto_stories_rounded, const Color(0xFFEA580C)),
      'Self-Improvement': _CatInfo(Icons.self_improvement_rounded, const Color(0xFF059669)),
      'Society & Culture': _CatInfo(Icons.groups_rounded, const Color(0xFF1E40AF)),
      'Food': _CatInfo(Icons.restaurant_rounded, const Color(0xFFC2410C)),
      'Travel': _CatInfo(Icons.flight_rounded, const Color(0xFF0284C7)),
    };

    final cats = _categories.isNotEmpty
        ? _categories
        : catData.keys.map((k) => Category(name: k)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_rounded, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text('Browse by Category', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.45,
          ),
          itemCount: cats.length,
          itemBuilder: (context, i) {
            final cat = cats[i];
            final info = catData[cat.name] ?? _CatInfo(Icons.category_rounded, Colors.grey);
            return _CategoryTile(category: cat, info: info);
          },
        ),
      ],
    );
  }
}

class _CatInfo {
  final IconData icon;
  final Color color;
  const _CatInfo(this.icon, this.color);
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final _CatInfo info;

  const _CategoryTile({required this.category, required this.info});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, '/podcasts', arguments: category.name),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [info.color, Color.lerp(info.color, Colors.black, 0.25)!],
            ),
            boxShadow: [
              BoxShadow(
                color: info.color.withAlpha(80),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -14,
                child: Icon(
                  info.icon,
                  size: 96,
                  color: Colors.white.withAlpha(38),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(56),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(info.icon, size: 20, color: Colors.white),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category.count > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${category.count} ${category.count == 1 ? "podcast" : "podcasts"}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
