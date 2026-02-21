// ============================================================================
// DOCTOR LIST SCREEN — Full map top, modern doctor cards below
// File: lib/screens/doctor_list_screen.dart
//
// Requires in pubspec.yaml:
//   google_maps_flutter: ^2.5.0
//   url_launcher: ^6.2.0
// ============================================================================

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/detection_result.dart';
import '../models/doctor_info.dart';
import '../repositories/location_repository.dart';
import '../utils/constants.dart';

// ── Palette (matches app-wide theme) ─────────────────────────────────────────
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
  static const pink = Color(0xFFEC4899);
  static const textHi = Color(0xFFF1F1F5);
  static const textMid = Color(0xFF8E8EA8);
  static const textLo = Color(0xFF4A4A60);
  static const border = Color(0xFF252535);
}

class DoctorListScreen extends StatefulWidget {
  final DetectionResult? detectionResult;

  const DoctorListScreen({super.key, this.detectionResult});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen>
    with SingleTickerProviderStateMixin {
  final LocationRepository _locationRepository = LocationRepository();

  List<DoctorInfo>? _doctors;
  bool _isLoading = true;
  String? _error;

  GoogleMapController? _mapController;
  int _selectedIndex = 0;

  // Will be updated to real GPS location on load
  LatLng _userLocation = const LatLng(23.8103, 90.4125);
  bool _locationReady = false;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _doctorMarkerIcon;
  BitmapDescriptor? _selectedMarkerIcon;
  BitmapDescriptor? _userMarkerIcon;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _createCustomMarkers();
    _loadNearbyDoctors();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // ── Step 1: get real GPS location ──────────────────────────────────────
      await _fetchUserLocation();

      // ── Step 2: load doctors (repository uses location internally) ─────────
      final doctors = await _locationRepository.findNearbyDoctors();

      // ── Step 3: recalculate distances from real location ────────────────────
      final updatedDoctors = doctors.map((doc) {
        final realDistance =
            Geolocator.distanceBetween(
              _userLocation.latitude,
              _userLocation.longitude,
              doc.latitude,
              doc.longitude,
            ) /
            1000; // convert metres → km

        return DoctorInfo(
          id: doc.id,
          name: doc.name,
          specialty: doc.specialty,
          address: doc.address,
          latitude: doc.latitude,
          longitude: doc.longitude,
          distance: double.parse(realDistance.toStringAsFixed(1)),
          rating: doc.rating,
          totalRatings: doc.totalRatings,
          phoneNumber: doc.phoneNumber,
          isOpenNow: doc.isOpenNow,
          photoUrl: doc.photoUrl,
        );
      }).toList();

      // Sort by distance ascending
      updatedDoctors.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _doctors = updatedDoctors;
        _isLoading = false;
      });
      _buildMarkers();
      _moveMapToUserLocation();
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Requests permission and fetches the real device GPS location.
  Future<void> _fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _locationReady = true;
      });
    } catch (_) {
      // Keep default location if GPS fails
    }
  }

  /// Moves the map camera to the user's real location and adds a "You" marker.
  void _moveMapToUserLocation() {
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon:
            _userMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 0.5),
        zIndex: 10,
      ),
    );
    setState(() {});

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_userLocation, 13),
    );

    // Auto-select and route to the nearest doctor (index 0, already sorted)
    if (_doctors != null && _doctors!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _drawRoute(_doctors![0]);
      });
    }
  }

  // ── Custom marker icon generator ─────────────────────────────────────────
  Future<void> _createCustomMarkers() async {
    _doctorMarkerIcon = await _buildMarkerBitmap(
      const Color(0xFF6366F1),
      false,
    );
    _selectedMarkerIcon = await _buildMarkerBitmap(
      const Color(0xFF06B6D4),
      true,
    );
    _userMarkerIcon = await _buildUserDotBitmap();
    if (mounted) setState(() {});
  }

  /// Draws a teardrop pin on a canvas and returns it as a BitmapDescriptor.
  Future<BitmapDescriptor> _buildMarkerBitmap(
    Color color,
    bool selected,
  ) async {
    const size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(size / 2, size / 2 - 4), 22, shadowPaint);

    // Outer circle
    final outerPaint = Paint()..color = selected ? Colors.white : color;
    canvas.drawCircle(const Offset(size / 2, size / 2 - 4), 20, outerPaint);

    // Inner circle
    final innerPaint = Paint()..color = selected ? color : Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2 - 4), 12, innerPaint);

    // Pin tail
    final tailPath = Path()
      ..moveTo(size / 2 - 6, size / 2 + 14)
      ..lineTo(size / 2 + 6, size / 2 + 14)
      ..lineTo(size / 2, size / 2 + 28)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = selected ? Colors.white : color);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Draws a pulsing dot for the user's own position.
  Future<BitmapDescriptor> _buildUserDotBitmap() async {
    const size = 60.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Outer glow ring
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      22,
      Paint()
        ..color = const Color(0xFF10B981).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // White border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      14,
      Paint()..color = Colors.white,
    );
    // Green fill
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      10,
      Paint()..color = const Color(0xFF10B981),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // ── Route drawing ─────────────────────────────────────────────────────────
  /// Fetches the walking/driving route from user → doctor via Directions API
  /// and draws it as a styled polyline on the map.
  Future<void> _drawRoute(DoctorInfo doc) async {
    const apiKey = 'AIzaSyBEXp-KjZtn3XPb6S6FF7Z8Bm5onjVTk8I';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=\${_userLocation.latitude},\${_userLocation.longitude}'
        '&destination=\${doc.latitude},\${doc.longitude}'
        '&mode=driving'
        '&key=\$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      if (data['routes'].isEmpty) return;

      final points = _decodePolyline(
        data['routes'][0]['overview_polyline']['points'] as String,
      );

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: const Color(0xFF06B6D4),
            width: 4,
            patterns: [],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
          // Subtle shadow polyline underneath
          Polyline(
            polylineId: const PolylineId('route_shadow'),
            points: points,
            color: const Color(0xFF06B6D4).withOpacity(0.2),
            width: 10,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      });

      // Fit camera to show full route
      if (points.isNotEmpty && _mapController != null) {
        double minLat = points
            .map((p) => p.latitude)
            .reduce((a, b) => a < b ? a : b);
        double maxLat = points
            .map((p) => p.latitude)
            .reduce((a, b) => a > b ? a : b);
        double minLng = points
            .map((p) => p.longitude)
            .reduce((a, b) => a < b ? a : b);
        double maxLng = points
            .map((p) => p.longitude)
            .reduce((a, b) => a > b ? a : b);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat - 0.005, minLng - 0.005),
              northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
            ),
            60,
          ),
        );
      }
    } catch (_) {
      // Route failed silently — markers still visible
    }
  }

  /// Decodes Google's encoded polyline format into a list of LatLng points.
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  void _buildMarkers() {
    if (_doctors == null) return;
    final markers = <Marker>{};
    for (int i = 0; i < _doctors!.length; i++) {
      final doc = _doctors![i];
      final isSelected = i == _selectedIndex;
      markers.add(
        Marker(
          markerId: MarkerId('doc_$i'),
          position: LatLng(doc.latitude, doc.longitude),
          infoWindow: InfoWindow(
            title: doc.name,
            snippet: '${doc.distance.toStringAsFixed(1)} km away',
          ),
          icon: isSelected
              ? (_selectedMarkerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ))
              : (_doctorMarkerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueViolet,
                    )),
          anchor: const Offset(0.5, 1.0),
          onTap: () => _selectDoctor(i),
          zIndex: isSelected ? 5 : 1,
        ),
      );
    }
    setState(() => _markers = markers);
  }

  void _selectDoctor(int index) {
    setState(() => _selectedIndex = index);
    _buildMarkers();
    _addUserMarker(); // keep user dot on top
    final doc = _doctors![index];
    _drawRoute(doc); // draw route to selected doctor
  }

  /// Re-adds the user location dot marker (called after _buildMarkers rebuilds the set).
  void _addUserMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon:
            _userMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 0.5),
        zIndex: 10,
      ),
    );
    setState(() {});
  }

  void _openDirections(DoctorInfo doc) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${doc.latitude},${doc.longitude}',
    );
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ══════════════════════════════════════════════════════════════════════
          // MAP SECTION — full width, large, with overlaid app bar
          // ══════════════════════════════════════════════════════════════════════
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                // Google Map — AndroidView needs a concrete bounded size from parent.
                // Wrapping in LayoutBuilder ensures the platform view receives its
                // final size before it tries to render, preventing the setSize crash.
                LayoutBuilder(
                  builder: (context, constraints) => GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userLocation,
                      zoom: 13,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (ctrl) {
                      _mapController = ctrl;
                      ctrl.setMapStyle(_kDarkMapStyle);
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),

                // Top gradient (for status bar readability)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topPad + 70,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_C.bg.withOpacity(0.85), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Bottom gradient (blend into list)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [_C.bg, Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // ── Overlaid AppBar ─────────────────────────────────────────────
                Positioned(
                  top: topPad + 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _C.surface.withOpacity(0.9),
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
                      const SizedBox(width: 12),
                      // Title pill
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _C.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _C.cyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Nearby Dermatologists',
                                style: TextStyle(
                                  color: _C.textHi,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Refresh button
                      GestureDetector(
                        onTap: _loadNearbyDoctors,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _C.surface.withOpacity(0.9),
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
                ),

                // ── Result chip (if opened from scan) ──────────────────────────
                if (widget.detectionResult != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _C.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.biotech_rounded,
                            color: _C.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'For: ${widget.detectionResult!.diseaseName}',
                            style: const TextStyle(
                              color: _C.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ══════════════════════════════════════════════════════════════════════
          // LIST SECTION
          // ══════════════════════════════════════════════════════════════════════
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                ? _buildErrorState()
                : (_doctors == null || _doctors!.isEmpty)
                ? _buildEmptyState()
                : _buildDoctorList(),
          ),
        ],
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: 4,
      itemBuilder: (_, i) => const _DoctorCardSkeleton(),
    );
  }

  // ── Error ───────────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.red.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _C.red.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: _C.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Could not load doctors',
              style: TextStyle(
                color: _C.textHi,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.textMid, fontSize: 13),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _loadNearbyDoctors,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.primary, _C.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ───────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _C.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: _C.textLo,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No doctors found nearby',
            style: TextStyle(
              color: _C.textHi,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try expanding your search area',
            style: TextStyle(color: _C.textMid, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Doctor list ─────────────────────────────────────────────────────────────
  Widget _buildDoctorList() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _doctors!.length,
        itemBuilder: (context, index) => _DoctorCard(
          doctor: _doctors![index],
          isSelected: index == _selectedIndex,
          onTap: () => _selectDoctor(index),
          onDirections: () => _openDirections(_doctors![index]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Doctor Card — modern dark design
// ══════════════════════════════════════════════════════════════════════════════
class _DoctorCard extends StatelessWidget {
  final DoctorInfo doctor;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  const _DoctorCard({
    required this.doctor,
    required this.isSelected,
    required this.onTap,
    required this.onDirections,
  });

  // Generate consistent avatar color from name
  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(doctor.name);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _C.primary.withOpacity(0.06) : _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _C.primary.withOpacity(0.4) : _C.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _C.primary.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + name + badge ──────────────────────────────
            Row(
              children: [
                // Avatar circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      _initials(doctor.name),
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + specialty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          color: _C.textHi,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doctor.specialty ?? 'Dermatologist',
                        style: const TextStyle(color: _C.textMid, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Open / selected badge
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _C.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.primary.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Selected',
                      style: TextStyle(
                        color: _C.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Info row: rating · distance · address ───────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (doctor.rating != null)
                  _InfoChip(
                    icon: Icons.star_rounded,
                    label: doctor.rating is double
                        ? (doctor.rating as double).toStringAsFixed(1)
                        : doctor.rating.toString(),
                    iconColor: _C.amber,
                  ),

                if (doctor.distance > 0)
                  _InfoChip(
                    icon: Icons.near_me_rounded,
                    label: '${doctor.distance.toStringAsFixed(1)} km',
                    iconColor: _C.cyan,
                  ),

                if (doctor.address.isNotEmpty)
                  _InfoChip(
                    icon: Icons.location_on_rounded,
                    label: doctor.address,
                    iconColor: _C.textLo,
                    maxWidth: 200,
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Action buttons ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onDirections,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF0E7490)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.directions_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Directions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bookmark button (replaces call — no phone field on DoctorInfo)
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: _C.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      color: _C.green,
                      size: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Share / info button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: _C.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Icon(
                      Icons.open_in_new_rounded,
                      color: _C.textMid,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info chip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final double? maxWidth;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth!)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 11),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: _C.textMid, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton loading card ─────────────────────────────────────────────────────
class _DoctorCardSkeleton extends StatefulWidget {
  const _DoctorCardSkeleton();

  @override
  State<_DoctorCardSkeleton> createState() => _DoctorCardSkeletonState();
}

class _DoctorCardSkeletonState extends State<_DoctorCardSkeleton>
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

  Widget _bar(double width, double height) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _ctrl.value * 3, 0),
            end: Alignment(-0.5 + _ctrl.value * 3, 0),
            colors: const [
              Color(0xFF1A1A24),
              Color(0xFF2A2A3C),
              Color(0xFF1A1A24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment(-1.5 + _ctrl.value * 3, 0),
                      end: Alignment(-0.5 + _ctrl.value * 3, 0),
                      colors: const [
                        Color(0xFF1A1A24),
                        Color(0xFF2A2A3C),
                        Color(0xFF1A1A24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(140, 13),
                  const SizedBox(height: 8),
                  _bar(90, 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _bar(60, 28),
              const SizedBox(width: 8),
              _bar(80, 28),
              const SizedBox(width: 8),
              _bar(100, 28),
            ],
          ),
          const SizedBox(height: 14),
          _bar(double.infinity, 40),
        ],
      ),
    );
  }
}

// ── Dark Google Map Style ─────────────────────────────────────────────────────
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
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#12121a"}]}
]
''';
