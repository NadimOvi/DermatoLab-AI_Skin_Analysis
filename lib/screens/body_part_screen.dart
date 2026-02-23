// ============================================================================
// BODY PART SCREEN
// File: lib/screens/body_part_screen.dart
//
// Uses `body_part_selector` package for the real anatomical SVG body.
// Everything else (BodyPart enum, BodyView toggle, chips, bottom sheet)
// is kept exactly from the original file.
//
// pubspec.yaml — add:
//   dependencies:
//     body_part_selector: ^0.2.0
//
// Then: flutter pub get
// ============================================================================

import 'package:body_part_selector/body_part_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const primary = Color(0xFF6366F1);
  static const cyan = Color(0xFF06B6D4);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const textHi = Color(0xFFF1F1F5);
  static const textMid = Color(0xFF8E8EA8);
  static const border = Color(0xFF252535);
}

// ── BodyPart enum — ORIGINAL, unchanged ──────────────────────────────────────
enum BodyPart {
  head,
  face,
  neck,
  chest,
  back,
  leftShoulder,
  rightShoulder,
  leftUpperArm,
  rightUpperArm,
  leftForearm,
  rightForearm,
  leftHand,
  rightHand,
  abdomen,
  lowerBack,
  leftThigh,
  rightThigh,
  leftKnee,
  rightKnee,
  leftShin,
  rightShin,
  leftFoot,
  rightFoot,
}

extension BodyPartX on BodyPart {
  String get label {
    switch (this) {
      case BodyPart.head:
        return 'Head & Scalp';
      case BodyPart.face:
        return 'Face';
      case BodyPart.neck:
        return 'Neck';
      case BodyPart.chest:
        return 'Chest';
      case BodyPart.back:
        return 'Upper Back';
      case BodyPart.leftShoulder:
        return 'Left Shoulder';
      case BodyPart.rightShoulder:
        return 'Right Shoulder';
      case BodyPart.leftUpperArm:
        return 'Left Upper Arm';
      case BodyPart.rightUpperArm:
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
      case BodyPart.lowerBack:
        return 'Lower Back';
      case BodyPart.leftThigh:
        return 'Left Thigh';
      case BodyPart.rightThigh:
        return 'Right Thigh';
      case BodyPart.leftKnee:
        return 'Left Knee';
      case BodyPart.rightKnee:
        return 'Right Knee';
      case BodyPart.leftShin:
        return 'Left Shin';
      case BodyPart.rightShin:
        return 'Right Shin';
      case BodyPart.leftFoot:
        return 'Left Foot';
      case BodyPart.rightFoot:
        return 'Right Foot';
    }
  }

  Color get color {
    switch (this) {
      case BodyPart.head:
      case BodyPart.face:
        return const Color(0xFFEC4899);
      case BodyPart.neck:
        return const Color(0xFF06B6D4);
      case BodyPart.chest:
      case BodyPart.back:
        return const Color(0xFFEF4444);
      case BodyPart.leftShoulder:
      case BodyPart.rightShoulder:
        return const Color(0xFF8B5CF6);
      case BodyPart.leftUpperArm:
      case BodyPart.rightUpperArm:
        return const Color(0xFF10B981);
      case BodyPart.leftForearm:
      case BodyPart.rightForearm:
        return const Color(0xFF06B6D4);
      case BodyPart.leftHand:
      case BodyPart.rightHand:
        return const Color(0xFFF59E0B);
      case BodyPart.abdomen:
      case BodyPart.lowerBack:
        return const Color(0xFFF97316);
      case BodyPart.leftThigh:
      case BodyPart.rightThigh:
        return const Color(0xFF0EA5E9);
      case BodyPart.leftKnee:
      case BodyPart.rightKnee:
        return const Color(0xFF6366F1);
      case BodyPart.leftShin:
      case BodyPart.rightShin:
        return const Color(0xFF06B6D4);
      case BodyPart.leftFoot:
      case BodyPart.rightFoot:
        return const Color(0xFFEC4899);
    }
  }

