import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF3F7F6);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF128C7E);
  static const primaryDark = Color(0xFF075E54);
  static const accent = Color(0xFF25D366);
  static const text = Color(0xFF111B21);
  static const muted = Color(0xFF667781);
  static const border = Color(0xFFE4E9E7);
  static const outgoing = Color(0xFFE7F6F1);
  static const incoming = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF0F4F3);
}

class AppGradients {
  static const header = LinearGradient(
    colors: [Color(0xFF075E54), Color(0xFF128C7E), Color(0xFF1FAF7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const background = LinearGradient(
    colors: [Color(0xFFF9FBFA), Color(0xFFE8F2EE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const floatingAction = LinearGradient(
    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const card = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF4FBF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
  );

  final textTheme = base.textTheme.apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.text,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.outgoing,
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
          fontFamily: 'Manrope',
        ),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: AppColors.muted),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.chip,
      labelStyle: const TextStyle(color: AppColors.primaryDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
  );
}

BoxDecoration buildGlassCardDecoration({
  Color color = AppColors.surface,
  double radius = 24,
  List<BoxShadow>? shadows,
  Gradient? gradient,
}) {
  return BoxDecoration(
    gradient: gradient ?? LinearGradient(colors: [color, color]),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: shadows ?? AppShadows.soft,
    border: Border.all(color: AppColors.border),
  );
}
