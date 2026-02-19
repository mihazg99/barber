import 'package:flutter/material.dart';
import 'package:barber/core/utils/price_formatter.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:gap/gap.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

class BookingServiceSection extends HookWidget {
  const BookingServiceSection({
    super.key,
    required this.services,
    required this.selectedServiceId,
    required this.onServiceSelected,
  });

  final List<ServiceEntity> services;
  final String? selectedServiceId;
  final void Function(ServiceEntity) onServiceSelected;

  @override
  Widget build(BuildContext context) {
    // efficient category extraction
    final categories = useMemoized<List<String>>(() {
      final cats =
          services
              .map((s) => s.category)
              .where((c) => c != null && c.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
      cats.sort();
      return ['All', ...cats];
    }, [services]);

    final selectedCategory = useState('All');

    // Reset category if selected service changes and belongs to a different category
    useEffect(() {
      if (selectedServiceId != null) {
        final service = services.firstWhere(
          (s) => s.serviceId == selectedServiceId,
          orElse: () => services.first,
        );
        if (service.category != null &&
            selectedCategory.value != 'All' &&
            service.category != selectedCategory.value) {
          // If we wanted to auto-switch category on external selection, we could do it here.
          // But for now let's keep it simple.
        }
      }
      return null;
    }, [selectedServiceId]);

    final filteredServices = useMemoized(() {
      if (selectedCategory.value == 'All') return services;
      return services
          .where((s) => s.category == selectedCategory.value)
          .toList();
    }, [services, selectedCategory.value]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
          ),
          child: Text(
            context.l10n.bookingSelectService,
            style: context.appTextStyles.h2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.appColors.primaryTextColor,
            ),
          ),
        ),

        // Category Chips
        if (categories.length > 1) ...[
          Gap(context.appSizes.paddingSmall),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: context.appSizes.paddingMedium,
            ),
            child: Row(
              children:
                  categories.map((category) {
                    final isSelected = category == selectedCategory.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          category == 'All' ? 'All' : category,
                        ), // Assuming 'All' localization or literal
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            selectedCategory.value = category;
                          }
                        },
                        backgroundColor: context.appColors.menuBackgroundColor,
                        selectedColor: context.appColors.primaryColor
                            .withValues(alpha: 0.1),
                        checkmarkColor: context.appColors.primaryColor,
                        labelStyle: context.appTextStyles.body.copyWith(
                          color:
                              isSelected
                                  ? context.appColors.primaryColor
                                  : context.appColors.primaryTextColor,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? context.appColors.primaryColor
                                    : context.appColors.borderColor.withValues(
                                      alpha: 0.5,
                                    ),
                          ),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],

        Gap(context.appSizes.paddingSmall),

        if (filteredServices.isEmpty)
          Padding(
            padding: EdgeInsets.all(context.appSizes.paddingMedium),
            child: Text(
              'No services available',
              style: context.appTextStyles.body.copyWith(
                color: context.appColors.captionTextColor,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: context.appSizes.paddingMedium,
            ),
            itemCount: filteredServices.length,
            separatorBuilder: (_, __) => Gap(context.appSizes.paddingSmall),
            itemBuilder: (context, index) {
              final service = filteredServices[index];
              final isSelected = service.serviceId == selectedServiceId;
              return _ServiceCard(
                service: service,
                isSelected: isSelected,
                onTap: () => onServiceSelected(service),
              );
            },
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  final ServiceEntity service;
  final bool isSelected;
  final VoidCallback onTap;

  String _formatPrice(BuildContext context, num price) =>
      context.formatPriceWithCurrency(price);

  static String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? context.appColors.primaryColor.withValues(alpha: 0.05)
                    : context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
            border: Border.all(
              color:
                  isSelected
                      ? context.appColors.primaryColor
                      : context.appColors.borderColor.withValues(alpha: 0.4),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.primaryTextColor,
                      ),
                    ),
                    Gap(4),
                    Row(
                      children: [
                        Text(
                          _formatPrice(context, service.price),
                          style: context.appTextStyles.h2.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.appColors.captionTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(service.durationMinutes),
                          style: context.appTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: context.appColors.captionTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: context.appColors.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
