import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/ai_models.dart';
import '../domain/tool.dart';
import 'json_schema_validator.dart';

/// Loads and validates the JSON tool schemas bundled with the app.
class ToolRegistry {
  /// Builds a registry from already-parsed definitions (used by tests).
  factory ToolRegistry.fromDefinitions(List<ToolDefinition> definitions) =>
      ToolRegistry(definitions);

  ToolRegistry(List<ToolDefinition> definitions)
    : _definitions = List<ToolDefinition>.unmodifiable(definitions),
      _byName = {
        for (final definition in definitions) definition.name: definition,
      };

  final List<ToolDefinition> _definitions;
  final Map<String, ToolDefinition> _byName;
  final JsonSchemaValidator _validator = const JsonSchemaValidator();

  static const List<String> assetPaths = <String>[
    'assets/ai/tools/manage_category.json',
    'assets/ai/tools/add_account.json',
    'assets/ai/tools/add_transaction.json',
    'assets/ai/tools/add_transfer.json',
    'assets/ai/tools/add_loan.json',
    'assets/ai/tools/mark_installment_paid.json',
    'assets/ai/tools/query_transactions.json',
    'assets/ai/tools/query_records.json',
    'assets/ai/tools/get_financial_overview.json',
    'assets/ai/tools/generate_report.json',
    'assets/ai/tools/review_sms_suggestions.json',
    'assets/ai/tools/confirm_sms_suggestion.json',
    'assets/ai/tools/edit_sms_suggestion.json',
    'assets/ai/tools/dismiss_sms_suggestion.json',
    'assets/ai/tools/update_pending_draft.json',
    'assets/ai/tools/cancel_pending_draft.json',
    'assets/ai/tools/manage_account.json',
    'assets/ai/tools/manage_transaction.json',
    'assets/ai/tools/manage_transfer.json',
    'assets/ai/tools/manage_loan.json',
    'assets/ai/tools/manage_asset.json',
    'assets/ai/tools/manage_obligation.json',
    'assets/ai/tools/update_settings.json',
  ];

  List<ToolDefinition> get definitions => _definitions;

  ToolDefinition? byName(String name) => _byName[name];

  DaramTool? toolFor(String name) => DaramTool.fromName(name);

  /// Loads every schema from [bundle] (rootBundle in the app, a test bundle in
  /// widget tests).
  static Future<ToolRegistry> load(AssetBundle bundle) async {
    final definitions = <ToolDefinition>[];
    for (final path in assetPaths) {
      final raw = await bundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw FormatException('Invalid tool schema at $path');
      }
      definitions.add(
        fromJson(decoded.map((key, value) => MapEntry('$key', value))),
      );
    }
    return ToolRegistry(definitions);
  }

  static ToolDefinition fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final description = json['description'];
    final parameters = json['parameters'];
    if (name is! String || description is! String || parameters is! Map) {
      throw const FormatException(
        'Tool schema needs name, description and parameters',
      );
    }
    return ToolDefinition(
      name: name,
      description: description,
      parameters: parameters.map((key, value) => MapEntry('$key', value)),
    );
  }

  /// Validates tool arguments, returning `null` when they are acceptable.
  String? validateArguments(String toolName, Map<String, Object?> arguments) {
    final definition = byName(toolName);
    if (definition == null) return 'ابزار «$toolName» شناخته نشد.';
    final errors = _validator.validate(definition.parameters, arguments);
    if (errors.isEmpty) return null;
    return 'آرگومان‌های ابزار معتبر نیستند: ${errors.take(4).join('؛ ')}';
  }
}
