import 'package:flutter/material.dart';
import 'package:prepstation/app/theme/color_tokens.dart';
import 'package:prepstation/app/theme/typography.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ColorTokens.backgroundBase,
    colorScheme: const ColorScheme.dark(
      primary: ColorTokens.accentPrimary,
      onPrimary: ColorTokens.textInverse,
      secondary: ColorTokens.accentSecondary,
      onSecondary: ColorTokens.textPrimary,
      surface: ColorTokens.backgroundPanel,
      onSurface: ColorTokens.textPrimary,
      error: ColorTokens.error,
      onError: ColorTokens.textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorTokens.backgroundPanel,
      foregroundColor: ColorTokens.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headlineMedium,
    ),
    cardTheme: const CardThemeData(
      color: ColorTokens.backgroundSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: ColorTokens.borderSubtle,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(
      color: ColorTokens.textSecondary,
      size: 16,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: ColorTokens.backgroundElevated,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: Border.fromBorderSide(
          BorderSide(color: ColorTokens.borderDefault),
        ),
      ),
      textStyle: AppTypography.bodySmall,
      waitDuration: Duration(milliseconds: 500),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: ColorTokens.accentPrimary,
      inactiveTrackColor: ColorTokens.sliderTrack,
      thumbColor: ColorTokens.sliderThumb,
      overlayColor: Color(0x200A84FF),
      trackHeight: 3,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(ColorTokens.borderStrong),
      radius: const Radius.circular(3),
      thickness: WidgetStateProperty.all(3),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: ColorTokens.backgroundElevated,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: ColorTokens.borderDefault),
      ),
      textStyle: AppTypography.bodyMedium,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: ColorTokens.backgroundSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: ColorTokens.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: ColorTokens.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: ColorTokens.accentPrimary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: AppTypography.caption,
      hintStyle: AppTypography.caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorTokens.accentPrimary,
        foregroundColor: Colors.white,
        textStyle: AppTypography.labelLarge,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(64, 36),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorTokens.accentPrimary,
        textStyle: AppTypography.labelLarge,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(40, 32),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorTokens.textPrimary,
        side: const BorderSide(color: ColorTokens.borderDefault),
        textStyle: AppTypography.labelLarge,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(64, 36),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: ColorTokens.backgroundPanel,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ColorTokens.backgroundElevated,
      contentTextStyle: AppTypography.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
