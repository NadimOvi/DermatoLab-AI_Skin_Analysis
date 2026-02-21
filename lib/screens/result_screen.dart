// ============================================================================
// RESULT SCREEN — Dark indigo theme with redesigned AI + Doctors sections
// File: lib/screens/result_screen.dart
//
// Add to pubspec.yaml:
//   google_maps_flutter: ^2.5.0
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/detection_result.dart';
import '../blocs/detection/detection_bloc.dart';
import '../blocs/history/history_bloc.dart';
import '../utils/constants.dart';
import 'doctor_list_screen.dart';

class _C {
  static const bg = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const surfaceAlt = Color(0xFF22222F);
  static const primary = Color(0xFF6366F1);
  static const accent = Color(0xFF8B5CF6);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const cyan = Color(0xFF06B6D4);
  static const textHi = Color(0xFFF1F1F5);
  static const textMid = Color(0xFF8E8EA8);
  static const textLo = Color(0xFF4A4A60);
  static const border = Color(0xFF252535);
}

class ResultScreen extends StatefulWidget {
  final DetectionResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _barAnimation = Tween<double>(begin: 0, end: widget.result.confidence)
        .animate(
          CurvedAnimation(parent: _barController, curve: Curves.easeOutCubic),
        );
    _barController.forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  Color get _confidenceColor {
    final c = widget.result.confidence;
    if (c >= 0.8) return _C.green;
    if (c >= 0.6) return _C.amber;
    return _C.red;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildResultCard(),
                  const SizedBox(height: 20),
                  _buildAISection(),
                  const SizedBox(height: 16),
                  _buildFindDoctorsCard(),
                  const SizedBox(height: 28),
                  if (widget.result.allPredictions != null) ...[
                    _buildAllPredictions(),
                    const SizedBox(height: 20),
                  ],
                  _buildDisclaimer(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: _C.textHi,
            size: 18,
          ),
        ),
      ),
      title: const Text(
        'Results',
        style: TextStyle(
          color: _C.textHi,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _isSaved ? null : _saveToHistory,
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _isSaved ? _C.green.withOpacity(0.1) : _C.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isSaved ? _C.green.withOpacity(0.4) : _C.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: _isSaved ? _C.green : _C.textMid,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  _isSaved ? 'Saved' : 'Save',
                  style: TextStyle(
                    color: _isSaved ? _C.green : _C.textMid,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final diseaseColor =
        DiseaseLabels.colors[widget.result.diseaseCode] ?? _C.primary;
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(widget.result.imagePath), fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, _C.bg.withOpacity(0.6), _C.bg],
                stops: const [0.4, 0.8, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: diseaseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: diseaseColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    DiseaseLabels.icons[widget.result.diseaseCode] ??
                        Icons.healing_rounded,
                    color: diseaseColor,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.result.diseaseName,
                    style: TextStyle(
                      color: diseaseColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final diseaseColor =
        DiseaseLabels.colors[widget.result.diseaseCode] ?? _C.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: diseaseColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: diseaseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: diseaseColor.withOpacity(0.25)),
                ),
                child: Icon(
                  DiseaseLabels.icons[widget.result.diseaseCode] ??
                      Icons.healing_rounded,
                  color: diseaseColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Condition',
                      style: TextStyle(color: _C.textMid, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.result.diseaseName,
                      style: const TextStyle(
                        color: _C.textHi,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _confidenceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _confidenceColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${(widget.result.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _confidenceColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Confidence',
                    style: TextStyle(color: _C.textMid, fontSize: 13),
                  ),
                  AnimatedBuilder(
                    animation: _barAnimation,
                    builder: (_, __) => Text(
                      '${(_barAnimation.value * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _confidenceColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AnimatedBuilder(
                  animation: _barAnimation,
                  builder: (_, __) => LinearProgressIndicator(
                    value: _barAnimation.value,
                    minHeight: 8,
                    backgroundColor: _C.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(_confidenceColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
            ),
            child: Text(
              DiseaseLabels.descriptions[widget.result.diseaseCode] ??
                  'No description available.',
              style: const TextStyle(
                color: _C.textMid,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISection() {
    return BlocBuilder<DetectionBloc, DetectionState>(
      builder: (context, state) {
        if (state is AIRecommendationsLoading) return const _AILoadingCard();
        if (widget.result.aiRecommendations != null) {
          return _AIRecommendationsCard(text: widget.result.aiRecommendations!);
        }
        return _AICallToActionCard(
          onTap: () => context.read<DetectionBloc>().add(
            GetAIRecommendationsEvent(widget.result),
          ),
        );
      },
    );
  }

  Widget _buildFindDoctorsCard() {
    return _FindDoctorsMapCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorListScreen(detectionResult: widget.result),
        ),
      ),
    );
  }

  Widget _buildAllPredictions() {
    final predictions = widget.result.allPredictions!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: _C.accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'All Predictions',
                style: TextStyle(
                  color: _C.textHi,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...predictions.map((entry) {
            final name = DiseaseLabels.labels[entry.key] ?? entry.key;
            final conf = entry.value;
            final barColor = DiseaseLabels.colors[entry.key] ?? _C.primary;
            final isTop = entry.key == widget.result.diseaseCode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: isTop ? _C.textHi : _C.textMid,
                              fontSize: 13,
                              fontWeight: isTop
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          if (isTop) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: barColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'TOP',
                                style: TextStyle(
                                  color: barColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${(conf * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isTop ? barColor : _C.textLo,
                          fontSize: 12,
                          fontWeight: isTop ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: conf,
                      minHeight: isTop ? 7 : 5,
                      backgroundColor: _C.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation(
                        isTop ? barColor : _C.textLo.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.amber.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.amber.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning_amber_rounded, color: _C.amber, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This result is for educational purposes only. Please consult a dermatologist for professional diagnosis and treatment.',
              style: TextStyle(color: _C.textMid, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  void _saveToHistory() {
    context.read<HistoryBloc>().add(AddToHistoryEvent(widget.result));
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saved to history'),
        backgroundColor: _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AI CTA card
// ══════════════════════════════════════════════════════════════════════════════
class _AICallToActionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AICallToActionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get AI Recommendations',
                    style: TextStyle(
                      color: _C.textHi,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Personalised care tips for your condition',
                    style: TextStyle(color: _C.textMid, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: _C.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AI Loading card — shimmer skeleton
// ══════════════════════════════════════════════════════════════════════════════
class _AILoadingCard extends StatefulWidget {
  const _AILoadingCard();

  @override
  State<_AILoadingCard> createState() => _AILoadingCardState();
}

class _AILoadingCardState extends State<_AILoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _C.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _C.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Generating recommendations...',
                style: TextStyle(
                  color: _C.textHi,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _C.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...[1.0, 0.75, 0.88, 0.6].map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (_, __) => FractionallySizedBox(
                  widthFactor: w,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 11,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment(
                          -1.5 + _shimmerController.value * 3,
                          0,
                        ),
                        end: Alignment(-0.5 + _shimmerController.value * 3, 0),
                        colors: const [
                          Color(0xFF22222F),
                          Color(0xFF30304A),
                          Color(0xFF22222F),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AI Recommendations — natural flowing prose with icon-tagged sections
// ══════════════════════════════════════════════════════════════════════════════
class _AIRecommendationsCard extends StatelessWidget {
  final String text;
  const _AIRecommendationsCard({required this.text});

  static const _sectionIcons = [
    Icons.healing_rounded,
    Icons.medication_rounded,
    Icons.wb_sunny_rounded,
    Icons.no_food_rounded,
    Icons.schedule_rounded,
    Icons.local_hospital_rounded,
  ];

  /// Merges bullet/numbered lines into clean prose sections.
  /// If a line ends with ':' and is short → treat as a section heading.
  /// All other lines are merged into a single paragraph per section.
  List<_Section> _parse(String raw) {
    final sections = <_Section>[];
    String? title;
    final body = StringBuffer();

    void flush() {
      if (body.isNotEmpty) {
        sections.add(_Section(title: title, body: body.toString().trim()));
        body.clear();
        title = null;
      }
    }

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Detect heading: short, ends with ':'
      if (line.endsWith(':') && line.length < 70) {
        flush();
        title = line.replaceAll(':', '').trim();
        continue;
      }

      // Strip list prefixes (1. / - / • / *) and append to prose buffer
      final clean = line.replaceAll(RegExp(r'^[\d\.\-\*•►▸]+\s*'), '').trim();
      if (clean.isNotEmpty) {
        if (body.isNotEmpty) body.write(' ');
        body.write(clean);
      }
    }
    flush();

    if (sections.isEmpty) sections.add(_Section(title: null, body: raw.trim()));
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parse(text);

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Recommendations',
                    style: TextStyle(
                      color: _C.textHi,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.primary.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      color: _C.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: _C.border),
          const SizedBox(height: 16),

          // ── Sections — icon + title + prose ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections.asMap().entries.map((e) {
                final i = e.key;
                final sec = e.value;
                final isLast = i == sections.length - 1;
                final icon = _sectionIcons[i % _sectionIcons.length];

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + vertical line
                      Column(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _C.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _C.border),
                            ),
                            child: Icon(icon, color: _C.primary, size: 15),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: _C.border,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      // Text block
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sec.title != null) ...[
                                Text(
                                  sec.title!,
                                  style: const TextStyle(
                                    color: _C.textHi,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                sec.body,
                                style: const TextStyle(
                                  color: _C.textMid,
                                  fontSize: 13,
                                  height: 1.65,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // ── Footer disclaimer ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _C.amber.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.amber.withOpacity(0.15)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, color: _C.amber, size: 13),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'For reference only — consult a doctor for treatment.',
                    style: TextStyle(
                      color: _C.amber,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String? title;
  final String body;
  const _Section({required this.title, required this.body});
}

// ══════════════════════════════════════════════════════════════════════════════
// Find Doctors — real Google Map on right, info panel on left
// ══════════════════════════════════════════════════════════════════════════════
class _FindDoctorsMapCard extends StatefulWidget {
  final VoidCallback onTap;
  const _FindDoctorsMapCard({required this.onTap});

  @override
  State<_FindDoctorsMapCard> createState() => _FindDoctorsMapCardState();
}

class _FindDoctorsMapCardState extends State<_FindDoctorsMapCard>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _center = LatLng(23.8103, 90.4125);

  final _markers = <Marker>{
    const Marker(
      markerId: MarkerId('you'),
      position: _center,
      infoWindow: InfoWindow(title: 'You are here'),
    ),
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              // ── Left: info panel ─────────────────────────────────────────────
              Expanded(
                flex: 52,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon + title
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, child) => Transform.scale(
                              scale: _pulseAnim.value,
                              child: child,
                            ),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF06B6D4),
                                    Color(0xFF0E7490),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Find Doctors',
                            style: TextStyle(
                              color: _C.textHi,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      // Subtitle
                      const Text(
                        'Nearby dermatologists\n& skin specialists',
                        style: TextStyle(
                          color: _C.textMid,
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                      ),

                      // CTA pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _C.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _C.cyan.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Open map',
                              style: TextStyle(
                                color: _C.cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _C.cyan,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Right: Google Map ─────────────────────────────────────────────
              Expanded(
                flex: 48,
                child: Stack(
                  children: [
                    // The real map — LayoutBuilder gives AndroidView a concrete
                    // size before rendering, preventing the setSize crash on Android.
                    LayoutBuilder(
                      builder: (context, constraints) => GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: _center,
                          zoom: 13.5,
                        ),
                        markers: _markers,
                        onMapCreated: (ctrl) {
                          _mapController = ctrl;
                          ctrl.setMapStyle(_kDarkMapStyle);
                        },
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: false,
                        scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                        liteModeEnabled: true,
                      ),
                    ),

                    // Left fade so map blends cleanly into panel
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 32,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_C.surface, _C.surface.withOpacity(0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),

                    // Intercept taps so the card action fires (not the map)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: widget.onTap,
                        behavior: HitTestBehavior.translucent,
                        child: const SizedBox.expand(),
                      ),
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

// ── Dark Google Map style ─────────────────────────────────────────────────────
const _kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0f0f14"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4A4A60"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0f0f14"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1c1c2a"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#252535"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#22222F"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#333350"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#080810"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#2a2a45"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#252535"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#12121a"}]}
]
''';
