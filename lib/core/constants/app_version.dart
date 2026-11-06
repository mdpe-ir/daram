import 'package:package_info_plus/package_info_plus.dart';

import 'app_info.dart';

/// The version name reported by the platform, falling back to the pubspec
/// constants while [PackageInfo] is loading or unavailable.
String appVersionName(PackageInfo? info) {
  final version = info?.version.trim();
  return version == null || version.isEmpty ? AppInfo.version : version;
}

/// The build code reported by the platform, falling back to the pubspec
/// constants while [PackageInfo] is loading or unavailable.
String appVersionCode(PackageInfo? info) {
  final build = info?.buildNumber.trim();
  return build == null || build.isEmpty ? AppInfo.buildNumber : build;
}

/// `1.0.0 (1)` — used in LTR contexts and the license page.
String appVersionLabel(PackageInfo? info) =>
    '${appVersionName(info)} (${appVersionCode(info)})';
