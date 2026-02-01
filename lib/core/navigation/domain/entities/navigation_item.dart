class NavigationItem {
  final String route;
  final String label;
  final String Function(bool isSelected) iconBuilder;

  const NavigationItem({
    required this.route,
    required this.label,
    required this.iconBuilder,
  });
}