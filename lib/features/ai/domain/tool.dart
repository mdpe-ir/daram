import 'dart:convert';

/// Names of the tools DARAM exposes to the model.
///
/// The identifiers are part of the prompt/tool contract and match the JSON
/// schema files in `assets/ai/tools/`.
enum DaramTool {
  manageCategory('manage_category'),
  addAccount('add_account'),
  addTransaction('add_transaction'),
  addTransfer('add_transfer'),
  addLoan('add_loan'),
  markInstallmentPaid('mark_installment_paid'),
  queryTransactions('query_transactions'),
  generateReport('generate_report');

  const DaramTool(this.toolName);

  final String toolName;

  static DaramTool? fromName(String name) {
    for (final tool in DaramTool.values) {
      if (tool.toolName == name) return tool;
    }
    return null;
  }

  /// Tools which create a financial draft and therefore require confirmation.
  bool get isWriteTool => switch (this) {
    DaramTool.addAccount ||
    DaramTool.addTransaction ||
    DaramTool.addTransfer ||
    DaramTool.addLoan ||
    DaramTool.markInstallmentPaid => true,
    DaramTool.manageCategory ||
    DaramTool.queryTransactions ||
    DaramTool.generateReport => false,
  };
}

/// Serialises a tool schema for a provider.
String encodeToolSchema(Map<String, Object?> schema) => jsonEncode(schema);
