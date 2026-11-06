import 'package:daram/core/constants/iranian_banks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog has unique ids and all key institutions', () {
    final ids = iranianBanks.map((bank) => bank.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in [
      'melli',
      'mellat',
      'saderat',
      'sepah',
      'bankino',
      'vipad',
      'dima',
      'qbank',
      'blue',
      'metabank',
      'melall',
      'markazi',
      'other',
    ]) {
      expect(ids, contains(id), reason: id);
    }
    expect(iranianBanks.length, greaterThanOrEqualTo(60));
    expect(
      iranianBanks.where((bank) => bank.kind == BankKind.digitalBank).length,
      26,
    );
  });

  test('BluBank resolves from Persian and English aliases', () {
    for (final name in ['بلوبانک', 'بلو بانک', 'بلو', 'blue', 'BluBank']) {
      expect(bankByName(name)?.id, 'blue', reason: name);
    }
    final blue = bankById('blue');
    expect(blue.kind, BankKind.digitalBank);
    expect(blue.parentBank, 'بانک سامان');
    expect(blue.logoAsset, 'assets/banks/blue.svg');
  });

  test('new bank and neobank names resolve', () {
    expect(bankByName('بانک ملت')?.id, 'mellat');
    expect(bankByName('ملت')?.id, 'mellat');
    expect(bankByName('بانکینو')?.id, 'bankino');
    expect(bankByName('Bankino')?.id, 'bankino');
    expect(bankByName('ویپاد')?.id, 'vipad');
    expect(bankByName('دیما')?.id, 'dima');
    expect(bankByName('کیوبانک')?.id, 'qbank');
    expect(bankByName('مؤسسه اعتباری ملل')?.id, 'melall');
    expect(bankByName('بانک مرکزی')?.id, 'markazi');
    expect(bankByName('یک بانک ناشناخته'), isNull);
    expect(bankByName('سایر')?.id, 'other');
  });

  test('every bundled logo asset exists and is non-empty', () async {
    final withLogos = iranianBanks.where((bank) => bank.logoAsset != null);
    expect(withLogos.length, 41);
    for (final bank in withLogos) {
      final data = await rootBundle.load(bank.logoAsset!);
      expect(data.lengthInBytes, greaterThan(200), reason: bank.logoAsset);
    }
  });

  test('picker groups are filtered by a query', () {
    final blue = groupedBanks('بلو');
    expect(blue[BankKind.digitalBank]!.first.id, 'blue');
    final all = groupedBanks();
    expect(all[BankKind.digitalBank]!.length, 26);
    expect(all[BankKind.creditInstitution]!.length, 5);
  });
}
