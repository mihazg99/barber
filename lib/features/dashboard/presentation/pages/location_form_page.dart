import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/core/widgets/custom_back_button.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/dashboard/presentation/widgets/edit_location_working_hours_dialog.dart';
import 'package:barber/features/dashboard/presentation/widgets/location_working_hours_card.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

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

    // Working hours state - managed separately from controllers
    final workingHours = useState<WorkingHoursMap?>(location?.workingHours);

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
        workingHours: workingHours.value ?? {},
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
                  validator:
                      (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? context.l10n.dashboardLocationAddressRequired
                              : null,
                ),
                Gap(context.appSizes.paddingMedium),
                CustomTextField.withTitle(
                  title: context.l10n.dashboardLocationPhone,
                  hint: context.l10n.dashboardLocationPhoneHint,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator:
                      (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? context.l10n.dashboardLocationPhoneRequired
                              : null,
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
                LocationWorkingHoursCard(
                  workingHours: workingHours.value,
                  onEdit: () async {
                    final result = await showModalBottomSheet<WorkingHoursMap>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) => EditLocationWorkingHoursDialog(
                            initialHours: workingHours.value,
                          ),
                    );
                    if (result != null) {
                      workingHours.value = result;
                    }
                  },
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
