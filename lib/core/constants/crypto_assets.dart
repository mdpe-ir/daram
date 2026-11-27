import '../formatting/persian_formatting.dart';

/// A cryptocurrency the asset editor can hold.
///
/// Only coins with a bundled icon are listed; anything else can still be typed
/// through the picker's custom-symbol fallback, without an icon.
class CryptoAsset {
  const CryptoAsset({
    required this.symbol,
    required this.nameFa,
    required this.nameEn,
    this.popular = false,
    this.hasQuote = false,
  });

  /// Ticker symbol, uppercase, stored as the holding's code (e.g. BTC).
  final String symbol;

  /// Persian display name, also used to prefill the asset name.
  final String nameFa;

  /// English name, accepted by the picker search.
  final String nameEn;

  /// Highlighted as a commonly held coin in the picker.
  final bool popular;

  /// True when DARAM's market sources publish a quote for this symbol, so
  /// «دریافت نرخ» is offered. Quotes come from Nobitex/Tetherland (and Chand
  /// for most coins).
  final bool hasQuote;

  /// Bundled circular icon, or `null` for symbols outside the catalog.
  String? get iconAsset => cryptoBySymbol(symbol) == null
      ? null
      : 'assets/crypto/${symbol.toLowerCase()}.svg';

  /// True when [query] matches the symbol, Persian or English name.
  bool matches(String query) {
    final normalized = normalizeSearchText(query);
    if (normalized.isEmpty) return true;
    return normalizeSearchText(symbol).contains(normalized) ||
        normalizeSearchText(nameFa).contains(normalized) ||
        normalizeSearchText(nameEn).contains(normalized);
  }
}

const List<CryptoAsset> cryptoAssets = [
  CryptoAsset(
    symbol: 'BTC',
    nameFa: 'بیت‌کوین',
    nameEn: 'Bitcoin',
    popular: true,
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'ETH',
    nameFa: 'اتریوم',
    nameEn: 'Ethereum',
    popular: true,
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'USDT',
    nameFa: 'تتر',
    nameEn: 'Tether',
    popular: true,
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'BNB',
    nameFa: 'بایننس کوین',
    nameEn: 'BNB',
    popular: true,
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'SOL',
    nameFa: 'سولانا',
    nameEn: 'Solana',
    popular: true,
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'XRP',
    nameFa: 'ریپل',
    nameEn: 'XRP',
    popular: true,
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'ADA',
    nameFa: 'کاردانو',
    nameEn: 'Cardano',
    popular: true,
  ),
  CryptoAsset(
    symbol: 'DOGE',
    nameFa: 'دوج‌کوین',
    nameEn: 'Dogecoin',
    popular: true,
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'TRX',
    nameFa: 'ترون',
    nameEn: 'TRON',
    popular: true,
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'TON',
    nameFa: 'تون‌کوین',
    nameEn: 'Toncoin',
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'LINK',
    nameFa: 'چین‌لینک',
    nameEn: 'Chainlink',
    popular: true,
  ),
  CryptoAsset(
    symbol: 'AVAX',
    nameFa: 'آوالانچ',
    nameEn: 'Avalanche',
    popular: true,
  ),
  CryptoAsset(
    symbol: 'DOT',
    nameFa: 'پولکادات',
    nameEn: 'Polkadot',
    popular: true,
  ),
  CryptoAsset(
    symbol: 'LTC',
    nameFa: 'لایت‌کوین',
    nameEn: 'Litecoin',
    hasQuote: true,
  ),
  CryptoAsset(
    symbol: 'BCH',
    nameFa: 'بیت‌کوین کش',
    nameEn: 'Bitcoin Cash',
    hasQuote: true,
  ),
  CryptoAsset(symbol: 'XMR', nameFa: 'مونرو', nameEn: 'Monero'),
  CryptoAsset(symbol: 'ATOM', nameFa: 'کوزموس', nameEn: 'Cosmos'),
  CryptoAsset(symbol: 'UNI', nameFa: 'یونی‌سواپ', nameEn: 'Uniswap'),
  CryptoAsset(symbol: 'MATIC', nameFa: 'پالیگان', nameEn: 'Polygon'),
  CryptoAsset(symbol: 'XLM', nameFa: 'استلار', nameEn: 'Stellar'),
  CryptoAsset(symbol: 'FIL', nameFa: 'فایل‌کوین', nameEn: 'Filecoin'),
  CryptoAsset(
    symbol: 'ETC',
    nameFa: 'اتریوم کلاسیک',
    nameEn: 'Ethereum Classic',
  ),
  CryptoAsset(symbol: 'XTZ', nameFa: 'تزوس', nameEn: 'Tezos'),
  CryptoAsset(symbol: 'AAVE', nameFa: 'آوی', nameEn: 'Aave'),
  CryptoAsset(symbol: 'SAND', nameFa: 'سندباکس', nameEn: 'The Sandbox'),
  CryptoAsset(symbol: 'MANA', nameFa: 'دیسنترالند', nameEn: 'Decentraland'),
  CryptoAsset(symbol: 'CHZ', nameFa: 'چیلزی', nameEn: 'Chiliz'),
  CryptoAsset(symbol: 'QNT', nameFa: 'کوانت', nameEn: 'Quant'),
  CryptoAsset(symbol: 'GRT', nameFa: 'د گراف', nameEn: 'The Graph'),
  CryptoAsset(symbol: 'EOS', nameFa: 'ای‌اس', nameEn: 'EOS'),
  CryptoAsset(symbol: 'ALGO', nameFa: 'الگوراند', nameEn: 'Algorand'),
  CryptoAsset(symbol: 'VET', nameFa: 'وی‌چین', nameEn: 'VeChain'),
  CryptoAsset(symbol: 'ZEC', nameFa: 'زیکش', nameEn: 'Zcash'),
  CryptoAsset(symbol: 'DASH', nameFa: 'دش', nameEn: 'Dash'),
  CryptoAsset(symbol: 'NEO', nameFa: 'نئو', nameEn: 'NEO'),
];

final Map<String, CryptoAsset> _bySymbol = {
  for (final coin in cryptoAssets) coin.symbol: coin,
};

/// Looks up a coin by its ticker symbol, case-insensitively.
CryptoAsset? cryptoBySymbol(String? symbol) {
  final key = symbol?.trim().toUpperCase();
  if (key == null || key.isEmpty) return null;
  return _bySymbol[key];
}

/// Returns a coin for display, falling back to a bare entry for symbols typed
/// outside the catalog so stored holdings never render as "not selected".
CryptoAsset cryptoOrSymbol(String symbol) {
  final normalized = symbol.trim().toUpperCase();
  return cryptoBySymbol(normalized) ??
      CryptoAsset(symbol: normalized, nameFa: normalized, nameEn: '');
}

/// Coins matching [query], in catalog order.
List<CryptoAsset> searchCryptoAssets([String query = '']) =>
    cryptoAssets.where((coin) => coin.matches(query)).toList();
