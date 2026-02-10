import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/time_input_formatter.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/core/widgets/custom_back_button.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/di.dart';

const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Full-page form for add/edit barber. Pass [barber] for edit, null for create.
class BarberFormPage extends HookConsumerWidget {
  const BarberFormPage({super.key, this.barber});

  final BarberEntity? barber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = barber != null;
    final nameController = useTextEditingController(text: barber?.name ?? '');
    final photoUrlController = useTextEditingController(
      text: barber?.photoUrl ?? '',
    );
    final active = useState(barber?.active ?? true);
    final selectedLocationId = useState<String?>(barber?.locationId);
    final showWorkingHours = useState(
      barber?.workingHoursOverride != null &&
          barber!.workingHoursOverride!.isNotEmpty,
    );
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final locations = useState<List<LocationEntity>>([]);
    final currentLocation = useState<LocationEntity?>(null);
    final effectiveBrandId = ref.watch(dashboardBrandIdProvider);
    final locationRepo = ref.watch(locationRepositoryProvider);
    final notifier = ref.read(dashboardBarbersNotifierProvider.notifier);

    final openControllers = useMemoized(
      () {
        final controllers = List.generate(
          7,
          (i) {
            // Use barber override if exists, otherwise use location default
            final value =
                barber?.workingHoursOverride?[_dayKeys[i]]?.open ??
                currentLocation.value?.workingHours[_dayKeys[i]]?.open ??
                '';
            return TextEditingController(text: value);
          },
        );
        return controllers;
      },
      // No dependency - only create once to preserve user input
    );
    final closeControllers = useMemoized(
      () {
        final controllers = List.generate(
          7,
          (i) {
            // Use barber override if exists, otherwise use location default
            final value =
                barber?.workingHoursOverride?[_dayKeys[i]]?.close ??
                currentLocation.value?.workingHours[_dayKeys[i]]?.close ??
                '';
            return TextEditingController(text: value);
          },
        );
        return controllers;
      },
      // No dependency - only create once to preserve user input
    );

    useEffect(() {
      void loadLocations() async {
        final result = await locationRepo.getByBrandId(effectiveBrandId);
        result.fold((_) => {}, (list) {
          locations.value = list;
          if (selectedLocationId.value == null && list.isNotEmpty) {
            selectedLocationId.value = list.first.locationId;
          }
          // Load current location for default hours
          if (barber?.locationId != null) {
            currentLocation.value = list.firstWhere(
              (loc) => loc.locationId == barber!.locationId,
              orElse: () => list.first,
            );
          } else if (list.isNotEmpty) {
            currentLocation.value = list.first;
          }
        });
      }

      loadLocations();
      return null;
    }, [effectiveBrandId, locationRepo]);

    // Update controllers when location loads (only if barber has no override)
    useEffect(() {
      if (currentLocation.value != null &&
          barber?.workingHoursOverride == null) {
        final locationHours = currentLocation.value!.workingHours;
        for (var i = 0; i < 7; i++) {
          final dayKey = _dayKeys[i];
          final open = locationHours[dayKey]?.open ?? '';
          final close = locationHours[dayKey]?.close ?? '';
          if (openControllers[i].text.isEmpty && open.isNotEmpty) {
            openControllers[i].text = open;
          }
          if (closeControllers[i].text.isEmpty && close.isNotEmpty) {
            closeControllers[i].text = close;
          }
        }
      }
      return null;
    }, [currentLocation.value]);

