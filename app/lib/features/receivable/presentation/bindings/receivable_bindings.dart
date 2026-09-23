import 'package:get/get.dart';

import '../../../../core/services/session_service.dart';
import '../../domain/usecases/receivable_usecases.dart';
import '../controllers/customer_statement_controller.dart';

class CustomerStatementBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      CustomerStatementController(
        getStatement: Get.find<GetCustomerStatementUseCase>(),
        createReceipt: Get.find<CreateArReceiptUseCase>(),
        getReceipt: Get.find<GetArReceiptUseCase>(),
        voidReceipt: Get.find<VoidArReceiptUseCase>(),
        createBillingNote: Get.find<CreateBillingNoteUseCase>(),
        getBillingNote: Get.find<GetBillingNoteUseCase>(),
        voidBillingNote: Get.find<VoidBillingNoteUseCase>(),
        previewLateFee: Get.find<PreviewLateFeeUseCase>(),
        createLateFee: Get.find<CreateLateFeeUseCase>(),
        getLateFee: Get.find<GetLateFeeUseCase>(),
        voidLateFee: Get.find<VoidLateFeeUseCase>(),
        createCreditNote: Get.find<CreateCreditNoteUseCase>(),
        getCreditNote: Get.find<GetCreditNoteUseCase>(),
        downloadPdf: Get.find<DownloadReceivablePdfUseCase>(),
        emailDocument: Get.find<EmailReceivableDocumentUseCase>(),
        session: Get.find<SessionService>(),
      ),
    );
  }
}
