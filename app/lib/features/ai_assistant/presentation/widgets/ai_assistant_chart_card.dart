// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/ai_assistant_answer.dart';

/// กราฟแท่งประกอบคำตอบของผู้ช่วย AI — เขียนด้วย widget ล้วนแบบเดียวกับ HourlyBarChart
/// (ไม่พึ่ง package กราฟ) แกน x เป็น label อิสระตามที่ AI ส่งมา ไม่ใช่ชั่วโมงตายตัว
class AiAssistantChartCard extends StatelessWidget {
  const AiAssistantChartCard({super.key, required this.chart});

  final AiAssistantChart chart;

  @override
  Widget build(BuildContext context) {
    if (chart.points.isEmpty) return const SizedBox.shrink();

    final maxValue = chart.points.fold<double>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chart.title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: chart.points
                      .map((point) {
                        final ratio = maxValue == 0
                            ? 0.0
                            : point.value / maxValue;
                        final barHeight = (constraints.maxHeight - 34) * ratio;

                        return Expanded(
                          child: Tooltip(
                            message:
                                '${point.label}: ${Formatters.compact(point.value)}',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.compact(point.value),
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    height: barHeight < 3 ? 3 : barHeight,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryDark,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    point.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
