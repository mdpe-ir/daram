import 'package:daram/app/design_system/daram_widgets.dart';
import 'package:daram/app/theme/daram_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BankAvatar renders raster marks and a wordmark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DaramTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                BankAvatar(bankId: 'bankino', size: 46),
                SizedBox(width: 8),
                BankAvatar(bankId: 'forbix', size: 46),
                SizedBox(width: 8),
                BankAvatar(bankId: 'omid', size: 46),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
