import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../detection_screen.dart';
import '../history_screen.dart';
import '../doctor_list_screen.dart';
import '../info_screen.dart';
import 'learn_tab.dart';

class _C {
  static const bg = Color(0xFF0F0F14); // dark page bg
  static const surface = Color(0xFF1A1A24); // cards
  static const surfaceAlt = Color(0xFF22222F); // elevated surface
  static const primary = Color(0xFF6366F1); // indigo
  static const primaryLit = Color(0xFF818CF8); // lighter indigo
  static const accent = Color(0xFF8B5CF6); // violet
  static const pink = Color(0xFFEC4899); // pink accent
  static const green = Color(0xFF10B981); // success
  static const amber = Color(0xFFF59E0B); // warning
  static const textHi = Color(0xFFF1F1F5); // primary text
  static const textMid = Color(0xFF8E8EA8); // secondary text
  static const textLo = Color(0xFF4A4A60); // disabled / border
  static const border = Color(0xFF252535); // dividers
}

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  int _tab = 0;

  static const _tabs = [
    _HomeTab(),
    const HistoryScreen(),
    const LearnTab(),
    _ProfilePlaceholder(),
  ];

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
      extendBody: true,
      body: IndexedStack(index: _tab, children: _tabs),

      bottomNavigationBar: _BottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        onCameraPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DetectionScreen()),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCameraPressed;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onCameraPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60, // fixed height — no overflow
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                index: 1,
                current: currentIndex,
                onTap: onTap,
              ),
              // Centre camera button
              _CameraButton(onPressed: onCameraPressed),
              _NavItem(
                icon: Icons.school_rounded,
                label: 'Learn',
                index: 2,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                current: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? _C.primary : _C.textLo),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? _C.primary : _C.textLo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CameraButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Center(
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_C.primary, _C.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// HOME TAB

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _Header()),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    label: 'Scans',
                    value: '124',
                    icon: Icons.document_scanner_rounded,
                    color: _C.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Accuracy',
                    value: '89%',
                    icon: Icons.analytics_rounded,
                    color: _C.pink,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Streak',
                    value: '7d',
                    icon: Icons.local_fire_department_rounded,
                    color: _C.amber,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(child: _SectionLabel('Quick Actions')),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(child: _QuickActions()),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Recent Scans'),
                Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 13,
                    color: _C.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: 5,
              itemBuilder: (_, i) => _ScanCard(
                disease: [
                  'Melanoma',
                  'Acne',
                  'Eczema',
                  'Rosacea',
                  'Psoriasis',
                ][i],
                date: ['2d ago', '5d ago', '1w ago', '2w ago', '3w ago'][i],
                confidence: [0.91, 0.78, 0.85, 0.62, 0.94][i],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(child: _HealthTip()),
        ),

        // Bottom padding (accounts for nav bar + safe area)
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// HEADER

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1040), Color(0xFF0F0F14)],
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_C.primary, _C.accent]),
            ),
            child: const Center(
              child: Text(
                'NM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(color: _C.textMid, fontSize: 13),
                ),
                const Text(
                  'Hi, Nadim Mahmud!',
                  style: TextStyle(
                    color: _C.textHi,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.border),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: _C.textMid,
                  size: 20,
                ),
              ),
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _C.pink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}

// STAT CARD

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: _C.textHi,
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
}

// QUICK ACTIONS

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(
        icon: Icons.camera_alt_rounded,
        label: 'Scan',
        color: _C.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DetectionScreen()),
        ),
      ),
      _QA(
        icon: Icons.history_rounded,
        label: 'History',
        color: _C.pink,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        ),
      ),
      _QA(
        icon: Icons.info_rounded,
        label: 'Diseases',
        color: _C.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InfoScreen()),
        ),
      ),
      _QA(
        icon: Icons.local_hospital_rounded,
        label: 'Doctors',
        color: _C.amber,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorListScreen()),
        ),
      ),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: GestureDetector(
                onTap: a.onTap,
                child: Container(
                  margin: EdgeInsets.only(right: a == actions.last ? 0 : 10),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _C.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: a.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(a.icon, color: a.color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.label,
                        style: const TextStyle(
                          color: _C.textHi,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QA({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// SCAN CARD (horizontal scroll)

class _ScanCard extends StatelessWidget {
  final String disease;
  final String date;
  final double confidence;

  const _ScanCard({
    required this.disease,
    required this.date,
    required this.confidence,
  });

  Color get _confColor {
    if (confidence >= 0.85) return _C.green;
    if (confidence >= 0.65) return _C.amber;
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: _C.surfaceAlt,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Icon(Icons.image_rounded, size: 32, color: _C.textLo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease,
                  style: const TextStyle(
                    color: _C.textHi,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(color: _C.textMid, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _confColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${(confidence * 100).toInt()}%',
                      style: TextStyle(
                        color: _confColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// HEALTH TIP

class _HealthTip extends StatelessWidget {
  const _HealthTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: _C.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Tip',
                  style: TextStyle(
                    color: _C.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Regular skin checks help detect issues early. Schedule monthly self-exams.',
                  style: TextStyle(
                    color: _C.textMid,
                    fontSize: 13,
                    height: 1.4,
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

// SECTION LABEL

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

// PLACEHOLDER TABS  (replace with real content later)

class _HistoryPlaceholder extends StatelessWidget {
  const _HistoryPlaceholder();
  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
    icon: Icons.history_rounded,
    title: 'Scan History',
    subtitle: 'Your past skin scans will appear here.',
  );
}

class _LearnPlaceholder extends StatelessWidget {
  const _LearnPlaceholder();
  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
    icon: Icons.school_rounded,
    title: 'Education',
    subtitle: 'Learn about skin conditions and care tips.',
  );
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();
  @override
  Widget build(BuildContext context) => const _PlaceholderPage(
    icon: Icons.person_rounded,
    title: 'Profile',
    subtitle: 'Manage your account and preferences.',
  );
}

class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _C.bg,
      child: Column(
        children: [
          SizedBox(height: top + 20),
          Expanded(
            child: Center(
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
                    child: Icon(icon, color: _C.primary, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _C.textHi,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _C.textMid, fontSize: 14),
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
