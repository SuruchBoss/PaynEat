import 'package:flutter/widgets.dart';

/// ตัวช่วยทำ layout ให้เหมาะกับอุปกรณ์
/// มือถือ (พนักงานเสิร์ฟ) / แท็บเล็ต (จุดรับออเดอร์) / เว็บ-เดสก์ท็อป (ผู้ดูแลระบบ)
enum DeviceType { mobile, tablet, desktop }

class Responsive {
  const Responsive._();

  static const double tabletBreakpoint = 720;
  static const double desktopBreakpoint = 1100;

  static DeviceType of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return DeviceType.desktop;
    if (width >= tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) => of(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => of(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => of(context) == DeviceType.desktop;
  static bool isWide(BuildContext context) => of(context) != DeviceType.mobile;

  /// เลือกค่าตามขนาดจอ — ใช้กับจำนวนคอลัมน์ grid, ระยะ padding ฯลฯ
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      switch (of(context)) {
        DeviceType.desktop => desktop ?? tablet ?? mobile,
        DeviceType.tablet => tablet ?? mobile,
        DeviceType.mobile => mobile,
      };

  /// จำนวนคอลัมน์ของ grid ที่คำนวณจากความกว้างที่เหลือจริง
  static int gridColumns(double width, {double minTileWidth = 180}) {
    final columns = (width / minTileWidth).floor();
    return columns < 1 ? 1 : columns;
  }
}
