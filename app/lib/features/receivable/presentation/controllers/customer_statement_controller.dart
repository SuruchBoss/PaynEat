import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/receivable.dart';
import '../../domain/repositories/receivable_repository.dart';
import '../../domain/usecases/receivable_usecases.dart';

/// บัญชีลูกหนี้ของลูกค้าหนึ่งราย — รับชำระหนี้ ออก/ยกเลิกใบวางบิล ยกเลิกใบเสร็จ
/// (ดู docs/tickets/20-b2b-credit.md)
class CustomerStatementController extends GetxController {
  CustomerStatementController({
    required GetCustomerStatementUseCase getStatement,
    required CreateArReceiptUseCase createReceipt,
    required GetArReceiptUseCase getReceipt,
    required VoidArReceiptUseCase voidReceipt,
    required CreateBillingNoteUseCase createBillingNote,
    required GetBillingNoteUseCase getBillingNote,
    required VoidBillingNoteUseCase voidBillingNote,
    required SessionService session,
    int? customerId,
  }) : _getStatement = getStatement,
       _createReceipt = createReceipt,
       _getReceipt = getReceipt,
       _voidReceipt = voidReceipt,
       _createBillingNote = createBillingNote,
       _getBillingNote = getBillingNote,
       _voidBillingNote = voidBillingNote,
       _session = session,
       _customerIdOverride = customerId;

  final GetCustomerStatementUseCase _getStatement;
  final CreateArReceiptUseCase _createReceipt;
  final GetArReceiptUseCase _getReceipt;
  final VoidArReceiptUseCase _voidReceipt;
  final CreateBillingNoteUseCase _createBillingNote;
  final GetBillingNoteUseCase _getBillingNote;
  final VoidBillingNoteUseCase _voidBillingNote;
  final SessionService _session;
  final int? _customerIdOverride;

  final Rxn<CustomerStatement> statement = Rxn<CustomerStatement>();
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  late final int customerId;

  /// ยกเลิกใบเสร็จ/ใบวางบิลได้เฉพาะผู้จัดการขึ้นไป (ตรงกับ receivable.routes.js)
  bool get canVoid => _session.currentUser?.isManagement ?? false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    customerId =
        _customerIdOverride ??
        (args is Map ? args['customerId'] as int? : null) ??
        0;
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    final result = await _getStatement(customerId);
    isLoading.value = false;
    result.fold(
      onSuccess: (data) => statement.value = data,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  /// รับชำระหนี้ — คืนใบเสร็จที่ออกให้ (null = ไม่สำเร็จ ข้อความผิดพลาดโชว์ไปแล้ว)
  Future<ArReceipt?> receivePayment({
    required double amount,
    required String method,
    String? reference,
    int? billingNoteId,
  }) async {
    isSubmitting.value = true;
    final result = await _createReceipt(
      CreateReceiptParams(
        customerId: customerId,
        amount: amount,
        method: method,
        reference: reference,
        billingNoteId: billingNoteId,
      ),
    );
    isSubmitting.value = false;
    final receipt = result.dataOrNull;
    if (receipt == null) {
      AppDialogs.error(result.failureOrNull!.message);
      return null;
    }
    AppDialogs.success(
      'receivable_receipt_success'.trParams({'no': receipt.receiptNo}),
    );
    await load();
    return receipt;
  }

  /// ออกใบวางบิลรวบทุกบิลค้างที่ยังไม่ได้วางบิล
  Future<BillingNote?> issueBillingNote({String? dueDate}) async {
    isSubmitting.value = true;
    final result = await _createBillingNote(
      CreateBillingNoteParams(customerId: customerId, dueDate: dueDate),
    );
    isSubmitting.value = false;
    final note = result.dataOrNull;
    if (note == null) {
      AppDialogs.error(result.failureOrNull!.message);
      return null;
    }
    AppDialogs.success(
      'receivable_billing_note_success'.trParams({'no': note.noteNo}),
    );
    await load();
    return note;
  }

  Future<ArReceipt?> fetchReceipt(int id) async {
    final result = await _getReceipt(id);
    return result.fold(
      onSuccess: (receipt) => receipt,
      onFailure: (failure) {
        AppDialogs.error(failure.message);
        return null;
      },
    );
  }

  Future<BillingNote?> fetchBillingNote(int id) async {
    final result = await _getBillingNote(id);
    return result.fold(
      onSuccess: (note) => note,
      onFailure: (failure) {
        AppDialogs.error(failure.message);
        return null;
      },
    );
  }

  Future<void> voidReceipt(int id, String reason) async {
    final result = await _voidReceipt(
      VoidDocumentParams(id: id, reason: reason),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      AppDialogs.error(failure.message);
      return;
    }
    AppDialogs.success('receivable_receipt_voided'.tr);
    await load();
  }

  Future<void> voidBillingNote(int id, String reason) async {
    final result = await _voidBillingNote(
      VoidDocumentParams(id: id, reason: reason),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      AppDialogs.error(failure.message);
      return;
    }
    AppDialogs.success('receivable_billing_note_voided'.tr);
    await load();
  }
}
