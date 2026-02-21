// ============================================================================
// DETECTION SCREEN — Real custom camera with live viewfinder + scan overlay
// File: lib/screens/detection_screen.dart
//
// Add to pubspec.yaml:
//   camera: ^0.10.5+9
//   path_provider: ^2.1.2
//   path: ^1.9.0
// ============================================================================

import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../blocs/detection/detection_bloc.dart';
import 'result_screen.dart';

class _C {
  static const bg = Color(0xFF0F0F14);
  static const surface = Color(0xFF1A1A24);
  static const primary = Color(0xFF6366F1);
  static const cyan = Color(0xFF06B6D4);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const textHi = Color(0xFFF1F1F5);
  static const textMid = Color(0xFF8E8EA8);
  static const textLo = Color(0xFF4A4A60);
}

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});
  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen>
    with TickerProviderStateMixin {
  // ── Camera state ───────────────────────────────────────────────────────────
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _isFrontCamera = false;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 4.0;
  bool _flashOn = false;
  bool _isCapturing = false;

  // ── Tap-to-focus ───────────────────────────────────────────────────────────
  Offset? _focusTapPos;
  bool _showFocusRing = false;

  // ── Distance state 0=far 1=good 2=close ────────────────────────────────────
  int _distanceState = 1;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _dotCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _flashCtrl;
  late AnimationController _focusCtrl;

  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _dotAnim;
  late Animation<double> _ringAnim;
  late Animation<double> _flashAnim;
  late Animation<double> _focusAnim;

  @override
  void initState() {
    super.initState();
    _initAnims();
    _initCamera();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initAnims() {
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _scanAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _dotAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _ringAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ringCtrl);

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _flashAnim = Tween<double>(begin: 0, end: 1).animate(_flashCtrl);

    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _focusAnim = Tween<double>(
      begin: 1.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _focusCtrl, curve: Curves.easeOut));
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _startCamera(_cameras[0]);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _startCamera(CameraDescription desc) async {
    final ctrl = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await ctrl.initialize();
      _minZoom = await ctrl.getMinZoomLevel();
      _maxZoom = await ctrl.getMaxZoomLevel();
      if (mounted)
        setState(() {
          _cameraCtrl = ctrl;
          _cameraReady = true;
        });
    } catch (e) {
      debugPrint('Camera start error: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _cameraReady = false;
      _isFrontCamera = !_isFrontCamera;
    });
    await _cameraCtrl?.dispose();
    await _startCamera(_cameras[_isFrontCamera ? 1 : 0]);
  }

  Future<void> _toggleFlash() async {
    if (_cameraCtrl == null || !_cameraReady) return;
    setState(() => _flashOn = !_flashOn);
    await _cameraCtrl!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _onTapFocus(TapUpDetails details, BoxConstraints box) async {
    if (_cameraCtrl == null || !_cameraReady) return;
    final x = details.localPosition.dx / box.maxWidth;
    final y = details.localPosition.dy / box.maxHeight;
    setState(() {
      _focusTapPos = details.localPosition;
      _showFocusRing = true;
    });
    _focusCtrl.forward(from: 0);
    try {
      await _cameraCtrl!.setFocusPoint(Offset(x, y));
      await _cameraCtrl!.setExposurePoint(Offset(x, y));
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _showFocusRing = false);
  }

  Future<void> _capture() async {
    if (_cameraCtrl == null || !_cameraReady || _isCapturing) return;
    setState(() => _isCapturing = true);
    _flashCtrl.forward(from: 0).then((_) => _flashCtrl.reverse());
    try {
      final XFile photo = await _cameraCtrl!.takePicture();
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(photo.path).copy(path);
      if (mounted)
        context.read<DetectionBloc>().add(DetectDiseaseEvent(File(path)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: $e'),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickGallery() async {
    final XFile? img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (img != null && mounted) {
      context.read<DetectionBloc>().add(DetectDiseaseEvent(File(img.path)));
    }
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    for (final c in [
      _scanCtrl,
      _pulseCtrl,
      _dotCtrl,
      _ringCtrl,
      _flashCtrl,
      _focusCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<DetectionBloc, DetectionState>(
        listener: (context, state) {
          if (state is DetectionSuccess ||
              state is DetectionWithAIRecommendations) {
            final result = state is DetectionSuccess
                ? state.result
                : (state as DetectionWithAIRecommendations).result;
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => ResultScreen(result: result),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
          } else if (state is DetectionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: _C.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DetectionLoading) return _buildAnalyzing();
          return _buildCamera();
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FULL CAMERA SCREEN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCamera() {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // ── 1. Live viewfinder (fills screen) ──────────────────────────────
        Positioned.fill(child: _buildPreview()),

        // ── 2. Vignette ─────────────────────────────────────────────────────
        Positioned.fill(child: _Vignette()),

        // ── 3. Scan frame (brackets + line + crosshair + dots) ──────────────
        Positioned.fill(child: _buildScanFrame()),

        // ── 4. Focus ring ───────────────────────────────────────────────────
        if (_showFocusRing && _focusTapPos != null)
          Positioned(
            left: _focusTapPos!.dx - 30,
            top: _focusTapPos!.dy - 30,
            child: AnimatedBuilder(
              animation: _focusAnim,
              builder: (_, __) => Transform.scale(
                scale: _focusAnim.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.amber, width: 1.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: _C.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── 5. White capture flash ───────────────────────────────────────────
        AnimatedBuilder(
          animation: _flashAnim,
          builder: (_, __) => IgnorePointer(
            child: Opacity(
              opacity: _flashAnim.value * 0.65,
              child: Container(color: Colors.white),
            ),
          ),
        ),

        // ── 6. Top bar ───────────────────────────────────────────────────────
        Positioned(top: top + 8, left: 16, right: 16, child: _buildTopBar()),

        // ── 7. Distance chip ────────────────────────────────────────────────
        Positioned(
          bottom: bottom + 165,
          left: 0,
          right: 0,
          child: Center(child: _buildDistanceChip()),
        ),

        // ── 8. Zoom row ─────────────────────────────────────────────────────
        Positioned(
          bottom: bottom + 125,
          left: 48,
          right: 48,
          child: _buildZoomRow(),
        ),

        // ── 9. Bottom controls ───────────────────────────────────────────────
        Positioned(
          bottom: bottom + 28,
          left: 0,
          right: 0,
          child: _buildBottomControls(),
        ),
      ],
    );
  }

  // ── Live preview ───────────────────────────────────────────────────────────
  Widget _buildPreview() {
    if (!_cameraReady || _cameraCtrl == null) {
      return Container(
        color: const Color(0xFF080810),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _C.primary, strokeWidth: 2),
              SizedBox(height: 16),
              Text(
                'Starting camera...',
                style: TextStyle(color: _C.textMid, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        onTapUp: (d) => _onTapFocus(d, box),
        onScaleUpdate: (d) {
          if (d.scale != 1.0) {
            final newZoom = (_zoomLevel * d.scale)
                .clamp(_minZoom, math.min(_maxZoom, 4.0))
                .toDouble();
            _cameraCtrl!.setZoomLevel(newZoom);
            setState(() => _zoomLevel = newZoom);
          }
        },
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraCtrl!.value.previewSize!.height,
              height: _cameraCtrl!.value.previewSize!.width,
              child: CameraPreview(_cameraCtrl!),
            ),
          ),
        ),
      ),
    );
  }

  // ── Scan frame overlay ─────────────────────────────────────────────────────
  Widget _buildScanFrame() {
    return LayoutBuilder(
      builder: (context, box) {
        final frameSize = math.min(box.maxWidth, box.maxHeight) * 0.74;
        final left = (box.maxWidth - frameSize) / 2;
        final top = (box.maxHeight - frameSize) / 2 - 28;
        final frameRect = Rect.fromLTWH(left, top, frameSize, frameSize);

        return Stack(
          children: [
            // Dark mask outside frame
            ClipPath(
              clipper: _MaskClipper(frameRect: frameRect, radius: 20),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),

            // Scan sweep line
            Positioned(
              left: left,
              top: top,
              width: frameSize,
              height: frameSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AnimatedBuilder(
                  animation: _scanAnim,
                  builder: (_, __) =>
                      CustomPaint(painter: _ScanLinePainter(_scanAnim.value)),
                ),
              ),
            ),

            // Dot grid
            Positioned(
              left: left,
              top: top,
              width: frameSize,
              height: frameSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(painter: _DotGridPainter()),
              ),
            ),

            // Corner brackets (pulsing)
            Positioned(
              left: left,
              top: top,
              width: frameSize,
              height: frameSize,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: CustomPaint(painter: _CornerPainter()),
                ),
              ),
            ),

            // Rotating dashed ring
            Positioned(
              left: left,
              top: top,
              width: frameSize,
              height: frameSize,
              child: AnimatedBuilder(
                animation: _ringAnim,
                builder: (_, __) =>
                    CustomPaint(painter: _RingPainter(_ringAnim.value)),
              ),
            ),

            // Centre crosshair
            Positioned(
              left: left,
              top: top,
              width: frameSize,
              height: frameSize,
              child: AnimatedBuilder(
                animation: _dotAnim,
                builder: (_, __) => CustomPaint(
                  painter: _CrosshairPainter(opacity: _dotAnim.value),
                ),
              ),
            ),

            // 8-point scan marks
            Positioned(
              left: left,
              top: top,
              width: frameSize,
              height: frameSize,
              child: _MarkGrid(size: frameSize),
            ),

            // Frame label below scan box
            Positioned(
              left: left,
              top: top + frameSize + 14,
              width: frameSize,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.58),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.cyan.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Position skin area inside the frame',
                    style: TextStyle(
                      color: _C.textHi,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Top-left badge
            Positioned(
              left: left + 10,
              top: top + 10,
              child: _Badge(
                icon: Icons.center_focus_strong_rounded,
                label: 'Align Skin',
                color: _C.cyan,
              ),
            ),
            // Top-right badge
            Positioned(
              right: box.maxWidth - left - frameSize + 10,
              top: top + 10,
              child: _Badge(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Ready',
                color: _C.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        _TopBtn(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Skin Scanner',
            style: TextStyle(
              color: _C.textHi,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _TopBtn(
          icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          color: _flashOn ? _C.amber : _C.textMid,
          onTap: _toggleFlash,
        ),
        const SizedBox(width: 8),
        _TopBtn(icon: Icons.flip_camera_ios_rounded, onTap: _toggleCamera),
      ],
    );
  }

  // ── Distance chip ──────────────────────────────────────────────────────────
  Widget _buildDistanceChip() {
    const cfg = [
      (_C.red, Icons.zoom_out_rounded, 'Too Far — move closer'),
      (_C.green, Icons.check_circle_rounded, 'Perfect distance ✓'),
      (_C.amber, Icons.zoom_in_rounded, 'Too Close — move back'),
    ];
    final (color, icon, label) = cfg[_distanceState];

    return GestureDetector(
      // tap to cycle for demo; in production replace with real depth sensor
      onTap: () => setState(() => _distanceState = (_distanceState + 1) % 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            // mini ruler
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                const barColors = [_C.amber, _C.green, _C.red];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: i == _distanceState ? 18 : 8,
                  height: 4,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: i == _distanceState
                        ? barColors[i]
                        : barColors[i].withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Zoom row ───────────────────────────────────────────────────────────────
  Widget _buildZoomRow() {
    return Row(
      children: [
        Text(
          '${_zoomLevel.toStringAsFixed(1)}×',
          style: const TextStyle(
            color: _C.textMid,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: _C.primary,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: _C.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _zoomLevel,
              min: _minZoom,
              max: math.min(_maxZoom, 4.0),
              onChanged: (v) {
                setState(() => _zoomLevel = v);
                _cameraCtrl?.setZoomLevel(v);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${math.min(_maxZoom, 4.0).toStringAsFixed(0)}×',
          style: const TextStyle(color: _C.textMid, fontSize: 11),
        ),
      ],
    );
  }

  // ── Bottom controls ────────────────────────────────────────────────────────
  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Gallery
        GestureDetector(
          onTap: _pickGallery,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        // Shutter
        GestureDetector(
          onTap: _isCapturing ? null : _capture,
          child: _ShutterBtn(isCapturing: _isCapturing),
        ),

        // Tips
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: _C.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => const _TipsSheet(),
          ),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANALYZING STATE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAnalyzing() {
    return Container(
      color: _C.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: _C.primary.withOpacity(0.15),
                    ),
                  ),
                  const SizedBox(
                    width: 108,
                    height: 108,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _C.primary,
                    ),
                  ),
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.primary.withOpacity(0.08),
                      border: Border.all(
                        color: _C.primary.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.biotech_rounded,
                      color: _C.primary,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Analyzing Image',
              style: TextStyle(
                color: _C.textHi,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI model is scanning for skin conditions...',
              style: TextStyle(color: _C.textMid, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _ScanningDots(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CLIP PATH — punches scan window out of dark mask
// ══════════════════════════════════════════════════════════════════════════════
class _MaskClipper extends CustomClipper<Path> {
  final Rect frameRect;
  final double radius;
  _MaskClipper({required this.frameRect, required this.radius});

  @override
  Path getClip(Size size) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(frameRect, Radius.circular(radius)));
    return Path.combine(PathOperation.difference, outer, inner);
  }

  @override
  bool shouldReclip(_MaskClipper old) => old.frameRect != frameRect;
}

// ══════════════════════════════════════════════════════════════════════════════
// VIGNETTE
// ══════════════════════════════════════════════════════════════════════════════
class _Vignette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
          stops: const [0.5, 1.0],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAINTERS
// ══════════════════════════════════════════════════════════════════════════════
class _ScanLinePainter extends CustomPainter {
  final double t;
  _ScanLinePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    final rect = Rect.fromLTWH(0, y - 50, size.width, 100);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF6366F1).withOpacity(0.12),
            const Color(0xFF6366F1).withOpacity(0.22),
            const Color(0xFF6366F1).withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0xFF6366F1).withOpacity(0.65)
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter o) => o.t != t;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF6366F1).withOpacity(0.08);
    for (double x = 22; x < size.width; x += 22) {
      for (double y = 22; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.primary
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 26.0, r = 8.0, pad = 0.0;

    void corner(double x, double y, double dx, double dy) {
      final path = Path()
        ..moveTo(x + dx * len, y)
        ..lineTo(x + dx * r, y)
        ..arcToPoint(
          Offset(x, y + dy * r),
          radius: const Radius.circular(r),
          clockwise: dx * dy < 0,
        )
        ..lineTo(x, y + dy * len);
      canvas.drawPath(path, paint);
    }

    corner(pad, pad, 1, 1);
    corner(size.width - pad, pad, -1, 1);
    corner(pad, size.height - pad, 1, -1);
    corner(size.width - pad, size.height - pad, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _RingPainter extends CustomPainter {
  final double angle;
  _RingPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 5;
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.13)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.translate(-c.dx, -c.dy);
    const n = 20;
    for (int i = 0; i < n; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * (2 * math.pi / n),
        (2 * math.pi / n) * 0.55,
        false,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.angle != angle;
}

class _CrosshairPainter extends CustomPainter {
  final double opacity;
  _CrosshairPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final p = Paint()
      ..color = _C.cyan.withOpacity(opacity * 0.9)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    const arm = 18.0, gap = 7.0;
    canvas.drawLine(Offset(cx - arm - gap, cy), Offset(cx - gap, cy), p);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + arm + gap, cy), p);
    canvas.drawLine(Offset(cx, cy - arm - gap), Offset(cx, cy - gap), p);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + arm + gap), p);
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()..color = _C.cyan.withOpacity(opacity),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      12,
      Paint()
        ..color = _C.cyan.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_CrosshairPainter o) => o.opacity != opacity;
}

// ══════════════════════════════════════════════════════════════════════════════
// MARK POINT GRID — 8 pulsing + scan dots
// ══════════════════════════════════════════════════════════════════════════════
class _MarkGrid extends StatefulWidget {
  final double size;
  const _MarkGrid({required this.size});
  @override
  State<_MarkGrid> createState() => _MarkGridState();
}

class _MarkGridState extends State<_MarkGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pts = <Offset>[];
    for (int r = 0; r < 3; r++)
      for (int c = 0; c < 3; c++) {
        if (r == 1 && c == 1) continue;
        pts.add(Offset((c + 1) / 4, (r + 1) / 4));
      }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        children: pts.asMap().entries.map((e) {
          final t = ((_ctrl.value * pts.length) - e.key) % 1.0;
          final op = (t < 0.5 ? t * 2.0 : (1.0 - t) * 2.0).clamp(0.1, 0.75);
          return Positioned(
            left: e.value.dx * widget.size - 5,
            top: e.value.dy * widget.size - 5,
            child: Opacity(
              opacity: op,
              child: SizedBox(
                width: 10,
                height: 10,
                child: CustomPaint(painter: _DotMark()),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DotMark extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _C.cyan
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2, cy = size.height / 2;
    canvas.drawLine(Offset(cx - 4, cy), Offset(cx + 4, cy), p);
    canvas.drawLine(Offset(cx, cy - 4), Offset(cx, cy + 4), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _TopBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TopBtn({
    required this.icon,
    this.color = _C.textHi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.55),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ShutterBtn extends StatefulWidget {
  final bool isCapturing;
  const _ShutterBtn({required this.isCapturing});
  @override
  State<_ShutterBtn> createState() => _ShutterBtnState();
}

class _ShutterBtnState extends State<_ShutterBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (_, child) => Transform.scale(
      scale: widget.isCapturing ? 0.9 : _pulse.value,
      child: child,
    ),
    child: Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.5),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: widget.isCapturing
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 28,
              ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TIPS SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _TipsSheet extends StatelessWidget {
  const _TipsSheet();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: _C.textLo,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scanning Tips',
          style: TextStyle(
            color: _C.textHi,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        ...[
          (
            Icons.wb_sunny_rounded,
            const Color(0xFFF59E0B),
            'Good Lighting',
            'Use natural light. Avoid harsh shadows on the skin area.',
          ),
          (
            Icons.straighten_rounded,
            const Color(0xFF06B6D4),
            'Ideal Distance',
            'Hold phone 10–20 cm from skin. Stay in the green zone.',
          ),
          (
            Icons.center_focus_strong_rounded,
            const Color(0xFF6366F1),
            'Stay in Frame',
            'Keep the affected area inside the scan frame brackets.',
          ),
          (
            Icons.clean_hands_rounded,
            const Color(0xFF10B981),
            'Clean the Area',
            'Remove makeup or creams before scanning for best accuracy.',
          ),
          (
            Icons.do_not_touch_rounded,
            const Color(0xFFEC4899),
            'Hold Steady',
            'Keep your hand still. Blurry images reduce detection accuracy.',
          ),
        ].map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: t.$2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(t.$1, color: t.$2, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.$3,
                        style: const TextStyle(
                          color: _C.textHi,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.$4,
                        style: const TextStyle(
                          color: _C.textMid,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
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

// ══════════════════════════════════════════════════════════════════════════════
// SCANNING DOTS
// ══════════════════════════════════════════════════════════════════════════════
class _ScanningDots extends StatefulWidget {
  @override
  State<_ScanningDots> createState() => _ScanningDotsState();
}

class _ScanningDotsState extends State<_ScanningDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final t = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
        final op = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.primary.withOpacity(op),
          ),
        );
      }),
    ),
  );
}
