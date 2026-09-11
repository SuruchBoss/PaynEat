import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _PaynEatLints();

class _PaynEatLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    TextStyleNeedsFontFamily(),
    UseAppClockNotDateTimeNow(),
    UseInkColorForForeground(),
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

/// ดัก `DateTime.now()` / `DateTime.timestamp()` ที่เรียกตรง ๆ แทนที่จะผ่าน `AppClock`
///
/// ทำไมต้องมีกฎนี้ — ภาพหน้าจอในเอกสารถูกถ่ายด้วย golden test แล้วคอมมิตลง git
/// ถ้าโค้ดที่ผลลัพธ์บนจอขึ้นกับเวลาปัจจุบันเรียก `DateTime.now()` ตรง ๆ ภาพที่ถ่าย
/// ซ้ำจะได้ไฟล์ไม่เหมือนเดิมทุกครั้ง (เวลาบนการ์ดออเดอร์เลื่อนไปเรื่อย ๆ) กลายเป็น
/// diff ปลอมที่แยกไม่ออกว่าอันไหนคือการเปลี่ยนแปลงจริงของ UI
///
/// เคยเกิดจริงแล้วสองชั้น: ครั้งแรกภาพ 4-6 ภาพดิ้นทุกรอบที่ถ่าย พอไล่แก้ในแอปจนหมด
/// ก็ยังเหลือจอครัวดิ้นอยู่ เพราะตัวสคริปต์ถ่ายภาพเองยัง backdate ตั๋วด้วยนาฬิกาจริง
/// ขณะที่ "ตอนนี้" ถูกตรึงไว้แล้ว ตั๋วทุกใบเลยขึ้น "11 ชม. 56 นาที" เหมือนกันหมด
/// จนแถบเตือนของช้าสีแดงไม่มีความหมาย — บั๊กที่มองด้วยตาไม่เห็นว่าผิด
///
/// เขียนแบบที่ถูกต้อง:
///
/// ```dart
/// final now = AppClock.now();
/// ```
///
/// ถ้าจุดนั้นต้องใช้นาฬิกาจริงจริง ๆ (เช่นออก id ที่ต้องไม่ซ้ำ ซึ่งถ้าเวลาถูกตรึง
/// จะได้ค่าเดียวกันหมด) ให้ปิดกฎเป็นบรรทัด ๆ ไปพร้อมเขียนเหตุผลกำกับ:
///
/// ```dart
/// // ignore: use_app_clock_not_date_time_now
/// id: '${DateTime.now().microsecondsSinceEpoch}',
/// ```
class UseAppClockNotDateTimeNow extends DartLintRule {
  const UseAppClockNotDateTimeNow() : super(code: _code);

  static const _code = LintCode(
    name: 'use_app_clock_not_date_time_now',
    problemMessage:
        'เรียก DateTime.now() ตรง ๆ ทำให้ตรึงเวลาตอนถ่ายภาพหน้าจอ/เขียนเทสต์ไม่ได้ '
        'ภาพที่ถ่ายซ้ำจะได้ไฟล์ไม่เหมือนเดิมทุกครั้ง กลายเป็น diff ปลอมใน git',
    correctionMessage:
        'ใช้ AppClock.now() แทน — ถ้าจำเป็นต้องใช้นาฬิกาจริง '
        '(เช่นออก id ที่ต้องไม่ซ้ำ) ให้ใส่ // ignore: use_app_clock_not_date_time_now '
        'พร้อมเหตุผลกำกับ',
  );

  /// ตัวสร้างของ DateTime ที่อ่านค่านาฬิกา ณ ตอนนั้น
  /// `timestamp()` คือฝาแฝดแบบ UTC ของ `now()` จึงมีปัญหาเดียวกันเป๊ะ
  static const _clockConstructors = {'now', 'timestamp'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // ไฟล์ที่นิยาม AppClock เองต้องเรียกนาฬิกาจริง ไม่งั้นก็ไม่มีอะไรให้ห่อ
    if (_isAppClockItself(resolver.path)) return;

    // เทสต์สร้างเวลาสมมติจากนาฬิกาจริงได้ตามปกติ (เช่น "เมื่อ 20 นาทีที่แล้ว")
    // ผลลัพธ์ไม่ได้ถูกคอมมิตเป็นไฟล์ภาพ จึงไม่มีปัญหา diff ปลอม
    // กฎนี้เล็งไปที่โค้ดแอปกับสคริปต์ถ่ายภาพเป็นหลัก
    if (_isTestFile(resolver.path)) return;

    context.registry.addInstanceCreationExpression((node) {
      final constructor = node.constructorName;
      if (constructor.type.name2.lexeme != 'DateTime') return;
      if (!_clockConstructors.contains(constructor.name?.name)) return;

      reporter.atNode(node, _code);
    });
  }

  static bool _isAppClockItself(String path) =>
      path.replaceAll('\\', '/').endsWith('/lib/core/utils/app_clock.dart');

  static bool _isTestFile(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.contains('/test/') || normalized.endsWith('_test.dart');
  }
}

