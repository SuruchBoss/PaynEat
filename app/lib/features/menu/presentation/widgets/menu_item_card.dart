import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/menu_item.dart';
import 'menu_item_thumbnail.dart';

/// การ์ดเมนู 1 รายการ
///
/// ถ้าไม่มีรูปจะสร้างพื้นหลังไล่สีจากชื่อเมนูแทน เพื่อให้จอสั่งอาหารยังดูมีชีวิตชีวา
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.trailing,
    this.showAvailabilityBadge = false,
  });

  final MenuItem item;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showAvailabilityBadge;

  static const List<List<Color>> _palettes = [
    [Color(0xFFFFB088), Color(0xFFFF6B2C)],
    [Color(0xFF8CE0C4), Color(0xFF12B886)],
    [Color(0xFF9DC8F5), Color(0xFF1971C2)],
    [Color(0xFFF7C7E8), Color(0xFFD6336C)],
    [Color(0xFFFFD98C), Color(0xFFF59F00)],
    [Color(0xFFC0B3F5), Color(0xFF7048E8)],
  ];

  List<Color> get _palette =>
      _palettes[item.name.hashCode.abs() % _palettes.length];

  @override
  Widget build(BuildContext context) {
    final disabled = !item.isAvailable;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MenuItemThumbnail(
                        imageUrl: item.imageUrl,
                        placeholder: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _palette,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              item.displayName.substring(0, 1),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (item.isRecommended)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'menu_recommended_badge'.tr,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (showAvailabilityBadge && disabled)
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Text(
                            'menu_sold_out_badge'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                Formatters.baht(item.price),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandInk,
                                ),
                              ),
                            ),
                            if (trailing != null)
                              trailing!
                            else if (item.hasOptions)
                              const Icon(
                                Icons.tune_rounded,
                                size: 15,
                                color: AppColors.textDisabled,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