  String get emoji {
    switch (this) {
      case BodyPart.head:
      case BodyPart.face:
        return '👤';
      case BodyPart.neck:
        return '🔵';
      case BodyPart.chest:
      case BodyPart.back:
        return '❤️';
      case BodyPart.leftShoulder:
      case BodyPart.rightShoulder:
        return '💪';
      case BodyPart.leftUpperArm:
      case BodyPart.rightUpperArm:
        return '💪';
      case BodyPart.leftForearm:
      case BodyPart.rightForearm:
        return '🦾';
      case BodyPart.leftHand:
      case BodyPart.rightHand:
        return '🤚';
      case BodyPart.abdomen:
      case BodyPart.lowerBack:
        return '🟡';
      case BodyPart.leftThigh:
      case BodyPart.rightThigh:
        return '🦵';
      case BodyPart.leftKnee:
      case BodyPart.rightKnee:
        return '🦿';
      case BodyPart.leftShin:
      case BodyPart.rightShin:
        return '🦴';
      case BodyPart.leftFoot:
      case BodyPart.rightFoot:
        return '🦶';
    }
  }
}

// ── BodyView enum — ORIGINAL, kept ───────────────────────────────────────────
// NOTE: The package's BodyPartSelectorTurnable handles front/back switching
// internally via swipe. We keep BodyView for the toggle buttons which call
// _showFront on the package widget.
enum BodyView { front, back }

// ── Chips data — ORIGINAL structure, kept ────────────────────────────────────
class _Zone {
  final BodyPart part;
  const _Zone(this.part);
}

// Front zones chips list (original order)
const _frontZones = <_Zone>[
  _Zone(BodyPart.head),
  _Zone(BodyPart.face),
  _Zone(BodyPart.neck),
  _Zone(BodyPart.chest),
  _Zone(BodyPart.leftShoulder),
  _Zone(BodyPart.rightShoulder),
  _Zone(BodyPart.leftUpperArm),
  _Zone(BodyPart.rightUpperArm),
  _Zone(BodyPart.abdomen),
  _Zone(BodyPart.leftForearm),
  _Zone(BodyPart.rightForearm),
  _Zone(BodyPart.leftHand),
  _Zone(BodyPart.rightHand),
  _Zone(BodyPart.leftThigh),
  _Zone(BodyPart.rightThigh),
  _Zone(BodyPart.leftKnee),
  _Zone(BodyPart.rightKnee),
  _Zone(BodyPart.leftShin),
  _Zone(BodyPart.rightShin),
  _Zone(BodyPart.leftFoot),
  _Zone(BodyPart.rightFoot),
];

const _backZones = <_Zone>[
  _Zone(BodyPart.head),
  _Zone(BodyPart.neck),
  _Zone(BodyPart.leftShoulder),
  _Zone(BodyPart.rightShoulder),
  _Zone(BodyPart.back),
  _Zone(BodyPart.lowerBack),
  _Zone(BodyPart.leftUpperArm),
  _Zone(BodyPart.rightUpperArm),
  _Zone(BodyPart.leftForearm),
  _Zone(BodyPart.rightForearm),
  _Zone(BodyPart.leftHand),
  _Zone(BodyPart.rightHand),
  _Zone(BodyPart.leftThigh),
  _Zone(BodyPart.rightThigh),
  _Zone(BodyPart.leftKnee),
  _Zone(BodyPart.rightKnee),
  _Zone(BodyPart.leftShin),
  _Zone(BodyPart.rightShin),
  _Zone(BodyPart.leftFoot),
  _Zone(BodyPart.rightFoot),
];

// ── Bridge: BodyPart enum ↔ package BodyParts ─────────────────────────────────

