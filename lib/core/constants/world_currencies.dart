import '../formatting/persian_formatting.dart';

/// Catalog of fiat currencies the asset editor offers for picker-based entry.
///
/// Every ISO code a user is likely to hold is listed; DARAM's own market
/// sources (Bonbast/Chand) quote the 28 most traded ones automatically and the
/// editor falls back to a manual rate for the rest. Popular holdings come
/// first; the rest are grouped by region so the long list stays scannable and
/// predictable.
class WorldCurrency {
  const WorldCurrency({
    required this.code,
    required this.nameFa,
    required this.countryFa,
    required this.countryCode,
    this.popular = false,
  });

  /// ISO 4217 code, uppercase, as stored on the holding.
  final String code;

  /// Persian display name, also used to prefill the asset name.
  final String nameFa;

  /// Persian country/region name, shown in the picker and searchable.
  final String countryFa;

  /// ISO 3166-1 alpha-2 code of the country whose flag represents this
  /// currency. Empty only for codes typed outside the catalog.
  final String countryCode;

  /// Highlighted as a commonly held currency in the picker.
  final bool popular;

  /// Bundled circular flag, or `null` for currencies without a country.
  String? get flagAsset =>
      countryCode.isEmpty ? null : 'assets/flags/$countryCode.svg';

  /// True when [query] matches the code, Persian name or country.
  bool matches(String query) {
    final normalized = normalizeSearchText(query);
    if (normalized.isEmpty) return true;
    return normalizeSearchText(code).contains(normalized) ||
        normalizeSearchText(nameFa).contains(normalized) ||
        normalizeSearchText(countryFa).contains(normalized);
  }
}

