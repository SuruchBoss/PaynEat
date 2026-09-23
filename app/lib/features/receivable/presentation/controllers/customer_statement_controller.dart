import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/file_download/file_download.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/receivable.dart';
import '../../domain/repositories/receivable_repository.dart';
import '../../domain/usecases/receivable_usecases.dart';

/// บัญชีลูกหนี้ของลูกค้าหนึ่งราย — รับชำระหนี้ ออก/ยกเลิกใบวางบิล ยกเลิกใบเสร็จ
/// (ดู docs/tickets/20-b2b-credit.md) + คิด/ยกเลิกดอกเบี้ยผิดนัด ออกใบลดหนี้ (ticket 21)
/// และดาวน์โหลด PDF/ส่งเอกสารทางอีเมล (ticket 23)
class CustomerStatementController extends GetxController {
  CustomerStatementController({
    required GetCustomerStatementUseCase getStatement,
    required CreateArReceiptUseCase createReceipt,
    required GetArReceiptUseCase getReceipt,
    required VoidArReceiptUseCase voidReceipt,
    required CreateBillingNoteUseCase createBillingNote,
    required GetBillingNoteUseCase getBillingNote,
    required VoidBillingNoteUseCase voidBillingNote,
    required PreviewLateFeeUseCase previewLateFee,
    required CreateLateFeeUseCase createLateFee,
    required GetLateFeeUseCase getLateFee,
    required VoidLateFeeUseCase voidLateFee,
    required CreateCreditNoteUseCase createCreditNote,
    required GetCreditNoteUseCase getCreditNote,
    required DownloadReceivablePdfUseCase downloadPdf,
    required EmailReceivableDocumentUseCase emailDocument,
    required SessionService session,
    int? customerId,
  }) : _getStatement = getStatement,
       _previewLateFee = previewLateFee,
       _createLateFee = createLateFee,
       _getLateFee = getLateFee,
       _voidLateFee = voidLateFee,
       _createCreditNote = createCreditNote,
       _getCreditNote = getCreditNote,
       _downloadPdf = downloadPdf,
       _emailDocument = emailDocument,
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
  final PreviewLateFeeUseCase _previewLateFee;
  final CreateLateFeeUseCase _createLateFee;
  final GetLateFeeUseCase _getLateFee;
  final VoidLateFeeUseCase _voidLateFee;
  final CreateCreditNoteUseCase _createCreditNote;
  final GetCreditNoteUseCase _getCreditNote;
  final DownloadReceivablePdfUseCase _downloadPdf;
  final EmailReceivableDocumentUseCase _emailDocument;
  final SessionService _session;
  final int? _customerIdOverride;

  final Rxn<CustomerStatement> statement = Rxn<CustomerStatement>();
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  late final int customerId;

  /// ยกเลิกใบเสร็จ/ใบวางบิลได้เฉพาะผู้จัดการขึ้นไป (ตรงกับ receivable.routes.js)
  bool get canVoid => _session.currentUser?.isManagement ?? false;

  /// คิดดอกเบี้ย/ออกใบลดหนี้ = เปลี่ยนยอดหนี้ของลูกค้า — ผู้จัดการขึ้นไปเท่านั้น (receivable.routes.js)
  bool get canAdjustDebt => canVoid;

  /// PDF สร้างที่เซิร์ฟเวอร์ร้าน — โหมดสาธิตไม่มีเซิร์ฟเวอร์ และดาวน์โหลดไฟล์ได้เฉพาะบนเว็บ
  /// (แอปมือถือส่งอีเมลแทน) ดู docs/tickets/23-document-pdf-email.md
  bool get canDownloadPdf => !AppConfig.demoMode && isFileDownloadSupported;

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

  // ------------------------------------------------ ดอกเบี้ยผิดนัด (ticket 21) -----

  Future<LateFeePreview?> previewLateFee() async {
    final result = await _previewLateFee(customerId);
    final preview = result.dataOrNull;
    if (preview == null) AppDialogs.error(result.failureOrNull!.message);
    return preview;
  }

  Future<LateFeeCharge?> issueLateFee({String? note}) async {
    isSubmitting.value = true;
    final result = await _createLateFee(
      CreateLateFeeParams(customerId: customerId, note: note),
    );
    isSubmitting.value = false;
    final charge = result.dataOrNull;
    if (charge == null) {
      AppDialogs.error(result.failureOrNull!.message);
      return null;
    }
    AppDialogs.success(
      'receivable_late_fee_success'.trParams({'no': charge.chargeNo}),
    );
    await load();
    return charge;
  }

  Future<LateFeeCharge?> fetchLateFee(int id) async {
    final result = await _getLateFee(id);
    final charge = result.dataOrNull;
    if (charge == null) AppDialogs.error(result.failureOrNull!.message);
    return charge;
  }

  Future<void> voidLateFee(int id, String reason) async {
    final result = await _voidLateFee(
      VoidDocumentParams(id: id, reason: reason),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      AppDialogs.error(failure.message);
      return;
    }
    AppDialogs.success('receivable_late_fee_voided'.tr);
    await load();
  }

  // ------------------------------------------------------ ใบลดหนี้ (ticket 21) -----

  Future<CreditNote?> issueCreditNote({
    required int paymentId,
    required double amount,
    required String reason,
  }) async {
    isSubmitting.value = true;
    final result = await _createCreditNote(
      CreateCreditNoteParams(
        paymentId: paymentId,
        amount: amount,
        reason: reason,
      ),
    );
    isSubmitting.value = false;
    final note = result.dataOrNull;
    if (note == null) {
      AppDialogs.error(result.failureOrNull!.message);
      return null;
    }
    AppDialogs.success(
      'receivable_credit_note_success'.trParams({'no': note.noteNo}),
    );
    await load();
    return note;
  }

  Future<CreditNote?> fetchCreditNote(int id) async {
    final result = await _getCreditNote(id);
    final note = result.dataOrNull;
    if (note == null) AppDialogs.error(result.failureOrNull!.message);
    return note;
  }

  // ------------------------------------------------- PDF + อีเมล (ticket 23) -----

  Future<void> downloadPdf(
    ReceivableDocumentKind kind,
    int id,
    String number,
  ) async {
    final result = await _downloadPdf(ReceivableDocumentRef(kind, id));
    final bytes = result.dataOrNull;
    if (bytes == null) {
      AppDialogs.error(result.failureOrNull!.message);
      return;
    }
    downloadBytes('$number.pdf', bytes, 'application/pdf');
  }

  /// ส่งเอกสารทางอีเมล — คืนประวัติการส่งล่าสุด (null = ส่งไม่สำเร็จ ข้อความผิดพลาดโชว์ไปแล้ว)
  Future<List<DocumentEmail>?> emailDocument(
    ReceivableDocumentKind kind,
    int id, {
    String? to,
    String? message,
  }) async {
    final result = await _emailDocument(
      EmailDocumentParams(kind: kind, id: id, to: to, message: message),
    );
    final emails = result.dataOrNull;
    if (emails == null) {
      AppDialogs.error(result.failureOrNull!.message);
      return null;
    }
    AppDialogs.success(
      AppConfig.demoMode
          ? 'receivable_email_sent_demo'.trParams({
              'to': emails.isEmpty ? (to ?? '') : emails.first.to,
            })
          : 'receivable_email_sent'.trParams({
              'to': emails.isEmpty ? (to ?? '') : emails.first.to,
            }),
    );
    return emails;
  }
}
