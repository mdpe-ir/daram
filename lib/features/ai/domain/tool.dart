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
  generateReport('generate_report'),
  reviewSmsSuggestions('review_sms_suggestions'),
  confirmSmsSuggestion('confirm_sms_suggestion'),
  editSmsSuggestion('edit_sms_suggestion'),
  dismissSmsSuggestion('dismiss_sms_suggestion');

  const DaramTool(this.toolName);

  final String toolName;

  static DaramTool? fromName(String name) {
    for (final tool in DaramTool.values) {
      if (tool.toolName == name) return tool;
    }
    return null;
  }

  /// Tools which change stored data.
  ///
  /// Financial draft tools still require a separate confirmation; SMS decision
  /// tools are only allowed after the user has seen the suggestion in chat.
  bool get isWriteTool => switch (this) {
    DaramTool.addAccount ||
    DaramTool.addTransaction ||
    DaramTool.addTransfer ||
    DaramTool.addLoan ||
    DaramTool.markInstallmentPaid ||
    DaramTool.confirmSmsSuggestion ||
    DaramTool.editSmsSuggestion ||
    DaramTool.dismissSmsSuggestion => true,
    DaramTool.manageCategory ||
    DaramTool.queryTransactions ||
    DaramTool.generateReport ||
    DaramTool.reviewSmsSuggestions => false,
  };

  /// Tools which decide the fate of one existing SMS suggestion.
  ///
  /// They may only run after that suggestion has been shown in the chat.
  bool get isSmsDecision => switch (this) {
    DaramTool.confirmSmsSuggestion ||
    DaramTool.editSmsSuggestion ||
    DaramTool.dismissSmsSuggestion => true,
    _ => false,
  };
}

/// Serialises a tool schema for a provider.
String encodeToolSchema(Map<String, Object?> schema) => jsonEncode(schema);
