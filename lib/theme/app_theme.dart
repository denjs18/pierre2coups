import 'package:flutter/material.dart';

/// Thème CAMOUFLAGE OLIVE - Design militaire pour application de tir
class AppTheme {
  // ========================================
  // PALETTE CAMOUFLAGE OLIVE/VERT MILITAIRE
  // ========================================

  // Backgrounds
  static const Color backgroundPrimary = Color(0xFF1A1D14);   // olive très sombre
  static const Color backgroundSecondary = Color(0xFF252A1C); // olive sombre
  static const Color surfaceColor = Color(0xFF2B3020);        // olive medium

  // Accents
  static const Color accentPrimary = Color(0xFF8AB434);   // vert olive militaire
  static const Color accentSecondary = Color(0xFFD4A017); // or/laiton
  static const Color accentDanger = Color(0xFFC0392B);    // rouge alerte

  // Textes
  static const Color textPrimary = Color(0xFFE8EBDC);   // blanc kaki
  static const Color textSecondary = Color(0xFF9EA88A); // gris olive

  // Bordures
  static const Color borderColor = Color(0xFF3A4030); // olive border

  // Alias pour compatibilité
  static const Color successColor = accentPrimary;
  static const Color warningColor = accentDanger;
  static const Color errorColor = accentDanger;

  // ========================================
  // THÈME FLUTTER
  // ========================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Couleurs de base
      scaffoldBackgroundColor: backgroundPrimary,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: surfaceColor,
        background: backgroundPrimary,
        error: errorColor,
        onPrimary: backgroundPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textPrimary,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.4),
      ),

      // Boutons élevés (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: backgroundPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),

      // Boutons outlined (Secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          side: const BorderSide(color: accentPrimary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accentPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accentDanger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: borderColor),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
      ),

      // Texte
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 1,
        ),
      ),

      // Icons
      iconTheme: const IconThemeData(
        color: accentPrimary,
        size: 24,
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentPrimary,
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: borderColor),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========================================
  // WIDGET HELPERS
  // ========================================

  /// Badge pour les statistiques (vert olive)
  static BoxDecoration statsBadge() {
    return BoxDecoration(
      color: accentPrimary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: accentPrimary.withOpacity(0.3)),
    );
  }

  /// Badge pour les alertes (or)
  static BoxDecoration alertBadge() {
    return BoxDecoration(
      color: accentSecondary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: accentSecondary.withOpacity(0.3)),
    );
  }

  /// Badge pour les erreurs (rouge)
  static BoxDecoration errorBadge() {
    return BoxDecoration(
      color: accentDanger.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: accentDanger.withOpacity(0.3)),
    );
  }

  /// Card highlight (mission active)
  static BoxDecoration highlightCard() {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: accentPrimary, width: 2),
      boxShadow: [
        BoxShadow(
          color: accentPrimary.withOpacity(0.15),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Carte style camouflage militaire
  static BoxDecoration camoCard() {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borderColor, width: 1),
    );
  }

  /// Badge de mission (état opérationnel)
  static BoxDecoration missionBadge(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.5)),
    );
  }

  /// Barre de progression style militaire
  static Widget militaryProgressBar({
    required double value,
    Color? color,
    double height = 6,
  }) {
    final barColor = color ?? accentPrimary;
    return Stack(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  /// Style de texte pour les grands chiffres (stats)
  static const TextStyle statNumberStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: accentPrimary,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Style de texte pour les labels uppercase
  static const TextStyle labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 1,
  );
}
