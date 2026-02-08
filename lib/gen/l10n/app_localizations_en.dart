// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Retry';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get search => 'Search';

  @override
  String get book => 'Book';

  @override
  String get manage => 'Manage';

  @override
  String get select => 'Select';

  @override
  String get selected => 'Selected';

  @override
  String get continueButton => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get logout => 'Log out';

  @override
  String get navHome => 'Home';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get onboardingBookAppointmentsTitle => 'Book appointments';

  @override
  String get onboardingBookAppointmentsDescription =>
      'Schedule your visit in a few taps and manage your bookings easily.';

  @override
  String get onboardingScanQrTitle => 'Scan QR codes';

  @override
  String get onboardingScanQrDescription =>
      'Quick check-in and access to services by scanning QR codes at the location.';

  @override
  String get onboardingManageInventoryTitle => 'Manage inventory';

  @override
  String get onboardingManageInventoryDescription =>
      'Keep track of items and boxes across your locations.';

  @override
  String get authEnterPhone => 'Enter your phone number';

  @override
  String get authVerificationCodeSent => 'We\'ll send you a verification code';

  @override
  String get authPhoneNumber => 'Phone number';

  @override
  String get authPhoneHint => '123 456 7890';

  @override
  String get authPhoneValidation => 'Enter a valid phone number';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authEnterVerificationCode => 'Enter verification code';

  @override
  String authCodeSentTo(String phone) {
    return 'We sent a code to $phone';
  }

  @override
  String get authVerificationCode => 'Verification code';

  @override
  String get authCodeHint => '123456';

  @override
  String get authCodeValidation => 'Enter the 6-digit code';

  @override
  String get authVerify => 'Verify';

  @override
  String get authCompleteProfile => 'Complete your profile';

  @override
  String get authProfileDescription =>
      'Add your name so we can personalize your experience';

  @override
  String get authFullName => 'Full name';

  @override
  String get authFullNameHint => 'John Doe';

  @override
  String get authFullNameValidation => 'Please enter your name';

  @override
  String get authPhone => 'Phone';

  @override
  String get welcome => 'Welcome';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get or => 'or';

  @override
  String get continueWithPhone => 'Continue with Phone';

  @override
  String get bookingTitle => 'Book appointment';

  @override
  String get bookingSelectService => 'Select Service';

  @override
  String get bookingSelectBarber => 'Select Barber';

  @override
  String get bookingAnyBarber => 'Any Barber';

  @override
  String get bookingSelectDate => 'Select Date';

  @override
  String get bookingSelectTime => 'Select Time';

  @override
  String get bookingConfirm => 'Confirm Booking';

  @override
  String get bookingTotal => 'Total';

  @override
  String bookingWithBarber(String barberName) {
    return 'Booking with $barberName';
  }

  @override
  String get timeMorning => 'Morning';

  @override
  String get timeAfternoon => 'Afternoon';

  @override
  String get timeEvening => 'Evening';

  @override
  String get bookingNoAvailableTimes => 'No available times';

  @override
  String get bookingSelectDifferentDate => 'Please select a different date';

  @override
  String get bookingAppointmentSuccess => 'Appointment booked successfully!';

  @override
  String get bookingUserNotAuthenticated => 'User not authenticated';

  @override
  String get bookingAlreadyHasUpcoming =>
      'You already have an upcoming appointment. Cancel or complete it before booking another.';

  @override
  String get bookingStepLocation => 'Location';

  @override
  String get bookingSelectLocation => 'Select Location';

  @override
  String get bookingStepService => 'Service';

  @override
  String get bookingStepBarber => 'Barber';

  @override
  String get bookingStepTime => 'Time';

  @override
  String get manageBookingTitle => 'Manage booking';

  @override
  String get manageBookingReschedule => 'Reschedule';

  @override
  String get manageBookingCancelAppointment => 'Cancel appointment';

  @override
  String get manageBookingCancelConfirmTitle => 'Cancel appointment?';

  @override
  String get manageBookingCancelConfirmMessage =>
      'Are you sure you want to cancel this appointment? This action cannot be undone.';

  @override
  String get manageBookingCancelConfirm => 'Yes, cancel';

  @override
  String get manageBookingCanceledSnackbar => 'Appointment canceled';

  @override
  String manageBookingCancelPolicyHours(int hours) {
    return 'Cancellation must be done at least $hours hours before the appointment.';
  }

  @override
  String get manageBookingCancelPeriodPassed =>
      'The cancellation period has passed. You can no longer cancel or reschedule this appointment.';

  @override
  String get editBookingTitle => 'Change date & time';

  @override
  String get editBookingSelectNewDate => 'Select new date';

  @override
  String get editBookingSelectNewTime => 'Select new time';

  @override
  String get editBookingUpdateButton => 'Update appointment';

  @override
  String get editBookingSuccessSnackbar => 'Appointment updated successfully';

  @override
  String get editBookingErrorSnackbar =>
      'Could not update appointment. Please try again.';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get upcomingAppointment => 'Upcoming appointment';

  @override
  String get bookYourNextVisit => 'Book your next visit';

  @override
  String get chooseLocationServiceTime => 'Choose location, service and time';

  @override
  String get bookNow => 'Book Now';

  @override
  String get sectionBarbers => 'Book with a barber';

  @override
  String get sectionPopularServices => 'Popular services';

  @override
  String get sectionNearbyBarbershop => 'NEARBY BARBERSHOP';

  @override
  String get loyaltyTitle => 'LOYALTY';

  @override
  String get loyaltyPointsAbbrev => 'pts';

  @override
  String get loyaltyMember => 'MEMBER';

  @override
  String get loyaltyViewRewards => 'View rewards';

  @override
  String get loyaltyPageTitle => 'Loyalty & Rewards';

  @override
  String get loyaltyRewardsComingSoon => 'Rewards coming soon';

  @override
  String get loyaltyEarnPointsDescription => 'Earn points and redeem rewards';

  @override
  String get loyaltyRedeem => 'Redeem';

  @override
  String get loyaltyMyRewards => 'My rewards';

  @override
  String get loyaltyInsufficientPoints => 'Not enough points';

  @override
  String get loyaltyRedeemSuccess =>
      'Reward claimed! Show this QR at the barber.';

  @override
  String get dashboardRedeemReward => 'Redeem reward';

  @override
  String get barberHomeGreetingMorning => 'Good morning';

  @override
  String get barberHomeGreetingAfternoon => 'Good afternoon';

  @override
  String get barberHomeGreetingEvening => 'Good evening';

  @override
  String get barberHomeScanCta => 'Scan QR';

  @override
  String get barberHomeScanSubtitle => 'Redeem rewards or add loyalty points';

  @override
  String get barberHomeRedeemReward => 'Redeem reward';

  @override
  String get barberHomeAddLoyalty => 'Add loyalty points';

  @override
  String get barberHomeViewBookings => 'View bookings';

  @override
  String get barberHomeTodayTitle => 'Today';

  @override
  String get barberHomeTodayEmpty => 'No appointments today';

  @override
  String get barberHomeUpcomingEmpty => 'No upcoming appointments';

  @override
  String get barberHomeUpcomingCardTitle => 'Appointments';

  @override
  String get barberHomeHey => 'Hey 👋';

  @override
  String barberHomeHeyName(String name) {
    return 'Hey, $name 👋';
  }

  @override
  String get barberHomeQuickActions => 'Quick actions';

  @override
  String get redeemSuccess => 'Reward redeemed';

  @override
  String get alreadyRedeemed => 'Already redeemed';

  @override
  String get scanPointsAwardedTitle => 'Points awarded';

  @override
  String scanPointsAwardedMessage(String customerName, int pointsAwarded) {
    return '$customerName received $pointsAwarded loyalty points.';
  }

  @override
  String get dashboardNavHome => 'Home';

  @override
  String get dashboardNavBookings => 'Bookings';

  @override
  String get dashboardNavCalendar => 'Calendar';

  @override
  String get dashboardNavShift => 'Shift';

  @override
  String get dashboardNavBrand => 'Brand';

  @override
  String get dashboardNavLocations => 'Locations';

  @override
  String get dashboardNavServices => 'Services';

  @override
  String get dashboardNavRewards => 'Rewards';

  @override
  String get dashboardNavBarbers => 'Barbers';

  @override
  String get dashboardNavAnalytics => 'Analytics';

  @override
  String get dashboardBookingsTitle => 'My Bookings';

  @override
  String get dashboardShiftTitle => 'My Shift';

  @override
  String get marketingInsightsTitle => 'Marketing Insights';

  @override
  String get averageTicketValue => 'Avg. ticket value';

  @override
  String get todayRevenue => 'Today\'s revenue';

  @override
  String get todayAppointments => 'Appointments today';

  @override
  String get newCustomersToday => 'New customers';

  @override
  String get noShowsToday => 'No-shows';

  @override
  String get addNewItem => 'Add new item';

  @override
  String get addItemTitle => 'Title';

  @override
  String get addItemTitleHint => 'Enter item title';

  @override
  String get addItemTitleRequired => 'Title is required';

  @override
  String get addItemCategory => 'Category';

  @override
  String get addItemCategoryHint => 'Enter category';

  @override
  String get addItemLocation => 'Location';

  @override
  String get addItemSelectLocation => 'Select location';

  @override
  String get addItemBox => 'Box';

  @override
  String get addItemSelectBox => 'Select box';

  @override
  String get addItemPriceOptional => 'Price (optional)';

  @override
  String get addItemPriceHint => 'Enter price';

  @override
  String addItemSavedSuccess(String name) {
    return 'Item $name saved successfully';
  }

  @override
  String addItemError(String message) {
    return 'Error: $message';
  }

  @override
  String get inventoryItems => 'Items';

  @override
  String get inventoryBoxes => 'Boxes';

  @override
  String get inventoryLocations => 'Locations';

  @override
  String get addNewBox => 'Add New Box';

  @override
  String get addBoxLabel => 'Box Label';

  @override
  String get addBoxLabelHint => 'e.g., Kitchen Utensils, Tools, Documents';

  @override
  String get addBoxLabelRequired => 'Please enter a box label';

  @override
  String get addBoxSuccess => 'Box added successfully!';

  @override
  String addBoxError(String error) {
    return 'Error adding box: $error';
  }

  @override
  String get addNewLocation => 'Add New Location';

  @override
  String get addLocationName => 'Location Name';

  @override
  String get addLocationNameHint => 'e.g., Kitchen, Garage, Office';

  @override
  String get addLocationNameRequired => 'Please enter a location name';

  @override
  String get addLocationColor => 'Color';

  @override
  String get addLocationColorHint => '#4CAF50';

  @override
  String get addLocationColorRequired => 'Please enter a color';

  @override
  String get addLocationColorInvalid =>
      'Please enter a valid hex color (e.g., #4CAF50)';

  @override
  String get addLocationSuccess => 'Location added successfully!';

  @override
  String addLocationError(String error) {
    return 'Error adding location: $error';
  }

  @override
  String get selectCountry => 'Select country';

  @override
  String get searchCountryOrCode => 'Search country or code';

  @override
  String get dashboardBrandTitle => 'Brand';

  @override
  String get dashboardBrandName => 'Name';

  @override
  String get dashboardBrandNameHint => 'e.g. Kingsman Barbershop';

  @override
  String get dashboardBrandNameRequired => 'Name is required';

  @override
  String get dashboardBrandPrimaryColor => 'Primary color';

  @override
  String get dashboardBrandPrimaryColorHint => '#9B784A';

  @override
  String get dashboardBrandLogoUrl => 'Logo URL';

  @override
  String get dashboardBrandLogoUrlHint => 'https://...';

  @override
  String get dashboardBrandContactEmail => 'Contact email';

  @override
  String get dashboardBrandContactEmailHint => 'contact@example.com';

  @override
  String get dashboardBrandSlotInterval => 'Slot interval (minutes)';

  @override
  String get dashboardBrandBufferTime => 'Buffer time (minutes)';

  @override
  String get dashboardBrandCancelHours => 'Cancel minimum hours';

  @override
  String get dashboardBrandLoyaltyPointsMultiplier => 'Loyalty points per 1€';

  @override
  String get dashboardBrandLoyaltyPointsMultiplierHint =>
      'e.g. 10 (30€ → 300 points)';

  @override
  String get dashboardBrandMultiLocation => 'Multi location';

  @override
  String get dashboardBrandSaved => 'Brand saved';

  @override
  String get dashboardBrandCreated => 'Brand created';

  @override
  String get dashboardBrandSetConfigId =>
      'Set default_brand_id in assets/config/default.json';

  @override
  String get dashboardLocationAdd => 'Add Location';

  @override
  String get dashboardLocationEdit => 'Edit Location';

  @override
  String get dashboardLocationName => 'Name';

  @override
  String get dashboardLocationNameHint => 'e.g. Zagreb Centar';

  @override
  String get dashboardLocationNameRequired => 'Name is required';

  @override
  String get dashboardLocationAddress => 'Address';

  @override
  String get dashboardLocationAddressHint => 'Street, city';

  @override
  String get dashboardLocationPhone => 'Phone';

  @override
  String get dashboardLocationPhoneHint => '+385 1 234 5678';

  @override
  String get dashboardLocationCoordinates => 'Coordinates';

  @override
  String get dashboardLocationLatHint => 'Latitude (e.g. 45.81)';

  @override
  String get dashboardLocationLngHint => 'Longitude (e.g. 15.98)';

  @override
  String get dashboardLocationWorkingHours => 'Working hours';

  @override
  String get dashboardLocationTimeFormat => 'Use HH:mm (e.g. 14:00)';

  @override
  String get dashboardLocationStartBeforeEnd => 'Start must be before end';

  @override
  String get dashboardLocationDayClosed => 'Closed';

  @override
  String get dashboardLocationSaved => 'Location saved';

  @override
  String get dashboardLocationDeleted => 'Location deleted';

  @override
  String get dashboardLocationDeleteConfirm => 'Delete this location?';

  @override
  String get dashboardLocationDeleteConfirmMessage => 'This cannot be undone.';

  @override
  String get dashboardLocationDeleteButton => 'Delete';

  @override
  String get dashboardLocationEmpty => 'No locations yet. Tap + to add one.';

  @override
  String get dashboardNoBrand => 'No brand configured';

  @override
  String get dashboardServiceAdd => 'Add Service';

  @override
  String get dashboardServiceEdit => 'Edit Service';

  @override
  String get dashboardServiceName => 'Name';

  @override
  String get dashboardServiceNameHint => 'e.g. Haircut & Wash';

  @override
  String get dashboardServiceNameRequired => 'Name is required';

  @override
  String get dashboardServicePrice => 'Price';

  @override
  String get dashboardServicePriceHint => '0';

  @override
  String get dashboardServicePriceInvalid => 'Enter a valid price';

  @override
  String get dashboardServiceDuration => 'Duration (minutes)';

  @override
  String get dashboardServiceDurationHint => '30';

  @override
  String get dashboardServiceDurationInvalid =>
      'Enter a valid duration (min 1)';

  @override
  String get dashboardServiceDescription => 'Description';

  @override
  String get dashboardServiceDescriptionHint => 'Optional description';

  @override
  String get dashboardServiceAvailableAt => 'Available at';

  @override
  String get dashboardServiceAvailableAtAll => 'All locations';

  @override
  String get dashboardServiceAvailableAtSelected => 'Selected locations only';

  @override
  String get dashboardServiceSaved => 'Service saved';

  @override
  String get dashboardServiceCreated => 'Service created';

  @override
  String get dashboardServiceDeleteConfirm => 'Delete this service?';

  @override
  String get dashboardServiceDeleteConfirmMessage => 'This cannot be undone.';

  @override
  String get dashboardServiceDeleteButton => 'Delete';

  @override
  String get dashboardServiceDeleted => 'Service deleted';

  @override
  String get dashboardServiceEmpty => 'No services yet. Tap + to add one.';

  @override
  String get dashboardBarberAdd => 'Add Barber';

  @override
  String get dashboardBarberEdit => 'Edit Barber';

  @override
  String get dashboardBarberName => 'Name';

  @override
  String get dashboardBarberNameHint => 'e.g. John Smith';

  @override
  String get dashboardBarberNameRequired => 'Name is required';

  @override
  String get dashboardBarberPhotoUrl => 'Photo URL';

  @override
  String get dashboardBarberPhotoUrlHint => 'https://...';

  @override
  String get dashboardBarberLocation => 'Location';

  @override
  String get dashboardBarberLocationRequired => 'Select a location';

  @override
  String get dashboardBarberNoLocations =>
      'Add locations first in the Locations tab.';

  @override
  String get dashboardBarberActive => 'Active';

  @override
  String get dashboardBarberWorkingHoursOverride => 'Custom working hours';

  @override
  String get dashboardBarberWorkingHoursOverrideHint =>
      'Override location hours for this barber. Leave empty to use location hours.';

  @override
  String get dashboardBarberSaved => 'Barber saved';

  @override
  String get dashboardBarberCreated => 'Barber created';

  @override
  String get dashboardBarberDeleteConfirm => 'Delete this barber?';

  @override
  String get dashboardBarberDeleteConfirmMessage => 'This cannot be undone.';

  @override
  String get dashboardBarberDeleteButton => 'Delete';

  @override
  String get dashboardBarberDeleted => 'Barber deleted';

  @override
  String get dashboardBarberEmpty => 'No barbers yet. Tap + to add one.';

  @override
  String get dashboardBarberInactive => 'Inactive';

  @override
  String get dashboardRewardAdd => 'Add Reward';

  @override
  String get dashboardRewardEdit => 'Edit Reward';

  @override
  String get dashboardRewardName => 'Name';

  @override
  String get dashboardRewardNameHint => 'e.g. Free coffee';

  @override
  String get dashboardRewardNameRequired => 'Name is required';

  @override
  String get dashboardRewardDescription => 'Description';

  @override
  String get dashboardRewardDescriptionHint => 'Optional description';

  @override
  String get dashboardRewardPointsCostLabel => 'Points cost';

  @override
  String get dashboardRewardPointsCostHint => '100';

  @override
  String get dashboardRewardPointsInvalid =>
      'Enter a valid points value (0 or more)';

  @override
  String dashboardRewardPointsCost(int points) {
    return '$points pts';
  }

  @override
  String get dashboardRewardSortOrder => 'Sort order';

  @override
  String get dashboardRewardSortOrderHint => '0';

  @override
  String get dashboardRewardActive => 'Active';

  @override
  String get dashboardRewardSaved => 'Reward saved';

  @override
  String get dashboardRewardCreated => 'Reward created';

  @override
  String get dashboardRewardDeleteConfirm => 'Delete this reward?';

  @override
  String get dashboardRewardDeleteConfirmMessage => 'This cannot be undone.';

  @override
  String get dashboardRewardDeleteButton => 'Delete';

  @override
  String get dashboardRewardDeleted => 'Reward deleted';

  @override
  String get dashboardRewardEmpty => 'No rewards yet. Tap + to add one.';

  @override
  String get dashboardRewardInactive => 'Inactive';

  @override
  String get closed => 'Closed';

  @override
  String openNow(String open, String close) {
    return 'OPEN NOW $open - $close';
  }

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarNoAppointments => 'No appointments';

  @override
  String calendarAppointmentsCount(int count) {
    return '$count appointment(s)';
  }

  @override
  String get calendarViewDay => 'Day';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewMonth => 'Month';

  @override
  String get calendarAppointmentDetails => 'Appointment details';

  @override
  String get calendarClient => 'Client';

  @override
  String get calendarService => 'Service';

  @override
  String get calendarTime => 'Time';

  @override
  String get calendarDuration => 'Duration';

  @override
  String get calendarPrice => 'Price';

  @override
  String get calendarStatus => 'Status';

  @override
  String get calendarLocation => 'Location';

  @override
  String get errorLoadingAppointments => 'Error loading appointments';
}
