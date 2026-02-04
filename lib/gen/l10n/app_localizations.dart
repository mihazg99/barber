import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hr'),
  ];

  /// No description provided for @retry.
  ///
  /// In hr, this message translates to:
  /// **'Pokušaj ponovo'**
  String get retry;

  /// No description provided for @skip.
  ///
  /// In hr, this message translates to:
  /// **'Preskoči'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In hr, this message translates to:
  /// **'Dalje'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In hr, this message translates to:
  /// **'Započni'**
  String get getStarted;

  /// No description provided for @save.
  ///
  /// In hr, this message translates to:
  /// **'Spremi'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In hr, this message translates to:
  /// **'Odustani'**
  String get cancel;

  /// No description provided for @search.
  ///
  /// In hr, this message translates to:
  /// **'Pretraži'**
  String get search;

  /// No description provided for @book.
  ///
  /// In hr, this message translates to:
  /// **'Rezerviraj'**
  String get book;

  /// No description provided for @manage.
  ///
  /// In hr, this message translates to:
  /// **'Upravljaj'**
  String get manage;

  /// No description provided for @select.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi'**
  String get select;

  /// No description provided for @selected.
  ///
  /// In hr, this message translates to:
  /// **'Odabrano'**
  String get selected;

  /// No description provided for @continueButton.
  ///
  /// In hr, this message translates to:
  /// **'Nastavi'**
  String get continueButton;

  /// No description provided for @back.
  ///
  /// In hr, this message translates to:
  /// **'Natrag'**
  String get back;

  /// No description provided for @logout.
  ///
  /// In hr, this message translates to:
  /// **'Odjava'**
  String get logout;

  /// No description provided for @navHome.
  ///
  /// In hr, this message translates to:
  /// **'Početna'**
  String get navHome;

  /// No description provided for @navInventory.
  ///
  /// In hr, this message translates to:
  /// **'Inventar'**
  String get navInventory;

  /// No description provided for @navStatistics.
  ///
  /// In hr, this message translates to:
  /// **'Statistika'**
  String get navStatistics;

  /// No description provided for @onboardingBookAppointmentsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Rezerviraj termine'**
  String get onboardingBookAppointmentsTitle;

  /// No description provided for @onboardingBookAppointmentsDescription.
  ///
  /// In hr, this message translates to:
  /// **'Zakažite posjet u nekoliko dodira i jednostavno upravljajte rezervacijama.'**
  String get onboardingBookAppointmentsDescription;

  /// No description provided for @onboardingScanQrTitle.
  ///
  /// In hr, this message translates to:
  /// **'Skeniraj QR kodove'**
  String get onboardingScanQrTitle;

  /// No description provided for @onboardingScanQrDescription.
  ///
  /// In hr, this message translates to:
  /// **'Brza prijava i pristup uslugama skeniranjem QR kodova na lokaciji.'**
  String get onboardingScanQrDescription;

  /// No description provided for @onboardingManageInventoryTitle.
  ///
  /// In hr, this message translates to:
  /// **'Upravljaj inventarom'**
  String get onboardingManageInventoryTitle;

  /// No description provided for @onboardingManageInventoryDescription.
  ///
  /// In hr, this message translates to:
  /// **'Pratite stavke i kutije na svim lokacijama.'**
  String get onboardingManageInventoryDescription;

  /// No description provided for @authEnterPhone.
  ///
  /// In hr, this message translates to:
  /// **'Unesite broj telefona'**
  String get authEnterPhone;

  /// No description provided for @authVerificationCodeSent.
  ///
  /// In hr, this message translates to:
  /// **'Poslat ćemo vam verifikacijski kod'**
  String get authVerificationCodeSent;

  /// No description provided for @authPhoneNumber.
  ///
  /// In hr, this message translates to:
  /// **'Broj telefona'**
  String get authPhoneNumber;

  /// No description provided for @authPhoneHint.
  ///
  /// In hr, this message translates to:
  /// **'123 456 7890'**
  String get authPhoneHint;

  /// No description provided for @authPhoneValidation.
  ///
  /// In hr, this message translates to:
  /// **'Unesite ispravan broj telefona'**
  String get authPhoneValidation;

  /// No description provided for @authSendCode.
  ///
  /// In hr, this message translates to:
  /// **'Pošalji kod'**
  String get authSendCode;

  /// No description provided for @authEnterVerificationCode.
  ///
  /// In hr, this message translates to:
  /// **'Unesite verifikacijski kod'**
  String get authEnterVerificationCode;

  /// No description provided for @authCodeSentTo.
  ///
  /// In hr, this message translates to:
  /// **'Poslali smo kod na {phone}'**
  String authCodeSentTo(String phone);

  /// No description provided for @authVerificationCode.
  ///
  /// In hr, this message translates to:
  /// **'Verifikacijski kod'**
  String get authVerificationCode;

  /// No description provided for @authCodeHint.
  ///
  /// In hr, this message translates to:
  /// **'123456'**
  String get authCodeHint;

  /// No description provided for @authCodeValidation.
  ///
  /// In hr, this message translates to:
  /// **'Unesite 6-znamenkasti kod'**
  String get authCodeValidation;

  /// No description provided for @authVerify.
  ///
  /// In hr, this message translates to:
  /// **'Potvrdi'**
  String get authVerify;

  /// No description provided for @authCompleteProfile.
  ///
  /// In hr, this message translates to:
  /// **'Dovršite svoj profil'**
  String get authCompleteProfile;

  /// No description provided for @authProfileDescription.
  ///
  /// In hr, this message translates to:
  /// **'Dodajte svoje ime kako bismo personalizirali vaše iskustvo'**
  String get authProfileDescription;

  /// No description provided for @authFullName.
  ///
  /// In hr, this message translates to:
  /// **'Puno ime'**
  String get authFullName;

  /// No description provided for @authFullNameHint.
  ///
  /// In hr, this message translates to:
  /// **'Ivan Horvat'**
  String get authFullNameHint;

  /// No description provided for @authFullNameValidation.
  ///
  /// In hr, this message translates to:
  /// **'Molimo unesite svoje ime'**
  String get authFullNameValidation;

  /// No description provided for @authPhone.
  ///
  /// In hr, this message translates to:
  /// **'Telefon'**
  String get authPhone;

  /// No description provided for @bookingTitle.
  ///
  /// In hr, this message translates to:
  /// **'Rezerviraj termin'**
  String get bookingTitle;

  /// No description provided for @bookingSelectService.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi uslugu'**
  String get bookingSelectService;

  /// No description provided for @bookingSelectBarber.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi brijača'**
  String get bookingSelectBarber;

  /// No description provided for @bookingAnyBarber.
  ///
  /// In hr, this message translates to:
  /// **'Bilo koji brijač'**
  String get bookingAnyBarber;

  /// No description provided for @bookingSelectDate.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi datum'**
  String get bookingSelectDate;

  /// No description provided for @bookingSelectTime.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi vrijeme'**
  String get bookingSelectTime;

  /// No description provided for @bookingConfirm.
  ///
  /// In hr, this message translates to:
  /// **'Potvrdi rezervaciju'**
  String get bookingConfirm;

  /// No description provided for @bookingTotal.
  ///
  /// In hr, this message translates to:
  /// **'Ukupno'**
  String get bookingTotal;

  /// No description provided for @bookingWithBarber.
  ///
  /// In hr, this message translates to:
  /// **'Rezervacija s {barberName}'**
  String bookingWithBarber(String barberName);

  /// No description provided for @timeMorning.
  ///
  /// In hr, this message translates to:
  /// **'Jutro'**
  String get timeMorning;

  /// No description provided for @timeAfternoon.
  ///
  /// In hr, this message translates to:
  /// **'Poslijepodne'**
  String get timeAfternoon;

  /// No description provided for @timeEvening.
  ///
  /// In hr, this message translates to:
  /// **'Večer'**
  String get timeEvening;

  /// No description provided for @bookingNoAvailableTimes.
  ///
  /// In hr, this message translates to:
  /// **'Nema dostupnih termina'**
  String get bookingNoAvailableTimes;

  /// No description provided for @bookingSelectDifferentDate.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi drugi datum'**
  String get bookingSelectDifferentDate;

  /// No description provided for @bookingAppointmentSuccess.
  ///
  /// In hr, this message translates to:
  /// **'Rezervacija uspješno zakazana!'**
  String get bookingAppointmentSuccess;

  /// No description provided for @bookingUserNotAuthenticated.
  ///
  /// In hr, this message translates to:
  /// **'Korisnik nije prijavljen'**
  String get bookingUserNotAuthenticated;

  /// No description provided for @bookingAlreadyHasUpcoming.
  ///
  /// In hr, this message translates to:
  /// **'Već imate zakazan termin. Otkazujte ili dovršite ga prije nove rezervacije.'**
  String get bookingAlreadyHasUpcoming;

  /// No description provided for @bookingStepService.
  ///
  /// In hr, this message translates to:
  /// **'Usluga'**
  String get bookingStepService;

  /// No description provided for @bookingStepBarber.
  ///
  /// In hr, this message translates to:
  /// **'Brijač'**
  String get bookingStepBarber;

  /// No description provided for @bookingStepTime.
  ///
  /// In hr, this message translates to:
  /// **'Vrijeme'**
  String get bookingStepTime;

  /// No description provided for @manageBookingTitle.
  ///
  /// In hr, this message translates to:
  /// **'Upravljanje rezervacijom'**
  String get manageBookingTitle;

  /// No description provided for @manageBookingReschedule.
  ///
  /// In hr, this message translates to:
  /// **'Preuredi termin'**
  String get manageBookingReschedule;

  /// No description provided for @manageBookingCancelAppointment.
  ///
  /// In hr, this message translates to:
  /// **'Otkaži rezervaciju'**
  String get manageBookingCancelAppointment;

  /// No description provided for @manageBookingCancelConfirmTitle.
  ///
  /// In hr, this message translates to:
  /// **'Otkazati rezervaciju?'**
  String get manageBookingCancelConfirmTitle;

  /// No description provided for @manageBookingCancelConfirmMessage.
  ///
  /// In hr, this message translates to:
  /// **'Jeste li sigurni da želite otkazati ovu rezervaciju? Ova radnja se ne može poništiti.'**
  String get manageBookingCancelConfirmMessage;

  /// No description provided for @manageBookingCancelConfirm.
  ///
  /// In hr, this message translates to:
  /// **'Da, otkaži'**
  String get manageBookingCancelConfirm;

  /// No description provided for @manageBookingCanceledSnackbar.
  ///
  /// In hr, this message translates to:
  /// **'Rezervacija otkazana'**
  String get manageBookingCanceledSnackbar;

  /// No description provided for @manageBookingCancelPolicyHours.
  ///
  /// In hr, this message translates to:
  /// **'Otkazivanje mora biti obavljeno najmanje {hours} sati prije termina.'**
  String manageBookingCancelPolicyHours(int hours);

  /// No description provided for @manageBookingCancelPeriodPassed.
  ///
  /// In hr, this message translates to:
  /// **'Rok za otkazivanje je istekao. Ovu rezervaciju više nije moguće otkazati niti preurediti.'**
  String get manageBookingCancelPeriodPassed;

  /// No description provided for @editBookingTitle.
  ///
  /// In hr, this message translates to:
  /// **'Promjena datuma i vremena'**
  String get editBookingTitle;

  /// No description provided for @editBookingSelectNewDate.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi novi datum'**
  String get editBookingSelectNewDate;

  /// No description provided for @editBookingSelectNewTime.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi novo vrijeme'**
  String get editBookingSelectNewTime;

  /// No description provided for @editBookingUpdateButton.
  ///
  /// In hr, this message translates to:
  /// **'Ažuriraj rezervaciju'**
  String get editBookingUpdateButton;

  /// No description provided for @editBookingSuccessSnackbar.
  ///
  /// In hr, this message translates to:
  /// **'Rezervacija uspješno ažurirana'**
  String get editBookingSuccessSnackbar;

  /// No description provided for @editBookingErrorSnackbar.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće ažurirati rezervaciju. Pokušajte ponovo.'**
  String get editBookingErrorSnackbar;

  /// No description provided for @upcoming.
  ///
  /// In hr, this message translates to:
  /// **'Nadolazeće'**
  String get upcoming;

  /// No description provided for @upcomingAppointment.
  ///
  /// In hr, this message translates to:
  /// **'Nadolazeći termin'**
  String get upcomingAppointment;

  /// No description provided for @bookYourNextVisit.
  ///
  /// In hr, this message translates to:
  /// **'Rezervirajte sljedeći posjet'**
  String get bookYourNextVisit;

  /// No description provided for @chooseLocationServiceTime.
  ///
  /// In hr, this message translates to:
  /// **'Odaberite uslugu i vrijeme'**
  String get chooseLocationServiceTime;

  /// No description provided for @bookNow.
  ///
  /// In hr, this message translates to:
  /// **'Rezerviraj sada'**
  String get bookNow;

  /// No description provided for @sectionBarbers.
  ///
  /// In hr, this message translates to:
  /// **'Rezerviraj kod brijača'**
  String get sectionBarbers;

  /// No description provided for @sectionPopularServices.
  ///
  /// In hr, this message translates to:
  /// **'Popularne usluge'**
  String get sectionPopularServices;

  /// No description provided for @sectionNearbyBarbershop.
  ///
  /// In hr, this message translates to:
  /// **'OBLIŽNJA BRIJANICA'**
  String get sectionNearbyBarbershop;

  /// No description provided for @loyaltyTitle.
  ///
  /// In hr, this message translates to:
  /// **'LOYALTY'**
  String get loyaltyTitle;

  /// No description provided for @loyaltyMember.
  ///
  /// In hr, this message translates to:
  /// **'ČLAN'**
  String get loyaltyMember;

  /// No description provided for @loyaltyViewRewards.
  ///
  /// In hr, this message translates to:
  /// **'Pogledaj nagrade'**
  String get loyaltyViewRewards;

  /// No description provided for @loyaltyPageTitle.
  ///
  /// In hr, this message translates to:
  /// **'Nagrade i lojalnost'**
  String get loyaltyPageTitle;

  /// No description provided for @loyaltyRewardsComingSoon.
  ///
  /// In hr, this message translates to:
  /// **'Nagrade uskoro'**
  String get loyaltyRewardsComingSoon;

  /// No description provided for @loyaltyEarnPointsDescription.
  ///
  /// In hr, this message translates to:
  /// **'Zaradite bodove i unovčite nagrade'**
  String get loyaltyEarnPointsDescription;

  /// No description provided for @addNewItem.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj novu stavku'**
  String get addNewItem;

  /// No description provided for @addItemTitle.
  ///
  /// In hr, this message translates to:
  /// **'Naslov'**
  String get addItemTitle;

  /// No description provided for @addItemTitleHint.
  ///
  /// In hr, this message translates to:
  /// **'Unesite naslov stavke'**
  String get addItemTitleHint;

  /// No description provided for @addItemTitleRequired.
  ///
  /// In hr, this message translates to:
  /// **'Naslov je obavezan'**
  String get addItemTitleRequired;

  /// No description provided for @addItemCategory.
  ///
  /// In hr, this message translates to:
  /// **'Kategorija'**
  String get addItemCategory;

  /// No description provided for @addItemCategoryHint.
  ///
  /// In hr, this message translates to:
  /// **'Unesite kategoriju'**
  String get addItemCategoryHint;

  /// No description provided for @addItemLocation.
  ///
  /// In hr, this message translates to:
  /// **'Lokacija'**
  String get addItemLocation;

  /// No description provided for @addItemSelectLocation.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi lokaciju'**
  String get addItemSelectLocation;

  /// No description provided for @addItemBox.
  ///
  /// In hr, this message translates to:
  /// **'Kutija'**
  String get addItemBox;

  /// No description provided for @addItemSelectBox.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi kutiju'**
  String get addItemSelectBox;

  /// No description provided for @addItemPriceOptional.
  ///
  /// In hr, this message translates to:
  /// **'Cijena (opcionalno)'**
  String get addItemPriceOptional;

  /// No description provided for @addItemPriceHint.
  ///
  /// In hr, this message translates to:
  /// **'Unesite cijenu'**
  String get addItemPriceHint;

  /// No description provided for @addItemSavedSuccess.
  ///
  /// In hr, this message translates to:
  /// **'Stavka {name} uspješno spremljena'**
  String addItemSavedSuccess(String name);

  /// No description provided for @addItemError.
  ///
  /// In hr, this message translates to:
  /// **'Greška: {message}'**
  String addItemError(String message);

  /// No description provided for @inventoryItems.
  ///
  /// In hr, this message translates to:
  /// **'Stavke'**
  String get inventoryItems;

  /// No description provided for @inventoryBoxes.
  ///
  /// In hr, this message translates to:
  /// **'Kutije'**
  String get inventoryBoxes;

  /// No description provided for @inventoryLocations.
  ///
  /// In hr, this message translates to:
  /// **'Lokacije'**
  String get inventoryLocations;

  /// No description provided for @addNewBox.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj novu kutiju'**
  String get addNewBox;

  /// No description provided for @addBoxLabel.
  ///
  /// In hr, this message translates to:
  /// **'Oznaka kutije'**
  String get addBoxLabel;

  /// No description provided for @addBoxLabelHint.
  ///
  /// In hr, this message translates to:
  /// **'npr. Kuhinjski pribor, Alati, Dokumenti'**
  String get addBoxLabelHint;

  /// No description provided for @addBoxLabelRequired.
  ///
  /// In hr, this message translates to:
  /// **'Unesite oznaku kutije'**
  String get addBoxLabelRequired;

  /// No description provided for @addBoxSuccess.
  ///
  /// In hr, this message translates to:
  /// **'Kutija uspješno dodana!'**
  String get addBoxSuccess;

  /// No description provided for @addBoxError.
  ///
  /// In hr, this message translates to:
  /// **'Greška pri dodavanju kutije: {error}'**
  String addBoxError(String error);

  /// No description provided for @addNewLocation.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj novu lokaciju'**
  String get addNewLocation;

  /// No description provided for @addLocationName.
  ///
  /// In hr, this message translates to:
  /// **'Naziv lokacije'**
  String get addLocationName;

  /// No description provided for @addLocationNameHint.
  ///
  /// In hr, this message translates to:
  /// **'npr. Kuhinja, Garaža, Ured'**
  String get addLocationNameHint;

  /// No description provided for @addLocationNameRequired.
  ///
  /// In hr, this message translates to:
  /// **'Unesite naziv lokacije'**
  String get addLocationNameRequired;

  /// No description provided for @addLocationColor.
  ///
  /// In hr, this message translates to:
  /// **'Boja'**
  String get addLocationColor;

  /// No description provided for @addLocationColorHint.
  ///
  /// In hr, this message translates to:
  /// **'#4CAF50'**
  String get addLocationColorHint;

  /// No description provided for @addLocationColorRequired.
  ///
  /// In hr, this message translates to:
  /// **'Unesite boju'**
  String get addLocationColorRequired;

  /// No description provided for @addLocationColorInvalid.
  ///
  /// In hr, this message translates to:
  /// **'Unesite ispravnu heksadecimalnu boju (npr. #4CAF50)'**
  String get addLocationColorInvalid;

  /// No description provided for @addLocationSuccess.
  ///
  /// In hr, this message translates to:
  /// **'Lokacija uspješno dodana!'**
  String get addLocationSuccess;

  /// No description provided for @addLocationError.
  ///
  /// In hr, this message translates to:
  /// **'Greška pri dodavanju lokacije: {error}'**
  String addLocationError(String error);

  /// No description provided for @selectCountry.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi državu'**
  String get selectCountry;

  /// No description provided for @searchCountryOrCode.
  ///
  /// In hr, this message translates to:
  /// **'Pretraži državu ili pozivni broj'**
  String get searchCountryOrCode;

  /// No description provided for @dashboardBrandTitle.
  ///
  /// In hr, this message translates to:
  /// **'Brend'**
  String get dashboardBrandTitle;

  /// No description provided for @dashboardBrandName.
  ///
  /// In hr, this message translates to:
  /// **'Naziv'**
  String get dashboardBrandName;

  /// No description provided for @dashboardBrandNameHint.
  ///
  /// In hr, this message translates to:
  /// **'npr. Kingsman Barbershop'**
  String get dashboardBrandNameHint;

  /// No description provided for @dashboardBrandNameRequired.
  ///
  /// In hr, this message translates to:
  /// **'Naziv je obavezan'**
  String get dashboardBrandNameRequired;

  /// No description provided for @dashboardBrandPrimaryColor.
  ///
  /// In hr, this message translates to:
  /// **'Primarna boja'**
  String get dashboardBrandPrimaryColor;

  /// No description provided for @dashboardBrandPrimaryColorHint.
  ///
  /// In hr, this message translates to:
  /// **'#9B784A'**
  String get dashboardBrandPrimaryColorHint;

  /// No description provided for @dashboardBrandLogoUrl.
  ///
  /// In hr, this message translates to:
  /// **'URL logotipa'**
  String get dashboardBrandLogoUrl;

  /// No description provided for @dashboardBrandLogoUrlHint.
  ///
  /// In hr, this message translates to:
  /// **'https://...'**
  String get dashboardBrandLogoUrlHint;

  /// No description provided for @dashboardBrandContactEmail.
  ///
  /// In hr, this message translates to:
  /// **'Kontakt email'**
  String get dashboardBrandContactEmail;

  /// No description provided for @dashboardBrandContactEmailHint.
  ///
  /// In hr, this message translates to:
  /// **'contact@example.com'**
  String get dashboardBrandContactEmailHint;

  /// No description provided for @dashboardBrandSlotInterval.
  ///
  /// In hr, this message translates to:
  /// **'Interval termina (min)'**
  String get dashboardBrandSlotInterval;

  /// No description provided for @dashboardBrandBufferTime.
  ///
  /// In hr, this message translates to:
  /// **'Vrijeme između termina (min)'**
  String get dashboardBrandBufferTime;

  /// No description provided for @dashboardBrandCancelHours.
  ///
  /// In hr, this message translates to:
  /// **'Min. sati za otkaz'**
  String get dashboardBrandCancelHours;

  /// No description provided for @dashboardBrandMultiLocation.
  ///
  /// In hr, this message translates to:
  /// **'Više lokacija'**
  String get dashboardBrandMultiLocation;

  /// No description provided for @dashboardBrandSaved.
  ///
  /// In hr, this message translates to:
  /// **'Brend spremljen'**
  String get dashboardBrandSaved;

  /// No description provided for @dashboardBrandCreated.
  ///
  /// In hr, this message translates to:
  /// **'Brend kreiran'**
  String get dashboardBrandCreated;

  /// No description provided for @dashboardBrandSetConfigId.
  ///
  /// In hr, this message translates to:
  /// **'Postavite default_brand_id u assets/config/default.json'**
  String get dashboardBrandSetConfigId;

  /// No description provided for @dashboardLocationAdd.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj lokaciju'**
  String get dashboardLocationAdd;

  /// No description provided for @dashboardLocationEdit.
  ///
  /// In hr, this message translates to:
  /// **'Uredi lokaciju'**
  String get dashboardLocationEdit;

  /// No description provided for @dashboardLocationName.
  ///
  /// In hr, this message translates to:
  /// **'Naziv'**
  String get dashboardLocationName;

  /// No description provided for @dashboardLocationNameHint.
  ///
  /// In hr, this message translates to:
  /// **'npr. Zagreb Centar'**
  String get dashboardLocationNameHint;

  /// No description provided for @dashboardLocationNameRequired.
  ///
  /// In hr, this message translates to:
  /// **'Naziv je obavezan'**
  String get dashboardLocationNameRequired;

  /// No description provided for @dashboardLocationAddress.
  ///
  /// In hr, this message translates to:
  /// **'Adresa'**
  String get dashboardLocationAddress;

  /// No description provided for @dashboardLocationAddressHint.
  ///
  /// In hr, this message translates to:
  /// **'Ulica, grad'**
  String get dashboardLocationAddressHint;

  /// No description provided for @dashboardLocationPhone.
  ///
  /// In hr, this message translates to:
  /// **'Telefon'**
  String get dashboardLocationPhone;

  /// No description provided for @dashboardLocationPhoneHint.
  ///
  /// In hr, this message translates to:
  /// **'+385 1 234 5678'**
  String get dashboardLocationPhoneHint;

  /// No description provided for @dashboardLocationCoordinates.
  ///
  /// In hr, this message translates to:
  /// **'Koordinate'**
  String get dashboardLocationCoordinates;

  /// No description provided for @dashboardLocationLatHint.
  ///
  /// In hr, this message translates to:
  /// **'Širina (npr. 45.81)'**
  String get dashboardLocationLatHint;

  /// No description provided for @dashboardLocationLngHint.
  ///
  /// In hr, this message translates to:
  /// **'Duljina (npr. 15.98)'**
  String get dashboardLocationLngHint;

  /// No description provided for @dashboardLocationWorkingHours.
  ///
  /// In hr, this message translates to:
  /// **'Radno vrijeme'**
  String get dashboardLocationWorkingHours;

  /// No description provided for @dashboardLocationTimeFormat.
  ///
  /// In hr, this message translates to:
  /// **'Koristite HH:mm (npr. 14:00)'**
  String get dashboardLocationTimeFormat;

  /// No description provided for @dashboardLocationStartBeforeEnd.
  ///
  /// In hr, this message translates to:
  /// **'Početak mora biti prije kraja'**
  String get dashboardLocationStartBeforeEnd;

  /// No description provided for @dashboardLocationDayClosed.
  ///
  /// In hr, this message translates to:
  /// **'Zatvoreno'**
  String get dashboardLocationDayClosed;

  /// No description provided for @dashboardLocationSaved.
  ///
  /// In hr, this message translates to:
  /// **'Lokacija spremljena'**
  String get dashboardLocationSaved;

  /// No description provided for @dashboardLocationDeleted.
  ///
  /// In hr, this message translates to:
  /// **'Lokacija obrisana'**
  String get dashboardLocationDeleted;

  /// No description provided for @dashboardLocationDeleteConfirm.
  ///
  /// In hr, this message translates to:
  /// **'Obrisati ovu lokaciju?'**
  String get dashboardLocationDeleteConfirm;

  /// No description provided for @dashboardLocationDeleteConfirmMessage.
  ///
  /// In hr, this message translates to:
  /// **'Ova radnja se ne može poništiti.'**
  String get dashboardLocationDeleteConfirmMessage;

  /// No description provided for @dashboardLocationDeleteButton.
  ///
  /// In hr, this message translates to:
  /// **'Obriši'**
  String get dashboardLocationDeleteButton;

  /// No description provided for @dashboardLocationEmpty.
  ///
  /// In hr, this message translates to:
  /// **'Još nema lokacija. Dodajte novu.'**
  String get dashboardLocationEmpty;

  /// No description provided for @dashboardNoBrand.
  ///
  /// In hr, this message translates to:
  /// **'Nije konfiguriran brend'**
  String get dashboardNoBrand;

  /// No description provided for @dashboardServiceAdd.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj uslugu'**
  String get dashboardServiceAdd;

  /// No description provided for @dashboardServiceEdit.
  ///
  /// In hr, this message translates to:
  /// **'Uredi uslugu'**
  String get dashboardServiceEdit;

  /// No description provided for @dashboardServiceName.
  ///
  /// In hr, this message translates to:
  /// **'Naziv'**
  String get dashboardServiceName;

  /// No description provided for @dashboardServiceNameHint.
  ///
  /// In hr, this message translates to:
  /// **'npr. Šišanje & Pranje'**
  String get dashboardServiceNameHint;

  /// No description provided for @dashboardServiceNameRequired.
  ///
  /// In hr, this message translates to:
  /// **'Naziv je obavezan'**
  String get dashboardServiceNameRequired;

  /// No description provided for @dashboardServicePrice.
  ///
  /// In hr, this message translates to:
  /// **'Cijena'**
  String get dashboardServicePrice;

  /// No description provided for @dashboardServicePriceHint.
  ///
  /// In hr, this message translates to:
  /// **'0'**
  String get dashboardServicePriceHint;

  /// No description provided for @dashboardServicePriceInvalid.
  ///
  /// In hr, this message translates to:
  /// **'Unesite valjanu cijenu'**
  String get dashboardServicePriceInvalid;

  /// No description provided for @dashboardServiceDuration.
  ///
  /// In hr, this message translates to:
  /// **'Trajanje (minute)'**
  String get dashboardServiceDuration;

  /// No description provided for @dashboardServiceDurationHint.
  ///
  /// In hr, this message translates to:
  /// **'30'**
  String get dashboardServiceDurationHint;

  /// No description provided for @dashboardServiceDurationInvalid.
  ///
  /// In hr, this message translates to:
  /// **'Unesite valjano trajanje (min 1)'**
  String get dashboardServiceDurationInvalid;

  /// No description provided for @dashboardServiceDescription.
  ///
  /// In hr, this message translates to:
  /// **'Opis'**
  String get dashboardServiceDescription;

  /// No description provided for @dashboardServiceDescriptionHint.
  ///
  /// In hr, this message translates to:
  /// **'Opcionalni opis'**
  String get dashboardServiceDescriptionHint;

  /// No description provided for @dashboardServiceAvailableAt.
  ///
  /// In hr, this message translates to:
  /// **'Dostupno na'**
  String get dashboardServiceAvailableAt;

  /// No description provided for @dashboardServiceAvailableAtAll.
  ///
  /// In hr, this message translates to:
  /// **'Svim lokacijama'**
  String get dashboardServiceAvailableAtAll;

  /// No description provided for @dashboardServiceAvailableAtSelected.
  ///
  /// In hr, this message translates to:
  /// **'Samo odabranim lokacijama'**
  String get dashboardServiceAvailableAtSelected;

  /// No description provided for @dashboardServiceSaved.
  ///
  /// In hr, this message translates to:
  /// **'Usluga spremljena'**
  String get dashboardServiceSaved;

  /// No description provided for @dashboardServiceCreated.
  ///
  /// In hr, this message translates to:
  /// **'Usluga kreirana'**
  String get dashboardServiceCreated;

  /// No description provided for @dashboardServiceDeleteConfirm.
  ///
  /// In hr, this message translates to:
  /// **'Obrisati ovu uslugu?'**
  String get dashboardServiceDeleteConfirm;

  /// No description provided for @dashboardServiceDeleteConfirmMessage.
  ///
  /// In hr, this message translates to:
  /// **'Ova radnja se ne može poništiti.'**
  String get dashboardServiceDeleteConfirmMessage;

  /// No description provided for @dashboardServiceDeleteButton.
  ///
  /// In hr, this message translates to:
  /// **'Obriši'**
  String get dashboardServiceDeleteButton;

  /// No description provided for @dashboardServiceDeleted.
  ///
  /// In hr, this message translates to:
  /// **'Usluga obrisana'**
  String get dashboardServiceDeleted;

  /// No description provided for @dashboardServiceEmpty.
  ///
  /// In hr, this message translates to:
  /// **'Još nema usluga. Dodajte novu.'**
  String get dashboardServiceEmpty;

  /// No description provided for @dashboardBarberAdd.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj brijača'**
  String get dashboardBarberAdd;

  /// No description provided for @dashboardBarberEdit.
  ///
  /// In hr, this message translates to:
  /// **'Uredi brijača'**
  String get dashboardBarberEdit;

  /// No description provided for @dashboardBarberName.
  ///
  /// In hr, this message translates to:
  /// **'Naziv'**
  String get dashboardBarberName;

  /// No description provided for @dashboardBarberNameHint.
  ///
  /// In hr, this message translates to:
  /// **'npr. Ivan Horvat'**
  String get dashboardBarberNameHint;

  /// No description provided for @dashboardBarberNameRequired.
  ///
  /// In hr, this message translates to:
  /// **'Naziv je obavezan'**
  String get dashboardBarberNameRequired;

  /// No description provided for @dashboardBarberPhotoUrl.
  ///
  /// In hr, this message translates to:
  /// **'URL fotografije'**
  String get dashboardBarberPhotoUrl;

  /// No description provided for @dashboardBarberPhotoUrlHint.
  ///
  /// In hr, this message translates to:
  /// **'https://...'**
  String get dashboardBarberPhotoUrlHint;

  /// No description provided for @dashboardBarberLocation.
  ///
  /// In hr, this message translates to:
  /// **'Lokacija'**
  String get dashboardBarberLocation;

  /// No description provided for @dashboardBarberLocationRequired.
  ///
  /// In hr, this message translates to:
  /// **'Odaberite lokaciju'**
  String get dashboardBarberLocationRequired;

  /// No description provided for @dashboardBarberNoLocations.
  ///
  /// In hr, this message translates to:
  /// **'Prvo dodajte lokacije u tabu Lokacije.'**
  String get dashboardBarberNoLocations;

  /// No description provided for @dashboardBarberActive.
  ///
  /// In hr, this message translates to:
  /// **'Aktivan'**
  String get dashboardBarberActive;

  /// No description provided for @dashboardBarberWorkingHoursOverride.
  ///
  /// In hr, this message translates to:
  /// **'Prilagođeno radno vrijeme'**
  String get dashboardBarberWorkingHoursOverride;

  /// No description provided for @dashboardBarberWorkingHoursOverrideHint.
  ///
  /// In hr, this message translates to:
  /// **'Nadopiši radno vrijeme lokacije za ovog brijača. Ostavite prazno za vrijeme lokacije.'**
  String get dashboardBarberWorkingHoursOverrideHint;

  /// No description provided for @dashboardBarberSaved.
  ///
  /// In hr, this message translates to:
  /// **'Brijač spremljen'**
  String get dashboardBarberSaved;

  /// No description provided for @dashboardBarberCreated.
  ///
  /// In hr, this message translates to:
  /// **'Brijač kreiran'**
  String get dashboardBarberCreated;

  /// No description provided for @dashboardBarberDeleteConfirm.
  ///
  /// In hr, this message translates to:
  /// **'Obrisati ovog brijača?'**
  String get dashboardBarberDeleteConfirm;

  /// No description provided for @dashboardBarberDeleteConfirmMessage.
  ///
  /// In hr, this message translates to:
  /// **'Ova radnja se ne može poništiti.'**
  String get dashboardBarberDeleteConfirmMessage;

  /// No description provided for @dashboardBarberDeleteButton.
  ///
  /// In hr, this message translates to:
  /// **'Obriši'**
  String get dashboardBarberDeleteButton;

  /// No description provided for @dashboardBarberDeleted.
  ///
  /// In hr, this message translates to:
  /// **'Brijač obrisan'**
  String get dashboardBarberDeleted;

  /// No description provided for @dashboardBarberEmpty.
  ///
  /// In hr, this message translates to:
  /// **'Još nema brijača. Dodajte novog.'**
  String get dashboardBarberEmpty;

  /// No description provided for @dashboardBarberInactive.
  ///
  /// In hr, this message translates to:
  /// **'Neaktivan'**
  String get dashboardBarberInactive;

  /// No description provided for @closed.
  ///
  /// In hr, this message translates to:
  /// **'Zatvoreno'**
  String get closed;

  /// No description provided for @openNow.
  ///
  /// In hr, this message translates to:
  /// **'OTVORENO SADA {open} - {close}'**
  String openNow(String open, String close);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hr':
      return AppLocalizationsHr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
