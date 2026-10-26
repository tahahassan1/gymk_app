/// Confirmed MVP monetary unit: whole Egyptian pounds, not piastres.
/// Stored integer minor units are the app's smallest accepted unit (one EGP).
abstract final class GymkCurrency {
  static const code = 'EGP';
  static const fractionDigits = 0;
  static const minorUnitsPerMajorUnit = 1;
}
