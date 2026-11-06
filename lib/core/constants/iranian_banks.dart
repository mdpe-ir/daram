import 'package:flutter/material.dart';

/// Category used to group the bank picker and label an account's bank.
enum BankKind {
  bank('بانک'),
  digitalBank('نئوبانک'),
  creditInstitution('مؤسسه اعتباری'),
  international('بانک خارجی'),
  centralBank('بانک مرکزی'),
  other('سایر');

  const BankKind(this.label);

  final String label;
}

/// Metadata for an Iranian bank, neobank or credit institution.
///
/// Logos are bundled only where their license permits redistribution. The
/// BluBank logo is CC BY-SA 4.0 (see `assets/banks/ATTRIBUTION.md`); the rest
/// of the SVG logos are CC0. Neobanks without a freely licensed logo use a
/// designed monogram and their brand colour instead.
class IranianBank {
  const IranianBank({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.colorHex,
    this.kind = BankKind.bank,
    this.logoAsset,
    this.parentBank,
    this.aliases = const [],
    this.logoIsWordmark = false,
  });

  final String id;
  final String nameFa;
  final String nameEn;

  /// Brand identity colour used for the monogram and accents.
  final String colorHex;

  final BankKind kind;

  /// Bundled SVG path, when a redistributable asset exists.
  final String? logoAsset;

  /// For neobanks: the traditional bank behind the digital brand.
  final String? parentBank;

  /// Alternative Persian/English names accepted from the user or the AI.
  final List<String> aliases;

