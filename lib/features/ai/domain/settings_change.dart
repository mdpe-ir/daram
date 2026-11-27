import 'package:flutter/material.dart';

import '../../../core/money/currency.dart';

/// A non-financial preference change requested through chat.
///
/// Settings are not money records, so they apply immediately instead of going
/// through the draft/confirmation flow. The controller applies the change and
/// the executor only reports it.
@immutable
final class SettingsChange {
  const SettingsChange({this.themeMode, this.currencyUnit, this.persianDigits});

  final ThemeMode? themeMode;
  final CurrencyUnit? currencyUnit;
  final bool? persianDigits;

  bool get isEmpty =>
      themeMode == null && currencyUnit == null && persianDigits == null;

  /// Persian summary of what changed, for the tool result and the chat log.
  String get summaryFa {
    final parts = <String>[
      if (themeMode != null)
        'حالت ظاهری: ${switch (themeMode!) {
          ThemeMode.system => 'خودکار سیستم',
          ThemeMode.light => 'روشن',
          ThemeMode.dark => 'تاریک',
        }}',
      if (currencyUnit != null) 'واحد نمایش: ${currencyUnit!.label}',
      if (persianDigits != null)
        'ارقام فارسی: ${persianDigits! ? 'روشن' : 'خاموش'}',
    ];
    return parts.join('، ');
  }
}
