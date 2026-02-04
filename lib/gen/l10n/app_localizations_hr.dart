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
  String get logout => 'Odjava';

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
  String get bookingTitle => 'Rezerviraj termin';

  @override
  String get bookingSelectService => 'Odaberi uslugu';

  @override
  String get bookingSelectBarber => 'Odaberi brijača';

  @override
  String get bookingAnyBarber => 'Bilo koji brijač';

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
  String get bookingStepService => 'Usluga';

  @override
  String get bookingStepBarber => 'Brijač';

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
  String get sectionBarbers => 'Rezerviraj kod brijača';

  @override
  String get sectionPopularServices => 'Popularne usluge';

  @override
  String get sectionNearbyBarbershop => 'OBLIŽNJA BRIJANICA';

  @override
  String get loyaltyTitle => 'LOYALTY';

  @override
  String get loyaltyMember => 'ČLAN';

  @override
  String get loyaltyViewRewards => 'Pogledaj nagrade';

  @override
  String get loyaltyPageTitle => 'Nagrade i lojalnost';

  @override
  String get loyaltyRewardsComingSoon => 'Nagrade uskoro';

  @override
  String get loyaltyEarnPointsDescription =>
      'Zaradite bodove i unovčite nagrade';

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
  String get dashboardBrandTitle => 'Brend';

  @override
  String get dashboardBrandName => 'Naziv';

  @override
  String get dashboardBrandNameHint => 'npr. Kingsman Barbershop';

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
  String get dashboardNoBrand => 'Nije konfiguriran brend';

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
  String get dashboardBarberAdd => 'Dodaj brijača';

  @override
  String get dashboardBarberEdit => 'Uredi brijača';

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
      'Nadopiši radno vrijeme lokacije za ovog brijača. Ostavite prazno za vrijeme lokacije.';

  @override
  String get dashboardBarberSaved => 'Brijač spremljen';

  @override
  String get dashboardBarberCreated => 'Brijač kreiran';

  @override
  String get dashboardBarberDeleteConfirm => 'Obrisati ovog brijača?';

  @override
  String get dashboardBarberDeleteConfirmMessage =>
      'Ova radnja se ne može poništiti.';

  @override
  String get dashboardBarberDeleteButton => 'Obriši';

  @override
  String get dashboardBarberDeleted => 'Brijač obrisan';

  @override
  String get dashboardBarberEmpty => 'Još nema brijača. Dodajte novog.';

  @override
  String get dashboardBarberInactive => 'Neaktivan';

  @override
  String get closed => 'Zatvoreno';

  @override
  String openNow(String open, String close) {
    return 'OTVORENO SADA $open - $close';
  }
}
