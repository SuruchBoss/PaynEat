// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ช่องเขตเวลาของร้าน (T03 #94, docs/DECISIONS.md #101) — แนะนำเขตเวลาที่ร้านในภูมิภาคใช้บ่อยระหว่างพิมพ์
/// แต่พิมพ์ชื่อ IANA อื่นเองได้ ส่วนการตรวจว่าชื่อนั้นมีจริงเป็นของ backend
class TimeZoneField extends StatefulWidget {
  const TimeZoneField({super.key, required this.controller});

  final TextEditingController controller;

  /// เขตเวลาที่แนะนำ — ไทยก่อน ตามด้วยเพื่อนบ้านและประเทศของเจ้าของร้านที่แอปรองรับภาษา
  static const List<String> suggestions = [
    'Asia/Bangkok',
    'Asia/Vientiane',
    'Asia/Phnom_Penh',
    'Asia/Yangon',
    'Asia/Ho_Chi_Minh',
    'Asia/Kuala_Lumpur',
    'Asia/Singapore',
    'Asia/Jakarta',
    'Asia/Manila',
    'Asia/Hong_Kong',
    'Asia/Shanghai',
    'Asia/Taipei',
    'Asia/Seoul',
    'Asia/Tokyo',
    'Asia/Kolkata',
    'Asia/Dubai',
    'Australia/Sydney',
    'Europe/London',
    'America/New_York',
    'UTC',
  ];

  @override
  State<TimeZoneField> createState() => _TimeZoneFieldState();
}

class _TimeZoneFieldState extends State<TimeZoneField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return TimeZoneField.suggestions;
        return TimeZoneField.suggestions.where(
          (zone) => zone.toLowerCase().contains(query),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextField(
            key: const ValueKey('settings-time-zone'),
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              labelText: 'settings_time_zone_label'.tr,
              helperText: 'settings_time_zone_helper'.tr,
              helperMaxLines: 2,
              hintText: 'Asia/Bangkok',
              prefixIcon: const Icon(Icons.public_rounded),
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final zone in options)
                  ListTile(
                    dense: true,
                    title: Text(zone),
                    onTap: () => onSelected(zone),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
