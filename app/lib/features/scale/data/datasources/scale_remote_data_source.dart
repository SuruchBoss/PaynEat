// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/socket_client.dart';
import '../../domain/entities/scale_status.dart';
import '../models/scale_model.dart';

abstract class ScaleRemoteDataSource {
  Future<ScaleStatus> status();
  Stream<ScaleStatus> watch();
}

class ScaleRemoteDataSourceImpl implements ScaleRemoteDataSource {
  const ScaleRemoteDataSourceImpl(this._client, this._socket);

  final ApiClient _client;
  final SocketClient _socket;

  @override
  Future<ScaleStatus> status() async {
    final result = await _client.get(ApiEndpoints.scale);
    return ScaleModel.fromJson(result.asMap);
  }

  /// ฟัง socket เฉพาะตอนมีคนฟัง stream อยู่ (กล่องชั่งเปิด) — ปิดกล่องแล้วถอด listener ทันที
  @override
  Stream<ScaleStatus> watch() {
    void Function()? unsubscribe;
    late final StreamController<ScaleStatus> controller;
    controller = StreamController<ScaleStatus>(
      onListen: () {
        unsubscribe = _socket.on(SocketEvents.scaleReading, (data) {
          if (data is Map) {
            controller.add(ScaleModel.fromJson(data.cast<String, dynamic>()));
          }
        });
      },
      onCancel: () => unsubscribe?.call(),
    );
    return controller.stream;
  }
}
