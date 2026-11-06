import 'package:daram/app/app_providers.dart';
import 'package:daram/app/theme/daram_theme.dart';
import 'package:daram/features/settings/presentation/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('About shows the package version name and build code', (
    tester,
  ) async {
    final info = PackageInfo(
      appName: 'DARAM',
      packageName: 'ir.daram.daram',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [packageInfoProvider.overrideWith((ref) async => info)],
        child: MaterialApp(theme: DaramTheme.dark(), home: const AboutScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DARAM · 1.2.3 (42)'), findsOneWidget);
    expect(find.text('نسخه ۱.۲.۳ · کد ساخت ۴۲'), findsOneWidget);
  });
}