  /// Wide wordmarks are replaced by a monogram in very small tiles.
  final bool logoIsWordmark;

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Two-letter monogram used when there is no logo asset (or at tiny sizes).
  String get monogram {
    if (id == 'other') return 'س';
    if (kind == BankKind.digitalBank) {
      final english = nameEn.replaceAll(RegExp('[^A-Za-z]'), '');
      if (english.isNotEmpty) return english[0].toUpperCase();
    }
    final words = nameFa
        .replaceAll('بانک', '')
        .replaceAll('مؤسسه', '')
        .replaceAll('اعتباری', '')
        .replaceAll('نئوبانک', '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'ب';
    final first = words.first.characters.first;
    final second = words.length > 1 ? words[1].characters.first : '';
    return '$first$second';
  }

  /// Short descriptor shown under the name in the picker.
  String get subtitle {
    if (id == 'other') return 'افزودن بانک خارج از فهرست';
    return switch (kind) {
      BankKind.digitalBank =>
        parentBank == null ? 'نئوبانک' : 'نئوبانک · $parentBank',
      BankKind.bank => parentBank == null ? 'بانک' : 'بانک · $parentBank',
      BankKind.creditInstitution => 'مؤسسه اعتباری',
      BankKind.international => 'بانک خارجی',
      BankKind.centralBank => 'بانک مرکزی',
      BankKind.other => 'سایر بانک‌ها',
    };
  }

  /// True when [query] matches the Persian/English name, an alias or the
  /// parent bank. Used by the searchable picker and by the AI resolver.
  bool matches(String query) {
    final normalized = normalizeBankName(query);
    if (normalized.isEmpty) return true;
    if (normalizeBankName(nameFa).contains(normalized)) return true;
    if (normalizeBankName(nameEn).contains(normalized)) return true;
    if (parentBank != null &&
        normalizeBankName(parentBank!).contains(normalized)) {
      return true;
    }
    for (final alias in aliases) {
      if (normalizeBankName(alias).contains(normalized)) return true;
    }
    return false;
  }
}

/// Removes bank words, spaces, ZWNJ, Arabic yeh/kaf and punctuation so that
/// colloquial names («بلوبانک»، «بلو بانک»، «blue») compare consistently.
String normalizeBankName(String value) => value
    .toLowerCase()
    .replaceAll('نئوبانک', '')
    .replaceAll('بانک', '')
    .replaceAll('مؤسسه', '')
    .replaceAll('اعتباری', '')
    .replaceAll('‌', '')
    .replaceAll('ي', 'ی')
    .replaceAll('ك', 'ک')
    .replaceAll(RegExp(r'[\s\-_()\.]+'), '')
    .trim();

/// The full catalog: state/private/specialized banks, credit institutions,
/// foreign banks used by Iranians, and licensed digital banks/neobanks.
const List<IranianBank> iranianBanks = <IranianBank>[
  // ---------------------------------------------------------------- State banks
  IranianBank(
    id: 'melli',
    nameFa: 'بانک ملی ایران',
    nameEn: 'Bank Melli',
    colorHex: '#0E4C92',
    logoAsset: 'assets/banks/melli.svg',
    aliases: ['ملی'],
  ),
  IranianBank(
    id: 'sepah',
    nameFa: 'بانک سپه',
    nameEn: 'Bank Sepah',
    colorHex: '#1D3C6E',
    logoAsset: 'assets/banks/sepah.svg',
    aliases: ['سپه'],
  ),
  IranianBank(
    id: 'maskan',
    nameFa: 'بانک مسکن',
    nameEn: 'Bank Maskan',
    colorHex: '#0F7B6C',
    logoAsset: 'assets/banks/maskan.svg',
    aliases: ['مسکن'],
  ),
  IranianBank(
    id: 'postbank',
    nameFa: 'پست بانک ایران',
    nameEn: 'Post Bank',
    colorHex: '#EAB308',
    logoAsset: 'assets/banks/postbank.svg',
    aliases: ['پست', 'پست‌بانک'],
  ),
  IranianBank(
    id: 'keshavarzi',
    nameFa: 'بانک کشاورزی',
    nameEn: 'Bank Keshavarzi',
    colorHex: '#2E7D32',
    logoAsset: 'assets/banks/keshavarzi.svg',
    aliases: ['کشاورزی'],
  ),
  IranianBank(
    id: 'tosee_taavon',
    nameFa: 'بانک توسعه تعاون',
    nameEn: "Tose'e Ta'avon",
    colorHex: '#0E7490',
    logoAsset: 'assets/banks/tosee_taavon.svg',
    aliases: ['توسعه تعاون'],
  ),
  IranianBank(
    id: 'sanat_madan',
    nameFa: 'بانک صنعت و معدن',
    nameEn: 'Bank of Industry and Mine',
    colorHex: '#B45309',
    logoAsset: 'assets/banks/sanat_madan.svg',
    aliases: ['صنعت و معدن', 'صنعت‌ومعدن'],
  ),
  IranianBank(
    id: 'tosee_saderat',
    nameFa: 'بانک توسعه صادرات ایران',
    nameEn: 'Export Development Bank',
    colorHex: '#1E40AF',
    logoAsset: 'assets/banks/tosee_saderat.svg',
    aliases: ['توسعه صادرات'],
  ),

  // ------------------------------------------------------------ Commercial banks
  IranianBank(
    id: 'mellat',
    nameFa: 'بانک ملت',
    nameEn: 'Bank Mellat',
    colorHex: '#C8102E',
    logoAsset: 'assets/banks/mellat.svg',
    aliases: ['ملت'],
  ),
  IranianBank(
    id: 'saderat',
    nameFa: 'بانک صادرات ایران',
    nameEn: 'Bank Saderat',
    colorHex: '#1B4F9C',
    logoAsset: 'assets/banks/saderat.svg',
    aliases: ['صادرات'],
  ),
  IranianBank(
    id: 'tejarat',
    nameFa: 'بانک تجارت',
    nameEn: 'Bank Tejarat',
    colorHex: '#0F4C81',
    logoAsset: 'assets/banks/tejarat.svg',
    aliases: ['تجارت'],
  ),
  IranianBank(
    id: 'refah',
    nameFa: 'بانک رفاه کارگران',
    nameEn: 'Refah Bank',
    colorHex: '#007A3D',
    logoAsset: 'assets/banks/refah.svg',
    aliases: ['رفاه', 'رفاه کارگران'],
  ),
  IranianBank(
    id: 'parsian',
    nameFa: 'بانک پارسیان',
    nameEn: 'Parsian Bank',
    colorHex: '#6C2C90',
    logoAsset: 'assets/banks/parsian.svg',
    aliases: ['پارسیان'],
  ),
  IranianBank(
    id: 'pasargad',
    nameFa: 'بانک پاسارگاد',
    nameEn: 'Bank Pasargad',
    colorHex: '#C9A227',
    logoAsset: 'assets/banks/pasargad.svg',
    aliases: ['پاسارگاد'],
  ),
  IranianBank(
    id: 'saman',
    nameFa: 'بانک سامان',
    nameEn: 'Saman Bank',
    colorHex: '#00A0DF',
    logoAsset: 'assets/banks/saman.svg',
    aliases: ['سامان'],
  ),
  IranianBank(
    id: 'ayandeh',
    nameFa: 'بانک آینده',
    nameEn: 'Ayandeh Bank',
    colorHex: '#F58220',
    logoAsset: 'assets/banks/ayandeh.svg',
    aliases: ['آینده'],
  ),
  IranianBank(
    id: 'eghtesad_novin',
    nameFa: 'بانک اقتصاد نوین',
    nameEn: 'Eghtesad Novin',
    colorHex: '#1F6FB2',
    logoAsset: 'assets/banks/eghtesad_novin.svg',
    aliases: ['اقتصاد نوین'],
  ),
  IranianBank(
    id: 'shahr',
    nameFa: 'بانک شهر',
    nameEn: 'Bank Shahr',
    colorHex: '#D32F2F',
    logoAsset: 'assets/banks/shahr.svg',
    aliases: ['شهر'],
  ),
  IranianBank(
    id: 'sina',
    nameFa: 'بانک سینا',
    nameEn: 'Sina Bank',
    colorHex: '#0B5FA5',
    logoAsset: 'assets/banks/sina.svg',
    aliases: ['سینا'],
  ),
  IranianBank(
    id: 'dey',
    nameFa: 'بانک دی',
    nameEn: 'Bank Dey',
    colorHex: '#1A237E',
    logoAsset: 'assets/banks/dey.svg',
    aliases: ['دی'],
  ),
  IranianBank(
    id: 'resalat',
    nameFa: 'بانک قرض‌الحسنه رسالت',
    nameEn: 'Resalat Bank',
    colorHex: '#006B3F',
    logoAsset: 'assets/banks/resalat.svg',
    aliases: ['رسالت', 'قرض‌الحسنه رسالت'],
  ),
  IranianBank(
    id: 'gardeshgari',
    nameFa: 'بانک گردشگری',
    nameEn: 'Tourism Bank',
    colorHex: '#00A19A',
    logoAsset: 'assets/banks/gardeshgari.svg',
    aliases: ['گردشگری'],
  ),
  IranianBank(
    id: 'khavar_mianeh',
    nameFa: 'بانک خاورمیانه',
    nameEn: 'Middle East Bank',
    colorHex: '#1E3A8A',
    logoAsset: 'assets/banks/khavar_mianeh.svg',
    aliases: ['خاورمیانه', 'خاور میانه'],
  ),
  IranianBank(
    id: 'iran_zamin',
    nameFa: 'بانک ایران زمین',
    nameEn: 'Iran Zamin',
    colorHex: '#00695C',
    logoAsset: 'assets/banks/iran_zamin.svg',
    aliases: ['ایران زمین'],
  ),
  IranianBank(
    id: 'karafarin',
    nameFa: 'بانک کارآفرین',
    nameEn: 'Karafarin Bank',
    colorHex: '#E11D48',
    logoAsset: 'assets/banks/karafarin.svg',
    aliases: ['کارآفرین'],
  ),
  IranianBank(
    id: 'sarmayeh',
    nameFa: 'بانک سرمایه',
    nameEn: 'Sarmayeh Bank',
    colorHex: '#7C3AED',
    logoAsset: 'assets/banks/sarmayeh.svg',
    aliases: ['سرمایه'],
  ),
  IranianBank(
    id: 'mehr_iran',
    nameFa: 'بانک قرض‌الحسنه مهر ایران',
    nameEn: 'Qarz Al-Hasaneh Mehr Iran',
    colorHex: '#16A34A',
    logoAsset: 'assets/banks/mehr_iran.svg',
    aliases: ['مهر ایران', 'قرض‌الحسنه مهر ایران'],
  ),
  IranianBank(
    id: 'ansar',
    nameFa: 'بانک انصار',
    nameEn: 'Ansar Bank',
    colorHex: '#006B3F',
    logoAsset: 'assets/banks/ansar.svg',
    aliases: ['انصار'],
  ),
  IranianBank(
    id: 'ghavamin',
    nameFa: 'بانک قوامین',
    nameEn: 'Ghavamin Bank',
    colorHex: '#1D4ED8',
    logoAsset: 'assets/banks/ghavamin.svg',
    aliases: ['قوامین'],
  ),
  IranianBank(
    id: 'hekmat',
    nameFa: 'بانک حکمت ایرانیان',
    nameEn: 'Hekmat Bank',
    colorHex: '#7C3AED',
    logoAsset: 'assets/banks/hekmat.svg',
    aliases: ['حکمت', 'حکمت ایرانیان'],
  ),
  IranianBank(
    id: 'mehr_eghresad',
    nameFa: 'بانک مهر اقتصاد',
    nameEn: 'Mehr Eghtesad',
    colorHex: '#15803D',
    logoAsset: 'assets/banks/mehr_eghresad.svg',
    aliases: ['مهر اقتصاد'],
  ),
  IranianBank(
    id: 'iran_venezuela',
    nameFa: 'بانک مشترک ایران و ونزوئلا',
    nameEn: 'Iran-Venezuela Bank',
    colorHex: '#B91C1C',
    logoAsset: 'assets/banks/iran_venezuela.svg',
    aliases: ['ایران و ونزوئلا', 'ونزوئلا'],
  ),

  // -------------------------------------------------------- Credit institutions
  IranianBank(
    id: 'melall',
    nameFa: 'مؤسسه اعتباری ملل',
    nameEn: 'Melall Credit Institution',
    colorHex: '#4338CA',
    kind: BankKind.creditInstitution,
    logoAsset: 'assets/banks/melall.svg',
    aliases: ['ملل'],
  ),
  IranianBank(
    id: 'caspian',
    nameFa: 'مؤسسه اعتباری کاسپین',
    nameEn: 'Caspian Credit Institution',
    colorHex: '#0E7490',
    kind: BankKind.creditInstitution,
    logoAsset: 'assets/banks/caspian.svg',
    aliases: ['کاسپین'],
  ),
  IranianBank(
    id: 'noor',
    nameFa: 'مؤسسه اعتباری نور',
    nameEn: 'Noor Credit Institution',
    colorHex: '#0369A1',
    kind: BankKind.creditInstitution,
    logoAsset: 'assets/banks/noor.svg',
    aliases: ['نور'],
  ),
  IranianBank(
    id: 'kosar',
    nameFa: 'مؤسسه اعتباری کوثر',
    nameEn: 'Kosar Credit Institution',
    colorHex: '#0D9488',
    kind: BankKind.creditInstitution,
    logoAsset: 'assets/banks/kosar.svg',
    aliases: ['کوثر'],
  ),
  IranianBank(
    id: 'taavon_eslami',
    nameFa: 'بانک تعاون اسلامی',
    nameEn: 'Taavon Eslami',
    colorHex: '#0F766E',
    kind: BankKind.creditInstitution,
    logoAsset: 'assets/banks/taavon_eslami.svg',
    aliases: ['تعاون اسلامی'],
  ),

  // ----------------------------------------------------------- Foreign banks
  IranianBank(
    id: 'iran_europe',
    nameFa: 'بانک ایران اروپا',
    nameEn: 'Iran Europe Bank',
    colorHex: '#1E3A8A',
    kind: BankKind.international,
    logoAsset: 'assets/banks/iran_europe.svg',
    aliases: ['ایران اروپا'],
  ),
  IranianBank(
    id: 'futurebank',
    nameFa: 'بانک فیوچر (بحرین)',
    nameEn: 'Futurebank',
    colorHex: '#0C4A6E',
    kind: BankKind.international,
    logoAsset: 'assets/banks/futurebank.svg',
    aliases: ['فیوچر', 'فیوچربانک'],
  ),

  // ------------------------------------------------------------- Central bank
  IranianBank(
    id: 'markazi',
    nameFa: 'بانک مرکزی ایران',
    nameEn: 'Central Bank of Iran',
    colorHex: '#1A237E',
    kind: BankKind.centralBank,
    logoAsset: 'assets/banks/markazi.svg',
    aliases: ['مرکزی', 'بانک مرکزی'],
  ),

  // ---------------------------------------------------------------- Neobanks
  IranianBank(
    id: 'blue',
    nameFa: 'بلوبانک',
    nameEn: 'BluBank',
    colorHex: '#0057FF',
    kind: BankKind.digitalBank,
    parentBank: 'بانک سامان',
    logoAsset: 'assets/banks/blue.svg',
    logoIsWordmark: true,
    aliases: ['بلو', 'blue', 'blubank', 'blu bank', 'بلو بانک'],
  ),
  IranianBank(
    id: 'bankino',
    nameFa: 'بانکینو',
    nameEn: 'Bankino',
    colorHex: '#F58220',
    logoAsset: 'assets/banks/bankino.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک خاورمیانه',
    aliases: ['بانکی نو', 'bankino'],
  ),
  IranianBank(
    id: 'vipad',
    nameFa: 'ویپاد',
    nameEn: 'Vipad',
    colorHex: '#C9A227',
    logoAsset: 'assets/banks/vipad.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک پاسارگاد',
    aliases: ['وی پاد', 'vipad'],
  ),
  IranianBank(
    id: 'dima',
    nameFa: 'دیما',
    nameEn: 'Dima',
    colorHex: '#2563EB',
    logoAsset: 'assets/banks/mellat.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک ملت',
    aliases: ['dima'],
  ),
  IranianBank(
    id: 'qbank',
    nameFa: 'کیوبانک',
    nameEn: 'QBank',
    colorHex: '#0D9488',
    logoAsset: 'assets/banks/qbank.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک قرض‌الحسنه مهر ایران',
    aliases: ['کیو بانک', 'qbank', 'q bank'],
  ),
  IranianBank(
    id: 'banket',
    nameFa: 'بانکت',
    nameEn: 'Banket',
    colorHex: '#7C3AED',
    logoAsset: 'assets/banks/banket.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک قرض‌الحسنه مهر ایران',
    aliases: ['banket'],
  ),
  IranianBank(
    id: 'tobank',
    nameFa: 'توبانک',
    nameEn: 'ToBank',
    colorHex: '#0EA5E9',
    logoAsset: 'assets/banks/gardeshgari.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک گردشگری',
    aliases: ['to bank', 'tobank'],
  ),
  IranianBank(
    id: 'hibank',
    nameFa: 'هایبانک',
    nameEn: 'HiBank',
    colorHex: '#059669',
    logoAsset: 'assets/banks/hibank.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک کارآفرین',
    aliases: ['های بانک', 'hibank'],
  ),
  IranianBank(
    id: 'baran',
    nameFa: 'باران',
    nameEn: 'Baran',
    colorHex: '#16A34A',
    logoAsset: 'assets/banks/baran.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک کشاورزی',
    aliases: ['baran'],
  ),
  IranianBank(
    id: 'omid',
    nameFa: 'امیدبانک',
    nameEn: 'OmidBank',
    colorHex: '#0E7490',
    logoAsset: 'assets/banks/omid.png',
    logoIsWordmark: true,
    kind: BankKind.digitalBank,
    parentBank: 'بانک سپه',
    aliases: ['امید', 'omid'],
  ),
  IranianBank(
    id: 'bam',
    nameFa: 'بام',
    nameEn: 'Bam',
    colorHex: '#0F766E',
    logoAsset: 'assets/banks/bam.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک ملی ایران',
    aliases: ['bam'],
  ),
  IranianBank(
    id: 'bajet',
    nameFa: 'باجت',
    nameEn: 'Bajet',
    colorHex: '#DB2777',
    logoAsset: 'assets/banks/bajet.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک تجارت',
    aliases: ['bajet'],
  ),
  IranianBank(
    id: 'sepino',
    nameFa: 'سپینو',
    nameEn: 'Sepino',
    colorHex: '#1D4ED8',
    logoAsset: 'assets/banks/sepino.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک صادرات ایران',
    aliases: ['sepino'],
  ),
  IranianBank(
    id: 'greenbank',
    nameFa: 'گرین بانک',
    nameEn: 'GreenBank',
    colorHex: '#15803D',
    logoAsset: 'assets/banks/greenbank.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک سینا',
    aliases: ['گرین', 'green', 'greenbank'],
  ),
  IranianBank(
    id: 'metabank',
    nameFa: 'متابانک',
    nameEn: 'MetaBank',
    colorHex: '#7C3AED',
    logoAsset: 'assets/banks/metabank.png',
    kind: BankKind.digitalBank,
    parentBank: 'مؤسسه اعتباری ملل',
    aliases: ['متا', 'meta', 'metabank'],
  ),
  IranianBank(
    id: 'bankvareh',
    nameFa: 'بانکواره',
    nameEn: 'Bankvareh',
    colorHex: '#0D9488',
    logoAsset: 'assets/banks/tosee_taavon.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک توسعه تعاون',
    aliases: ['bankvareh'],
  ),
  IranianBank(
    id: 'fararefah',
    nameFa: 'فرارفاه',
    nameEn: 'Fararefah',
    colorHex: '#0891B2',
    logoAsset: 'assets/banks/refah.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک رفاه کارگران',
    aliases: ['fararefah'],
  ),
  IranianBank(
    id: 'farazbank',
    nameFa: 'فراز بانک',
    nameEn: 'FarazBank',
    colorHex: '#4F46E5',
    logoAsset: 'assets/banks/iran_zamin.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک ایران زمین',
    aliases: ['فراز', 'farazbank'],
  ),
  IranianBank(
    id: 'redbank',
    nameFa: 'ردبانک',
    nameEn: 'RedBank',
    colorHex: '#DC2626',
    logoAsset: 'assets/banks/redbank.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک شهر',
    aliases: ['رد', 'red', 'redbank'],
  ),
  IranianBank(
    id: 'parsianman',
    nameFa: 'پارسیان من',
    nameEn: 'Parsian Man',
    colorHex: '#9333EA',
    logoAsset: 'assets/banks/parsian.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک پارسیان',
    aliases: ['پارسیانمن', 'parsian man', 'parsianman'],
  ),
  IranianBank(
    id: 'teambank',
    nameFa: 'تیم بانک',
    nameEn: 'TeamBank',
    colorHex: '#EA580C',
    logoAsset: 'assets/banks/sanat_madan.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک صنعت و معدن',
    aliases: ['تیم', 'team', 'teambank'],
  ),
  IranianBank(
    id: 'sarmayeh_digital',
    nameFa: 'سرمایه دیجیتال',
    nameEn: 'Sarmayeh Digital',
    colorHex: '#B45309',
    logoAsset: 'assets/banks/sarmayeh.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک سرمایه',
    aliases: ['sarmayeh digital'],
  ),
  IranianBank(
    id: 'jahesh',
    nameFa: 'جهش بانک',
    nameEn: 'Jahesh Bank',
    colorHex: '#059669',
    logoAsset: 'assets/banks/iran_zamin.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک ایران زمین',
    aliases: ['جهش', 'jahesh'],
  ),
  IranianBank(
    id: 'abank',
    nameFa: 'آبانک',
    nameEn: 'ABank',
    colorHex: '#1E40AF',
    logoAsset: 'assets/banks/melli.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک ملی ایران',
    aliases: ['ای بانک', 'abank'],
  ),
  IranianBank(
    id: 'neon',
    nameFa: 'نئون',
    nameEn: 'Neon',
    colorHex: '#22D3EE',
    logoAsset: 'assets/banks/eghtesad_novin.svg',
    kind: BankKind.digitalBank,
    parentBank: 'بانک اقتصاد نوین',
    aliases: ['neon'],
  ),
  IranianBank(
    id: 'forbix',
    nameFa: 'فوربیکس',
    nameEn: 'ForBix',
    colorHex: '#84CC16',
    logoAsset: 'assets/banks/forbix.png',
    kind: BankKind.digitalBank,
    parentBank: 'بانک اقتصاد نوین',
    aliases: ['فور بیکس', 'forbix'],
  ),

  // --------------------------------------------------------------------- Other
  IranianBank(
    id: 'other',
    nameFa: 'سایر بانک‌ها',
    nameEn: 'Other',
    colorHex: '#64748B',
    kind: BankKind.other,
    aliases: ['سایر', 'other', 'بانک دیگر'],
  ),
];

/// Groups shown in the bank picker, in order.
const List<BankKind> bankPickerGroups = <BankKind>[
  BankKind.bank,
  BankKind.digitalBank,
  BankKind.creditInstitution,
  BankKind.international,
  BankKind.centralBank,
  BankKind.other,
];

/// Looks up a bank by id, with a safe fallback.
IranianBank bankById(String id) => iranianBanks.firstWhere(
  (bank) => bank.id == id,
  orElse: () => iranianBanks.last,
);

/// Fuzzy matching for Persian/English bank and neobank names coming from the
/// user, the AI or a saved account.
///
/// Exact matches on the Persian name, English name, parent bank or aliases win
/// over substring matches. Two-character names are only matched exactly to
/// avoid false positives (e.g. «دی»).
IranianBank? bankByName(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  final query = normalizeBankName(name);
  if (query.isEmpty) return null;

  for (final bank in iranianBanks) {
    for (final candidate in _candidates(bank)) {
      if (normalizeBankName(candidate) == query) return bank;
    }
  }
  if (query.length < 3) return null;
  for (final bank in iranianBanks) {
    for (final candidate in _candidates(bank)) {
      final normalized = normalizeBankName(candidate);
      // Short fragments (e.g. «ت» from «بانکت») create false positives such
      // as matching an unknown sentence that happens to contain that letter.
      if (normalized.length < 3) continue;
      if (normalized.contains(query) || query.contains(normalized)) return bank;
    }
  }
  return null;
}

Iterable<String> _candidates(IranianBank bank) sync* {
  yield bank.nameFa;
  yield bank.nameEn;
  if (bank.parentBank != null) yield bank.parentBank!;
  yield* bank.aliases;
}

/// Banks and neobanks grouped for the picker, filtered by [query].
Map<BankKind, List<IranianBank>> groupedBanks([String query = '']) {
  final filtered = iranianBanks.where((bank) => bank.matches(query)).toList()
    ..sort((a, b) => a.nameFa.compareTo(b.nameFa));
  final groups = <BankKind, List<IranianBank>>{};
  for (final bank in filtered) {
    groups.putIfAbsent(bank.kind, () => <IranianBank>[]).add(bank);
  }
  return groups;
}