const List<WorldCurrency> worldCurrencies = [
  // Most-held currencies in Iran.
  WorldCurrency(
    code: 'USD',
    nameFa: 'دلار آمریکا',
    countryFa: 'آمریکا',
    countryCode: 'us',
    popular: true,
  ),
  WorldCurrency(
    code: 'EUR',
    nameFa: 'یورو',
    countryFa: 'اتحادیه اروپا',
    countryCode: 'eu',
    popular: true,
  ),
  WorldCurrency(
    code: 'AED',
    nameFa: 'درهم امارات',
    countryFa: 'امارات متحده عربی',
    countryCode: 'ae',
    popular: true,
  ),
  WorldCurrency(
    code: 'TRY',
    nameFa: 'لیر ترکیه',
    countryFa: 'ترکیه',
    countryCode: 'tr',
    popular: true,
  ),
  WorldCurrency(
    code: 'GBP',
    nameFa: 'پوند انگلیس',
    countryFa: 'انگلیس',
    countryCode: 'gb',
    popular: true,
  ),
  WorldCurrency(
    code: 'CNY',
    nameFa: 'یوان چین',
    countryFa: 'چین',
    countryCode: 'cn',
    popular: true,
  ),
  WorldCurrency(
    code: 'CAD',
    nameFa: 'دلار کانادا',
    countryFa: 'کانادا',
    countryCode: 'ca',
    popular: true,
  ),
  WorldCurrency(
    code: 'AUD',
    nameFa: 'دلار استرالیا',
    countryFa: 'استرالیا',
    countryCode: 'au',
    popular: true,
  ),
  WorldCurrency(
    code: 'CHF',
    nameFa: 'فرانک سوئیس',
    countryFa: 'سوئیس',
    countryCode: 'ch',
    popular: true,
  ),
  WorldCurrency(
    code: 'RUB',
    nameFa: 'روبل روسیه',
    countryFa: 'روسیه',
    countryCode: 'ru',
    popular: true,
  ),
  WorldCurrency(
    code: 'IQD',
    nameFa: 'دینار عراق',
    countryFa: 'عراق',
    countryCode: 'iq',
    popular: true,
  ),
  WorldCurrency(
    code: 'SAR',
    nameFa: 'ریال عربستان',
    countryFa: 'عربستان',
    countryCode: 'sa',
    popular: true,
  ),
  // Neighbours and West Asia.
  WorldCurrency(
    code: 'QAR',
    nameFa: 'ریال قطر',
    countryFa: 'قطر',
    countryCode: 'qa',
  ),
  WorldCurrency(
    code: 'KWD',
    nameFa: 'دینار کویت',
    countryFa: 'کویت',
    countryCode: 'kw',
  ),
  WorldCurrency(
    code: 'BHD',
    nameFa: 'دینار بحرین',
    countryFa: 'بحرین',
    countryCode: 'bh',
  ),
  WorldCurrency(
    code: 'OMR',
    nameFa: 'ریال عمان',
    countryFa: 'عمان',
    countryCode: 'om',
  ),
  WorldCurrency(
    code: 'JOD',
    nameFa: 'دینار اردن',
    countryFa: 'اردن',
    countryCode: 'jo',
  ),
  WorldCurrency(
    code: 'EGP',
    nameFa: 'پوند مصر',
    countryFa: 'مصر',
    countryCode: 'eg',
  ),
  WorldCurrency(
    code: 'SYP',
    nameFa: 'پوند سوریه',
    countryFa: 'سوریه',
    countryCode: 'sy',
  ),
  WorldCurrency(
    code: 'LBP',
    nameFa: 'پوند لبنان',
    countryFa: 'لبنان',
    countryCode: 'lb',
  ),
  WorldCurrency(
    code: 'YER',
    nameFa: 'ریال یمن',
    countryFa: 'یمن',
    countryCode: 'ye',
  ),
  WorldCurrency(
    code: 'AFN',
    nameFa: 'افغانی',
    countryFa: 'افغانستان',
    countryCode: 'af',
  ),
  WorldCurrency(
    code: 'PKR',
    nameFa: 'روپیه پاکستان',
    countryFa: 'پاکستان',
    countryCode: 'pk',
  ),
  WorldCurrency(
    code: 'INR',
    nameFa: 'روپیه هند',
    countryFa: 'هند',
    countryCode: 'in',
  ),
  WorldCurrency(
    code: 'AZN',
    nameFa: 'منات آذربایجان',
    countryFa: 'آذربایجان',
    countryCode: 'az',
  ),
  WorldCurrency(
    code: 'AMD',
    nameFa: 'درام ارمنستان',
    countryFa: 'ارمنستان',
    countryCode: 'am',
  ),
  WorldCurrency(
    code: 'GEL',
    nameFa: 'لاری گرجستان',
    countryFa: 'گرجستان',
    countryCode: 'ge',
  ),
  WorldCurrency(
    code: 'KZT',
    nameFa: 'تنگه قزاقستان',
    countryFa: 'قزاقستان',
    countryCode: 'kz',
  ),
  WorldCurrency(
    code: 'UZS',
    nameFa: 'سوم ازبکستان',
    countryFa: 'ازبکستان',
    countryCode: 'uz',
  ),
  WorldCurrency(
    code: 'TJS',
    nameFa: 'سامانی تاجیکستان',
    countryFa: 'تاجیکستان',
    countryCode: 'tj',
  ),
  WorldCurrency(
    code: 'TMT',
    nameFa: 'منات ترکمنستان',
    countryFa: 'ترکمنستان',
    countryCode: 'tm',
  ),
  // East and Southeast Asia.
  WorldCurrency(
    code: 'MYR',
    nameFa: 'رینگیت مالزی',
    countryFa: 'مالزی',
    countryCode: 'my',
  ),
  WorldCurrency(
    code: 'SGD',
    nameFa: 'دلار سنگاپور',
    countryFa: 'سنگاپور',
    countryCode: 'sg',
  ),
  WorldCurrency(
    code: 'HKD',
    nameFa: 'دلار هنگ‌کنگ',
    countryFa: 'هنگ‌کنگ',
    countryCode: 'hk',
  ),
  WorldCurrency(
    code: 'TWD',
    nameFa: 'دلار تایوان',
    countryFa: 'تایوان',
    countryCode: 'tw',
  ),
  WorldCurrency(
    code: 'KRW',
    nameFa: 'وون کره جنوبی',
    countryFa: 'کره جنوبی',
    countryCode: 'kr',
  ),
  WorldCurrency(
    code: 'THB',
    nameFa: 'بات تایلند',
    countryFa: 'تایلند',
    countryCode: 'th',
  ),
  WorldCurrency(
    code: 'IDR',
    nameFa: 'روپیه اندونزی',
    countryFa: 'اندونزی',
    countryCode: 'id',
  ),
  WorldCurrency(
    code: 'PHP',
    nameFa: 'پزو فیلیپین',
    countryFa: 'فیلیپین',
    countryCode: 'ph',
  ),
  WorldCurrency(
    code: 'VND',
    nameFa: 'دانگ ویتنام',
    countryFa: 'ویتنام',
    countryCode: 'vn',
  ),
  WorldCurrency(
    code: 'NZD',
    nameFa: 'دلار نیوزیلند',
    countryFa: 'نیوزیلند',
    countryCode: 'nz',
  ),
  // Europe.
  WorldCurrency(
    code: 'SEK',
    nameFa: 'کرون سوئد',
    countryFa: 'سوئد',
    countryCode: 'se',
  ),
  WorldCurrency(
    code: 'NOK',
    nameFa: 'کرون نروژ',
    countryFa: 'نروژ',
    countryCode: 'no',
  ),
  WorldCurrency(
    code: 'DKK',
    nameFa: 'کرون دانمارک',
    countryFa: 'دانمارک',
    countryCode: 'dk',
  ),
  WorldCurrency(
    code: 'ISK',
    nameFa: 'کرون ایسلند',
    countryFa: 'ایسلند',
    countryCode: 'is',
  ),
  WorldCurrency(
    code: 'PLN',
    nameFa: 'زلوتی لهستان',
    countryFa: 'لهستان',
    countryCode: 'pl',
  ),
  WorldCurrency(
    code: 'CZK',
    nameFa: 'کرون چک',
    countryFa: 'جمهوری چک',
    countryCode: 'cz',
  ),
  WorldCurrency(
    code: 'HUF',
    nameFa: 'فورینت مجارستان',
    countryFa: 'مجارستان',
    countryCode: 'hu',
  ),
  WorldCurrency(
    code: 'RON',
    nameFa: 'لئوی رومانی',
    countryFa: 'رومانی',
    countryCode: 'ro',
  ),
  WorldCurrency(
    code: 'BGN',
    nameFa: 'لو بلغارستان',
    countryFa: 'بلغارستان',
    countryCode: 'bg',
  ),
  WorldCurrency(
    code: 'UAH',
    nameFa: 'هریونیا اوکراین',
    countryFa: 'اوکراین',
    countryCode: 'ua',
  ),
  WorldCurrency(
    code: 'BYN',
    nameFa: 'روبل بلاروس',
    countryFa: 'بلاروس',
    countryCode: 'by',
  ),
  // Americas and Africa.
  WorldCurrency(
    code: 'BRL',
    nameFa: 'رئال برزیل',
    countryFa: 'برزیل',
    countryCode: 'br',
  ),
  WorldCurrency(
    code: 'MXN',
    nameFa: 'پزو مکزیک',
    countryFa: 'مکزیک',
    countryCode: 'mx',
  ),
  WorldCurrency(
    code: 'ARS',
    nameFa: 'پزو آرژانتین',
    countryFa: 'آرژانتین',
    countryCode: 'ar',
  ),
  WorldCurrency(
    code: 'CLP',
    nameFa: 'پزو شیلی',
    countryFa: 'شیلی',
    countryCode: 'cl',
  ),
  WorldCurrency(
    code: 'COP',
    nameFa: 'پزو کلمبیا',
    countryFa: 'کلمبیا',
    countryCode: 'co',
  ),
  WorldCurrency(
    code: 'PEN',
    nameFa: 'سول پرو',
    countryFa: 'پرو',
    countryCode: 'pe',
  ),
  WorldCurrency(
    code: 'ZAR',
    nameFa: 'رند آفریقای جنوبی',
    countryFa: 'آفریقای جنوبی',
    countryCode: 'za',
  ),
  WorldCurrency(
    code: 'KES',
    nameFa: 'شیلینگ کنیا',
    countryFa: 'کنیا',
    countryCode: 'ke',
  ),
  WorldCurrency(
    code: 'NGN',
    nameFa: 'نایرا نیجریه',
    countryFa: 'نیجریه',
    countryCode: 'ng',
  ),
  WorldCurrency(
    code: 'GHS',
    nameFa: 'سدی غنا',
    countryFa: 'غنا',
    countryCode: 'gh',
  ),
  WorldCurrency(
    code: 'MAD',
    nameFa: 'درهم مراکش',
    countryFa: 'مراکش',
    countryCode: 'ma',
  ),
  WorldCurrency(
    code: 'DZD',
    nameFa: 'دینار الجزایر',
    countryFa: 'الجزایر',
    countryCode: 'dz',
  ),
  WorldCurrency(
    code: 'TND',
    nameFa: 'دینار تونس',
    countryFa: 'تونس',
    countryCode: 'tn',
  ),
  WorldCurrency(
    code: 'LYD',
    nameFa: 'دینار لیبی',
    countryFa: 'لیبی',
    countryCode: 'ly',
  ),
];

final Map<String, WorldCurrency> _byCode = {
  for (final currency in worldCurrencies) currency.code: currency,
};

/// Looks up a currency by its ISO code, case-insensitively. Returns `null` for
/// codes outside the catalog (holdings saved before the picker existed).
WorldCurrency? currencyByCode(String? code) {
  final key = code?.trim().toUpperCase();
  if (key == null || key.isEmpty) return null;
  return _byCode[key];
}

/// Returns a currency for display, falling back to a bare entry for codes the
/// catalog does not know so stored holdings never render as "not selected".
WorldCurrency currencyOrCode(String code) {
  final normalized = code.trim().toUpperCase();
  return currencyByCode(normalized) ??
      WorldCurrency(
        code: normalized,
        nameFa: normalized,
        countryFa: '',
        countryCode: '',
      );
}

/// Currencies matching [query], in catalog order.
List<WorldCurrency> searchCurrencies([String query = '']) =>
    worldCurrencies.where((currency) => currency.matches(query)).toList();
