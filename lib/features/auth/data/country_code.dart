/// Country dial code for phone input (ISO 3166-1 alpha-2 + E.164).
class CountryCode {
  const CountryCode({
    required this.isoCode,
    required this.name,
    required this.dialCode,
  });

  final String isoCode;
  final String name;
  final String dialCode;

  /// Flag emoji from ISO 3166-1 alpha-2 (e.g. US -> 🇺🇸).
  String get flag {
    if (isoCode.length != 2) return '';
    final a = isoCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final b = isoCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([a, b]);
  }

  /// Display label: "🇺🇸 +1" or "United States +1".
  String get displayLabel => '$flag $dialCode';
}

/// Common country codes for phone prefix selector (alphabetical by name).
const List<CountryCode> kCountryCodes = [
  CountryCode(isoCode: 'AT', name: 'Austria', dialCode: '+43'),
  CountryCode(isoCode: 'AU', name: 'Australia', dialCode: '+61'),
  CountryCode(isoCode: 'BE', name: 'Belgium', dialCode: '+32'),
  CountryCode(isoCode: 'BR', name: 'Brazil', dialCode: '+55'),
  CountryCode(isoCode: 'CA', name: 'Canada', dialCode: '+1'),
  CountryCode(isoCode: 'CH', name: 'Switzerland', dialCode: '+41'),
  CountryCode(isoCode: 'DE', name: 'Germany', dialCode: '+49'),
  CountryCode(isoCode: 'ES', name: 'Spain', dialCode: '+34'),
  CountryCode(isoCode: 'FR', name: 'France', dialCode: '+33'),
  CountryCode(isoCode: 'GB', name: 'United Kingdom', dialCode: '+44'),
  CountryCode(isoCode: 'GR', name: 'Greece', dialCode: '+30'),
  CountryCode(isoCode: 'HR', name: 'Croatia', dialCode: '+385'),
  CountryCode(isoCode: 'HU', name: 'Hungary', dialCode: '+36'),
  CountryCode(isoCode: 'IE', name: 'Ireland', dialCode: '+353'),
  CountryCode(isoCode: 'IN', name: 'India', dialCode: '+91'),
  CountryCode(isoCode: 'IT', name: 'Italy', dialCode: '+39'),
  CountryCode(isoCode: 'JP', name: 'Japan', dialCode: '+81'),
  CountryCode(isoCode: 'MX', name: 'Mexico', dialCode: '+52'),
  CountryCode(isoCode: 'NL', name: 'Netherlands', dialCode: '+31'),
  CountryCode(isoCode: 'PL', name: 'Poland', dialCode: '+48'),
  CountryCode(isoCode: 'PT', name: 'Portugal', dialCode: '+351'),
  CountryCode(isoCode: 'RO', name: 'Romania', dialCode: '+40'),
  CountryCode(isoCode: 'RS', name: 'Serbia', dialCode: '+381'),
  CountryCode(isoCode: 'RU', name: 'Russia', dialCode: '+7'),
  CountryCode(isoCode: 'SE', name: 'Sweden', dialCode: '+46'),
  CountryCode(isoCode: 'SI', name: 'Slovenia', dialCode: '+386'),
  CountryCode(isoCode: 'SK', name: 'Slovakia', dialCode: '+421'),
  CountryCode(isoCode: 'US', name: 'United States', dialCode: '+1'),
  CountryCode(isoCode: 'ZA', name: 'South Africa', dialCode: '+27'),
];
