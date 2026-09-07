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

  /// ช่วงเวลาเริ่มต้นที่ใช้เมื่อยังไม่มียอดขายของวันนั้นเลย
  static const int defaultStartHour = 9;
  static const int defaultEndHour = 22;

  /// จำนวนชั่วโมงอย่างน้อยที่ต้องแสดง เพื่อไม่ให้กราฟแท่งเดียวดูแปลก
  static const int minimumSpan = 6;

  /// หาช่วงเวลาที่จะแสดงจากข้อมูลจริง
  ///
  /// ถ้าตรึงช่วงไว้ตายตัว ร้านที่เปิดเช้ากว่าหรือปิดดึกกว่านั้นจะมองไม่เห็นยอดของตัวเองเลย
  /// จึงคำนวณจากชั่วโมงที่มียอดจริง แล้วขยายให้กว้างพอที่กราฟยังอ่านง่าย
  static ({int start, int end}) visibleRange(List<HourlySales> data) {
    final withSales = data
        .where((item) => item.total > 0)
        .toList(growable: false);
    if (withSales.isEmpty) {
      return (start: defaultStartHour, end: defaultEndHour);
    }

    var start = withSales.first.hour;
    var end = withSales.first.hour;
    for (final item in withSales) {
      if (item.hour < start) start = item.hour;
      if (item.hour > end) end = item.hour;
    }

    // เผื่อขอบซ้ายขวาไว้หนึ่งชั่วโมง แล้วขยายจนกว้างพอตามที่กำหนด
    start = (start - 1).clamp(0, 23);
    end = (end + 1).clamp(0, 23);
    while (end - start < minimumSpan) {
      if (start > 0) start--;
      if (end < 23 && end - start < minimumSpan) end++;
      if (start == 0 && end == 23) break;
    }

    return (start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final byHour = {for (final item in data) item.hour: item};
    final range = visibleRange(data);
    final hours = [for (int h = range.start; h <= range.end; h++) h];
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
