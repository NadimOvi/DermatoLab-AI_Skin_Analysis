import 'package:flutter/material.dart';

// ⚠️ RENAMED from AppColors → LegacyAppColors to avoid clash with new app_theme.dart
// Used by: detection_screen.dart, history_screen.dart, doctor_list_screen.dart, result_screen.dart
class LegacyAppColors {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF7F7FC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color successColor = Color(0xFF00B894);
  static const Color warningColor = Color(0xFFFDCB6E);
  static const Color errorColor = Color(0xFFFF7675);
}

class AppStrings {
  static const String appName = 'DermatoLab';
  static const String infoTab = 'Info';
  static const String detectTab = 'Detect';
  static const String historyTab = 'History';

  // Info Screen
  static const String recentDiseaseInfo = 'Recent Skin Disease Info';
  static const String learMore = 'Learn More';

  // Detection Screen
  static const String scanSkin = 'Scan Your Skin';
  static const String takePhoto = 'Take Photo';
  static const String chooseGallery = 'Choose from Gallery';
  static const String analyzing = 'Analyzing...';

  // Result Screen
  static const String results = 'Results';
  static const String confidence = 'Confidence';
  static const String treatment = 'AI Recommendations';
  static const String findDoctors = 'Find Nearby Doctors';
  static const String saveToHistory = 'Save to History';

  // History Screen
  static const String scanHistory = 'Scan History';
  static const String noHistory = 'No scan history yet';
  static const String startScanning = 'Start scanning to see your history';

  // Errors
  static const String errorLoadingModel = 'Error loading ML model';
  static const String errorProcessingImage = 'Error processing image';
  static const String errorPermission = 'Permission denied';
  static const String errorLocation = 'Unable to get location';
}

class DiseaseLabels {
  static const Map<String, String> labels = {
    'akiec': 'Actinic Keratoses',
    'bcc': 'Basal Cell Carcinoma',
    'bkl': 'Benign Keratosis',
    'df': 'Dermatofibroma',
    'mel': 'Melanoma',
    'nv': 'Melanocytic Nevi',
    'vasc': 'Vascular Lesions',
  };

  static const Map<String, String> descriptions = {
    'akiec':
        'Actinic keratoses and intraepithelial carcinoma are common non-invasive variants of squamous cell carcinoma that can be treated locally without surgery.',
    'bcc':
        'Basal cell carcinoma is a common variant of epithelial skin cancer that rarely metastasizes but grows destructively if untreated.',
    'bkl':
        'Benign keratosis-like lesions include solar lentigines, seborrheic keratoses and lichen-planus like keratoses. These are harmless skin lesions.',
    'df':
        'Dermatofibroma is a benign skin lesion regarded as either a benign proliferation or an inflammatory reaction to minimal trauma.',
    'mel':
        'Melanoma is a malignant neoplasm derived from melanocytes. If excised in an early stage it can be cured by simple surgical excision.',
    'nv':
        'Melanocytic nevi are benign neoplasms of melanocytes that appear in various variants and are generally harmless.',
    'vasc':
        'Vascular lesions range from cherry angiomas to angiokeratomas and pyogenic granulomas. These are usually benign.',
  };

  static const Map<String, Color> colors = {
    'akiec': Color(0xFFFF6B6B),
    'bcc': Color(0xFFFF8C42),
    'bkl': Color(0xFF95E1D3),
    'df': Color(0xFF38ADA9),
    'mel': Color(0xFFEE5A6F),
    'nv': Color(0xFF4ECDC4),
    'vasc': Color(0xFFC44569),
  };

  static const Map<String, IconData> icons = {
    'akiec': Icons.warning_amber_rounded,
    'bcc': Icons.dangerous_outlined,
    'bkl': Icons.check_circle_outline,
    'df': Icons.healing_outlined,
    'mel': Icons.error_outline,
    'nv': Icons.star_border_purple500_outlined,
    'vasc': Icons.favorite_border,
  };
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
}

class ModelConstants {
  static const String modelPath = 'assets/models/skin_disease_model.tflite';
  static const String labelsPath = 'assets/models/labels.txt';
  static const int inputSize = 224;
  static const int numChannels = 3;
  static const int numClasses = 7;
  static const double confidenceThreshold = 0.5;
}
