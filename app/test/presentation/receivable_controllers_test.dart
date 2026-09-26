// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/auth/domain/entities/user.dart';
import 'package:payneat_pos/features/customer/domain/entities/customer.dart';
import 'package:payneat_pos/features/receivable/domain/entities/receivable.dart';
import 'package:payneat_pos/features/receivable/domain/repositories/receivable_repository.dart';
import 'package:payneat_pos/features/receivable/domain/usecases/receivable_usecases.dart';
import 'package:payneat_pos/features/receivable/presentation/controllers/customer_statement_controller.dart';
import 'package:payneat_pos/features/receivable/presentation/controllers/receivables_controller.dart';

const _customer = Customer(
  id: 900,
  name: 'บริษัท โซลบาร์บีคิว จำกัด',
  phone: '021234567',
  creditLimit: 50000,
);

ReceivableSummary _summary({double outstanding = 0, double overdue = 0}) =>
    ReceivableSummary(
      customer: _customer,
      creditLimit: 50000,
      creditTermDays: 30,
      outstanding: outstanding,
      overdue: overdue,
      available: 50000 - outstanding,
    );

CustomerStatement _statement() => CustomerStatement(
  summary: _summary(outstanding: 1500),
  today: '2026-09-23',
  invoices: const [
    CreditInvoice(
      paymentId: 1,
      orderId: 11,
      orderCode: 'T001',
      amount: 1000,
      outstanding: 1000,
      billingNoteNo: 'BN69000001',
    ),
    CreditInvoice(
      paymentId: 2,
      orderId: 12,
      orderCode: 'T002',
      amount: 500,
      outstanding: 500,
    ),
    CreditInvoice(
      paymentId: 3,
      orderId: 13,
      orderCode: 'T003',
      amount: 800,
      outstanding: 0,
      settled: 800,
    ),
  ],
  billingNotes: const [
    BillingNote(
      id: 7,
      noteNo: 'BN69000001',
      customerId: 900,
      customerName: 'บริษัท โซลบาร์บีคิว จำกัด',
      total: 1000,
      remaining: 1000,
      status: BillingNoteStatus.open,
      dueDate: '2026-10-23',
    ),
    BillingNote(
      id: 6,
      noteNo: 'BN69000000',
      customerId: 900,
      customerName: 'บริษัท โซลบาร์บีคิว จำกัด',
      total: 800,
      remaining: 0,
      status: BillingNoteStatus.voided,
      dueDate: '2026-10-01',
      isVoided: true,
    ),
  ],
);

class _FakeReceivableRepository implements ReceivableRepository {
  Result<List<ReceivableSummary>> nextList = Result.success([
    _summary(outstanding: 1500, overdue: 500),
    _summary(outstanding: 250),
  ]);
  Result<CustomerStatement> nextStatement = Result.success(_statement());
  Result<ArReceipt>? nextReceipt;
  int statementCalls = 0;
  CreateReceiptParams? lastReceiptParams;

  @override
  Future<Result<List<ReceivableSummary>>> listCustomers() async => nextList;

  @override
  Future<Result<CustomerStatement>> statement(int customerId) async {
    statementCalls++;
    return nextStatement;
  }

  @override
  Future<Result<ArReceipt>> createReceipt(CreateReceiptParams params) async {
    lastReceiptParams = params;
    return nextReceipt!;
  }

  // ดอกเบี้ยผิดนัด / ใบลดหนี้ / อีเมล (tickets 21, 23)
  CreateLateFeeParams? lastLateFee;
  CreateCreditNoteParams? lastCreditNote;
  EmailDocumentParams? lastEmail;
  Result<List<DocumentEmail>> nextEmails = const Result.success([
    DocumentEmail(to: 'ap@soulbbq.example', subject: 'ใบวางบิล BN69-000001'),
  ]);

  @override
  Future<Result<LateFeeCharge>> createLateFee(
    int customerId, {
    String? note,
  }) async {
    lastLateFee = CreateLateFeeParams(customerId: customerId, note: note);
    return const Result.success(
      LateFeeCharge(
        id: 41,
        chargeNo: 'LF69-000001',
        customerId: 900,
        customerName: 'บริษัท โซลบาร์บีคิว จำกัด',
        total: 42.5,
        annualRate: 12,
        asOf: '2026-09-23',
      ),
    );
  }

