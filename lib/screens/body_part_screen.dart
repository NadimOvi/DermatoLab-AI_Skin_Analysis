// ============================================================================
// BODY PART SELECTOR SCREEN — Interactive tap-to-select human body diagram
// File: lib/screens/body_part_selector_screen.dart
//
// Usage: Navigate to this screen BEFORE camera/gallery selection.
// Returns: BodyPart enum value, then user picks image source.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Color palette (matches result_screen.dart dark indigo theme) ─────────────
class _C {
  static const bg = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const surfaceAlt = Color(0xFF22222F);
  static const primary = Color(0xFF6366F1);
  static const accent = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF06B6D4);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const textHi = Color(0xFFF1F1F5);
  static const textMid = Color(0xFF8E8EA8);
  static const border = Color(0xFF252535);
}

// ── Body part enum ────────────────────────────────────────────────────────────
enum BodyPart {
  head,
  neck,
  chest,
  leftArm,
  rightArm,
  leftForearm,
  rightForearm,
  leftHand,
  rightHand,
  abdomen,
  back,
  leftLeg,
  rightLeg,
  leftFoot,
  rightFoot,
}

extension BodyPartInfo on BodyPart {
  String get label {
    switch (this) {
      case BodyPart.head:
        return 'Head & Face';
      case BodyPart.neck:
        return 'Neck';
      case BodyPart.chest:
        return 'Chest';
      case BodyPart.leftArm:
        return 'Left Upper Arm';
      case BodyPart.rightArm:
        return 'Right Upper Arm';
      case BodyPart.leftForearm:
        return 'Left Forearm';
      case BodyPart.rightForearm:
        return 'Right Forearm';
      case BodyPart.leftHand:
        return 'Left Hand';
      case BodyPart.rightHand:
        return 'Right Hand';
      case BodyPart.abdomen:
        return 'Abdomen';
      case BodyPart.back:
        return 'Back';
      case BodyPart.leftLeg:
        return 'Left Thigh';
      case BodyPart.rightLeg:
        return 'Right Thigh';
      case BodyPart.leftFoot:
        return 'Left Foot';
      case BodyPart.rightFoot:
        return 'Right Foot';
    }
  }

  IconData get icon {
    switch (this) {
      case BodyPart.head:
        return Icons.face_rounded;
      case BodyPart.neck:
        return Icons.airline_seat_flat_rounded;
      case BodyPart.chest:
        return Icons.favorite_rounded;
      case BodyPart.abdomen:
        return Icons.circle_outlined;
      case BodyPart.back:
        return Icons.accessibility_new_rounded;
      case BodyPart.leftHand:
      case BodyPart.rightHand:
        return Icons.pan_tool_rounded;
      case BodyPart.leftFoot:
      case BodyPart.rightFoot:
        return Icons.directions_walk_rounded;
      default:
        return Icons.accessibility_rounded;
    }
  }

  String get hint {
    switch (this) {
      case BodyPart.head:
        return 'Face, scalp, ears';
      case BodyPart.neck:
        return 'Front & back neck';
      case BodyPart.chest:
        return 'Front torso';
      case BodyPart.back:
        return 'Upper & lower back';
      case BodyPart.abdomen:
        return 'Stomach area';
      case BodyPart.leftHand:
      case BodyPart.rightHand:
        return 'Palm, fingers, nails';
      case BodyPart.leftFoot:
      case BodyPart.rightFoot:
        return 'Sole, toes, ankle';
      default:
        return '';
    }
  }
}

// ── Hit area data ─────────────────────────────────────────────────────────────
class _HitZone {
  final BodyPart part;
  final Offset center; // Normalized 0–1 relative to diagram container
  final double width;
  final double height;

  const _HitZone({
    required this.part,
    required this.center,
    required this.width,
    required this.height,
  });
}

// ── Main screen ───────────────────────────────────────────────────────────────
class BodyPartSelectorScreen extends StatefulWidget {
  /// Called when user confirms a body part and image source.
  /// [part] — selected body part
  /// [fromGallery] — true = gallery, false = camera
  final void Function(BodyPart part, bool fromGallery) onConfirm;

  const BodyPartSelectorScreen({super.key, required this.onConfirm});

  @override
  State<BodyPartSelectorScreen> createState() => _BodyPartSelectorScreenState();
}

