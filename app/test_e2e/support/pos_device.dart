import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/api_client.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/audit_log/data/datasources/audit_log_remote_data_source.dart';
import 'package:payneat_pos/features/audit_log/data/repositories/audit_log_repository_impl.dart';
import 'package:payneat_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:payneat_pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:payneat_pos/features/auth/domain/entities/login_result.dart';
import 'package:payneat_pos/features/auth/domain/entities/user.dart';
import 'package:payneat_pos/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:payneat_pos/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:payneat_pos/features/ingredient/data/datasources/ingredient_remote_data_source.dart';
import 'package:payneat_pos/features/ingredient/data/repositories/ingredient_repository_impl.dart';
import 'package:payneat_pos/features/menu/data/datasources/menu_remote_data_source.dart';
import 'package:payneat_pos/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:payneat_pos/features/order/data/datasources/order_remote_data_source.dart';
import 'package:payneat_pos/features/order/data/repositories/order_repository_impl.dart';
import 'package:payneat_pos/features/payment/data/datasources/payment_remote_data_source.dart';
import 'package:payneat_pos/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:payneat_pos/features/receivable/data/datasources/receivable_remote_data_source.dart';
import 'package:payneat_pos/features/receivable/data/repositories/receivable_repository_impl.dart';
import 'package:payneat_pos/features/report/data/datasources/report_remote_data_source.dart';
import 'package:payneat_pos/features/report/data/repositories/report_repository_impl.dart';
import 'package:payneat_pos/features/scale/data/datasources/scale_remote_data_source.dart';
import 'package:payneat_pos/features/scale/data/repositories/scale_repository_impl.dart';
import 'package:payneat_pos/features/self_order/data/datasources/self_order_remote_data_source.dart';
import 'package:payneat_pos/features/self_order/data/repositories/self_order_repository_impl.dart';
import 'package:payneat_pos/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:payneat_pos/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:payneat_pos/features/shift/data/datasources/shift_remote_data_source.dart';
import 'package:payneat_pos/features/shift/data/repositories/shift_repository_impl.dart';
import 'package:payneat_pos/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:payneat_pos/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:payneat_pos/features/table/data/datasources/table_remote_data_source.dart';
import 'package:payneat_pos/features/table/data/repositories/table_repository_impl.dart';
import 'package:payneat_pos/features/tax_invoice/data/datasources/tax_invoice_remote_data_source.dart';
import 'package:payneat_pos/features/tax_invoice/data/repositories/tax_invoice_repository_impl.dart';

/// "เครื่องหนึ่งเครื่องในร้าน" — มือถือพนักงานเสิร์ฟ แท็บเล็ตครัว เครื่องแคชเชียร์ หรือมือถือลูกค้า
///
/// ประกอบ object graph ชุดเดียวกับที่แอปจริงประกอบตอนเปิดเครื่องทุกชั้น (ดู
/// `lib/app/di/bindings/core_bindings.dart`, `data_source_bindings.dart`, `repository_bindings.dart`):
/// `ApiClient(tokenProvider: () => storage.token)` → `XxxRemoteDataSourceImpl(client)` →
/// `XxxRepositoryImpl(remote)` ต่างกันแค่ไม่ผ่าน GetX และ storage อยู่ในหน่วยความจำ
///
/// แต่ละบทบาทใช้เครื่องของตัวเองเสมอ (session แยกกันจริงเหมือนในร้าน) — token ที่ได้จาก login
/// ถูกเก็บลง storage โดย `AuthRepositoryImpl` แล้ว `ApiClient` หยิบไปแนบเองทุก request ตามกลไก
/// เดียวกับของจริง ไม่มีการยัด header เองในเทสต์
class PosDevice {
  /// [language] = ภาษาที่เครื่องนี้แสดงอยู่ (ส่งเป็น Accept-Language) — ไม่ระบุ = ไม่ส่ง
  /// ได้ข้อความไทยเหมือนเดิม เทสต์เดิมที่เทียบข้อความไทยจึงไม่ต้องแก้
  PosDevice(String apiBaseUrl, {String? language}) {
    final dio = Dio();
    client = ApiClient(
      dio: dio,
      tokenProvider: () => storage.token,
      onUnauthorized: () => unauthorizedCount++,
      languageProvider: () => language,
    );
    // ApiClient ตั้ง baseUrl จาก AppConfig (compile-time) ในคอนสตรักเตอร์ แต่พอร์ตของ backend
    // ในเทสต์สุ่มตอนรัน จึงทับหลังสร้างแทน — ถือ Dio ตัวเดียวกันอยู่ จึงมีผลกับทุก request
    dio.options.baseUrl = apiBaseUrl;
    // LogInterceptor ถูกเปิดเพราะ kDebugMode เป็นจริงในเทสต์ — พ่น body ทุก response ออก console
    // จนหาบรรทัดที่เทสต์ล้มไม่เจอ ตัดทิ้งเฉพาะตัวนี้ interceptor แนบ token ยังอยู่ครบ
    dio.interceptors.removeWhere(
      (interceptor) => interceptor is LogInterceptor,
    );

    auth = AuthRepositoryImpl(
      remote: AuthRemoteDataSourceImpl(client),
      storage: storage,
    );
    tables = TableRepositoryImpl(TableRemoteDataSourceImpl(client));
    menu = MenuRepositoryImpl(MenuRemoteDataSourceImpl(client));
    orders = OrderRepositoryImpl(OrderRemoteDataSourceImpl(client));
    payments = PaymentRepositoryImpl(PaymentRemoteDataSourceImpl(client));
    shifts = ShiftRepositoryImpl(ShiftRemoteDataSourceImpl(client));
    reports = ReportRepositoryImpl(ReportRemoteDataSourceImpl(client));
    selfOrder = SelfOrderRepositoryImpl(SelfOrderRemoteDataSourceImpl(client));
    ingredients = IngredientRepositoryImpl(
      IngredientRemoteDataSourceImpl(client),
    );
    taxInvoices = TaxInvoiceRepositoryImpl(
      TaxInvoiceRemoteDataSourceImpl(client),
    );
    auditLogs = AuditLogRepositoryImpl(AuditLogRemoteDataSourceImpl(client));
    settings = SettingsRepositoryImpl(SettingsRemoteDataSourceImpl(client));
    staff = StaffRepositoryImpl(StaffRemoteDataSourceImpl(client));
    customers = CustomerRepositoryImpl(CustomerRemoteDataSourceImpl(client));
    receivables = ReceivableRepositoryImpl(
      ReceivableRemoteDataSourceImpl(client),
    );
    scale = ScaleRepositoryImpl(ScaleRemoteDataSourceImpl(client, socket));
  }

