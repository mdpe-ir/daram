/// Units in which money can be displayed. Stored values are always Rial.
enum CurrencyUnit {
  rial('ریال', 1),
  toman('تومان', 10);

  const CurrencyUnit(this.label, this.rialFactor);

  /// Persian label shown next to amounts.
  final String label;

  /// How many Rial one display unit is worth.
  final int rialFactor;

  /// Parses a tool/base-model value such as `toman`, `toman`, `rial`.
  static CurrencyUnit? tryParse(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'rial' || 'ریال' || 'irr' => CurrencyUnit.rial,
      'toman' || 'تومان' || 'تومن' || 'irt' => CurrencyUnit.toman,
      _ => null,
    };
  }
}
