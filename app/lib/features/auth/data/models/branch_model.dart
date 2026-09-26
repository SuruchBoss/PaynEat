// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../domain/entities/branch.dart';

class BranchModel extends Branch {
  const BranchModel({
    required super.id,
    required super.name,
    super.code,
    super.address,
    super.isActive,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) => BranchModel(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    code: json['code'] as String?,
    address: json['address'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}