  @override
  Future<Result<CreditNote>> createCreditNote(
    CreateCreditNoteParams params,
  ) async {
    lastCreditNote = params;
    return const Result.success(
      CreditNote(
        id: 51,
        noteNo: 'CN69-000001',
        customerId: 900,
        customerName: 'บริษัท โซลบาร์บีคิว จำกัด',
        paymentId: 2,
        orderCode: 'T002',
        originalAmount: 500,
        amount: 100,
        correctAmount: 400,
        reason: 'ของชำรุด',
      ),
    );
  }

  @override
  Future<Result<List<DocumentEmail>>> emailDocument(
    EmailDocumentParams params,
  ) async {
    lastEmail = params;
    return nextEmails;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// User.== เทียบแค่ id — ต้องใช้ id ต่างกันต่อบทบาท ไม่งั้น Rxn ไม่อัปเดตค่า
User _user(String role) => User(
  id: UserRole.all.indexOf(role) + 1,
  name: 'ทดสอบ',
  username: role,
  role: role,
  isActive: true,
);

void main() {
  late _FakeReceivableRepository repository;
  late SessionService session;

  CustomerStatementController statementController() =>
      CustomerStatementController(
        getStatement: GetCustomerStatementUseCase(repository),
        createReceipt: CreateArReceiptUseCase(repository),
        getReceipt: GetArReceiptUseCase(repository),
        voidReceipt: VoidArReceiptUseCase(repository),
        createBillingNote: CreateBillingNoteUseCase(repository),
        getBillingNote: GetBillingNoteUseCase(repository),
        voidBillingNote: VoidBillingNoteUseCase(repository),
        previewLateFee: PreviewLateFeeUseCase(repository),
        createLateFee: CreateLateFeeUseCase(repository),
        getLateFee: GetLateFeeUseCase(repository),
        voidLateFee: VoidLateFeeUseCase(repository),
        createCreditNote: CreateCreditNoteUseCase(repository),
        getCreditNote: GetCreditNoteUseCase(repository),
        downloadPdf: DownloadReceivablePdfUseCase(repository),
        emailDocument: EmailReceivableDocumentUseCase(repository),
        session: session,
        customerId: 900,
      );

  setUp(() {
    repository = _FakeReceivableRepository();
    session = SessionService(
      storage: StorageService.memory(),
      socket: SocketClient(),
    );
  });

  group('ReceivablesController', () {
    test('รวมยอดค้าง/เกินกำหนดของลูกค้าเครดิตทุกราย', () async {
      final controller = ReceivablesController(
        getCustomers: GetReceivableCustomersUseCase(repository),
      );

      await controller.load();

      expect(controller.summaries, hasLength(2));
      expect(controller.totalOutstanding, 1750);
      expect(controller.totalOverdue, 500);
      expect(controller.isLoading.value, isFalse);
    });

    test('โหลดไม่สำเร็จ → ตั้ง errorMessage', () async {
      repository.nextList = Result.failure(NetworkFailure('ต่อไม่ได้'));
      final controller = ReceivablesController(
        getCustomers: GetReceivableCustomersUseCase(repository),
      );

      await controller.load();

      expect(controller.errorMessage.value, 'ต่อไม่ได้');
      expect(controller.summaries, isEmpty);
    });
  });

  group('CustomerStatementController', () {
    test(
      'โหลดบัญชีลูกหนี้ แยกบิลค้าง/บิลที่ยังไม่วางบิล/ใบวางบิลที่ยังเปิด',
      () async {
        final controller = statementController()..onInit();
        await Future<void>.delayed(Duration.zero);

        final statement = controller.statement.value!;
        expect(controller.customerId, 900);
        expect(statement.openInvoices.map((i) => i.orderCode), [
          'T001',
          'T002',
        ]);
        expect(statement.unbilledInvoices.map((i) => i.orderCode), ['T002']);
        expect(statement.openBillingNotes.map((n) => n.noteNo), ['BN69000001']);
      },
    );

    test('ยกเลิกเอกสารได้เฉพาะผู้จัดการขึ้นไป (ตรงกับ backend)', () {
      final controller = statementController();

      session.updateUser(_user(UserRole.cashier));
      expect(controller.canVoid, isFalse);
      session.updateUser(_user(UserRole.manager));
      expect(controller.canVoid, isTrue);
    });

    testWidgets('รับชำระสำเร็จ → ส่งใบวางบิลที่เลือกไป และโหลดยอดใหม่', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      final controller = statementController()..onInit();
      await tester.pump();
      repository.nextReceipt = const Result.success(
        ArReceipt(
          id: 31,
          receiptNo: 'RC69000001',
          customerId: 900,
          customerName: 'บริษัท โซลบาร์บีคิว จำกัด',
          amount: 1000,
          method: PaymentMethod.transfer,
        ),
      );

      final receipt = await controller.receivePayment(
        amount: 1000,
        method: PaymentMethod.transfer,
        reference: 'KBANK-0923',
        billingNoteId: 7,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(receipt?.receiptNo, 'RC69000001');
      expect(repository.lastReceiptParams?.billingNoteId, 7);
      expect(repository.lastReceiptParams?.toJson(), {
        'customerId': 900,
        'amount': 1000.0,
        'method': 'transfer',
        'reference': 'KBANK-0923',
        'billingNoteId': 7,
      });
      expect(
        repository.statementCalls,
        2,
        reason: 'โหลดยอดค้างใหม่หลังรับเงิน',
      );
      expect(controller.isSubmitting.value, isFalse);
    });

    testWidgets('รับชำระไม่สำเร็จ (เช่น เกินยอดค้าง) → คืน null ไม่โหลดซ้ำ', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      final controller = statementController()..onInit();
      await tester.pump();
      repository.nextReceipt = Result.failure(
        ServerFailure('รับชำระเกินยอดค้าง (ค้างอยู่ 1500.00 บาท)'),
      );

      final receipt = await controller.receivePayment(
        amount: 9999,
        method: PaymentMethod.cash,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(receipt, isNull);
      expect(repository.statementCalls, 1);
    });

    test('คิดดอกเบี้ย/ออกใบลดหนี้ได้เฉพาะผู้จัดการขึ้นไป', () {
      final controller = statementController();
      session.updateUser(_user(UserRole.cashier));
      expect(controller.canAdjustDebt, isFalse);
      session.updateUser(_user(UserRole.admin));
      expect(controller.canAdjustDebt, isTrue);
    });

    testWidgets(
      'ออกใบแจ้งดอกเบี้ย/ใบลดหนี้สำเร็จ → ส่งค่าถูก และโหลดยอดค้างใหม่',
      (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
        final controller = statementController()..onInit();
        await tester.pump();

        final charge = await controller.issueLateFee(note: 'ตามสัญญา');
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(charge?.chargeNo, 'LF69-000001');
        expect(repository.lastLateFee?.customerId, 900);
        expect(repository.lastLateFee?.note, 'ตามสัญญา');

        final note = await controller.issueCreditNote(
          paymentId: 2,
          amount: 100,
          reason: 'ของชำรุด',
        );
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(note?.noteNo, 'CN69-000001');
        expect(repository.lastCreditNote?.toJson(), {
          'paymentId': 2,
          'amount': 100.0,
          'reason': 'ของชำรุด',
        });
        expect(repository.statementCalls, 3, reason: 'โหลดใหม่หลังแต่ละครั้ง');
      },
    );

    testWidgets(
      'ส่งเอกสารทางอีเมล: ไม่ระบุผู้รับ = ใช้อีเมลลูกค้า / ล้มเหลว → null',
      (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
        final controller = statementController();

        final emails = await controller.emailDocument(
          ReceivableDocumentKind.billingNote,
          7,
          message: '  ',
        );
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(emails?.single.to, 'ap@soulbbq.example');
        expect(repository.lastEmail?.kind.path, 'billing-notes');
        expect(repository.lastEmail?.toJson(), isEmpty);

        repository.nextEmails = Result.failure(
          ServerFailure('ยังไม่ได้ตั้งค่าเซิร์ฟเวอร์อีเมล', statusCode: 503),
        );
        final failed = await controller.emailDocument(
          ReceivableDocumentKind.receipt,
          31,
          to: 'account@soulbbq.example',
        );
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(failed, isNull);
        expect(repository.lastEmail?.toJson(), {
          'to': 'account@soulbbq.example',
        });
      },
    );
  });
}