  final StorageService storage = StorageService.memory();
  late final ApiClient client;

  /// นับว่า [ApiClient] เรียก onUnauthorized ไปกี่ครั้ง — แอปจริงใช้ hook นี้เด้งกลับหน้า login
  int unauthorizedCount = 0;

  late final AuthRepositoryImpl auth;
  late final TableRepositoryImpl tables;
  late final MenuRepositoryImpl menu;
  late final OrderRepositoryImpl orders;
  late final PaymentRepositoryImpl payments;
  late final ShiftRepositoryImpl shifts;
  late final ReportRepositoryImpl reports;
  late final SelfOrderRepositoryImpl selfOrder;
  late final IngredientRepositoryImpl ingredients;
  late final TaxInvoiceRepositoryImpl taxInvoices;
  late final AuditLogRepositoryImpl auditLogs;
  late final SettingsRepositoryImpl settings;
  late final StaffRepositoryImpl staff;
  late final CustomerRepositoryImpl customers;
  late final ReceivableRepositoryImpl receivables;
  late final ScaleRepositoryImpl scale;

  /// socket.io ของเครื่องนี้ — ต่อเองด้วย [connectRealtime] หลังล็อกอิน (แอปจริงต่อใน SessionService)
  final SocketClient socket = SocketClient();

  /// ต่อ realtime ด้วย token ของผู้ใช้ที่ล็อกอินอยู่ แล้วรอจนต่อติดจริง
  Future<void> connectRealtime(String url) async {
    socket.connect(storage.token!, url: url);
    final started = Stopwatch()..start();
    while (!socket.isConnected) {
      if (started.elapsed > const Duration(seconds: 10)) {
        throw StateError('ต่อ socket.io ไม่ติดภายใน 10 วินาที');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// ล็อกอินผ่าน repository จริง — ถ้าผู้ใช้มีหลายสาขา backend จะตอบ pendingToken มาให้เลือกสาขา
  /// ก่อน (ticket 11) จึงเลือกสาขาตาม [branchCode] ต่อให้ในขั้นเดียว เหมือนผู้ใช้กดเลือกบนหน้าจอ
  Future<User> signIn(
    String username,
    String password, {
    String? branchCode,
  }) async {
    final login = expectOk(
      await auth.login(username: username, password: password),
      'login $username',
    );
    switch (login) {
      case LoginSuccess(:final user):
        return user;
      case LoginNeedsBranchSelection(:final pendingToken, :final branches):
        final branch = branchCode == null
            ? branches.first
            : branches.firstWhere(
                (b) => b.code == branchCode,
                orElse: () => fail(
                  '$username ไม่มีสิทธิ์สาขา $branchCode '
                  '(มี: ${branches.map((b) => b.code).join(', ')})',
                ),
              );
        final session = expectOk(
          await auth.selectBranch(token: pendingToken, branchId: branch.id),
          'select branch ${branch.code} for $username',
        );
        return session.user;
    }
  }
}

/// ดึงค่าจาก [Result] ที่ต้องสำเร็จ — ถ้าล้มจะ fail พร้อมข้อความจริงจาก backend (status code,
/// error code, field errors) ไม่ใช่แค่ "expected true" ที่ต้องไปไล่ debug ต่อเอง
T expectOk<T>(Result<T> result, String step) => result.fold(
  onSuccess: (data) => data,
  onFailure: (failure) => fail('[$step] ล้มเหลว: ${describeFailure(failure)}'),
);

/// คืน [Failure] จาก [Result] ที่ *ต้อง* ล้ม — ใช้กับเคสที่ตั้งใจทดสอบว่าระบบปฏิเสธถูกต้อง
Failure expectFailure<T>(Result<T> result, String step) => result.fold(
  onSuccess: (data) => fail('[$step] ควรถูกปฏิเสธ แต่สำเร็จ: $data'),
  onFailure: (failure) => failure,
);

String describeFailure(Failure failure) {
  final parts = <String>[failure.runtimeType.toString(), failure.message];
  if (failure is ServerFailure) {
    parts.add('status=${failure.statusCode}');
    if (failure.code != null) parts.add('code=${failure.code}');
  }
  final details = failure.details;
  if (details != null && details.isNotEmpty) {
    parts.add(details.map((d) => '${d.field}: ${d.message}').join('; '));
  }
  return parts.join(' | ');
}
