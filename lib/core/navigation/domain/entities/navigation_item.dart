import 'package:barber/gen/assets.gen.dart';

class NavigationItem {
  final String route;
  final String label;
  final SvgGenImage Function(bool isSelected) iconBuilder;

  const NavigationItem({
    required this.route,
    required this.label,
    required this.iconBuilder,
  });
}