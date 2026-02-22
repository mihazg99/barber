import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/inventory/di.dart';
import 'package:barber/gen/assets.gen.dart';

class ImagePickerSection extends HookConsumerWidget {
  const ImagePickerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imagePickerProvider);
    final notifier = ref.read(imagePickerProvider.notifier);

    final imagePath =
        state is BaseData<String> && state.data.isNotEmpty ? state.data : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo',
          style: context.appTextStyles.h2.copyWith(
            color: context.appColors.secondaryTextColor,
          ),
        ),
        SizedBox(height: context.appSizes.paddingSmall),
        GestureDetector(
          onTap: imagePath == null ? notifier.pickImage : null,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: context.appColors.secondaryColor,
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
            ),
            child: Center(
              child:
                  imagePath == null
                      ? Assets.icons.photo.svg()
                      : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              context.appSizes.borderRadius,
                            ),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: 140,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: notifier.removeImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.appColors.primaryTextColor.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: context.appColors.primaryWhiteColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ],
    );
  }
}