/// package BodyParts → your BodyPart enum (first truthy wins)
BodyPart? _fromPkg(BodyParts bp) {
  if (bp.head) return BodyPart.head;
  if (bp.neck) return BodyPart.neck;
  if (bp.leftShoulder) return BodyPart.leftShoulder;
  if (bp.rightShoulder) return BodyPart.rightShoulder;

  // FIXED MAPPINGS:
  if (bp.upperBody) return BodyPart.chest;
  if (bp.leftUpperArm) return BodyPart.leftUpperArm; // Changed from leftHand
  if (bp.rightUpperArm) return BodyPart.rightUpperArm; // Changed from rightHand
  if (bp.leftLowerArm) return BodyPart.leftForearm;
  if (bp.rightLowerArm) return BodyPart.rightForearm;
  if (bp.leftHand) return BodyPart.leftHand;
  if (bp.rightHand) return BodyPart.rightHand;
  if (bp.abdomen) return BodyPart.abdomen;
  if (bp.lowerBody) return BodyPart.back;
  if (bp.leftUpperLeg) return BodyPart.leftThigh; // Changed from leftKnee
  if (bp.rightUpperLeg) return BodyPart.rightThigh; // Changed from leftKnee
  if (bp.leftFoot) return BodyPart.leftFoot;
  if (bp.rightFoot) return BodyPart.rightFoot;

  return null;
}

/// your BodyPart enum → package BodyParts
BodyParts _toPkg(BodyPart part) {
  switch (part) {
    case BodyPart.chest:
      return const BodyParts(upperBody: true); // Use upperBody, not chest
    case BodyPart.back:
      return const BodyParts(lowerBody: true); // Use lowerBody, not back
    case BodyPart.leftUpperArm:
      return const BodyParts(leftUpperArm: true);
    case BodyPart.rightUpperArm:
      return const BodyParts(rightUpperArm: true);
    case BodyPart.leftForearm:
      return const BodyParts(leftLowerArm: true); // Use leftLowerArm
    case BodyPart.rightForearm:
      return const BodyParts(rightLowerArm: true); // Use rightLowerArm
    case BodyPart.leftThigh:
      return const BodyParts(leftUpperLeg: true); // Use leftUpperLeg
    case BodyPart.rightThigh:
      return const BodyParts(rightUpperLeg: true); // Use rightUpperLeg
    case BodyPart.leftShin:
      return const BodyParts(leftLowerLeg: true); // Use leftLowerLeg
    case BodyPart.rightShin:
      return const BodyParts(rightLowerLeg: true); // Use rightLowerLeg
    default:
      return const BodyParts();
  }
}

