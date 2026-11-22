import 'package:meta/meta.dart';

/// What the user is currently pointing the assistant at in an SMS review.
///
/// The two modes are mutually exclusive: either the user replied to one
/// suggestion, or they selected one or more suggestions for a group command.
@immutable
final class SmsChatFocus {
  const SmsChatFocus({
    this.selecting = false,
    this.selectedIds = const <String>{},
    this.replyToId,
  });

  /// Selection mode is active even when nothing is selected yet.
  final bool selecting;

  final Set<String> selectedIds;
  final String? replyToId;

  bool get hasReply => replyToId != null;
  bool get hasSelection => selectedIds.isNotEmpty;
  bool get hasContent => hasReply || hasSelection;
  int get count => hasReply ? 1 : selectedIds.length;

  SmsChatFocus copyWith({
    bool? selecting,
    Set<String>? selectedIds,
    String? replyToId,
    bool clearReply = false,
  }) => SmsChatFocus(
    selecting: selecting ?? this.selecting,
    selectedIds: selectedIds ?? this.selectedIds,
    replyToId: clearReply ? null : (replyToId ?? this.replyToId),
  );

  @override
  bool operator ==(Object other) =>
      other is SmsChatFocus &&
      other.selecting == selecting &&
      other.replyToId == replyToId &&
      other.selectedIds.length == selectedIds.length &&
      other.selectedIds.containsAll(selectedIds);

  @override
  int get hashCode =>
      Object.hash(selecting, replyToId, Object.hashAllUnordered(selectedIds));
}
