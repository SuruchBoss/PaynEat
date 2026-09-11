import 'package:flutter/material.dart';

/// ครอบรายการแนวนอนให้ขอบด้านที่ยัง "เลื่อนต่อได้" จางลง
///
/// แถบกรอง (โซนโต๊ะ / หมวดหมู่เมนู) ถูกตัดพอดีขอบจอบนมือถือ ทำให้ดูเหมือนมีแค่
/// ตัวเลือกที่เห็นอยู่ พนักงานที่ไม่เคยลากดูจะไม่รู้ว่ายังมีต่อ — เงาจางที่ขอบ
/// เป็นสัญญาณมาตรฐานที่บอกเรื่องนี้ได้โดยไม่กินพื้นที่เพิ่มเลย
class HorizontalFade extends StatefulWidget {
  const HorizontalFade({super.key, required this.builder});

  /// สร้างรายการแนวนอน โดยต้องผูก [ScrollController] ที่ได้รับเข้ากับตัว list
  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  @override
  State<HorizontalFade> createState() => _HorizontalFadeState();
}

class _HorizontalFadeState extends State<HorizontalFade> {
  final ScrollController _controller = ScrollController();
  bool _fadeStart = false;
  bool _fadeEnd = false;

  @override
  void initState() {
    super.initState();
    // ต้องรอให้วาดเสร็จก่อนถึงจะรู้ว่าเนื้อหายาวเกินจอหรือไม่
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final fadeStart = position.pixels > 1;
    final fadeEnd = position.pixels < position.maxScrollExtent - 1;
    if (fadeStart != _fadeStart || fadeEnd != _fadeEnd) {
      setState(() {
        _fadeStart = fadeStart;
        _fadeEnd = fadeEnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const opaque = Color(0xFFFFFFFF);
    const clear = Color(0x00FFFFFF);

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _fadeStart ? clear : opaque,
          opaque,
          opaque,
          _fadeEnd ? clear : opaque,
        ],
        stops: const [0, 0.05, 0.93, 1],
      ).createShader(rect),
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _sync();
          return false;
        },
        child: widget.builder(context, _controller),
      ),
    );
  }
}
