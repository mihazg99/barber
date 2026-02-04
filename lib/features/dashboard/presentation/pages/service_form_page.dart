import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_back_button.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/di.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';

/// Full-page form for add/edit service. Pass [service] for edit, null for create.
class ServiceFormPage extends HookConsumerWidget {
  const ServiceFormPage({super.key, this.service});

  final ServiceEntity? service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = service != null;
    final nameController = useTextEditingController(text: service?.name ?? '');
    final priceController = useTextEditingController(
      text: service != null ? '${service!.price}' : '',
    );
    final durationController = useTextEditingController(
      text: service != null ? '${service!.durationMinutes}' : '',
    );
    final descriptionController = useTextEditingController(
      text: service?.description ?? '',
    );
    final availableAtAll = useState(service?.availableAtLocations.isEmpty ?? true);
    final selectedLocationIds = useState<Set<String>>(
      service != null && service!.availableAtLocations.isNotEmpty
          ? Set.from(service!.availableAtLocations)
          : {},
    );
    final locations = useState<List<LocationEntity>>([]);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final brandId =
        ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
    final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
    final locationRepo = ref.watch(locationRepositoryProvider);
    final notifier = ref.read(dashboardServicesNotifierProvider.notifier);

    useEffect(() {
      void loadLocations() async {
        final result = await locationRepo.getByBrandId(effectiveBrandId);
        result.fold(
          (_) => {},
          (list) => locations.value = list,
        );
      }

      loadLocations();
      return null;
    }, [effectiveBrandId, locationRepo]);

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

      final price = num.tryParse(priceController.text.trim());
      final duration = int.tryParse(durationController.text.trim());
      if (price == null || price < 0) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardServicePriceInvalid),
            backgroundColor: context.appColors.errorColor,
          ),
        );
        return;
      }
      if (duration == null || duration <= 0) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardServiceDurationInvalid),
            backgroundColor: context.appColors.errorColor,
          ),
        );
        return;
      }

      final availableAtLocations = availableAtAll.value
          ? <String>[]
          : selectedLocationIds.value.toList();

      final serviceId = isEdit
          ? service!.serviceId
          : _slugFromName(nameController.text.trim());

      final entity = ServiceEntity(
        serviceId: serviceId,
        brandId: effectiveBrandId,
        availableAtLocations: availableAtLocations,
        name: nameController.text.trim(),
        price: price,
        durationMinutes: duration,
        description: descriptionController.text.trim(),
      );

      await notifier.save(entity);

      if (!context.mounted) return;
      final messenger = rootScaffoldMessengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);
      if (notifier.hasError) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(notifier.errorMessage ?? 'Error'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      } else {
        ref.invalidate(servicesForHomeProvider);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(isEdit ? context.l10n.dashboardServiceSaved : context.l10n.dashboardServiceCreated),
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
          isEdit ? context.l10n.dashboardServiceEdit : context.l10n.dashboardServiceAdd,
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
                title: context.l10n.dashboardServiceName,
                hint: context.l10n.dashboardServiceNameHint,
                controller: nameController,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true)
                        ? context.l10n.dashboardServiceNameRequired
                        : null,
              ),
              Gap(context.appSizes.paddingMedium),
              CustomTextField.withTitle(
                title: context.l10n.dashboardServicePrice,
                hint: context.l10n.dashboardServicePriceHint,
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              Gap(context.appSizes.paddingMedium),
              CustomTextField.withTitle(
                title: context.l10n.dashboardServiceDuration,
                hint: context.l10n.dashboardServiceDurationHint,
                controller: durationController,
                keyboardType: TextInputType.number,
              ),
              Gap(context.appSizes.paddingMedium),
              CustomTextField.withTitle(
                title: context.l10n.dashboardServiceDescription,
                hint: context.l10n.dashboardServiceDescriptionHint,
                controller: descriptionController,
                maxLines: 3,
              ),
              Gap(context.appSizes.paddingLarge),
              Text(
                context.l10n.dashboardServiceAvailableAt,
                style: context.appTextStyles.medium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.primaryTextColor,
                ),
              ),
              Gap(context.appSizes.paddingSmall),
              RadioListTile<bool>(
                title: Text(
                  context.l10n.dashboardServiceAvailableAtAll,
                  style: context.appTextStyles.medium.copyWith(
                    color: context.appColors.primaryTextColor,
                  ),
                ),
                value: true,
                groupValue: availableAtAll.value,
                onChanged: (v) {
                  if (v == true) {
                    availableAtAll.value = true;
                    selectedLocationIds.value = {};
                  }
                },
                activeColor: context.appColors.primaryColor,
              ),
              RadioListTile<bool>(
                title: Text(
                  context.l10n.dashboardServiceAvailableAtSelected,
                  style: context.appTextStyles.medium.copyWith(
                    color: context.appColors.primaryTextColor,
                  ),
                ),
                value: false,
                groupValue: availableAtAll.value,
                onChanged: (v) {
                  if (v == false) availableAtAll.value = false;
                },
                activeColor: context.appColors.primaryColor,
              ),
              if (!availableAtAll.value && locations.value.isNotEmpty) ...[
                Gap(context.appSizes.paddingSmall),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: locations.value.map((loc) {
                    final isSelected = selectedLocationIds.value.contains(loc.locationId);
                    return FilterChip(
                      label: Text(loc.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        final next = Set<String>.from(selectedLocationIds.value);
                        if (selected) {
                          next.add(loc.locationId);
                        } else {
                          next.remove(loc.locationId);
                        }
                        selectedLocationIds.value = next;
                      },
                      selectedColor: context.appColors.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: context.appColors.primaryColor,
                    );
                  }).toList(),
                ),
              ],
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

  static String _slugFromName(String name) {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isNotEmpty ? slug : 'service-${DateTime.now().millisecondsSinceEpoch}';
  }
}
