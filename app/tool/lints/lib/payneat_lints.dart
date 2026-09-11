import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _PaynEatLints();

class _PaynEatLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    TextStyleNeedsFontFamily(),
  ];
}

/// ดัก `TextStyle(...)` ที่สร้างขึ้นใหม่โดยไม่ระบุ `fontFamily`
/// ในตำแหน่งที่ Flutter จะเอาไป "แทนที่" สไตล์เดิมทั้งก้อน แทนที่จะ merge
///
/// ทำไมต้องมีกฎนี้ — เคยเกิดจริงในโปรเจกต์นี้สองครั้ง:
///
/// 1. ปุ่มเดินสถานะอาหารในหน้ารายละเอียดออเดอร์
/// 2. ป้ายชื่อเมนูบน NavigationRail ของแท็บเล็ต/เว็บ
///
/// ทั้งสองครั้งอักษรไทยกลายเป็นกล่องสี่เหลี่ยมบนหน้าจอจริง เพราะ property พวกนี้
/// ไม่ได้ merge สไตล์กับธีม พอส่ง TextStyle เปล่าที่ไม่มี fontFamily เข้าไป
/// ฟอนต์จึงหลุดไปใช้ค่า default ของแต่ละแพลตฟอร์มซึ่งไม่มีกลิฟไทยครบ
///
/// เขียนแบบที่ถูกต้องคือ copyWith ต่อจากสไตล์ของธีม:
///
/// ```dart
/// textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12.5)
/// ```
///
/// หรือระบุ fontFamily ตรง ๆ ถ้าอยู่ใน const context ที่เรียก Theme.of ไม่ได้:
///
/// ```dart
/// selectedLabelTextStyle: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13)
/// ```
class TextStyleNeedsFontFamily extends DartLintRule {
  const TextStyleNeedsFontFamily() : super(code: _code);

  static const _code = LintCode(
    name: 'text_style_needs_font_family',
    problemMessage:
        'TextStyle ตรงนี้จะถูกใช้ "แทนที่" สไตล์เดิมทั้งก้อน ไม่ใช่ merge '
        'ถ้าไม่ระบุ fontFamily ฟอนต์จะหลุดไปใช้ค่า default ของแพลตฟอร์ม '
        'แล้วอักษรไทยจะกลายเป็นกล่องสี่เหลี่ยม',
    correctionMessage:
        'ใช้ copyWith ต่อจาก Theme.of(context).textTheme.* '
        'หรือใส่ fontFamily: AppTheme.fontFamily ลงไปตรง ๆ',
  );

  /// จุดที่ Flutter เอา TextStyle ไปใช้ทั้งก้อนโดยไม่ merge กับธีม
  /// แยกตาม widget/ตัวสร้าง ไม่ได้ดูแค่ชื่อพารามิเตอร์ เพราะชื่อเดียวกันพฤติกรรมต่างกัน
  ///
  /// ทุกบรรทัดในนี้ตรวจจาก source ของ Flutter แล้วว่าเป็น `a ?? b ?? c`
  /// (เลือกอันใดอันหนึ่ง) ไม่ใช่ `.merge()` — ตัวอย่างที่จงใจ **ไม่** ใส่:
  ///
  /// - `Chip.labelStyle` → `labelStyle.merge(widget.labelStyle)` จึง merge ให้อยู่แล้ว
  /// - `TabBar.labelStyle` → `.merge(labelStyle ?? tabBarTheme.labelStyle)` เช่นกัน
  /// - `Text(style:)` / `TextSpan(style:)` → merge กับ DefaultTextStyle
  ///
  /// ถ้าดักกว้างกว่านี้จะได้ false positive เป็นสิบจุดตั้งแต่วันแรก
  /// แล้วคนก็จะปิดกฎทิ้ง ซึ่งแย่กว่าไม่มีกฎเลย
  ///
  /// เวลาจะเพิ่มรายการใหม่ ให้เปิด source ของ widget นั้นดูก่อนว่าใช้ `??` หรือ `.merge()`
  static const _replacingSlots = <String, Set<String>>{
    // ปุ่มทุกชนิด — ButtonStyle.textStyle ถูกเลือกทั้งก้อน ไม่ merge รายฟิลด์กับธีม
    // (เคสนี้คือบั๊ก F-01 ปุ่มเดินสถานะอาหาร)
    'styleFrom': {'textStyle'},
    'ButtonStyle': {'textStyle'},

    // NavigationRail — widget.X ?? theme.X ?? defaults.X
    // (เคสนี้คือบั๊กที่เกิดซ้ำรอบสอง ตอนทำ active state ของ sidebar ให้ชัดขึ้น)
    'NavigationRail': {'selectedLabelTextStyle', 'unselectedLabelTextStyle'},
    'NavigationRailThemeData': {
      'selectedLabelTextStyle',
      'unselectedLabelTextStyle',
    },

    // ListTile — titleTextStyle ?? tileTheme.titleTextStyle ?? defaults
    'ListTile': {
      'titleTextStyle',
      'subtitleTextStyle',
      'leadingAndTrailingTextStyle',
    },
    'ListTileThemeData': {
      'titleTextStyle',
      'subtitleTextStyle',
      'leadingAndTrailingTextStyle',
    },

    // AppBar — widget.titleTextStyle ?? appBarTheme.titleTextStyle ?? defaults
    'AppBar': {'titleTextStyle', 'toolbarTextStyle'},
    'SliverAppBar': {'titleTextStyle', 'toolbarTextStyle'},
    'AppBarTheme': {'titleTextStyle', 'toolbarTextStyle'},

    // SnackBar — snackBarTheme.contentTextStyle ?? defaults
    'SnackBarThemeData': {'contentTextStyle'},
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.type.name2.lexeme != 'TextStyle') return;

      final slot = node.parent;
      if (slot is! NamedExpression) return;

      final owner = _enclosingConstructorName(slot);
      if (owner == null) return;
      if (!(_replacingSlots[owner]?.contains(slot.name.label.name) ?? false)) {
        return;
      }

      final hasFontFamily = node.argumentList.arguments
          .whereType<NamedExpression>()
          .any(
            (argument) =>
                argument.name.label.name == 'fontFamily' ||
                argument.name.label.name == 'fontFamilyFallback',
          );
      if (hasFontFamily) return;

      reporter.atNode(node, _code);
    });
  }

  /// ชื่อ widget หรือเมธอดที่พารามิเตอร์นี้ถูกส่งเข้าไป
  ///
  /// `FilledButton.styleFrom(textStyle: ...)` คืน `styleFrom`
  /// ส่วน `NavigationRail(selectedLabelTextStyle: ...)` คืน `NavigationRail`
  static String? _enclosingConstructorName(NamedExpression argument) {
    final invocation = argument.parent?.parent;
    return switch (invocation) {
      InstanceCreationExpression() =>
        invocation.constructorName.type.name2.lexeme,
      MethodInvocation() => invocation.methodName.name,
      _ => null,
    };
  }
}
