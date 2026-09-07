import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/network/socket_client.dart';
import '../../../../core/services/session_service.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/report_usecases.dart';

/// หน้าสรุปภาพรวมร้านสำหรับผู้จัดการ/เจ้าของ
class DashboardController extends GetxController {
  DashboardController({
    required GetDashboardUseCase getDashboard,
    required SessionService session,
  }) : _getDashboard = getDashboard,
       _session = session;

  final GetDashboardUseCase _getDashboard;
  final SessionService _session;

  final Rx<DashboardData> data = DashboardData.empty.obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final List<VoidCallback> _unsubscribers = [];
  Timer? _autoRefresh;

  @override
  void onInit() {
    super.onInit();
    load();
    _listenToRealtimeUpdates();
    // เผื่อ event หายระหว่างเน็ตสะดุด ให้ refresh เองทุก 1 นาที
    _autoRefresh = Timer.periodic(
      const Duration(minutes: 1),
      (_) => load(showLoader: false),
    );
  }

  @override
  void onClose() {
    _autoRefresh?.cancel();
    for (final unsubscribe in _unsubscribers) {
      unsubscribe();
    }
    super.onClose();
  }

  Future<void> load({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = null;

    final result = await _getDashboard();

    isLoading.value = false;
    result.fold(
      onSuccess: (value) => data.value = value,
      onFailure: (failure) => errorMessage.value = failure.message,
    );
  }

  void _listenToRealtimeUpdates() {
    final socket = _session.socket;
    for (final event in [SocketEvents.orderPaid, SocketEvents.orderCreated]) {
      _unsubscribers.add(socket.on(event, (_) => load(showLoader: false)));
    }
  }
}
