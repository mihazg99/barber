import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/dashboard/presentation/widgets/edit_working_hours_dialog.dart';
import 'package:barber/features/dashboard/presentation/widgets/working_hours_card.dart';
import 'package:barber/features/time_off/di.dart';
import 'package:barber/features/time_off/presentation/widgets/add_time_off_dialog.dart';
import 'package:barber/features/time_off/presentation/widgets/time_off_card.dart';

/// Shift tab for barbers to manage their working hours and time-off.
class DashboardShiftTab extends HookConsumerWidget {
  const DashboardShiftTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeOffAsync = ref.watch(barberTimeOffProvider);
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).languageCode;
    final sizes = context.appSizes;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Working Hours Section
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              sizes.paddingMedium,
              sizes.paddingMedium,
              sizes.paddingMedium,
              sizes.paddingSmall,
            ),
            sliver: SliverToBoxAdapter(
              child: _WorkingHoursSection(),
            ),
          ),

          // 2. Time Off Header & Add Button
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: sizes.paddingMedium,
              vertical: sizes.paddingSmall,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.shiftUpcomingTimeOff,
                    style: context.appTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.primaryTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showAddTimeOffDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: colors.primaryColor,
                            ),
                            const Gap(4),
                            Text(
                              context.l10n.shiftAddTimeOff,
                              style: context.appTextStyles.caption.copyWith(
                                color: colors.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Time Off List or Empty State
          timeOffAsync.when(
            data: (timeOffList) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final upcomingTimeOff =
                  timeOffList
                      .where((timeOff) => !timeOff.endDate.isBefore(today))
                      .toList();

              if (upcomingTimeOff.isEmpty) {
                return SliverToBoxAdapter(
                  child: _CompactEmptyState(
                    onAdd: () => _showAddTimeOffDialog(context),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: sizes.paddingMedium),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final timeOff = upcomingTimeOff[index];
                      // Add entrance animation key if needed, or simple direct render
                      return TimeOffCard(
                        key: ValueKey(timeOff.timeOffId),
                        timeOff: timeOff,
                        locale: locale,
                      );
                    },
                    childCount: upcomingTimeOff.length,
                  ),
                ),
              );
            },
            loading:
                () => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(colors.primaryColor),
                      ),
                    ),
                  ),
                ),
            error:
                (error, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Unable to load time off.',
                        style: context.appTextStyles.caption.copyWith(
                          color: colors.errorColor,
                        ),
                      ),
                    ),
                  ),
                ),
          ),

          // Bottom padding
          SliverPadding(
            padding: EdgeInsets.only(bottom: sizes.paddingLarge * 2),
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  void _showAddTimeOffDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTimeOffDialog(),
    );
  }
}

class _CompactEmptyState extends HookConsumerWidget {
  const _CompactEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondaryTextColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.beach_access_rounded,
              size: 32,
              color: colors.secondaryTextColor.withOpacity(0.5),
            ),
          ),
          const Gap(16),
          Text(
            context.l10n.shiftNoTimeOff,
            textAlign: TextAlign.center,
            style: context.appTextStyles.medium.copyWith(
              color: colors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.primaryColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.l10n.shiftAddTimeOff,
                  style: context.appTextStyles.caption.copyWith(
                    color: colors.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkingHoursSection extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workingHoursAsync = ref.watch(barberEffectiveWorkingHoursProvider);

    return workingHoursAsync.when(
      data:
          (workingHours) => WorkingHoursCard(
            workingHours: workingHours,
            onEdit: () {
              showDialog(
                context: context,
                builder: (context) => const EditWorkingHoursDialog(),
              );
            },
          ),
      loading:
          () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
