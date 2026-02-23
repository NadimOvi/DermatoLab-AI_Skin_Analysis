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
import 'body_part_screen.dart'; // ← import BodyPart enum

class _C {
  static const bg = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const surfaceAlt = Color(0xFF22222F);
  static const primary = Color(0xFF6366F1);
  static const accent = Color(0xFF8B5CF6);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF97316);
  static const cyan = Color(0xFF06B6D4);
  static const textHi = Color(0xFFF1F1F5);
  static const textMid = Color(0xFF8E8EA8);
  static const textLo = Color(0xFF4A4A60);
  static const border = Color(0xFF252535);
}

enum RiskLevel { low, moderate, high, veryHigh }

extension RiskLevelInfo on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.veryHigh:
        return 'Very High Risk';
    }
  }

  String get emoji {
    switch (this) {
      case RiskLevel.low:
        return '🟢';
      case RiskLevel.moderate:
        return '🟡';
      case RiskLevel.high:
        return '🟠';
      case RiskLevel.veryHigh:
        return '🔴';
    }
  }

  String get description {
    switch (this) {
      case RiskLevel.low:
        return 'This condition is typically benign. Monitor for changes and maintain good skincare habits.';
      case RiskLevel.moderate:
        return 'This condition warrants attention. Schedule a dermatologist visit within the next few weeks.';
      case RiskLevel.high:
        return 'This condition requires professional evaluation. Book a dermatologist appointment soon.';
      case RiskLevel.veryHigh:
        return 'This condition needs urgent medical attention. Please see a dermatologist as soon as possible.';
    }
  }

  String get actionLabel {
    switch (this) {
      case RiskLevel.low:
        return 'Monitor & Self-care';
      case RiskLevel.moderate:
        return 'Book Appointment';
      case RiskLevel.high:
        return 'See Doctor Soon';
      case RiskLevel.veryHigh:
        return 'Urgent Consultation';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return const Color(0xFF10B981);
      case RiskLevel.moderate:
        return const Color(0xFFF59E0B);
      case RiskLevel.high:
        return const Color(0xFFF97316);
      case RiskLevel.veryHigh:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.low:
        return Icons.check_circle_rounded;
      case RiskLevel.moderate:
        return Icons.info_rounded;
      case RiskLevel.high:
        return Icons.warning_rounded;
      case RiskLevel.veryHigh:
        return Icons.dangerous_rounded;
    }
  }

  double get gaugeValue {
    switch (this) {
      case RiskLevel.low:
        return 0.18;
      case RiskLevel.moderate:
        return 0.45;
      case RiskLevel.high:
        return 0.72;
      case RiskLevel.veryHigh:
        return 0.96;
    }
  }
}

class _RiskMapper {
  static RiskLevel compute(String diseaseCode, double confidence) {
    final baseRisk = _baseRisk(diseaseCode);

    if (confidence < 0.5) {
      if (baseRisk.index > RiskLevel.moderate.index) return RiskLevel.moderate;
      return baseRisk;
    }
    if (confidence >= 0.85) {
      if (baseRisk == RiskLevel.moderate) return RiskLevel.high;
      if (baseRisk == RiskLevel.high) return RiskLevel.veryHigh;
    }
    return baseRisk;
  }

  static RiskLevel _baseRisk(String code) {
    const lowRisk = {
      'df', // Dermatofibroma
      'nv', // Melanocytic nevi (common moles)
      'vasc', // Vascular lesions — most benign
    };
    const moderateRisk = {
      'bkl', // Benign keratosis
      'seb', // Seborrheic keratosis
      'ak', // Actinic keratosis — pre-cancerous
    };
    const highRisk = {
      'bcc', // Basal cell carcinoma
      'scc', // Squamous cell carcinoma
    };
    const veryHighRisk = {
      'mel', // Melanoma
    };

    if (veryHighRisk.contains(code)) return RiskLevel.veryHigh;
    if (highRisk.contains(code)) return RiskLevel.high;
    if (moderateRisk.contains(code)) return RiskLevel.moderate;
    if (lowRisk.contains(code)) return RiskLevel.low;

    return RiskLevel.moderate;
  }
}

class ResultScreen extends StatefulWidget {
  final DetectionResult result;

  final BodyPart? bodyPart;

  const ResultScreen({super.key, required this.result, this.bodyPart});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  late AnimationController _barController;
  late Animation<double> _barAnimation;
  late RiskLevel _riskLevel;