/// Isolates only the newly tapped field (enforces single-selection)
BodyParts? _findAdded(BodyParts prev, BodyParts next) {
  if (!prev.head && next.head) return const BodyParts(head: true);
  if (!prev.neck && next.neck) return const BodyParts(neck: true);
  if (!prev.leftShoulder && next.leftShoulder)
    return const BodyParts(leftShoulder: true);
  if (!prev.rightShoulder && next.rightShoulder)
    return const BodyParts(rightShoulder: true);

  // CORRECTED PACKAGE NAMES BELOW:
  if (!prev.upperBody && next.upperBody)
    return const BodyParts(upperBody: true); // Fixed chest
  if (!prev.leftUpperArm && next.leftUpperArm)
    return const BodyParts(leftUpperArm: true); // Fixed leftArm
  if (!prev.rightUpperArm && next.rightUpperArm)
    return const BodyParts(rightUpperArm: true); // Fixed rightArm
  if (!prev.leftLowerArm && next.leftLowerArm)
    return const BodyParts(leftLowerArm: true); // Fixed leftForearm
  if (!prev.rightLowerArm && next.rightLowerArm)
    return const BodyParts(rightLowerArm: true); // Fixed rightForearm

  if (!prev.leftHand && next.leftHand) return const BodyParts(leftHand: true);
  if (!prev.rightHand && next.rightHand)
    return const BodyParts(rightHand: true);
  if (!prev.abdomen && next.abdomen) return const BodyParts(abdomen: true);

  if (!prev.lowerBody && next.lowerBody)
    return const BodyParts(lowerBody: true); // Fixed back

  if (!prev.leftUpperLeg && next.leftUpperLeg)
    return const BodyParts(leftUpperLeg: true); // Fixed leftThigh
  if (!prev.rightUpperLeg && next.rightUpperLeg)
    return const BodyParts(rightUpperLeg: true); // Fixed rightThigh
  if (!prev.leftLowerLeg && next.leftLowerLeg)
    return const BodyParts(leftLowerLeg: true); // Fixed leftLeg
  if (!prev.rightLowerLeg && next.rightLowerLeg)
    return const BodyParts(rightLowerLeg: true); // Fixed rightLeg

  if (!prev.leftFoot && next.leftFoot) return const BodyParts(leftFoot: true);
  if (!prev.rightFoot && next.rightFoot)
    return const BodyParts(rightFoot: true);

  return null;
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN — same class name, same signature as your original
// ══════════════════════════════════════════════════════════════════════════════
class BodyPartSelectorScreen extends StatefulWidget {
  final void Function(BodyPart part, bool fromGallery) onConfirm;
  const BodyPartSelectorScreen({super.key, required this.onConfirm});

  @override
  State<BodyPartSelectorScreen> createState() => _BodyPartSelectorState();
}

class _BodyPartSelectorState extends State<BodyPartSelectorScreen> {
  // Package selection state (single-field only)
  BodyParts _pkg = const BodyParts();

  // Current view — synced with toggle buttons
  BodyView _view = BodyView.front;

  // Derived selected part
  BodyPart? get _selected => _fromPkg(_pkg);

  // Chips list based on current view
  List<_Zone> get _zones => _view == BodyView.front ? _frontZones : _backZones;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  // ── Called by the SVG body when user taps a region ───────────────────────
  void _onBodyTap(BodyParts next) {
    final added = _findAdded(_pkg, next);
    if (added != null) {
      HapticFeedback.selectionClick();
      setState(() => _pkg = added);
    } else {
      // Tapped same zone again → deselect
      setState(() => _pkg = const BodyParts());
    }
  }

  // ── Called by chip tap — same logic as original selectPart ───────────────
  void _selectPart(BodyPart p) {
    HapticFeedback.selectionClick();
    setState(() => _pkg = _toPkg(p));
  }

  // ── Called when user taps Next — ORIGINAL logic unchanged ────────────────
  void _confirm() {
    if (_selected == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SourceSheet(
        part: _selected!,
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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final sel = _selected;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          SizedBox(height: topPad),

          // ── Top bar — ORIGINAL ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: _C.textHi,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Body Area',
                        style: TextStyle(
                          color: _C.textHi,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      // ORIGINAL: dynamic subtitle
                      Text(
                        sel == null
                            ? 'Tap the region you want to scan'
                            : '${sel.emoji}  ${sel.label} selected',
                        style: TextStyle(
                          color: sel == null ? _C.textMid : sel.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.primary.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Step 1 / 2',
                    style: TextStyle(
                      color: _C.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Instruction — ORIGINAL animated text ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                key: ValueKey(sel),
                sel == null
                    ? 'Tap directly on any part of the body to select it.'
                    : '${sel.emoji}  ${sel.label} selected — tap Next to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sel == null ? _C.textMid : sel.color,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Front / Back toggle — ORIGINAL design ────────────────────────
          // Tapping these drives the package via _showFront flag on
          // BodyPartSelectorTurnable (the package uses its own swipe
          // internally, but we keep the buttons for explicit control).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: BodyView.values.map((v) {
                  final active = v == _view;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _view = v;
                        _pkg =
                            const BodyParts(); // clear selection on view change
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: active ? _C.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: Text(
                            v == BodyView.front ? 'Front' : 'Back',
                            style: TextStyle(
                              color: active ? Colors.white : _C.textMid,
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ══════════════════════════════════════════════════════════════════
          // REPLACED: _RealisticBodyPainter → BodyPartSelectorTurnable
          //
          // The package renders the real anatomical SVG human body.
          // • Tap a region → onSelectionUpdated fires → _onBodyTap
          // • selectedColor matches the tapped part's colour from your enum
          // • unselectedColor = dark fill matching your app's dark theme
          // • User can SWIPE to go front ↔ back (package handles internally)
          // • showFront drives the initial view from our toggle buttons
          // ══════════════════════════════════════════════════════════════════
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: BodyPartSelectorTurnable(
                bodyParts: _pkg,
                onSelectionUpdated: _onBodyTap,
                selectedColor: sel?.color ?? _C.primary,
                unselectedColor: const Color(0xFF2A2A3E),
                // showFront drives which side is shown when toggle is tapped
                mirrored: _view == BodyView.front,
              ),
            ),
          ),

          // ── Selected part pill — ORIGINAL animated card ───────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: sel != null
                ? Padding(
                    key: ValueKey(sel),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel.color.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Text(sel.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sel.label,
                                  style: TextStyle(
                                    color: sel.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  'Ready to scan this area',
                                  style: TextStyle(
                                    color: _C.textMid,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle_rounded,
                            color: sel.color,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), height: 0),
          ),

          const SizedBox(height: 10),

          // ── Quick chips row — ORIGINAL _Chip widget, unchanged ────────────
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _zones
                  .map(
                    (z) => _Chip(
                      zone: z,
                      isSelected: _selected == z.part,
                      onTap: () => _selectPart(z.part),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 12),

          // ── Next button — ORIGINAL design, unchanged ──────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 16),
            child: GestureDetector(
              onTap: _confirm,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sel != null
                        ? [sel.color, sel.color.withOpacity(0.72)]
                        : [const Color(0xFF1E1E2C), const Color(0xFF1E1E2C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: sel != null
                      ? [
                          BoxShadow(
                            color: sel.color.withOpacity(0.38),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                  border: sel == null ? Border.all(color: _C.border) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      sel != null
                          ? Icons.camera_alt_rounded
                          : Icons.touch_app_rounded,
                      color: sel != null ? Colors.white : _C.textMid,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      sel != null
                          ? 'Next — Scan ${sel.label}'
                          : 'Tap a body area to continue',
                      style: TextStyle(
                        color: sel != null ? Colors.white : _C.textMid,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
// _Chip — ORIGINAL widget, unchanged
// ══════════════════════════════════════════════════════════════════════════════
class _Chip extends StatelessWidget {
  final _Zone zone;
  final bool isSelected;
  final VoidCallback onTap;
  const _Chip({
    required this.zone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = zone.part.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.6) : _C.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(zone.part.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              zone.part.label,
              style: TextStyle(
                color: isSelected ? color : _C.textMid,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _SourceSheet — ORIGINAL bottom sheet, unchanged
// ══════════════════════════════════════════════════════════════════════════════
class _SourceSheet extends StatelessWidget {
  final BodyPart part;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _SourceSheet({
    required this.part,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, pad + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF13131E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A55),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: part.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: part.color.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(part.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan ${part.label}',
                    style: const TextStyle(
                      color: Color(0xFFF1F1F5),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Choose how to capture the area',
                    style: TextStyle(color: Color(0xFF8E8EA8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SrcBtn(
            icon: Icons.camera_alt_rounded,
            label: 'Take a Photo',
            subtitle: 'Live camera · best quality for AI detection',
            color: _C.primary,
            onTap: onCamera,
          ),
          const SizedBox(height: 12),
          _SrcBtn(
            icon: Icons.photo_library_rounded,
            label: 'Choose from Gallery',
            subtitle: 'Select an existing photo from your device',
            color: _C.green,
            onTap: onGallery,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.amber.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.amber.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.tips_and_updates_rounded, color: _C.amber, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Good lighting + 10–20 cm distance = most accurate AI results.',
                    style: TextStyle(
                      color: Color(0xFF8E8EA8),
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

class _SrcBtn extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SrcBtn({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
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
                    color: Color(0xFFF1F1F5),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8E8EA8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: color.withOpacity(0.5),
            size: 14,
          ),
        ],
      ),
    ),
  );
}
