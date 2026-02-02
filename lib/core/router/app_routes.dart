enum AppRoute {
  onboarding(name: 'Onboarding', path: '/onboarding'),
  auth(name: 'Auth', path: '/auth'),
  home(name: 'Home', path: '/'),
  inventory(name: 'Inventory', path: '/inventory'),
  statistics(name: 'Statistics', path: '/statistics'),
  addNewItem(name: 'Add new item', path: '/add_new_item');

  final String name;
  final String path;

  const AppRoute({required this.name, required this.path});
}
