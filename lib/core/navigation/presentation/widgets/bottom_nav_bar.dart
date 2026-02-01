import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:barber/core/navigation/data/navigation_config.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/utils/extensions/go_router_extension.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRouteName = context.currentNavigationRouteName;
    final textStyles = context.appTextStyles;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: context.currentNavigationIndex,
      onTap:
          (index) =>
              context.navigateToRoute(NavigationConfig.items[index].route),
      backgroundColor: context.appColors.navigationBackgroundColor,
      selectedItemColor: context.appColors.primaryColor,
      unselectedItemColor: context.appColors.secondaryTextColor,
      selectedLabelStyle: textStyles.medium.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: textStyles.medium.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      items:
          NavigationConfig.items.map((item) {
            final isSelected = item.route == currentRouteName;

            return BottomNavigationBarItem(
              icon: Container(
                margin: EdgeInsets.symmetric(
                  vertical: context.appSizes.paddingSmall,
                ),
                child: SvgPicture.asset(
                  item.iconBuilder(isSelected),
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? context.appColors.primaryColor
                        : context.appColors.secondaryTextColor,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
              ),
              label: item.label,
            );
          }).toList(),
    );
  }
}
