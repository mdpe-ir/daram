import 'package:meta/meta.dart';

import '../../../core/money/rial.dart';
import 'asset_quantity.dart';

/// A user-held asset (gold, silver, foreign currency or crypto) with an
/// optional valuation rate.
///
/// The quantity is exact (six decimals of a gram/unit); the rate is the price
/// of one gram/unit in Rial. The estimated value is always computed locally.
@immutable
final class AssetHolding {
  const AssetHolding({
    required this.id,
    required this.name,
    required this.kind,
    required this.quantity,
    required this.createdAt,
    this.currencyCode,
    this.rateRial,
    this.rateDate,
    this.isMarketRate = false,
  });

  final String id;
  final String name;
  final AssetKind kind;

  /// ISO currency code or crypto ticker; `null` for bullion.
  final String? currencyCode;
  final AssetQuantity quantity;

  /// Price of one gram/unit in Rial, when the holding is valued.
  final Rial? rateRial;

  /// When the rate was captured (market quote time or manual entry date).
  final DateTime? rateDate;

  /// True when the rate came from a live market source.
  final bool isMarketRate;
  final DateTime createdAt;

  /// Rial value of the holding, or `null` when no rate is set.
  Rial? get estimatedValue {
    final rate = rateRial;
    return rate == null ? null : quantity.valueAt(rate);
  }

  bool get hasRate => rateRial != null;

  /// Unit label used in Persian copy: gram for bullion, code otherwise.
  String get unitLabel => currencyCode ?? 'گرم';

  AssetHolding copyWith({
    String? name,
    AssetKind? kind,
    String? currencyCode,
    AssetQuantity? quantity,
    Rial? rateRial,
    DateTime? rateDate,
    bool? isMarketRate,
    bool clearRate = false,
    bool clearCode = false,
  }) => AssetHolding(
    id: id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    currencyCode: clearCode ? null : (currencyCode ?? this.currencyCode),
    quantity: quantity ?? this.quantity,
    rateRial: clearRate ? null : (rateRial ?? this.rateRial),
    rateDate: clearRate ? null : (rateDate ?? this.rateDate),
    isMarketRate: clearRate ? false : (isMarketRate ?? this.isMarketRate),
    createdAt: createdAt,
  );
}
