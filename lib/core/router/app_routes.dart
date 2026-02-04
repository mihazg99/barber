enum AppRoute {
  onboarding(name: 'Onboarding', path: '/onboarding'),
  auth(name: 'Auth', path: '/auth'),
  home(name: 'Home', path: '/'),
  dashboard(name: 'Dashboard', path: '/dashboard'),
  booking(name: 'Booking', path: '/booking'),
  manageBooking(name: 'Manage booking', path: '/manage_booking/:appointmentId'),
  editBooking(name: 'Edit booking', path: '/edit_booking/:appointmentId'),
  loyalty(name: 'Loyalty', path: '/loyalty'),
  inventory(name: 'Inventory', path: '/inventory'),
  statistics(name: 'Statistics', path: '/statistics'),
  addNewItem(name: 'Add new item', path: '/add_new_item'),
  dashboardLocationForm(name: 'Location form', path: '/dashboard/location_form'),
  dashboardServiceForm(name: 'Service form', path: '/dashboard/service_form'),
  dashboardBarberForm(name: 'Barber form', path: '/dashboard/barber_form');

  final String name;
  final String path;

  const AppRoute({required this.name, required this.path});
}
