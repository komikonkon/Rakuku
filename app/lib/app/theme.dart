import 'package:flutter/material.dart';

/// 確定UIトークン（要件定義書 §「UIルック」: Indigo × ライトモード）。
/// 出典: docs/requirements.md / prototype/index.html
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF4F46E5); // Indigo
  static const primaryWeak = Color(0xFFEEF2FF); // 強調背景・選択中チップ
  static const accent = Color(0xFF06B6D4); // 種別ラベル等の補助強調

  static const background = Color(0xFFEEF1F6); // 画面背景
  static const surface = Color(0xFFFFFFFF); // カード
  static const text = Color(0xFF1F2937); // 本文
  static const muted = Color(0xFF6B7280); // 補助テキスト
  static const border = Color(0xFFE5E7EB);

  // 学習ステータス4色
  static const statusLearned = Color(0xFF16A34A); // 覚えた
  static const statusVague = Color(0xFFCA8A04); // うろ覚え
  static const statusWeak = Color(0xFFDC2626); // 苦手
  static const statusNew = Color(0xFF64748B); // 未復習
}

ThemeData buildLightTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryWeak,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.statusWeak,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: null, // 端末標準（日本語含む）に追従
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.background,
      side: BorderSide(color: AppColors.border),
    ),
  );
}