  @override
  void initState() {
    super.initState();
    _riskLevel = _RiskMapper.compute(
      widget.result.diseaseCode,
      widget.result.confidence,
    );

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
                  if (widget.bodyPart != null) ...[
                    _buildBodyPartBadge(),
                    const SizedBox(height: 12),
                  ],

                  _buildResultCard(),
                  const SizedBox(height: 16),

                  _RiskLevelCard(
                    riskLevel: _riskLevel,
                    confidence: widget.result.confidence,
                  ),
                  const SizedBox(height: 16),

                  _buildActionRow(),
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

  Widget _buildBodyPartBadge() {
    final bp = widget.bodyPart!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.cyan.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.cyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pin_drop_rounded, color: _C.cyan, size: 15),
          const SizedBox(width: 8),
          Text(
            'Scanned area: ',
            style: const TextStyle(color: _C.textMid, fontSize: 12),
          ),
          Text(
            bp.label,
            style: const TextStyle(
              color: _C.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
          // Disease label
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

          Positioned(
            top: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _riskLevel.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _riskLevel.color.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_riskLevel.icon, color: _riskLevel.color, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    _riskLevel.label,
                    style: TextStyle(
                      color: _riskLevel.color,
                      fontSize: 11,
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

  Widget _buildActionRow() {
    return BlocBuilder<DetectionBloc, DetectionState>(
      builder: (context, state) {
        final hasRecs = widget.result.aiRecommendations != null;
        final isLoading = state is AIRecommendationsLoading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  if (!hasRecs) {
                    context.read<DetectionBloc>().add(
                      GetAIRecommendationsEvent(widget.result),
                    );
                  }
                  _showAISheet(context);
                },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 10),
                Text(
                  isLoading
                      ? 'Analyzing...'
                      : hasRecs
                      ? 'View AI Analysis'
                      : 'Get AI Analysis',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAISheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<DetectionBloc>(),
        child: _AIBottomSheet(result: widget.result),
      ),
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
// RISK LEVEL CARD
// ══════════════════════════════════════════════════════════════════════════════
class _RiskLevelCard extends StatefulWidget {
  final RiskLevel riskLevel;
  final double confidence;
  const _RiskLevelCard({required this.riskLevel, required this.confidence});

  @override
  State<_RiskLevelCard> createState() => _RiskLevelCardState();
}

class _RiskLevelCardState extends State<_RiskLevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _gaugeAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _gaugeAnim = Tween<double>(begin: 0, end: widget.riskLevel.gaugeValue)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rl = widget.riskLevel;
    final color = rl.color;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Icon(rl.icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Severity Level',
                        style: TextStyle(color: _C.textMid, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rl.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Severity tier dots
                _SeverityDots(riskLevel: rl),
              ],
            ),

            const SizedBox(height: 20),

            // ── Gauge bar ────────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Gauge',
                  style: TextStyle(color: _C.textMid, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    // Background track with gradient zones
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF10B981), // green
                            Color(0xFFF59E0B), // amber
                            Color(0xFFF97316), // orange
                            Color(0xFFEF4444), // red
                          ],
                        ),
                      ),
                    ),
                    // Dark overlay (covers right portion)
                    AnimatedBuilder(
                      animation: _gaugeAnim,
                      builder: (_, __) => FractionallySizedBox(
                        alignment: Alignment.centerRight,
                        widthFactor: 1 - _gaugeAnim.value,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A24).withOpacity(0.82),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(7),
                              bottomRight: Radius.circular(7),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Needle / thumb
                    AnimatedBuilder(
                      animation: _gaugeAnim,
                      builder: (_, __) => Positioned(
                        left: null,
                        top: 0,
                        bottom: 0,
                        child: FractionallySizedBox(
                          widthFactor: _gaugeAnim.value,
                          alignment: Alignment.centerLeft,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Zone labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Low',
                      style: TextStyle(color: _C.textLo, fontSize: 10),
                    ),
                    Text(
                      'Moderate',
                      style: TextStyle(color: _C.textLo, fontSize: 10),
                    ),
                    Text(
                      'High',
                      style: TextStyle(color: _C.textLo, fontSize: 10),
                    ),
                    Text(
                      'Very High',
                      style: TextStyle(color: _C.textLo, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),
            // ── Description ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rl.description,
                    style: TextStyle(
                      color: _C.textMid,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.recommend_rounded, color: color, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Recommended: ${rl.actionLabel}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

// ── Severity dot row (4 dots, filled up to current level) ────────────────────
class _SeverityDots extends StatelessWidget {
  final RiskLevel riskLevel;
  const _SeverityDots({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final levels = RiskLevel.values;
    return Row(
      children: levels.map((lvl) {
        final filled = lvl.index <= riskLevel.index;
        return Container(
          margin: const EdgeInsets.only(left: 5),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? lvl.color : _C.surfaceAlt,
            border: Border.all(
              color: filled ? lvl.color.withOpacity(0.5) : _C.border,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AI BOTTOM SHEET — unchanged from original but included for completeness
// ══════════════════════════════════════════════════════════════════════════════
class _AIBottomSheet extends StatelessWidget {
  final DetectionResult result;
  const _AIBottomSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF13131E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A55),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Analysis',
                        style: TextStyle(
                          color: Color(0xFFF1F1F5),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        result.diseaseName,
                        style: const TextStyle(
                          color: Color(0xFF8E8EA8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF252535)),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF8E8EA8),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: const Color(0xFF252535)),
          Expanded(
            child: BlocBuilder<DetectionBloc, DetectionState>(
              builder: (context, state) {
                if (state is AIRecommendationsLoading)
                  return const _AISheetLoading();
                if (result.aiRecommendations != null) {
                  return _AISheetContent(text: result.aiRecommendations!);
                }
                return const _AISheetLoading();
              },
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.18),
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFF59E0B),
                  size: 14,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI suggestions are for reference only. Always consult a qualified dermatologist.',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 11,
                      height: 1.5,
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

// ── AI loading shimmer ────────────────────────────────────────────────────────
class _AISheetLoading extends StatefulWidget {
  const _AISheetLoading();
  @override
  State<_AISheetLoading> createState() => _AISheetLoadingState();
}

class _AISheetLoadingState extends State<_AISheetLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _shimmerBar(double widthFactor) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3, 0),
            end: Alignment(-0.5 + _ctrl.value * 3, 0),
            colors: const [
              Color(0xFF1E1E2E),
              Color(0xFF2E2E45),
              Color(0xFF1E1E2E),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Generating your personalised recommendations...',
              style: TextStyle(color: Color(0xFF8E8EA8), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 28),
        ...[1.0, 0.8, 0.92, 0.65, 1.0, 0.75, 0.88, 0.55, 0.9, 0.7].map(
          (w) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _shimmerBar(w),
          ),
        ),
      ],
    ),
  );
}

// ── AI content ────────────────────────────────────────────────────────────────
class _AISheetContent extends StatelessWidget {
  final String text;
  const _AISheetContent({required this.text});

  static const _icons = [
    (Icons.healing_rounded, Color(0xFF6366F1)),
    (Icons.medication_rounded, Color(0xFF06B6D4)),
    (Icons.wb_sunny_rounded, Color(0xFFF59E0B)),
    (Icons.no_food_rounded, Color(0xFF10B981)),
    (Icons.schedule_rounded, Color(0xFF8B5CF6)),
    (Icons.local_hospital_rounded, Color(0xFFEF4444)),
  ];

  List<({String? title, String body})> _parse(String raw) {
    final out = <({String? title, String body})>[];
    String? title;
    final buf = StringBuffer();

    void flush() {
      final b = buf.toString().trim();
      if (b.isNotEmpty) {
        out.add((title: title, body: b));
        buf.clear();
        title = null;
      }
    }

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flush();
        continue;
      }
      if (line.endsWith(':') && line.length < 70) {
        flush();
        title = line.replaceAll(RegExp(r'[:\*\_#]+'), '').trim();
        continue;
      }
      final clean = line
          .replaceAll(RegExp(r'^#+\s*'), '')
          .replaceAll(RegExp(r'^[\d\.\-\*•►▸]+\s*'), '')
          .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1')
          .trim();
      if (clean.isNotEmpty) {
        if (buf.isNotEmpty) buf.write(' ');
        buf.write(clean);
      }
    }
    flush();
    if (out.isEmpty) out.add((title: null, body: raw.trim()));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parse(text);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final sec = sections[i];
        final (icon, color) = _icons[i % _icons.length];
        final isLast = i == sections.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sec.title != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            sec.title!,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 7),
                        ] else
                          const SizedBox(height: 4),
                        Text(
                          sec.body,
                          style: const TextStyle(
                            color: Color(0xFFAAAAAC),
                            fontSize: 13.5,
                            height: 1.7,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
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

// ══════════════════════════════════════════════════════════════════════════════
// Find Doctors Map Card (unchanged)
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
              Expanded(
                flex: 52,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      const Text(
                        'Nearby dermatologists\n& skin specialists',
                        style: TextStyle(
                          color: _C.textMid,
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                      ),
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
              Expanded(
                flex: 48,
                child: Stack(
                  children: [
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