/// ดักการเอา "สีสด" ของพาเลตต์ไปใช้เป็นสีตัวหนังสือ/ไอคอน แทนที่จะใช้เฉด `*Ink`
///
/// ทำไมต้องมีกฎนี้ — บั๊กนี้เกิดซ้ำสามรอบในโปรเจกต์นี้ และทุกรอบหลุดสายตาไปได้
/// เพราะ "ดูแล้วก็อ่านออกอยู่" บนจอสะอาดในร่ม แต่วัดจริงแล้วไม่ผ่านเกณฑ์:
///
/// | รอบ | จุดที่พัง | คอนทราสต์ |
/// |---|---|---|
/// | 1 | ตัวเลขเงินและป้ายสถานะ | ส้ม 2.8:1 |
/// | 2 | ชิปตัวกรองที่ถูกเลือกทั้งแอป | เหลือง 2.1:1 |
/// | 3 | ปุ่มเดินสถานะจอครัว หัวคอลัมน์ครัว และไอคอนใน StatCard | เหลือง 1.9:1 |
///
/// สีสดในพาเลตต์ออกแบบมาเป็น "พื้น/จุด/ขอบ" ซึ่งสว่างเกินกว่าจะเป็นตัวหนังสือ
/// บนพื้นสว่างได้ ชุด `*Ink` คือเฉดเข้มของสีเดียวกันที่ตรวจแล้วว่าผ่านเกณฑ์
/// บนทุกพื้นที่ถูกใช้จริง ไม่ใช่แค่บนพื้นขาว
///
/// อีกเหตุผลหนึ่ง: สีสดเป็น `const` ไม่เปลี่ยนตามโหมดคอนทราสต์สูง ส่วน `*Ink`
/// เป็น getter ที่เข้มขึ้นตามโหมด ถ้าใช้สีสดเป็นตัวหนังสือ โหมดคอนทราสต์สูง
/// จะไม่มีผลกับจุดนั้นเลย
///
/// ```dart
/// // ❌ กฎจะเตือน
/// Text('ช้า', style: TextStyle(color: AppColors.warning))
/// Icon(Icons.timer, color: AppColors.primary)
///
/// // ✅ ผ่าน
/// Text('ช้า', style: TextStyle(color: AppColors.warningInk))
/// Icon(Icons.timer, color: AppColors.brandInk)
/// Icon(Icons.timer, color: AppColors.inkOf(statusColor))  // สีมาจากตัวแปร
///
/// // ✅ ผ่าน — เป็นพื้น/จุด/ขอบ ไม่ใช่ตัวหนังสือ จึงใช้สีสดได้ถูกต้องแล้ว
/// BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)
/// ```
class UseInkColorForForeground extends DartLintRule {
  const UseInkColorForForeground() : super(code: _code);

  static const _code = LintCode(
    name: 'use_ink_color_for_foreground',
    problemMessage:
        'สีสดในพาเลตต์ออกแบบมาเป็นพื้น/จุด/ขอบ ไม่ใช่ตัวหนังสือ — '
        'เอามาเป็นสีตัวหนังสือหรือไอคอนแล้วคอนทราสต์ไม่ถึงเกณฑ์ WCAG '
        'และไม่เข้มขึ้นตามโหมดคอนทราสต์สูงด้วย เพราะเป็น const',
    correctionMessage:
        'ใช้เฉด *Ink ของสีเดียวกัน (เช่น warningInk แทน warning) '
        'หรือ AppColors.inkOf(...) ถ้าสีมาจากตัวแปร',
  );

  /// สีสดที่ห้ามเอาไปเป็นตัวหนังสือ/ไอคอน
  ///
  /// `purple` ตัวเดียวที่ผ่านเกณฑ์ตัวหนังสือได้เองโดยไม่ต้องแปลง แต่ยังดักไว้
  /// เพื่อให้กฎอ่านง่ายและได้สีที่เข้มขึ้นตามโหมดคอนทราสต์สูงไปด้วย
  static const _vivid = {
    'primary',
    'secondary',
    'success',
    'warning',
    'danger',
    'info',
    'purple',
  };

  /// ชื่อพารามิเตอร์ที่หมายถึง "สีของสิ่งที่ต้องอ่าน"
  static const _foregroundSlots = {'color', 'foregroundColor', 'iconColor'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // ไฟล์ที่นิยามพาเลตต์เองต้องอ้างถึงสีสดตรง ๆ อยู่แล้ว
    if (resolver.path.replaceAll('\\', '/').endsWith('/app_colors.dart')) {
      return;
    }

    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name != 'AppColors') return;
      if (!_vivid.contains(node.identifier.name)) return;

      final slot = node.parent;
      if (slot is! NamedExpression) return;
      if (!_foregroundSlots.contains(slot.name.label.name)) return;
      if (!_isForegroundContext(slot)) return;

      reporter.atNode(node, _code);
    });
  }

  /// สีนี้ถูกส่งเข้า TextStyle หรือ Icon หรือไม่
  ///
  /// จงใจดูเฉพาะสองตัวนี้ ไม่ดัก `color:` ทุกที่ เพราะ `BoxDecoration(color:)`
  /// กับ `Container(color:)` คือ "พื้น" ซึ่งใช้สีสดได้ถูกต้องแล้ว
  /// ถ้าดักกว้างกว่านี้จะได้ false positive เป็นสิบจุดแล้วคนจะปิดกฎทิ้ง
  static bool _isForegroundContext(NamedExpression argument) {
    final invocation = argument.parent?.parent;
    if (invocation is InstanceCreationExpression) {
      final name = invocation.constructorName.type.name2.lexeme;
      return name == 'TextStyle' || name == 'Icon' || name == 'ImageIcon';
    }
    if (invocation is MethodInvocation) {
      // ปุ่มทุกชนิด: FilledButton.styleFrom(foregroundColor: ...)
      return invocation.methodName.name == 'styleFrom' &&
          argument.name.label.name != 'color';
    }
    return false;
  }
}
