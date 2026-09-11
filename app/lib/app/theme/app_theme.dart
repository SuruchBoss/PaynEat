import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// ธีมกลางของแอป — เขียนครั้งเดียวแล้วทุกหน้าจอหน้าตาสอดคล้องกัน
class AppTheme {
  const AppTheme._();

  /// ฟอนต์หลักของแอป — ต้องตรงกับชื่อ family ใน `pubspec.yaml`
  /// เครื่องมือถ่ายภาพหน้าจอ (`tool/screenshots`) ก็ลงทะเบียนฟอนต์ด้วยชื่อนี้
  /// ภาพในเอกสารจึงตรงกับที่ผู้ใช้เห็นจริง
  static const String fontFamily = 'NotoSansThai';

  /// ตัวเลขเงินก้อนใหญ่ที่ต้องอ่านให้ถูกในครั้งเดียว (เงินทอน / ยอดสุทธิ)
  /// รวมไว้ที่เดียวเพราะก่อนหน้านี้หน้าเก็บเงินกับหน้าแยกบิลใช้คนละขนาด (22 กับ 20)
  /// สีปล่อยให้ผู้เรียกกำหนดเอง แล้วแต่ว่าเป็นยอดรับหรือยอดทอน
  static const TextStyle moneyLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    // สร้างธีมฐานก่อน เพื่อให้ component theme ด้านล่างหยิบ TextStyle จาก textTheme ไปต่อยอดได้
    //
    // สำคัญ: ButtonStyle/ChipTheme จะ "แทนที่" TextStyle ทั้งก้อน ไม่ใช่การ merge
    // ถ้ากำหนด TextStyle เปล่า ๆ ลงไป ฟอนต์ของปุ่มจะหลุดไปใช้ค่า default ของแต่ละแพลตฟอร์ม
    // ทำให้หน้าตาไม่ตรงกันระหว่าง Android / iOS / Web จึงต้อง copyWith จากของเดิมเสมอ
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      // ตั้งที่ ThemeData ชั้นนี้จุดเดียว ทุก TextStyle ที่ copyWith ต่อจาก textTheme
      // จะได้ฟอนต์นี้ไปด้วยอัตโนมัติ (ดูฟอนต์ที่ฝังไว้ใน pubspec.yaml)
      fontFamily: fontFamily,
      textTheme: _textTheme,
    );

    final text = base.textTheme;

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleMedium?.copyWith(fontSize: 18),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary, width: 1.6),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.6),
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.textDisabled),
        labelStyle: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: text.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: text.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        labelStyle: text.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        backgroundColor: AppColors.surface,
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );

  static const TextTheme _textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(fontSize: 15, color: AppColors.textPrimary),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimary),
    bodySmall: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}
