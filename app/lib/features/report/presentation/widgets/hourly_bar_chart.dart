import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/report.dart';

/// กราฟแท่งยอดขายรายชั่วโมง — เขียนด้วย widget ล้วน ไม่พึ่ง package กราฟ
/// เพื่อคุมหน้าตาให้เข้ากับธีมและลดขนาด bundle
class HourlyBarChart extends StatelessWidget {
  const HourlyBarChart({super.key, required this.data, this.height = 170});

  final List<HourlySales> data;
  final double height;

  /// ช่วงเวลาเปิดร้านที่ต้องการแสดงเสมอ แม้ชั่วโมงนั้นยังไม่มียอด
  static const int startHour = 9;
  static const int endHour = 22;

  @override
  Widget build(BuildContext context) {
    final byHour = {for (final item in data) item.hour: item};
    final hours = [for (int h = startHour; h <= endHour; h++) h];
    final maxTotal = hours.fold<double>(
      0,
      (max, hour) =>
          (byHour[hour]?.total ?? 0) > max ? byHour[hour]!.total : max,
    );

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: hours
                      .map((hour) {
                        final total = byHour[hour]?.total ?? 0;
                        final ratio = maxTotal == 0 ? 0.0 : total / maxTotal;
                        final barHeight = (constraints.maxHeight - 20) * ratio;

                        return Expanded(
                          child: Tooltip(
                            message: '$hour:00 — ${Formatters.baht(total)}',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2.5,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (total > 0)
                                    Text(
                                      Formatters.compact(total),
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        color: AppColors.textDisabled,
                                      ),
                                    ),
                                  const SizedBox(height: 3),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                    height: barHeight < 3 && total > 0
                                        ? 3
                                        : barHeight,
                                    decoration: BoxDecoration(
                                      gradient: total > 0
                                          ? const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                AppColors.primary,
                                                AppColors.primaryDark,
                                              ],
                                            )
                                          : null,
                                      color: total > 0
                                          ? null
                                          : AppColors.surfaceAlt,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
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
          const SizedBox(height: 6),
          Row(
            children: hours
                .map(
                  (hour) => Expanded(
                    child: Text(
                      hour % 3 == 0 ? '$hour' : '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