class _BodyPartSelectorScreenState extends State<BodyPartSelectorScreen>
    with SingleTickerProviderStateMixin {
  BodyPart? _selected;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // Whether we're showing front or back
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onPartTap(BodyPart part) {
    HapticFeedback.selectionClick();
    setState(() => _selected = part);
    _bounceCtrl.forward(from: 0);
  }

  void _showImageSourceSheet() {
    if (_selected == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        bodyPart: _selected!,
        onCamera: () {
          Navigator.pop(context);
          widget.onConfirm(_selected!, false);
        },
        onGallery: () {
          Navigator.pop(context);
          widget.onConfirm(_selected!, true);
        },
      ),
    );
  }

  // ── Hit zones (front view) ─────────────────────────────────────────────────
  // Positions are percentages of the diagram's [width × height]
  List<_HitZone> get _frontZones => [
    const _HitZone(
      part: BodyPart.head,
      center: Offset(0.5, 0.095),
      width: 0.22,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.neck,
      center: Offset(0.5, 0.185),
      width: 0.14,
      height: 0.07,
    ),
    const _HitZone(
      part: BodyPart.chest,
      center: Offset(0.5, 0.295),
      width: 0.32,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.abdomen,
      center: Offset(0.5, 0.43),
      width: 0.28,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.leftArm,
      center: Offset(0.22, 0.30),
      width: 0.13,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.rightArm,
      center: Offset(0.78, 0.30),
      width: 0.13,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.leftForearm,
      center: Offset(0.17, 0.43),
      width: 0.12,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.rightForearm,
      center: Offset(0.83, 0.43),
      width: 0.12,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.leftHand,
      center: Offset(0.13, 0.56),
      width: 0.11,
      height: 0.09,
    ),
    const _HitZone(
      part: BodyPart.rightHand,
      center: Offset(0.87, 0.56),
      width: 0.11,
      height: 0.09,
    ),
    const _HitZone(
      part: BodyPart.leftLeg,
      center: Offset(0.39, 0.65),
      width: 0.16,
      height: 0.16,
    ),
    const _HitZone(
      part: BodyPart.rightLeg,
      center: Offset(0.61, 0.65),
      width: 0.16,
      height: 0.16,
    ),
    const _HitZone(
      part: BodyPart.leftFoot,
      center: Offset(0.37, 0.915),
      width: 0.15,
      height: 0.07,
    ),
    const _HitZone(
      part: BodyPart.rightFoot,
      center: Offset(0.63, 0.915),
      width: 0.15,
      height: 0.07,
    ),
  ];

  List<_HitZone> get _backZones => [
    const _HitZone(
      part: BodyPart.head,
      center: Offset(0.5, 0.095),
      width: 0.22,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.neck,
      center: Offset(0.5, 0.185),
      width: 0.14,
      height: 0.07,
    ),
    const _HitZone(
      part: BodyPart.back,
      center: Offset(0.5, 0.355),
      width: 0.32,
      height: 0.18,
    ),
    const _HitZone(
      part: BodyPart.leftArm,
      center: Offset(0.22, 0.30),
      width: 0.13,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.rightArm,
      center: Offset(0.78, 0.30),
      width: 0.13,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.leftForearm,
      center: Offset(0.17, 0.43),
      width: 0.12,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.rightForearm,
      center: Offset(0.83, 0.43),
      width: 0.12,
      height: 0.12,
    ),
    const _HitZone(
      part: BodyPart.leftHand,
      center: Offset(0.13, 0.56),
      width: 0.11,
      height: 0.09,
    ),
    const _HitZone(
      part: BodyPart.rightHand,
      center: Offset(0.87, 0.56),
      width: 0.11,
      height: 0.09,
    ),
    const _HitZone(
      part: BodyPart.leftLeg,
      center: Offset(0.39, 0.65),
      width: 0.16,
      height: 0.16,
    ),
    const _HitZone(
      part: BodyPart.rightLeg,
      center: Offset(0.61, 0.65),
      width: 0.16,
      height: 0.16,
    ),
    const _HitZone(
      part: BodyPart.leftFoot,
      center: Offset(0.37, 0.915),
      width: 0.15,
      height: 0.07,
    ),
    const _HitZone(
      part: BodyPart.rightFoot,
      center: Offset(0.63, 0.915),
      width: 0.15,
      height: 0.07,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final zones = _showFront ? _frontZones : _backZones;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
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
          'Select Body Part',
          style: TextStyle(
            color: _C.textHi,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Instruction banner ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.touch_app_rounded, color: _C.primary, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap on the body part where you want to check your skin',
                      style: TextStyle(
                        color: _C.textMid,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Front / Back toggle ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  _ToggleTab(
                    label: 'Front View',
                    selected: _showFront,
                    onTap: () => setState(() {
                      _showFront = true;
                      _selected = null;
                    }),
                  ),
                  _ToggleTab(
                    label: 'Back View',
                    selected: !_showFront,
                    onTap: () => setState(() {
                      _showFront = false;
                      _selected = null;
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── Body diagram ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxH = constraints.maxHeight;
                  final maxW = constraints.maxWidth;
                  // Diagram is taller than wide — constrain to fit height
                  final diagH = maxH;
                  final diagW = diagH * 0.55; // Approx aspect ratio of body

                  return Center(
                    child: SizedBox(
                      width: diagW,
                      height: diagH,
                      child: Stack(
                        children: [
                          // ── Body SVG painting ────────────────────────────────
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _BodyPainter(
                                selected: _selected,
                                zones: zones,
                                showFront: _showFront,
                              ),
                            ),
                          ),

                          // ── Tap zones (transparent overlay) ─────────────────
                          ...zones.map((zone) {
                            final isSelected = _selected == zone.part;
                            final left =
                                (zone.center.dx - zone.width / 2) * diagW;
                            final top =
                                (zone.center.dy - zone.height / 2) * diagH;
                            final w = zone.width * diagW;
                            final h = zone.height * diagH;

                            return Positioned(
                              left: left,
                              top: top,
                              width: w,
                              height: h,
                              child: GestureDetector(
                                onTap: () => _onPartTap(zone.part),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _C.cyan.withOpacity(0.22)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: _C.cyan.withOpacity(0.5),
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }),

                          // ── Labels for selected part ─────────────────────────
                          ...zones.where((z) => z.part == _selected).map((
                            zone,
                          ) {
                            final cx = zone.center.dx * diagW;
                            final ty =
                                (zone.center.dy - zone.height / 2 - 0.04) *
                                diagH;

                            return Positioned(
                              left: cx - 60,
                              top: ty,
                              width: 120,
                              child: AnimatedBuilder(
                                animation: _bounceAnim,
                                builder: (_, child) => Transform.scale(
                                  scale: _bounceAnim.value,
                                  child: child,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _C.cyan,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _C.cyan.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    zone.part.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Selected info + CTA ────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: _selected != null ? 140 : 80,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  if (_selected != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.cyan.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _C.cyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _selected!.icon,
                              color: _C.cyan,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selected!.label,
                                  style: const TextStyle(
                                    color: _C.textHi,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_selected!.hint.isNotEmpty)
                                  Text(
                                    _selected!.hint,
                                    style: const TextStyle(
                                      color: _C.textMid,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: _C.cyan,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Continue button ──────────────────────────────────────────
                  GestureDetector(
                    onTap: _selected != null ? _showImageSourceSheet : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _selected != null
                            ? const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: _selected == null ? _C.surface : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selected != null
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                        border: _selected == null
                            ? Border.all(color: _C.border)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: _selected != null
                                ? Colors.white
                                : _C.textMid,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selected != null
                                ? 'Continue with ${_selected!.label}'
                                : 'Select a body part first',
                            style: TextStyle(
                              color: _selected != null
                                  ? Colors.white
                                  : _C.textMid,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
}

// ── Toggle tab widget ─────────────────────────────────────────────────────────
class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? _C.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _C.textMid,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Image source bottom sheet ─────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final BodyPart bodyPart;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _ImageSourceSheet({
    required this.bodyPart,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 20),
      decoration: const BoxDecoration(
        color: Color(0xFF13131E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A55),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            'Scan ${bodyPart.label}',
            style: const TextStyle(
              color: _C.textHi,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose how to capture the affected area',
            style: TextStyle(color: _C.textMid, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Camera option
          _SourceOption(
            icon: Icons.camera_alt_rounded,
            label: 'Take a Photo',
            subtitle: 'Use camera for best quality',
            color: _C.primary,
            onTap: onCamera,
          ),
          const SizedBox(height: 12),

          // Gallery option
          _SourceOption(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            subtitle: 'Select an existing photo',
            color: _C.green,
            onTap: onGallery,
          ),
          const SizedBox(height: 16),

          // Tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.amber.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.amber.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.tips_and_updates_rounded, color: _C.amber, size: 15),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For accurate results, ensure good lighting and capture the affected area clearly.',
                    style: TextStyle(
                      color: _C.textMid,
                      fontSize: 11,
                      height: 1.5,
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

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _C.textHi,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _C.textMid, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Custom painter — draws a stylized human silhouette with region highlights
// ══════════════════════════════════════════════════════════════════════════════
class _BodyPainter extends CustomPainter {
  final BodyPart? selected;
  final List<_HitZone> zones;
  final bool showFront;

  const _BodyPainter({
    required this.selected,
    required this.zones,
    required this.showFront,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base fill paint
    final bodyFill = Paint()
      ..color = const Color(0xFF2A2A3E)
      ..style = PaintingStyle.fill;

    final bodyStroke = Paint()
      ..color = const Color(0xFF3A3A58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final selectedFill = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final selectedStroke = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // ── Draw each body zone ─────────────────────────────────────────────────
    for (final zone in zones) {
      final isSelected = zone.part == selected;
      final cx = zone.center.dx * w;
      final cy = zone.center.dy * h;
      final zw = zone.width * w;
      final zh = zone.height * h;
      final rect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: zw,
        height: zh,
      );
      final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

      canvas.drawRRect(rRect, isSelected ? selectedFill : bodyFill);
      canvas.drawRRect(rRect, isSelected ? selectedStroke : bodyStroke);

      // Draw zone labels (non-selected)
      if (!isSelected) {
        _drawZoneLabel(canvas, zone.part.label.split(' ').last, cx, cy, w, h);
      }
    }

    // ── Draw body outline (simplified stick-figure silhouette connecting zones) ─
    _drawBodyConnectors(canvas, size, bodyStroke);
  }

  void _drawZoneLabel(
    Canvas canvas,
    String text,
    double cx,
    double cy,
    double w,
    double h,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF4A4A65),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawBodyConnectors(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final linePaint = Paint()
      ..color = const Color(0xFF32324A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Neck → chest
    canvas.drawLine(
      Offset(w * 0.5, h * 0.22),
      Offset(w * 0.5, h * 0.24),
      linePaint,
    );
    // Chest → left arm
    canvas.drawLine(
      Offset(w * 0.36, h * 0.26),
      Offset(w * 0.28, h * 0.30),
      linePaint,
    );
    // Chest → right arm
    canvas.drawLine(
      Offset(w * 0.64, h * 0.26),
      Offset(w * 0.72, h * 0.30),
      linePaint,
    );
    // Left arm → forearm
    canvas.drawLine(
      Offset(w * 0.22, h * 0.36),
      Offset(w * 0.19, h * 0.40),
      linePaint,
    );
    // Right arm → forearm
    canvas.drawLine(
      Offset(w * 0.78, h * 0.36),
      Offset(w * 0.81, h * 0.40),
      linePaint,
    );
    // Left forearm → hand
    canvas.drawLine(
      Offset(w * 0.17, h * 0.49),
      Offset(w * 0.15, h * 0.52),
      linePaint,
    );
    // Right forearm → hand
    canvas.drawLine(
      Offset(w * 0.83, h * 0.49),
      Offset(w * 0.85, h * 0.52),
      linePaint,
    );
    // Abdomen → left leg
    canvas.drawLine(
      Offset(w * 0.44, h * 0.49),
      Offset(w * 0.41, h * 0.57),
      linePaint,
    );
    // Abdomen → right leg
    canvas.drawLine(
      Offset(w * 0.56, h * 0.49),
      Offset(w * 0.59, h * 0.57),
      linePaint,
    );
    // Left leg → foot
    canvas.drawLine(
      Offset(w * 0.39, h * 0.73),
      Offset(w * 0.38, h * 0.88),
      linePaint,
    );
    // Right leg → foot
    canvas.drawLine(
      Offset(w * 0.61, h * 0.73),
      Offset(w * 0.62, h * 0.88),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.selected != selected || old.showFront != showFront;
}
