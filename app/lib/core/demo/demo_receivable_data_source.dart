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
}
