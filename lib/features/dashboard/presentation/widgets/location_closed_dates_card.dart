import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Card for superadmin to manage closed dates (holidays) per location.
/// [closedDates] are YYYY-MM-DD strings. [onClosedDatesChanged] is called when list changes.
class LocationClosedDatesCard extends StatelessWidget {
  const LocationClosedDatesCard({
    required this.closedDates,
    required this.onClosedDatesChanged,
    super.key,
  });

  final List<String> closedDates;
  final ValueChanged<List<String>> onClosedDatesChanged;

  static String _formatDateKey(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return yyyyMmDd;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return yyyyMmDd;
    return DateFormat.yMMMd().format(DateTime(y, m, d));
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    final key =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (closedDates.contains(key)) return;
    onClosedDatesChanged([...closedDates, key]..sort());
  }

  void _remove(String key) {
    onClosedDatesChanged(closedDates.where((e) => e != key).toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(sizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_busy_rounded,
                    color: colors.primaryColor,
                    size: 18,
                  ),
                ),
                Gap(sizes.paddingSmall),
                Expanded(
                  child: Text(
                    l10n.dashboardLocationClosedDates,
                    style: context.appTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colors.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            Gap(sizes.paddingSmall),
            Text(
              l10n.dashboardLocationClosedDatesHint,
              style: context.appTextStyles.caption.copyWith(
                color: colors.secondaryTextColor,
                fontSize: 12,
              ),
            ),
            Gap(sizes.paddingMedium),
            if (closedDates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.dashboardLocationAddClosedDate,
                  style: context.appTextStyles.medium.copyWith(
                    color: colors.secondaryTextColor.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...closedDates.map(
                    (key) => _ClosedDateChip(
                      label: _formatDateKey(key),
                      onRemove: () => _remove(key),
                    ),
                  ),
                ],
              ),
            Gap(sizes.paddingSmall),
            OutlinedButton.icon(
              onPressed: () => _pickDate(context),
              icon: Icon(Icons.add_rounded, size: 18, color: colors.primaryColor),
              label: Text(
                l10n.dashboardLocationAddClosedDate,
                style: context.appTextStyles.medium.copyWith(
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryColor,
                side: BorderSide(color: colors.primaryColor.withValues(alpha: 0.5)),
                padding: EdgeInsets.symmetric(
                  vertical: sizes.paddingSmall,
                  horizontal: sizes.paddingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedDateChip extends StatelessWidget {
  const _ClosedDateChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.menuBackgroundColor,
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.appTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primaryTextColor,
                ),
              ),
              const Gap(6),
              Icon(
                Icons.close_rounded,
                size: 16,
                color: colors.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
