import 'package:flutter/material.dart';

import '../../../app/design_system/daram_widgets.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';

Future<void> showRecordSheet(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: builder,
    );

/// Keeps validation and submission in the sheet so errors can be corrected.
class RecordEditor extends StatefulWidget {
  const RecordEditor({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    this.saveLabel = 'ذخیره',
  });

  final String title;
  final Widget fields;
  final Future<void> Function()? onSave;
  final String saveLabel;

  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final onSave = widget.onSave;
    if (_saving || onSave == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await onSave();
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    } on AppException catch (error) {
      _error = error.message;
    } on Object {
      _error = 'ذخیره انجام نشد. دوباره تلاش کن.';
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => DaramSheet(
    title: widget.title,
    child: IgnorePointer(ignoring: _saving, child: widget.fields),
    actions: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            PrimaryButton(
              label: widget.saveLabel,
              loading: _saving,
              onPressed: _saving || widget.onSave == null ? null : _save,
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> confirmRecordDeletion(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() delete,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await delete();
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('حذف انجام نشد. دوباره تلاش کن.')),
    );
  }
}

String formatRecordTotal(DaramFormat format, Iterable<Rial> values) {
  final sum = values.fold(
    BigInt.zero,
    (total, amount) => total + BigInt.from(amount.value),
  );
  if (sum > BigInt.from(Rial.maxAbsoluteValue)) return 'بیش از محدودهٔ نمایش';
  return format.money.format(Rial(sum.toInt()));
}
