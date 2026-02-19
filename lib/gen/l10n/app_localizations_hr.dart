// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get retry => 'Pokušaj ponovo';

  @override
  String get skip => 'Preskoči';

  @override
  String get next => 'Dalje';

  @override
  String get getStarted => 'Započni';

  @override
  String get save => 'Spremi';

  @override
  String get cancel => 'Odustani';

  @override
  String get search => 'Pretraži';

  @override
  String get book => 'Rezerviraj';

  @override
  String get manage => 'Upravljaj';

  @override
  String get select => 'Odaberi';

  @override
  String get selected => 'Odabrano';

  @override
  String get continueButton => 'Nastavi';

  @override
  String get back => 'Natrag';

  @override
  String get generalBack => 'Natrag';

  @override
  String get logout => 'Odjava';

  @override
  String get logoutConfirmTitle => 'Odjava';

  @override
  String get logoutConfirmMessage => 'Jeste li sigurni da želite se odjaviti?';

  @override
  String logoutFailed(String error) {
    return 'Odjava nije uspjela: $error';
  }

  @override
  String get drawerGuestUser => 'Gost';

  @override
  String get drawerUser => 'Korisnik';

  @override
  String get drawerSignInToSaveBookings =>
      'Prijavite se kako biste napravili rezervacije';

  @override
  String get navHome => 'Početna';

  @override
  String get navInventory => 'Inventar';

  @override
  String get navStatistics => 'Statistika';

  @override
  String get onboardingBookAppointmentsTitle => 'Rezerviraj termine';

  @override
  String get onboardingBookAppointmentsDescription =>
      'Zakažite posjet u nekoliko dodira i jednostavno upravljajte rezervacijama.';

  @override
  String get onboardingScanQrTitle => 'Skeniraj QR kodove';

  @override
  String get onboardingScanQrDescription =>
      'Brza prijava i pristup uslugama skeniranjem QR kodova na lokaciji.';

  @override
  String get onboardingManageInventoryTitle => 'Upravljaj inventarom';

  @override
  String get onboardingManageInventoryDescription =>
      'Pratite stavke i kutije na svim lokacijama.';

  @override
  String get onboardingLoyaltyTitle => 'Zarađuj bodove vjernosti';

  @override
  String get onboardingLoyaltyDescription =>
      'Skupljaj bodove pri svakom posjetu i iskoristi nagrade u svojim omiljenim salonima.';

  @override
  String get onboardingNotificationsTitle => 'Ne propusti termin';

  @override
  String get onboardingNotificationsDescription =>
      'Primi podsjetnik prije posjeta da uvijek stigneš na vrijeme.';

  @override
  String get enableReminders => 'Uključi podsjetnike';

  @override
  String get notNow => 'Ne sada';

  @override
  String get authEnterPhone => 'Unesite broj telefona';

  @override
  String get authVerificationCodeSent => 'Poslat ćemo vam verifikacijski kod';

  @override
  String get authPhoneNumber => 'Broj telefona';

  @override
  String get authPhoneHint => '123 456 7890';

  @override
  String get authPhoneValidation => 'Unesite ispravan broj telefona';

  @override
  String get authSendCode => 'Pošalji kod';

  @override
  String get authEnterVerificationCode => 'Unesite verifikacijski kod';

  @override
  String authCodeSentTo(String phone) {
    return 'Poslali smo kod na $phone';
  }

  @override
  String get authVerificationCode => 'Verifikacijski kod';

  @override
  String get authCodeHint => '123456';

  @override
  String get authCodeValidation => 'Unesite 6-znamenkasti kod';

  @override
  String get authVerify => 'Potvrdi';

  @override
  String get authCompleteProfile => 'Dovršite svoj profil';

  @override
  String get authProfileDescription =>
      'Dodajte svoje ime kako bismo personalizirali vaše iskustvo';

  @override
  String get authFullName => 'Puno ime';

  @override
  String get authFullNameHint => 'Ivan Horvat';

  @override
  String get authFullNameValidation => 'Molimo unesite svoje ime';

  @override
  String get authPhone => 'Telefon';

  @override
  String get welcome => 'Dobrodošli';

  @override
  String get signIn => 'Prijavi se';

  @override
  String get signInToContinue => 'Prijavite se za nastavak';

  @override
  String get signInToAccessExclusiveRewards =>
      'Prijavite se za pristup ekskluzivnim nagradama';

  @override
  String get continueWithGoogle => 'Nastavi s Googleom';

  @override
  String get continueWithApple => 'Nastavi s Appleom';

  @override
  String get or => 'ili';

  @override
  String get continueWithPhone => 'Nastavi s telefonom';

  @override
  String get bookingTitle => 'Rezerviraj termin';

  @override
  String get bookingSelectService => 'Odaberi uslugu';

  @override
  String get bookingSelectBarber => 'Odaberi profesionalca';

  @override
  String get bookingAnyBarber => 'Bilo koji profesionalac';

  @override
  String get bookingSelectDate => 'Odaberi datum';

  @override
  String get bookingSelectTime => 'Odaberi vrijeme';

  @override
  String get bookingConfirm => 'Potvrdi rezervaciju';

  @override
  String get bookingTotal => 'Ukupno';

  @override
  String bookingWithBarber(String barberName) {
    return 'Rezervacija s $barberName';
  }

  @override
  String get timeMorning => 'Jutro';

  @override
  String get timeAfternoon => 'Poslijepodne';

  @override
  String get timeEvening => 'Večer';

  @override
  String get bookingNoAvailableTimes => 'Nema dostupnih termina';

  @override
  String get bookingSelectDifferentDate => 'Odaberi drugi datum';

  @override
  String get bookingAppointmentSuccess => 'Rezervacija uspješno zakazana!';

  @override
  String get bookingUserNotAuthenticated => 'Korisnik nije prijavljen';

  @override
  String get bookingAlreadyHasUpcoming =>
      'Već imate zakazan termin. Otkazujte ili dovršite ga prije nove rezervacije.';

  @override
  String get bookingStepLocation => 'Lokacija';

  @override
  String get bookingSelectLocation => 'Odaberi lokaciju';

  @override
  String get bookingStepService => 'Usluga';

  @override
  String get bookingStepBarber => 'Tim';

  @override
  String get bookingStepDate => 'Datum';

  @override
  String get bookingStepTime => 'Vrijeme';

  @override
  String get manageBookingTitle => 'Upravljanje rezervacijom';

  @override
  String get manageBookingReschedule => 'Preuredi termin';

  @override
  String get manageBookingCancelAppointment => 'Otkaži rezervaciju';

  @override
  String get manageBookingCancelConfirmTitle => 'Otkazati rezervaciju?';

  @override
  String get manageBookingCancelConfirmMessage =>
      'Jeste li sigurni da želite otkazati ovu rezervaciju? Ova radnja se ne može poništiti.';

  @override
  String get manageBookingCancelConfirm => 'Da, otkaži';

  @override
  String get manageBookingCanceledSnackbar => 'Rezervacija otkazana';

  @override
  String manageBookingCancelPolicyHours(int hours) {
    return 'Otkazivanje mora biti obavljeno najmanje $hours sati prije termina.';
  }

  @override
  String get manageBookingCancelPeriodPassed =>
      'Rok za otkazivanje je istekao. Ovu rezervaciju više nije moguće otkazati niti preurediti.';

  @override
  String get editBookingTitle => 'Promjena datuma i vremena';

  @override
  String get editBookingSelectNewDate => 'Odaberi novi datum';

  @override
  String get editBookingSelectNewTime => 'Odaberi novo vrijeme';

  @override
  String get editBookingUpdateButton => 'Ažuriraj rezervaciju';

  @override
  String get editBookingSuccessSnackbar => 'Rezervacija uspješno ažurirana';

  @override
  String get editBookingErrorSnackbar =>
      'Nije moguće ažurirati rezervaciju. Pokušajte ponovo.';

  @override
  String get upcoming => 'Nadolazeće';

  @override
  String get upcomingAppointment => 'Nadolazeći termin';

  @override
  String get bookYourNextVisit => 'Rezervirajte sljedeći posjet';

  @override
  String get chooseLocationServiceTime => 'Odaberite uslugu i vrijeme';

  @override
  String get bookNow => 'Rezerviraj sada';

  @override
  String get sectionBarbers => 'Odaberi profesionalca';

  @override
  String get sectionPopularServices => 'Popularne usluge';

  @override
  String get sectionNearbyBarbershop => 'Lokacije u blizini';

  @override
  String get loyaltyTitle => 'LOYALTY';

  @override
  String get loyaltyPointsAbbrev => 'bod.';

  @override
  String get loyaltyMember => 'ČLAN';

  @override
  String get loyaltyViewRewards => 'Pogledaj nagrade';

  @override
  String get loyaltyClub => 'Club';

  @override
  String get loyaltyGuestLabel => 'GOST';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get scanQrCode => 'Skeniraj QR kod';

  @override
  String get loyaltyPageTitle => 'Nagrade i lojalnost';

  @override
  String get loyaltyRewardsComingSoon => 'Nagrade uskoro';

  @override
  String get loyaltyEarnPointsDescription =>
      'Zaradite bodove i unovčite nagrade';

  @override
  String get loyaltyRedeem => 'Unovči';

  @override
  String get loyaltyMyRewards => 'Moje nagrade';

  @override
  String get loyaltyInsufficientPoints => 'Nedovoljno bodova';

  @override
  String get loyaltyRedeemSuccess => 'Nagrada zatražena! Pokažite ovaj QR kod.';

  @override
  String get dashboardRedeemReward => 'Skeniraj kod';

  @override
  String get barberHomeGreetingMorning => 'Dobro jutro';

  @override
  String get barberHomeGreetingAfternoon => 'Dobar dan';

  @override
  String get barberHomeGreetingEvening => 'Dobra večer';

  @override
  String get barberHomeScanCta => 'Skeniraj QR';

  @override
  String get barberHomeScanSubtitle => 'Unovči nagrade ili dodaj bodove';

  @override
  String get barberHomeRedeemReward => 'Unovči nagradu';

  @override
  String get barberHomeAddLoyalty => 'Dodaj bodove';

  @override
  String get barberHomeViewBookings => 'Pregled termina';

  @override
  String get barberHomeTodayTitle => 'Danas';

  @override
  String get barberHomeTodayEmpty => 'Nema termina danas';

  @override
  String get barberHomeUpcomingEmpty => 'Nema nadolazećih termina';

  @override
  String get barberHomeUpcomingCardTitle => 'Termini';

  @override
  String get barberHomeHey => 'Bok 👋';

  @override
  String barberHomeHeyName(String name) {
    return 'Bok, $name 👋';
  }

  @override
  String get barberHomeQuickActions => 'Brze radnje';

  @override
  String get redeemSuccess => 'Nagrada unovčena';

  @override
  String get alreadyRedeemed => 'Već unovčeno';

  @override
  String get scanPointsAwardedTitle => 'Bodovi dodani';

  @override
  String scanPointsAwardedMessage(String customerName, int pointsAwarded) {
    return '$customerName je primio $pointsAwarded bodova lojalnosti.';
  }

  @override
  String get dashboardNavHome => 'Početna';

  @override
  String get dashboardNavBookings => 'Termini';

  @override
  String get dashboardNavCalendar => 'Kalendar';

  @override
  String get dashboardNavShift => 'Smjena';

  @override
  String get dashboardNavBrand => 'Brend';

  @override
  String get dashboardNavLocations => 'Lokacije';

  @override
  String get dashboardNavServices => 'Usluge';

  @override
  String get dashboardNavRewards => 'Nagrade';

  @override
  String get dashboardNavBarbers => 'Tim';

  @override
  String get dashboardNavAnalytics => 'Analitika';

  @override
  String get dashboardBookingsTitle => 'Moji termini';

  @override
  String get dashboardShiftTitle => 'Moja smjena';

  @override
  String get marketingInsightsTitle => 'Marketing uvid';

  @override
  String get averageTicketValue => 'Prosječna vrijednost kartice';

  @override
  String get todayRevenue => 'Današnji prihod';

  @override
  String get todayAppointments => 'Termini danas';

  @override
  String get newCustomersToday => 'Novi kupci';

  @override
  String get noShowsToday => 'Nedolasci';

  @override
  String get addNewItem => 'Dodaj novu stavku';

  @override
  String get addItemTitle => 'Naslov';

  @override
  String get addItemTitleHint => 'Unesite naslov stavke';

  @override
  String get addItemTitleRequired => 'Naslov je obavezan';

  @override
  String get addItemCategory => 'Kategorija';

  @override
  String get addItemCategoryHint => 'Unesite kategoriju';

  @override
  String get addItemLocation => 'Lokacija';

  @override
  String get addItemSelectLocation => 'Odaberi lokaciju';

  @override
  String get addItemBox => 'Kutija';

  @override
  String get addItemSelectBox => 'Odaberi kutiju';

  @override
  String get addItemPriceOptional => 'Cijena (opcionalno)';

  @override
  String get addItemPriceHint => 'Unesite cijenu';

  @override
  String addItemSavedSuccess(String name) {
    return 'Stavka $name uspješno spremljena';
  }

  @override
  String addItemError(String message) {
    return 'Greška: $message';
  }

  @override
  String get inventoryItems => 'Stavke';

  @override
  String get inventoryBoxes => 'Kutije';

  @override
  String get inventoryLocations => 'Lokacije';

  @override
  String get addNewBox => 'Dodaj novu kutiju';

  @override
  String get addBoxLabel => 'Oznaka kutije';

  @override
  String get addBoxLabelHint => 'npr. Kuhinjski pribor, Alati, Dokumenti';

  @override
  String get addBoxLabelRequired => 'Unesite oznaku kutije';

  @override
  String get addBoxSuccess => 'Kutija uspješno dodana!';

  @override
  String addBoxError(String error) {
    return 'Greška pri dodavanju kutije: $error';
  }

  @override
  String get addNewLocation => 'Dodaj novu lokaciju';

  @override
  String get addLocationName => 'Naziv lokacije';

  @override
  String get addLocationNameHint => 'npr. Kuhinja, Garaža, Ured';

  @override
  String get addLocationNameRequired => 'Unesite naziv lokacije';

  @override
  String get addLocationColor => 'Boja';

  @override
  String get addLocationColorHint => '#4CAF50';

  @override
  String get addLocationColorRequired => 'Unesite boju';

  @override
  String get addLocationColorInvalid =>
      'Unesite ispravnu heksadecimalnu boju (npr. #4CAF50)';

  @override
  String get addLocationSuccess => 'Lokacija uspješno dodana!';

  @override
  String addLocationError(String error) {
    return 'Greška pri dodavanju lokacije: $error';
  }

  @override
  String get selectCountry => 'Odaberi državu';

  @override
  String get searchCountryOrCode => 'Pretraži državu ili pozivni broj';

  @override
  String get switchBrand => 'Promijeni salon';

  @override
  String get discoverBrand => 'Pronađi salon';

  @override
  String get switchBrandConfirmTitle => 'Promijeni salon';

  @override
  String switchBrandConfirmMessage(String brandName) {
    return 'Prebaciti na $brandName?';
  }

  @override
  String get switchBrandButton => 'Prebaci';

  @override
  String get settingsNotifications => 'Obavijesti';

  @override
  String get settingsNotificationsDescription =>
      'Podsjetnici i ažuriranja termina';

  @override
  String get currentBrand => 'Trenutni';

  @override
  String get noBrandsFound => 'Nema pronađenih salona';

  @override
  String get discoverBrandsHint =>
      'Dodirnite ikonu skeniranja iznad za otkrivanje salona';

  @override
  String get findYourBusiness => 'Pronađite svoj salon';

  @override
  String get searchBusinessByTag =>
      'Pretražite svoj salon\npo jedinstvenoj oznaci';

  @override
  String get searchBusinessByTagSingleLine =>
      'Pretražite svoj salon po jedinstvenoj oznaci.';

  @override
  String get selectBusinessFirst => 'Molimo prvo odaberite salon.';

  @override
  String get searchByTag => 'Pretraži po oznaci';

  @override
  String get dashboardBrandTitle => 'Brend';

  @override
  String get dashboardBrandName => 'Naziv';

  @override
  String get dashboardBrandNameHint => 'npr. Kingsman Salon';

  @override
  String get dashboardBrandNameRequired => 'Naziv je obavezan';

  @override
  String get dashboardBrandPrimaryColor => 'Primarna boja';

  @override
  String get dashboardBrandPrimaryColorHint => '#9B784A';

  @override
  String get dashboardBrandLogoUrl => 'URL logotipa';

  @override
  String get dashboardBrandLogoUrlHint => 'https://...';

  @override
  String get dashboardBrandContactEmail => 'Kontakt email';

  @override
  String get dashboardBrandContactEmailHint => 'contact@example.com';

  @override
  String get dashboardBrandSlotInterval => 'Interval termina (min)';

  @override
  String get dashboardBrandBufferTime => 'Vrijeme između termina (min)';

  @override
  String get dashboardBrandCancelHours => 'Min. sati za otkaz';

  @override
  String get dashboardBrandLoyaltyPointsMultiplier => 'Bodovi po 1€';

  @override
  String get dashboardBrandLoyaltyPointsMultiplierHint =>
      'npr. 10 (30€ → 300 bodova)';

  @override
  String get dashboardBrandMultiLocation => 'Više lokacija';

  @override
  String get dashboardBrandSaved => 'Brend spremljen';

  @override
  String get dashboardBrandCreated => 'Brend kreiran';

  @override
  String get dashboardBrandSetConfigId =>
      'Postavite default_brand_id u assets/config/default.json';

  @override
  String get dashboardLocationAdd => 'Dodaj lokaciju';

  @override
  String get dashboardLocationEdit => 'Uredi lokaciju';

  @override
  String get dashboardLocationName => 'Naziv';

  @override
  String get dashboardLocationNameHint => 'npr. Zagreb Centar';

  @override
  String get dashboardLocationNameRequired => 'Naziv je obavezan';

  @override
  String get dashboardLocationAddress => 'Adresa';

  @override
  String get dashboardLocationAddressHint => 'Ulica, grad';

  @override
  String get dashboardLocationPhone => 'Telefon';

  @override
  String get dashboardLocationPhoneHint => '+385 1 234 5678';

  @override
  String get dashboardLocationPhoneRequired => 'Broj telefona je obavezan';

  @override
  String get dashboardLocationAddressRequired => 'Adresa je obavezna';

  @override
  String get dashboardLocationCoordinates => 'Koordinate';

  @override
  String get dashboardLocationLatHint => 'Širina (npr. 45.81)';

  @override
  String get dashboardLocationLngHint => 'Duljina (npr. 15.98)';

  @override
  String get dashboardLocationWorkingHours => 'Radno vrijeme';

  @override
  String get dashboardLocationTimeFormat => 'Koristite HH:mm (npr. 14:00)';

  @override
  String get dashboardLocationStartBeforeEnd => 'Početak mora biti prije kraja';

  @override
  String get dashboardLocationDayClosed => 'Zatvoreno';

  @override
  String get dashboardLocationSaved => 'Lokacija spremljena';

  @override
  String get dashboardLocationDeleted => 'Lokacija obrisana';

  @override
  String get dashboardLocationDeleteConfirm => 'Obrisati ovu lokaciju?';

  @override
  String get dashboardLocationDeleteConfirmMessage =>
      'Ova radnja se ne može poništiti.';

  @override
  String get dashboardLocationDeleteButton => 'Obriši';

  @override
  String get dashboardLocationEmpty => 'Još nema lokacija. Dodajte novu.';

  @override
  String get dashboardLocationNoWorkingHours =>
      'Radno vrijeme nije postavljeno. Dodirnite za dodavanje.';

  @override
  String get dashboardNoBrand => 'Nije konfiguriran brend';

  @override
  String get add => 'Dodaj';

  @override
  String get edit => 'Uredi';

  @override
  String get dashboardServiceAdd => 'Dodaj uslugu';

  @override
  String get dashboardServiceEdit => 'Uredi uslugu';

  @override
  String get dashboardServiceName => 'Naziv';

  @override
  String get dashboardServiceNameHint => 'npr. Šišanje & Pranje';

  @override
  String get dashboardServiceNameRequired => 'Naziv je obavezan';

  @override
  String get dashboardServicePrice => 'Cijena';

  @override
  String get dashboardServicePriceHint => '0';

  @override
  String get dashboardServicePriceInvalid => 'Unesite valjanu cijenu';

  @override
  String get dashboardServiceDuration => 'Trajanje (minute)';

  @override
  String get dashboardServiceDurationHint => '30';

  @override
  String get dashboardServiceDurationInvalid =>
      'Unesite valjano trajanje (min 1)';

  @override
  String get dashboardServiceDurationRequired => 'Trajanje je obavezno';

  @override
  String get dashboardServicePriceRequired => 'Cijena je obavezna';

  @override
  String get dashboardServiceDescription => 'Opis';

  @override
  String get dashboardServiceDescriptionHint => 'Opcionalni opis';

  @override
  String get dashboardServiceAvailableAt => 'Dostupno na';

  @override
  String get dashboardServiceAvailableAtAll => 'Svim lokacijama';

  @override
  String get dashboardServiceAvailableAtSelected => 'Samo odabranim lokacijama';

  @override
  String get dashboardServiceSaved => 'Usluga spremljena';

  @override
  String get dashboardServiceCreated => 'Usluga kreirana';

  @override
  String get dashboardServiceDeleteConfirm => 'Obrisati ovu uslugu?';

  @override
  String get dashboardServiceDeleteConfirmMessage =>
      'Ova radnja se ne može poništiti.';

  @override
  String get dashboardServiceDeleteButton => 'Obriši';

  @override
  String get dashboardServiceDeleted => 'Usluga obrisana';

  @override
  String get dashboardServiceEmpty => 'Još nema usluga. Dodajte novu.';

  @override
  String get dashboardBarberAdd => 'Dodaj profesionalca';

  @override
  String get dashboardBarberEdit => 'Uredi profesionalca';

  @override
  String get dashboardBarberName => 'Naziv';

  @override
  String get dashboardBarberNameHint => 'npr. Ivan Horvat';

  @override
  String get dashboardBarberNameRequired => 'Naziv je obavezan';

  @override
  String get dashboardBarberPhotoUrl => 'URL fotografije';

  @override
  String get dashboardBarberPhotoUrlHint => 'https://...';

  @override
  String get dashboardBarberPhotoUrlRequired => 'URL fotografije je obavezan';

  @override
  String get dashboardBarberLocation => 'Lokacija';

  @override
  String get dashboardBarberLocationRequired => 'Odaberite lokaciju';

  @override
  String get dashboardBarberNoLocations =>
      'Prvo dodajte lokacije u tabu Lokacije.';

  @override
  String get dashboardBarberActive => 'Aktivan';

  @override
  String get dashboardBarberWorkingHoursOverride => 'Prilagođeno radno vrijeme';

  @override
  String get dashboardBarberWorkingHoursOverrideHint =>
      'Nadopiši radno vrijeme lokacije za ovog profesionalca. Ostavite prazno za vrijeme lokacije.';

  @override
  String get dashboardBarberSaved => 'Profesionalac spremljen';

  @override
  String get dashboardBarberCreated => 'Profesionalac kreiran';

  @override
  String get dashboardBarberDeleteConfirm => 'Obrisati ovog profesionalca?';

  @override
  String get dashboardBarberDeleteConfirmMessage =>
      'Ova radnja se ne može poništiti.';

  @override
  String get dashboardBarberDeleteButton => 'Obriši';

  @override
  String get dashboardBarberDeleted => 'Profesionalac obrisan';

  @override
  String get dashboardBarberEmpty => 'Još nema profesionalaca. Dodajte novog.';

  @override
  String get dashboardBarberInactive => 'Neaktivan';

  @override
  String get dashboardRewardAdd => 'Dodaj nagradu';

  @override
  String get dashboardRewardEdit => 'Uredi nagradu';

  @override
  String get dashboardRewardName => 'Naziv';

  @override
  String get dashboardRewardNameHint => 'npr. Besplatna kava';

  @override
  String get dashboardRewardNameRequired => 'Naziv je obavezan';

  @override
  String get dashboardRewardDescription => 'Opis';

  @override
  String get dashboardRewardDescriptionHint => 'Opcionalni opis';

  @override
  String get dashboardRewardDescriptionRequired => 'Opis je obavezan';

  @override
  String get dashboardRewardPointsCostLabel => 'Cijena u bodovima';

  @override
  String get dashboardRewardPointsCostHint => '100';

  @override
  String get dashboardRewardPointsInvalid =>
      'Unesite valjanu vrijednost bodova (0 ili više)';

  @override
  String dashboardRewardPointsCost(int points) {
    return '$points bod.';
  }

  @override
  String get dashboardRewardSortOrder => 'Redoslijed';

  @override
  String get dashboardRewardSortOrderHint => '0';

  @override
  String get dashboardRewardActive => 'Aktivna';

  @override
  String get dashboardRewardSaved => 'Nagrada spremljena';

  @override
  String get dashboardRewardCreated => 'Nagrada kreirana';

  @override
  String get dashboardRewardDeleteConfirm => 'Obrisati ovu nagradu?';

  @override
  String get dashboardRewardDeleteConfirmMessage =>
      'Ova radnja se ne može poništiti.';

  @override
  String get dashboardRewardDeleteButton => 'Obriši';

  @override
  String get dashboardRewardDeleted => 'Nagrada obrisana';

  @override
  String get dashboardRewardEmpty => 'Još nema nagrada. Dodajte novu.';

  @override
  String get dashboardRewardInactive => 'Neaktivna';

  @override
  String get closed => 'Zatvoreno';

  @override
  String openNow(String open, String close) {
    return 'OTVORENO SADA $open - $close';
  }

  @override
  String get calendarTitle => 'Kalendar';

  @override
  String get calendarToday => 'Danas';

  @override
  String get calendarNoAppointments => 'Nema termina';

  @override
  String calendarAppointmentsCount(int count) {
    return '$count termin(a)';
  }

  @override
  String get calendarViewDay => 'Dan';

  @override
  String get calendarViewWeek => 'Tjedan';

  @override
  String get calendarViewMonth => 'Mjesec';

  @override
  String get calendarAppointmentDetails => 'Detalji termina';

  @override
  String get calendarClient => 'Klijent';

  @override
  String get calendarService => 'Usluga';

  @override
  String get calendarTime => 'Vrijeme';

  @override
  String get calendarDuration => 'Trajanje';

  @override
  String get calendarPrice => 'Cijena';

  @override
  String get calendarStatus => 'Status';

  @override
  String get calendarLocation => 'Lokacija';

  @override
  String get errorLoadingAppointments => 'Greška pri učitavanju termina';

  @override
  String get shiftTabTitle => 'Moja smjena';

  @override
  String get shiftWorkingHours => 'Radno vrijeme';

  @override
  String get shiftTimeOff => 'Slobodni dani';

  @override
  String get shiftAddTimeOff => 'Dodaj slobodne dane';

  @override
  String get shiftNoTimeOff => 'Nema zakazanih slobodnih dana';

  @override
  String get shiftUpcomingTimeOff => 'Nadolazeći slobodni dani';

  @override
  String get timeOffStartDate => 'Datum početka';

  @override
  String get timeOffEndDate => 'Datum kraja';

  @override
  String get timeOffReason => 'Razlog';

  @override
  String get timeOffReasonVacation => 'Godišnji odmor';

  @override
  String get timeOffReasonSick => 'Bolovanje';

  @override
  String get timeOffReasonPersonal => 'Osobno';

  @override
  String get timeOffSaved => 'Slobodni dani spremljeni';

  @override
  String get timeOffDeleted => 'Slobodni dani obrisani';

  @override
  String get timeOffDeleteConfirm => 'Obrisati slobodne dane?';

  @override
  String get timeOffDeleteConfirmMessage =>
      'Jeste li sigurni da želite obrisati ovaj period slobodnih dana?';

  @override
  String get timeOffEdit => 'Uredi';

  @override
  String get timeOffDelete => 'Obriši';

  @override
  String timeOffDateRange(String startDate, String endDate) {
    return '$startDate - $endDate';
  }

  @override
  String get timeOffSelectReason => 'Odaberite razlog';

  @override
  String get timeOffStartDateRequired => 'Početni datum je obavezan';

  @override
  String get timeOffEndDateRequired => 'Krajnji datum je obavezan';

  @override
  String get timeOffEndBeforeStart =>
      'Krajnji datum mora biti nakon početnog datuma';

  @override
  String get timeOffDays => 'dana';

  @override
  String get shiftMyWorkingHours => 'Moje radno vrijeme';

  @override
  String get shiftEditWorkingHours => 'Uredi';

  @override
  String get shiftNoWorkingHours => 'Radno vrijeme nije postavljeno';

  @override
  String get shiftClosed => 'Zatvoreno';

  @override
  String get shiftWorkingHoursSaved => 'Radno vrijeme uspješno ažurirano';

  @override
  String get dashboardManualBookingTitle => 'Dodaj termin';

  @override
  String get dashboardManualBookingSelectService => 'Odaberi uslugu';

  @override
  String get dashboardManualBookingSelectBarber => 'Odaberi profesionalca';

  @override
  String get dashboardManualBookingSelectDate => 'Odaberi datum';

  @override
  String get dashboardManualBookingSelectTime => 'Odaberi vrijeme';

  @override
  String get dashboardManualBookingCustomerInfo => 'Podaci o klijentu';

  @override
  String get dashboardManualBookingCustomerName => 'Ime';

  @override
  String get dashboardManualBookingCustomerNameHint => 'npr. Ivan Horvat';

  @override
  String get dashboardManualBookingCustomerNameRequired => 'Ime je obavezno';

  @override
  String get dashboardManualBookingCustomerPhone => 'Telefon';

  @override
  String get dashboardManualBookingCustomerPhoneHint => '+385...';

  @override
  String get dashboardManualBookingCustomerPhoneRequired =>
      'Telefon je obavezan';

  @override
  String get dashboardManualBookingSuccess => 'Termin kreiran';

  @override
  String get dashboardManualBookingSlotTaken => 'Termin zauzet';

  @override
  String get dashboardManualBookingNoSlots => 'Nema slobodnih termina';

  @override
  String get completeAppointmentTitle => 'Završiti termin?';

  @override
  String get completeAppointmentMessage =>
      'Jeste li sigurni da želite označiti ovaj termin kao dovršen?';

  @override
  String get complete => 'Dovrši';

  @override
  String get appointmentCompleted => 'Termin označen kao dovršen';

  @override
  String get notificationsDisabledInSettings =>
      'Molimo uključite obavijesti u postavkama sustava';

  @override
  String get brandTagHint => 'oznaka-salona';

  @override
  String joinBrand(String brandName) {
    return 'Pridruži salonu $brandName';
  }

  @override
  String get markAsNoShowTitle => 'Označi kao nedolazak?';

  @override
  String get markAsNoShowMessage =>
      'Jeste li sigurni da želite označiti ovaj termin kao nedolazak?';

  @override
  String get noShow => 'Nedolazak';

  @override
  String get appointmentMarkedAsNoShow => 'Termin označen kao nedolazak';

  @override
  String get downloadAppCta => 'Preuzmi STYL';

  @override
  String get webBannerGreetingMorning => 'Dobro jutro';

  @override
  String get webBannerGreetingAfternoon => 'Dobar dan';

  @override
  String get webBannerGreetingEvening => 'Dobra večer';

  @override
  String webBannerWelcome(String brandName) {
    return 'Dobrodošli u $brandName';
  }

  @override
  String get webBannerLoyaltyTitle => 'Skupljaj bodove vjernosti';

  @override
  String get webBannerLoyaltyBody =>
      'Preuzmi STYL aplikaciju za praćenje posjeta, skupljanje bodova i otključavanje ekskluzivnih nagrada.';

  @override
  String get categoryAddNew => 'Dodaj novu kategoriju';

  @override
  String get categoryName => 'Naziv kategorije';

  @override
  String get categorySelect => 'Odaberi kategoriju';

  @override
  String get categorySaved => 'Kategorija spremljena';

  @override
  String categorySaveError(String error) {
    return 'Greška pri spremanju kategorije: $error';
  }

  @override
  String get error => 'Greška';

  @override
  String get locationLat => 'Geografska širina';

  @override
  String get locationLng => 'Geografska dužina';

  @override
  String get ok => 'U redu';

  @override
  String get invalidQrCode => 'Neispravan QR kod';

  @override
  String get noCompletableAppointmentFound =>
      'Nije pronađen aktivan ili nedavni termin za dovršetak';

  @override
  String scanCooldownMessage(int seconds) {
    return 'Pričekajte $seconds sekundi prije ponovnog skeniranja';
  }

  @override
  String get accessRestricted => 'Pristup ograničen';

  @override
  String get processing => 'Obrada u tijeku…';

  @override
  String redeemConfirmMessage(String reward, int points, String pointsLabel) {
    return 'Iskoristiti $reward ($points $pointsLabel)?';
  }

  @override
  String get create => 'Kreiraj';

  @override
  String get delete => 'Obriši';

  @override
  String durationMinutesShort(int minutes) {
    return '${minutes}min';
  }

  @override
  String durationHoursShort(int hours) {
    return '${hours}h';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String get timeOffLoadError => 'Nije moguće učitati slobodne dane.';

  @override
  String get noBarberProfileTitle => 'Profil frizera nije pronađen';

  @override
  String get noBarberProfileMessage =>
      'Vaš račun ima ulogu \"Frizer\", ali nije povezan s profilom frizera. Kontaktirajte podršku ili kreirajte novi profil.';

  @override
  String dashboardBrandId(String id) {
    return 'ID Brenda: $id';
  }
}
