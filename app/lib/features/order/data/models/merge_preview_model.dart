// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../domain/entities/merge_preview.dart';

double _baht(Object? value) => (value as num?)?.toDouble() ?? 0;

class MergePreviewSideModel extends MergePreviewSide {
  const MergePreviewSideModel({
    required super.code,
    required super.total,
    required super.paid,
    required super.discount,
    required super.promotionDiscount,
    super.promotionName,
  });

  factory MergePreviewSideModel.fromJson(Map<String, dynamic> json) =>
      MergePreviewSideModel(
        code: json['code'] as String? ?? '',
        total: _baht(json['total']),
        paid: _baht(json['paid']),
        discount: _baht(json['discount']),
        promotionDiscount: _baht(json['promotionDiscount']),
        promotionName: json['promotionName'] as String?,
      );
}

class MergePreviewModel extends MergePreview {
  const MergePreviewModel({
    required super.target,
    required super.source,
    required super.total,
    required super.paid,
    required super.remaining,
    required super.refundRequired,
    required super.discount,
    required super.promotionDiscount,
    required super.discountLost,
    super.promotionName,
  });

  factory MergePreviewModel.fromJson(Map<String, dynamic> json) {
    final merged = (json['merged'] as Map).cast<String, dynamic>();
    return MergePreviewModel(
      target: MergePreviewSideModel.fromJson(
        (json['target'] as Map).cast<String, dynamic>(),
      ),
      source: MergePreviewSideModel.fromJson(
        (json['source'] as Map).cast<String, dynamic>(),
      ),
      total: _baht(merged['total']),
      paid: _baht(merged['paid']),
      remaining: _baht(merged['remaining']),
      refundRequired: _baht(merged['refundRequired']),
      discount: _baht(merged['discount']),
      promotionDiscount: _baht(merged['promotionDiscount']),
      promotionName: merged['promotionName'] as String?,
      discountLost: _baht(json['discountLost']),
    );
  }
}
