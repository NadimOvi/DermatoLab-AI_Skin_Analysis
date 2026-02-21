// ============================================================================
// main.dart — updated to use SplashScreen as entry point + dark theme
// ============================================================================

import 'package:dermatolabapp/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'blocs/detection/detection_bloc.dart';
import 'blocs/history/history_bloc.dart';
import 'blocs/info/info_bloc.dart';
import 'repositories/ml_repository.dart';
import 'repositories/disease_info_repository.dart';
import 'repositories/location_repository.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const DermatoLabApp());
}

class DermatoLabApp extends StatelessWidget {
  const DermatoLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => MLRepository()),
        RepositoryProvider(create: (context) => DiseaseInfoRepository()),
        RepositoryProvider(create: (context) => LocationRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                DetectionBloc(mlRepository: context.read<MLRepository>()),
          ),
          BlocProvider(create: (context) => HistoryBloc()),
          BlocProvider(
            create: (context) => InfoBloc(
              diseaseInfoRepository: context.read<DiseaseInfoRepository>(),
            )..add(LoadDiseaseInfo()),
          ),
        ],
        child: MaterialApp(
          title: 'DermatoLab',
          debugShowCheckedModeBanner: false,
          // ── Dark theme to match the dashboard's dark color system ──────────
          theme: _buildTheme(),
          // ── Start at splash, which auto-navigates to dashboard ────────────
          home: const SplashScreen(),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    const bg = Color(0xFF0F0F14);
    const surface = Color(0xFF1A1A24);
    const primary = Color(0xFF6366F1);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF8B5CF6),
        surface: surface,
        background: bg,
        onPrimary: Colors.white,
        onSurface: Color(0xFFF1F1F5),
        onBackground: Color(0xFFF1F1F5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Color(0xFFF1F1F5),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF8E8EA8)),
        bodyLarge: TextStyle(color: Color(0xFFF1F1F5)),
      ),
    );
  }
}
