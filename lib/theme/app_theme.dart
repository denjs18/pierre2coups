import 'package:flutter/material.dart';

/// Thème TACTICAL DARK - Design professionnel pour application de tir
class AppTheme {
  // ========================================
  // PALETTE DE COULEURS TACTIQUES
  // ========================================

  // Backgrounds
  static const Color backgroundPrimary = Color(0xFF0F1419);
  static const Color backgroundSecondary = Color(0xFF1A1F29);
  static const Color surfaceColor = Color(0xFF1A1F29);

  // Accents
  static const Color accentPrimary = Color(0xFF2FA899); // Teal militaire
  static const Color accentSecondary = Color(0xFFFF6B35); // Orange tactique

  // Textes
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFFA8A8A8);

  // Bordures & Séparations
  static const Color borderColor = Color(0xFF2A2F3A);

  // États
  static const Color successColor = Color(0xFF2FA899);
  static const Color warningColor = Color(0xFFFF6B35);
  static const Color errorColor = Color(0xFFDC3545);

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
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
      ),

      // Boutons élevés (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: backgroundPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
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
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
      ),

      // Texte
      textTheme: const TextTheme(
        // Titres
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),

        // Titres de section
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),

        // Corps de texte
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

        // Labels
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.5,
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
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========================================
  // WIDGETS HELPERS
  // ========================================

  /// Badge pour les statistiques (teal)
  static BoxDecoration statsBadge() {
    return BoxDecoration(
      color: accentPrimary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// Badge pour les alertes (orange)
  static BoxDecoration alertBadge() {
    return BoxDecoration(
      color: accentSecondary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// Badge pour les erreurs (rouge)
  static BoxDecoration errorBadge() {
    return BoxDecoration(
      color: errorColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// Card highlight (session active)
  static BoxDecoration highlightCard() {
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accentPrimary, width: 2),
      boxShadow: [
        BoxShadow(
          color: accentPrimary.withOpacity(0.2),
          blurRadius: 20,
          spreadRadius: 0,
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
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );
}
