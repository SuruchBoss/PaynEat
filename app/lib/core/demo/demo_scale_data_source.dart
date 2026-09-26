// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_data_sources.dart';

/// ตาชั่งจำลองในโหมดสาธิต (ดู docs/tickets/22-live-scale-camera-scan.md) — ลำดับเดียวกับ
/// `simulatorDriver` ฝั่ง backend: วางของ → ตัวเลขแกว่ง → นิ่ง → ยกออก วนไปเรื่อย ๆ
/// น้ำหนักวนตามรายการคงที่ (ไม่สุ่ม) เทสต์จึงรู้ล่วงหน้าว่าจะได้ค่าอะไร
class DemoScaleDataSource implements ScaleRemoteDataSource {
  DemoScaleDataSource({this.interval = const Duration(milliseconds: 400)});

  final Duration interval;

  static const List<int> targets = [485, 1250, 730];
  static const int _framesPerCycle = 20;

  int _tick = 0;

  ScaleStatus _status(ScaleReading reading) => ScaleStatus(
    enabled: true,
    driver: 'simulator',
    connected: true,
    reading: reading,
  );

  ScaleReading _frame() {
    final phase = _tick % _framesPerCycle;
    final target = targets[(_tick ~/ _framesPerCycle) % targets.length];
    _tick += 1;
    final now = AppClock.now();
    if (phase < 3) return ScaleReading(grams: 0, stable: true, at: now);
    if (phase < 6) {
      return ScaleReading(
        grams: (target * (0.7 + phase * 0.08)).round(),
        stable: false,
        at: now,
      );
    }
    if (phase < 17) return ScaleReading(grams: target, stable: true, at: now);
    return ScaleReading(grams: 20, stable: false, at: now);
  }

  @override
  Future<ScaleStatus> status() => _delayed(() => _status(_frame()));

  @override
  Stream<ScaleStatus> watch() =>
      Stream<ScaleStatus>.periodic(interval, (_) => _status(_frame()));
}
