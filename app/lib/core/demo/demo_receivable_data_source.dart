// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_data_sources.dart';

/// ลูกหนี้/ขายเชื่อ/ใบวางบิล ในโหมดสาธิต (ดู docs/tickets/20-b2b-credit.md) — แปลงผลลัพธ์ด้วย
/// ReceivableModel ตัวเดียวกับที่อ่าน JSON จาก backend จริง
class DemoReceivableDataSource implements ReceivableRemoteDataSource {
  const DemoReceivableDataSource(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthDataSource _auth;

  @override
  Future<List<ReceivableSummary>> listCustomers() => _delayed(
    () => _store
        .receivableCustomers()
        .map(ReceivableModel.summaryFromJson)
        .toList(growable: false),
  );

  @override
  Future<CustomerStatement> statement(int customerId) => _delayed(
    () => ReceivableModel.statementFromJson(
      _store.receivableStatement(customerId),
    ),
  );

  @override
  Future<ArReceipt> createReceipt(CreateReceiptParams params) => _delayed(
    () => ReceivableModel.receiptFromJson(
      _store.createArReceipt(params.toJson(), actorId: _auth.currentUserId),
    ),
  );

  @override
  Future<ArReceipt> getReceipt(int id) => _delayed(
    () => ReceivableModel.receiptFromJson(_store.arReceiptDocument(id)),
  );

  @override
  Future<ArReceipt> voidReceipt(int id, String reason) => _delayed(
    () => ReceivableModel.receiptFromJson(
      _store.voidArReceipt(id, reason, actorId: _auth.currentUserId),
    ),
  );

  @override
  Future<BillingNote> createBillingNote(CreateBillingNoteParams params) =>
      _delayed(
        () => ReceivableModel.billingNoteFromJson(
          _store.createBillingNote(
            params.toJson(),
            actorId: _auth.currentUserId,
          ),
        ),
      );

  @override
  Future<BillingNote> getBillingNote(int id) => _delayed(
    () => ReceivableModel.billingNoteFromJson(_store.billingNoteDocument(id)),
  );

  @override
  Future<BillingNote> voidBillingNote(int id, String reason) => _delayed(
    () => ReceivableModel.billingNoteFromJson(
      _store.voidBillingNote(id, reason, actorId: _auth.currentUserId),
    ),
  );

  @override
  Future<LateFeePreview> previewLateFee(int customerId) => _delayed(
    () => ReceivableModel.lateFeePreviewFromJson(
      _store.lateFeePreview(customerId),
    ),
  );

  @override
  Future<LateFeeCharge> createLateFee(int customerId, {String? note}) =>
      _delayed(
        () => ReceivableModel.lateFeeFromJson(
          _store.createLateFee({
            'customerId': customerId,
            'note': note,
          }, actorId: _auth.currentUserId),
        ),
      );

  @override
  Future<LateFeeCharge> getLateFee(int id) => _delayed(
    () => ReceivableModel.lateFeeFromJson(_store.lateFeeDocument(id)),
  );

  @override
  Future<LateFeeCharge> voidLateFee(int id, String reason) => _delayed(
    () => ReceivableModel.lateFeeFromJson(
      _store.voidLateFee(id, reason, actorId: _auth.currentUserId),
    ),
  );

  @override
  Future<CreditNote> createCreditNote(CreateCreditNoteParams params) =>
      _delayed(
        () => ReceivableModel.creditNoteFromJson(
          _store.createCreditNote(
            params.toJson(),
            actorId: _auth.currentUserId ?? 0,
          ),
        ),
      );

  @override
  Future<CreditNote> getCreditNote(int id) => _delayed(
    () => ReceivableModel.creditNoteFromJson(_store.creditNoteDocument(id)),
  );

  /// โหมดสาธิตไม่มีเซิร์ฟเวอร์สร้าง PDF — หน้าจอซ่อนปุ่มดาวน์โหลดอยู่แล้ว ([AppConfig.demoMode])
  @override
  Future<List<int>> downloadPdf(ReceivableDocumentKind kind, int id) =>
      _delayed(
        () => throw ApiException(
          message: 'receivable_pdf_demo_unavailable'.tr,
          statusCode: 503,
        ),
      );

  @override
  Future<List<DocumentEmail>> emailDocument(EmailDocumentParams params) =>
      _delayed(
        () => ReceivableModel.emailsFromJson(
          _store.emailDocument(
            switch (params.kind) {
              ReceivableDocumentKind.billingNote => 'billing_note',
              ReceivableDocumentKind.receipt => 'receipt',
              ReceivableDocumentKind.creditNote => 'credit_note',
              ReceivableDocumentKind.lateFee => 'late_fee',
            },
            params.id,
            to: params.to,
            actorId: _auth.currentUserId,
          )['emails'],
        ),
      );
}
