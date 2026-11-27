/// Static fallback application metadata. The live version name and build
/// code are read with `package_info_plus`; these constants cover loading and
/// unsupported-platform cases.
abstract final class AppInfo {
  static const String name = 'DARAM';
  static const String persianName = 'دارام';
  static const String version = '1.6.0';
  static const String buildNumber = '13';
  static const String tagline = 'پولت رو بشناس، هوشمندانه زندگی کن.';
  static const String taglineEn = 'Know Your Money. Own Your Future.';
  static const String phase = 'فاز یک — دستیار مالی محلی';
  static const String fullVersion = '$version ($buildNumber)';
}
