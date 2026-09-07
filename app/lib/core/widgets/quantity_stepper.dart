import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// ปุ่ม - / + สำหรับปรับจำนวน ออกแบบให้กดง่ายด้วยนิ้วบนแท็บเล็ต
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.size = 34,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            size: size,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: size + 6,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            size: size,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.size, this.onTap});

  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
