import 'package:daram/app/design_system/bank_picker.dart';
import 'package:daram/app/theme/daram_theme.dart';
import 'package:daram/core/constants/iranian_banks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bank picker searches and selects BluBank', (tester) async {
    IranianBank? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: DaramTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await showBankPicker(
                      context,
                      selectedId: 'mellat',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('انتخاب بانک'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'بلوبانک');
    await tester.pumpAndSettle();
    expect(find.text('بلوبانک'), findsWidgets);

    await tester.tap(find.text('بلوبانک').last);
    await tester.pumpAndSettle();
    expect(picked?.id, 'blue');
  });

  testWidgets('bank picker offers a custom bank entry', (tester) async {
    IranianBank? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: DaramTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await showBankPicker(
                      context,
                      selectedId: 'mellat',
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بانک من در فهرست نیست'));
    await tester.pumpAndSettle();
    expect(picked?.id, 'other');
  });
}
