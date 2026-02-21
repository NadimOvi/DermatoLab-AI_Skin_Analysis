// ============================================================================
// LEARN TAB — Skin Disease News with WebView Integration
// File: lib/screens/dashboard/learn_tab.dart
//
// Features:
//  • Curated real news articles per disease (opens in WebView in-app)
//  • "Quick Search" button → opens Google/PubMed search in WebView
//  • News source cards with publisher logo, read time estimate
//  • Featured article hero card
//  • Category filter chips
//  • Stats ribbon from InfoBloc data
//  • Skeleton loading, error state, empty state
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/info/info_bloc.dart';
import '../../models/disease_info.dart';
import 'webview_article_screen.dart';

// ── Shared dark palette ───────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const surfaceAlt = Color(0xFF22222F);
  static const primary = Color(0xFF6366F1);
  static const accent = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const textHi = Color(0xFFF1F1F5);
  static const textMid = Color(0xFF8E8EA8);
  static const textLo = Color(0xFF4A4A60);
  static const border = Color(0xFF252535);
}

// ─────────────────────────────────────────────────────────────────────────────
// NEWS ARTICLE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _NewsArticle {
  final String title;
  final String summary;
  final String url;
  final String source;
  final String readTime;
  final Color sourceColor;
  final IconData sourceIcon;
  final String? diseaseCode; // null = general

  const _NewsArticle({
    required this.title,
    required this.summary,
    required this.url,
    required this.source,
    required this.readTime,
    required this.sourceColor,
    required this.sourceIcon,
    this.diseaseCode,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CURATED NEWS — real, working URLs for skin disease articles
// ─────────────────────────────────────────────────────────────────────────────

final List<_NewsArticle> _allNews = [
  // ── General skin health ───────────────────────────────────────────────────
  _NewsArticle(
    title: 'Early Detection of Skin Cancer: What You Need to Know',
    summary:
        'Dermatologists explain the ABCDE rule and why monthly self-exams can be life-saving.',
    url: 'https://www.aad.org/public/diseases/skin-cancer/find/early',
    source: 'AAD',
    readTime: '4 min',
    sourceColor: _C.primary,
    sourceIcon: Icons.local_hospital_rounded,
  ),
  _NewsArticle(
    title: 'AI in Dermatology: How Machine Learning is Changing Skin Care',
    summary:
        'New deep learning models can detect melanoma with accuracy matching board-certified dermatologists.',
    url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7577280/',
    source: 'PubMed',
    readTime: '7 min',
    sourceColor: _C.green,
    sourceIcon: Icons.science_rounded,
  ),
  _NewsArticle(
    title: 'Sun Protection Guide: SPF, UVA, UVB Explained',
    summary:
        'Everything you need to know about choosing the right sunscreen and protecting your skin year-round.',
    url:
        'https://www.aad.org/public/everyday-care/sun-protection/sunscreen-patients/sunscreen-faqs',
    source: 'AAD',
    readTime: '5 min',
    sourceColor: _C.primary,
    sourceIcon: Icons.local_hospital_rounded,
  ),
  _NewsArticle(
    title: 'Skin Microbiome: The Hidden Ecosystem on Your Skin',
    summary:
        'Scientists are uncovering how the trillions of microbes living on skin affect health and disease.',
    url: 'https://www.medicalnewstoday.com/articles/skin-microbiome',
    source: 'MedNewsToday',
    readTime: '6 min',
    sourceColor: _C.pink,
    sourceIcon: Icons.article_rounded,
  ),

  // ── Melanoma ──────────────────────────────────────────────────────────────
  _NewsArticle(
    title: 'Melanoma: Symptoms, Diagnosis & Treatment Options',
    summary:
        'A comprehensive guide to the most dangerous form of skin cancer — from risk factors to immunotherapy.',
    url:
        'https://www.cancer.org/cancer/types/melanoma-skin-cancer/about/what-is-melanoma.html',
    source: 'Cancer.org',
    readTime: '8 min',
    sourceColor: _C.red,
    sourceIcon: Icons.health_and_safety_rounded,
    diseaseCode: 'mel',
  ),
  _NewsArticle(
    title: 'Immunotherapy Breakthroughs in Advanced Melanoma Treatment',
    summary:
        'Checkpoint inhibitors and CAR-T cell therapies are transforming outcomes for metastatic melanoma patients.',
    url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8617671/',
    source: 'PubMed',
    readTime: '10 min',
    sourceColor: _C.green,
    sourceIcon: Icons.science_rounded,
    diseaseCode: 'mel',
  ),

  // ── Actinic Keratoses ─────────────────────────────────────────────────────
  _NewsArticle(
    title: 'Actinic Keratoses: Precancerous Patches You Should Not Ignore',
    summary:
        'These sun-damaged skin patches are among the most common precancerous conditions in adults over 40.',
    url: 'https://www.aad.org/public/diseases/a-z/actinic-keratosis-overview',
    source: 'AAD',
    readTime: '5 min',
    sourceColor: _C.primary,
    sourceIcon: Icons.local_hospital_rounded,
    diseaseCode: 'akiec',
  ),
  _NewsArticle(
    title:
        'Treating Actinic Keratoses: From Cryotherapy to Photodynamic Therapy',
    summary:
        'Dermatologists compare the effectiveness of different treatment approaches for AK lesions.',
    url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6122220/',
    source: 'PubMed',
    readTime: '9 min',
    sourceColor: _C.green,
    sourceIcon: Icons.science_rounded,
    diseaseCode: 'akiec',
  ),

  // ── Basal Cell Carcinoma ──────────────────────────────────────────────────
  _NewsArticle(
    title: 'Basal Cell Carcinoma: The Most Common Skin Cancer Explained',
    summary:
        'BCC rarely spreads but can cause significant local damage. Learn recognition and treatment options.',
    url: 'https://www.aad.org/public/diseases/skin-cancer/types/common/bcc',
    source: 'AAD',
    readTime: '6 min',
    sourceColor: _C.primary,
    sourceIcon: Icons.local_hospital_rounded,
    diseaseCode: 'bcc',
  ),

  // ── Eczema / Dermatitis ───────────────────────────────────────────────────
  _NewsArticle(
    title: 'Living with Eczema: New Biologic Treatments Offer Hope',
    summary:
        'Dupilumab and other biologics are changing the treatment landscape for moderate-to-severe atopic dermatitis.',
    url: 'https://nationaleczema.org/eczema/treatment/biologics/',
    source: 'NEA',
    readTime: '5 min',
    sourceColor: _C.amber,
    sourceIcon: Icons.healing_rounded,
    diseaseCode: 'bkl',
  ),

  // ── Vascular Lesions ─────────────────────────────────────────────────────
  _NewsArticle(
    title: 'Vascular Birthmarks and Lesions: Types and Treatment Options',
    summary:
        'Understanding hemangiomas, port wine stains, and spider veins — and when to seek treatment.',
    url: 'https://www.aad.org/public/diseases/a-z/birthmarks-overview',
    source: 'AAD',
    readTime: '4 min',
    sourceColor: _C.primary,
    sourceIcon: Icons.local_hospital_rounded,
    diseaseCode: 'vasc',
  ),

  // ── Dermatofibroma ────────────────────────────────────────────────────────
  _NewsArticle(
    title: 'Dermatofibroma: What Are These Common Skin Bumps?',
    summary:
        'These benign fibrous growths are usually harmless — here\'s how to tell them apart from worrisome lesions.',
    url: 'https://www.aad.org/public/diseases/bumps-and-growths/dermatofibroma',
    source: 'AAD',
    readTime: '3 min',
    sourceColor: _C.primary,
    sourceIcon: Icons.local_hospital_rounded,
    diseaseCode: 'df',
  ),
];

// Build a search URL for a given disease name
String _buildSearchUrl(String diseaseName) {
  final query = Uri.encodeComponent('$diseaseName skin disease treatment 2024');
  return 'https://www.google.com/search?q=$query&tbm=nws';
}

// Build a PubMed search URL
String _buildPubMedUrl(String diseaseName) {
  final query = Uri.encodeComponent(diseaseName);
  return 'https://pubmed.ncbi.nlm.nih.gov/?term=$query&filter=dates.2023%2F1%2F1-3000&sort=date';
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Color _severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'high':
    case 'severe':
    case 'critical':
      return _C.red;
    case 'moderate':
    case 'medium':
      return _C.amber;
    default:
      return _C.green;
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  return 'Just now';
}

void _openWebView(
  BuildContext ctx,
  String url,
  String title, {
  String? source,
}) {
  Navigator.push(
    ctx,
    PageRouteBuilder(
      pageBuilder: (_, a, __) =>
          WebViewArticleScreen(url: url, title: title, sourceName: source),
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN LEARN TAB
// ─────────────────────────────────────────────────────────────────────────────

class LearnTab extends StatefulWidget {
  const LearnTab({Key? key}) : super(key: key);

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  String _selectedCategory = 'All';

  static const _categories = [
    'All',
    'Latest',
    'Research',
    'Treatment',
    'Prevention',
  ];

  // Map category → filter tag in URL/source
  bool _matchCategory(_NewsArticle a) {
    switch (_selectedCategory) {
      case 'All':
        return true;
      case 'Latest':
        return true; // show all sorted by recency
      case 'Research':
        return a.source == 'PubMed';
      case 'Treatment':
        return a.title.toLowerCase().contains('treat') ||
            a.title.toLowerCase().contains('therapy') ||
            a.title.toLowerCase().contains('cure');
      case 'Prevention':
        return a.title.toLowerCase().contains('protect') ||
            a.title.toLowerCase().contains('prevent') ||
            a.title.toLowerCase().contains('sunscreen') ||
            a.title.toLowerCase().contains('detection') ||
            a.title.toLowerCase().contains('early');
      default:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    final state = context.read<InfoBloc>().state;
    if (state is InfoInitial) {
      context.read<InfoBloc>().add(LoadDiseaseInfo());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.bg,
      child: BlocBuilder<InfoBloc, InfoState>(
        builder: (context, state) {
          List<DiseaseInfo> diseases = [];
          bool loading = true;
          String? error;

          if (state is InfoLoaded) {
            diseases = state.diseases;
            loading = false;
          } else if (state is InfoError) {
            error = state.error;
            loading = false;
          } else {
            loading = true;
          }

          final filteredNews = _allNews.where(_matchCategory).toList();
          final top = MediaQuery.of(context).padding.top;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ─────────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader(top, diseases)),

              // ── Category chips ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildCategoryRow()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Stats ribbon (from InfoBloc) ────────────────────────────────
              if (!loading && error == null && diseases.isNotEmpty) ...[
                SliverToBoxAdapter(child: _StatsRibbon(diseases: diseases)),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // ── Quick search by disease ────────────────────────────────────
              if (!loading && error == null && diseases.isNotEmpty) ...[
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _SectionLabel('Search by Disease'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 110,
                    child: _DiseaseSearchRow(diseases: diseases),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // ── Featured article ───────────────────────────────────────────
              if (filteredNews.isNotEmpty) ...[
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _SectionLabel('Featured Article'),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _FeaturedArticleCard(article: filteredNews.first),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // ── News list ──────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('Latest News'),
                      Text(
                        '${filteredNews.length} articles',
                        style: const TextStyle(color: _C.textMid, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              if (loading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const _SkeletonNewsCard(),
                      childCount: 4,
                    ),
                  ),
                )
              else if (filteredNews.isEmpty)
                const SliverToBoxAdapter(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _NewsCard(article: filteredNews[i], index: i),
                      childCount: filteredNews.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(double top, List<DiseaseInfo> diseases) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1040), _C.bg],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skin Health Knowledge',
                  style: const TextStyle(
                    color: _C.textMid,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'News & Research',
                  style: TextStyle(
                    color: _C.textHi,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Search all articles in WebView (Google News)
          GestureDetector(
            onTap: () => _openWebView(
              context,
              'https://news.google.com/search?q=skin+disease+dermatology&hl=en',
              'Skin Disease News',
              source: 'Google News',
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.primary, _C.accent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh
          GestureDetector(
            onTap: () => context.read<InfoBloc>().add(RefreshDiseaseInfo()),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _C.textMid,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category chips ───────────────────────────────────────────────────────────
  Widget _buildCategoryRow() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final active = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(colors: [_C.primary, _C.accent])
                    : null,
                color: active ? null : _C.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? Colors.transparent : _C.border,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: active ? Colors.white : _C.textMid,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISEASE SEARCH ROW — horizontal chips, each opens WebView search
// ─────────────────────────────────────────────────────────────────────────────

class _DiseaseSearchRow extends StatelessWidget {
  final List<DiseaseInfo> diseases;
  const _DiseaseSearchRow({required this.diseases});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: diseases.length,
      itemBuilder: (_, i) {
        final d = diseases[i];
        final color = _severityColor(d.severity);
        return GestureDetector(
          onTap: () => _openWebView(
            context,
            _buildSearchUrl(d.name),
            '${d.name} — News',
            source: 'Google News',
          ),
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search_rounded, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    d.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _C.textHi,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURED ARTICLE CARD — large hero opens WebView
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedArticleCard extends StatelessWidget {
  final _NewsArticle article;
  const _FeaturedArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openWebView(
        context,
        article.url,
        article.title,
        source: article.source,
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [article.sourceColor.withOpacity(0.15), _C.surface],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: article.sourceColor.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative icon watermark
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  article.sourceIcon,
                  size: 140,
                  color: article.sourceColor.withOpacity(0.05),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source + read time badges
                    Row(
                      children: [
                        _SourceBadge(
                          label: article.source,
                          color: article.sourceColor,
                          icon: article.sourceIcon,
                        ),
                        const SizedBox(width: 8),
                        _SourceBadge(
                          label: '${article.readTime} read',
                          color: _C.textLo,
                          icon: Icons.schedule_rounded,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: article.sourceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: article.sourceColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        color: _C.textHi,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Summary
                    Text(
                      article.summary,
                      style: const TextStyle(
                        color: _C.textMid,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // CTA
                    Row(
                      children: [
                        Text(
                          'Tap to read in-app',
                          style: TextStyle(
                            color: article.sourceColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: article.sourceColor,
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// NEWS CARD — each article in the list
// ─────────────────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final _NewsArticle article;
  final int index;
  const _NewsCard({required this.article, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openWebView(
        context,
        article.url,
        article.title,
        source: article.source,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: index == 0 ? _C.primary.withOpacity(0.3) : _C.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source icon block
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: article.sourceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: article.sourceColor.withOpacity(0.2)),
              ),
              child: Center(
                child: Icon(
                  article.sourceIcon,
                  color: article.sourceColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + read time
                  Row(
                    children: [
                      _SourceBadge(
                        label: article.source,
                        color: article.sourceColor,
                        icon: article.sourceIcon,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        article.readTime,
                        style: const TextStyle(color: _C.textLo, fontSize: 10),
                      ),
                      const Spacer(),
                      // WebView indicator
                      Row(
                        children: const [
                          Icon(Icons.web_rounded, size: 11, color: _C.textLo),
                          SizedBox(width: 3),
                          Text(
                            'In-app',
                            style: TextStyle(color: _C.textLo, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: _C.textHi,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Summary
                  Text(
                    article.summary,
                    style: const TextStyle(
                      color: _C.textMid,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS RIBBON (uses InfoBloc disease data)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRibbon extends StatelessWidget {
  final List<DiseaseInfo> diseases;
  const _StatsRibbon({required this.diseases});

  @override
  Widget build(BuildContext context) {
    final severe = diseases
        .where(
          (d) =>
              d.severity.toLowerCase().contains('high') ||
              d.severity.toLowerCase().contains('severe'),
        )
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          _RibbonStat(
            value: diseases.length.toString(),
            label: 'Diseases',
            color: _C.primary,
            icon: Icons.biotech_rounded,
          ),
          _VDivider(),
          _RibbonStat(
            value: _allNews.length.toString(),
            label: 'Articles',
            color: _C.accent,
            icon: Icons.article_rounded,
          ),
          _VDivider(),
          _RibbonStat(
            value: severe.toString(),
            label: 'High Risk',
            color: _C.red,
            icon: Icons.warning_rounded,
          ),
        ],
      ),
    );
  }
}

class _RibbonStat extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  const _RibbonStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _C.textMid, fontSize: 11)),
      ],
    ),
  );
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 40,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: _C.border,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _SourceBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _C.textHi,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: const [
          Icon(Icons.article_outlined, color: _C.textLo, size: 48),
          SizedBox(height: 12),
          Text(
            'No articles in this category',
            style: TextStyle(color: _C.textMid, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON LOADING
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonNewsCard extends StatefulWidget {
  const _SkeletonNewsCard();
  @override
  State<_SkeletonNewsCard> createState() => _SkeletonNewsCardState();
}

class _SkeletonNewsCardState extends State<_SkeletonNewsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double r = 8}) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _C.surfaceAlt.withOpacity(_anim.value),
        borderRadius: BorderRadius.circular(r),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.border),
    ),
    child: Row(
      children: [
        _box(52, 52, r: 14),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(80, 14),
              const SizedBox(height: 8),
              _box(double.infinity, 14),
              const SizedBox(height: 6),
              _box(200, 12),
              const SizedBox(height: 6),
              _box(160, 12),
            ],
          ),
        ),
      ],
    ),
  );
}