    useEffect(
      () => () {
        for (final c in openControllers) {
          c.dispose();
        }
        for (final c in closeControllers) {
          c.dispose();
        }
      },
      [openControllers, closeControllers],
    );

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (effectiveBrandId.isEmpty) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardNoBrand),
            backgroundColor: context.appColors.errorColor,
          ),
        );
        return;
      }
      final locId = selectedLocationId.value;
      if (locId == null || locId.isEmpty) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardBarberLocationRequired),
            backgroundColor: context.appColors.errorColor,
          ),
        );
        return;
      }

      print('🔵 Form - showWorkingHours.value: ${showWorkingHours.value}');

      WorkingHoursMap? override;
      // Check if any working hours fields have values, regardless of expansion state
      bool hasAnyWorkingHours = false;
      for (var i = 0; i < 7; i++) {
        if (openControllers[i].text.trim().isNotEmpty ||
            closeControllers[i].text.trim().isNotEmpty) {
          hasAnyWorkingHours = true;
          break;
        }
      }

      if (hasAnyWorkingHours) {
        override = {};
        for (var i = 0; i < 7; i++) {
          final open = _normalizeTime(openControllers[i].text.trim());
          final close = _normalizeTime(closeControllers[i].text.trim());
          if (open.isNotEmpty && close.isNotEmpty) {
            override[_dayKeys[i]] = DayWorkingHours(open: open, close: close);
          } else {
            override[_dayKeys[i]] = null;
          }
        }
        if (override.values.every((v) => v == null)) {
          override = null;
        }
      }

      final barberId =
          isEdit ? barber!.barberId : _slugFromName(nameController.text.trim());
      final entity = BarberEntity(
        barberId: barberId,
        brandId: effectiveBrandId,
        locationId: locId,
        name: nameController.text.trim(),
        photoUrl: photoUrlController.text.trim(),
        active: active.value,
        workingHoursOverride: override,
        userId: barber?.userId,
      );

      await notifier.save(entity);

      if (!context.mounted) return;
      final messenger =
          rootScaffoldMessengerKey.currentState ??
          ScaffoldMessenger.maybeOf(context);
      if (notifier.hasError) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(notifier.errorMessage ?? 'Error'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      } else {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? context.l10n.dashboardBarberSaved
                  : context.l10n.dashboardBarberCreated,
            ),
            backgroundColor: context.appColors.primaryColor,
          ),
        );
        Navigator.of(context).pop();
      }
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: AppBar(
        leading: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(
          isEdit
              ? context.l10n.dashboardBarberEdit
              : context.l10n.dashboardBarberAdd,
          style: context.appTextStyles.h2.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.appColors.primaryTextColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.appSizes.paddingMedium),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField.withTitle(
                title: context.l10n.dashboardBarberName,
                hint: context.l10n.dashboardBarberNameHint,
                controller: nameController,
                validator:
                    (v) =>
                        (v?.trim().isEmpty ?? true)
                            ? context.l10n.dashboardBarberNameRequired
                            : null,
              ),
              Gap(context.appSizes.paddingMedium),
              CustomTextField.withTitle(
                title: context.l10n.dashboardBarberPhotoUrl,
                hint: context.l10n.dashboardBarberPhotoUrlHint,
                controller: photoUrlController,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                context.l10n.dashboardBarberLocation,
                style: context.appTextStyles.medium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.primaryTextColor,
                ),
              ),
              Gap(context.appSizes.paddingSmall),
              locations.value.isEmpty
                  ? Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.appSizes.paddingSmall,
                    ),
                    child: Text(
                      context.l10n.dashboardBarberNoLocations,
                      style: context.appTextStyles.caption.copyWith(
                        color: context.appColors.captionTextColor,
                      ),
                    ),
                  )
                  : DropdownButtonFormField<String>(
                    value: selectedLocationId.value,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.appColors.secondaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          context.appSizes.borderRadius,
                        ),
                      ),
                    ),
                    dropdownColor: context.appColors.menuBackgroundColor,
                    items:
                        locations.value
                            .map(
                              (loc) => DropdownMenuItem(
                                value: loc.locationId,
                                child: Text(
                                  loc.name,
                                  style: context.appTextStyles.medium.copyWith(
                                    color: context.appColors.primaryTextColor,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => selectedLocationId.value = v,
                    validator:
                        (v) =>
                            (v == null || v.isEmpty)
                                ? context.l10n.dashboardBarberLocationRequired
                                : null,
                  ),
              Gap(context.appSizes.paddingMedium),
              SwitchListTile(
                title: Text(
                  context.l10n.dashboardBarberActive,
                  style: context.appTextStyles.medium.copyWith(
                    color: context.appColors.primaryTextColor,
                  ),
                ),
                value: active.value,
                onChanged: (v) => active.value = v,
                activeTrackColor: context.appColors.primaryColor.withValues(
                  alpha: 0.5,
                ),
                activeThumbColor: context.appColors.primaryColor,
              ),
              Gap(context.appSizes.paddingMedium),
              ExpansionTile(
                initiallyExpanded: showWorkingHours.value,
                title: Text(
                  context.l10n.dashboardBarberWorkingHoursOverride,
                  style: context.appTextStyles.medium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appColors.primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  context.l10n.dashboardBarberWorkingHoursOverrideHint,
                  style: context.appTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: context.appColors.captionTextColor,
                  ),
                ),
                onExpansionChanged:
                    (expanded) => showWorkingHours.value = expanded,
                children: [
                  Gap(context.appSizes.paddingSmall),
                  ...List.generate(
                    7,
                    (i) => _BarberWorkingHoursRow(
                      dayLabel: _dayLabels[i],
                      openController: openControllers[i],
                      closeController: closeControllers[i],
                      timeFormatError: context.l10n.dashboardLocationTimeFormat,
                      startBeforeEndError:
                          context.l10n.dashboardLocationStartBeforeEnd,
                    ),
                  ),
                  Gap(context.appSizes.paddingSmall),
                ],
              ),
              Gap(context.appSizes.paddingLarge),
              PrimaryButton.big(
                onPressed: submit,
                child: Text(context.l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _normalizeTime(String s) {
    if (s.isEmpty) return s;
    if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) return s;
    final parts = s.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  static String _slugFromName(String name) {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isNotEmpty
        ? slug
        : 'barber-${DateTime.now().millisecondsSinceEpoch}';
  }
}

class _BarberWorkingHoursRow extends StatelessWidget {
  const _BarberWorkingHoursRow({
    required this.dayLabel,
    required this.openController,
    required this.closeController,
    required this.timeFormatError,
    required this.startBeforeEndError,
  });

  final String dayLabel;
  final TextEditingController openController;
  final TextEditingController closeController;
  final String timeFormatError;
  final String startBeforeEndError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.appSizes.paddingSmall),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              dayLabel,
              style: context.appTextStyles.medium.copyWith(
                fontSize: 12,
                color: context.appColors.secondaryTextColor,
              ),
            ),
          ),
          Gap(context.appSizes.paddingSmall),
          Expanded(
            child: TextFormField(
              controller: openController,
              decoration: InputDecoration(
                hintText: '09:00',
                filled: true,
                fillColor: context.appColors.secondaryColor,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.appSizes.paddingSmall,
                  horizontal: context.appSizes.paddingMedium,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    context.appSizes.borderRadius,
                  ),
                ),
              ),
              inputFormatters: [
                TimeInputFormatter(),
                LengthLimitingTextInputFormatter(5),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '–',
              style: context.appTextStyles.medium.copyWith(
                color: context.appColors.captionTextColor,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: closeController,
              decoration: InputDecoration(
                hintText: '18:00',
                filled: true,
                fillColor: context.appColors.secondaryColor,
                contentPadding: EdgeInsets.symmetric(
                  vertical: context.appSizes.paddingSmall,
                  horizontal: context.appSizes.paddingMedium,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    context.appSizes.borderRadius,
                  ),
                ),
              ),
              inputFormatters: [
                TimeInputFormatter(),
                LengthLimitingTextInputFormatter(5),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final formatErr = validateTimeFormat(
                  v,
                  formatError: timeFormatError,
                );
                if (formatErr != null) return formatErr;
                final open = openController.text.trim();
                if (open.isEmpty) return null;
                return validateStartBeforeEnd(
                  open,
                  v,
                  errorMessage: startBeforeEndError,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
