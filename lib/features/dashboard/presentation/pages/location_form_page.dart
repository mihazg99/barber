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
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Full-page form for add/edit location. Pass [location] for edit, null for create.
class LocationFormPage extends HookConsumerWidget {
  const LocationFormPage({super.key, this.location});

  final LocationEntity? location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = location != null;
    final nameController = useTextEditingController(text: location?.name ?? '');
    final addressController = useTextEditingController(
      text: location?.address ?? '',
    );
    final phoneController = useTextEditingController(
      text: location?.phone ?? '',
    );
    final latController = useTextEditingController(
      text:
          location != null && location!.latitude != 0
              ? location!.latitude.toString()
              : '',
    );
    final lngController = useTextEditingController(
      text:
          location != null && location!.longitude != 0
              ? location!.longitude.toString()
              : '',
    );
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final openControllers = useMemoized(
      () => List.generate(
        7,
        (i) => TextEditingController(
          text: _getHoursForDay(i)?.open ?? '',
        ),
      ),
      [location?.workingHours],
    );
    final closeControllers = useMemoized(
      () => List.generate(
        7,
        (i) => TextEditingController(
          text: _getHoursForDay(i)?.close ?? '',
        ),
      ),
      [location?.workingHours],
    );

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

    final notifier = ref.read(dashboardLocationsNotifierProvider.notifier);
    final effectiveBrandId = ref.watch(dashboardBrandIdProvider);

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

      final errorColor = context.appColors.errorColor;
      final primaryColor = context.appColors.primaryColor;
      final savedMsg = context.l10n.dashboardLocationSaved;
      final navigator = Navigator.of(context);

      final hours = <String, DayWorkingHours?>{};
      for (var i = 0; i < 7; i++) {
        final open = _normalizeTime(openControllers[i].text.trim());
        final close = _normalizeTime(closeControllers[i].text.trim());
        if (open.isNotEmpty && close.isNotEmpty) {
          hours[_dayKeys[i]] = DayWorkingHours(open: open, close: close);
        } else {
          hours[_dayKeys[i]] = null;
        }
      }

      final lat = double.tryParse(latController.text.trim()) ?? 0.0;
      final lng = double.tryParse(lngController.text.trim()) ?? 0.0;
      final locationId =
          isEdit
              ? location!.locationId
              : _slugFromName(nameController.text.trim());

      final entity = LocationEntity(
        locationId: locationId,
        brandId: effectiveBrandId,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        latitude: lat,
        longitude: lng,
        phone: phoneController.text.trim(),
        workingHours: hours,
      );

      if (isEdit) {
        await notifier.update(entity);
      } else {
        await notifier.create(entity);
      }

      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger != null) {
        if (notifier.hasError) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(notifier.errorMessage ?? 'Error'),
              backgroundColor: errorColor,
            ),
          );
        } else {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(savedMsg),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: AppBar(
        leading: CustomBackButton(),
        title: Text(
          isEdit
              ? context.l10n.dashboardLocationEdit
              : context.l10n.dashboardLocationAdd,
          style: context.appTextStyles.bold.copyWith(
            color: context.appColors.primaryTextColor,
          ),
        ),
        backgroundColor: context.appColors.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField.withTitle(
                  title: context.l10n.dashboardLocationName,
                  hint: context.l10n.dashboardLocationNameHint,
                  controller: nameController,
                  validator:
                      (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? context.l10n.dashboardLocationNameRequired
                              : null,
                ),
                Gap(context.appSizes.paddingMedium),
                CustomTextField.withTitle(
                  title: context.l10n.dashboardLocationAddress,
                  hint: context.l10n.dashboardLocationAddressHint,
                  controller: addressController,
                ),
                Gap(context.appSizes.paddingMedium),
                CustomTextField.withTitle(
                  title: context.l10n.dashboardLocationPhone,
                  hint: context.l10n.dashboardLocationPhoneHint,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),
                Gap(context.appSizes.paddingMedium),
                Text(
                  context.l10n.dashboardLocationCoordinates,
                  style: context.appTextStyles.h2.copyWith(
                    color: context.appColors.secondaryTextColor,
                  ),
                ),
                Gap(context.appSizes.paddingSmall),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField.withTitle(
                        title: 'Lat',
                        hint: context.l10n.dashboardLocationLatHint,
                        controller: latController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    Gap(context.appSizes.paddingSmall),
                    Expanded(
                      child: CustomTextField.withTitle(
                        title: 'Lng',
                        hint: context.l10n.dashboardLocationLngHint,
                        controller: lngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(context.appSizes.paddingMedium),
                Text(
                  context.l10n.dashboardLocationWorkingHours,
                  style: context.appTextStyles.h2.copyWith(
                    color: context.appColors.secondaryTextColor,
                  ),
                ),
                Gap(context.appSizes.paddingSmall),
                ...List.generate(
                  7,
                  (i) => _WorkingHoursRow(
                    dayLabel: _dayLabels[i],
                    openController: openControllers[i],
                    closeController: closeControllers[i],
                    timeFormatError: context.l10n.dashboardLocationTimeFormat,
                    startBeforeEndError:
                        context.l10n.dashboardLocationStartBeforeEnd,
                  ),
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
      ),
    );
  }

  DayWorkingHours? _getHoursForDay(int index) {
    if (location == null) return null;
    return location!.workingHours[_dayKeys[index]];
  }

  static String _normalizeTime(String s) {
    if (s.isEmpty) return s;
    if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) return s;
    final parts = s.split(':');
    final h = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    return '$h:$m';
  }

  static String _slugFromName(String name) {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isNotEmpty ? slug : 'location';
  }
}

class _WorkingHoursRow extends StatelessWidget {
  const _WorkingHoursRow({
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
                hintText: '14:00',
                hintStyle: context.appTextStyles.fields.copyWith(
                  color: context.appColors.hintTextColor,
                ),
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
                return validateTimeFormat(v, formatError: timeFormatError);
              },
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
                hintStyle: context.appTextStyles.fields.copyWith(
                  color: context.appColors.hintTextColor,
                ),
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
