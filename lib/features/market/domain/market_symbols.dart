/// Canonical symbol catalogs of the market price subsystem.
///
/// Every provider filters its payload down to these symbols, so a snapshot can
/// only contain quotes the rest of the app understands. Changing a catalog
/// changes the public price coverage of DARAM, not just a parser.
library;

/// ISO 4217 codes of the fiat currencies published by both Bonbast and Chand.
///
/// Order is the display order used for fiat quotes and for user-facing
/// "supported symbols" messages.
const List<String> fiatSymbols = <String>[
  'USD',
  'EUR',
  'GBP',
  'CHF',
  'CAD',
  'AUD',
  'SEK',
  'NOK',
  'RUB',
  'THB',
  'SGD',
  'HKD',
  'AZN',
  'AMD',
  'TRY',
  'DKK',
  'AED',
  'JPY',
  'CNY',
  'SAR',
  'INR',
  'MYR',
  'AFN',
  'KWD',
  'IQD',
  'BHD',
  'OMR',
  'QAR',
];

/// Crypto tickers published by Nobitex and Tetherland (and, for all but the
/// newest entries, by Chand). Order is the display order for crypto quotes.
const List<String> cryptoSymbols = <String>[
  'BTC',
  'ETH',
  'BNB',
  'USDT',
  'XRP',
  'LTC',
  'DOGE',
  'TON',
  'TRX',
  'SOL',
];

/// Canonical symbols of minted gold coins.
///
/// Bonbast and Chand publish the same five coins under different labels, so
/// both providers map their feed onto this list.
const List<String> goldCoinSymbols = <String>[
  'AZADI',
  'EMAMI',
  'AZADI_HALF',
  'AZADI_QUARTER',
  'GERAMI',
];

/// Symbol of one gram of 18-karat gold, the unit DARAM values gold holdings in.
const String goldGramSymbol = 'GOL18';

/// Symbol of one mithqal (4.6083 g) of gold, published by Bonbast and Chand.
const String mithqalSymbol = 'MITHQAL';

/// Symbol of one gram of fine silver, derived by the Bonbast provider.
const String silverSymbol = 'XAG';
