import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sms_chat_focus.dart';

/// Drives the "reply to this suggestion" and "select several suggestions"
/// affordances shown by the SMS cards in chat.
final smsChatFocusProvider =
    NotifierProvider.autoDispose<SmsChatFocusController, SmsChatFocus>(
      SmsChatFocusController.new,
    );

class SmsChatFocusController extends Notifier<SmsChatFocus> {
  @override
  SmsChatFocus build() => const SmsChatFocus();

  void beginSelection() {
    state = SmsChatFocus(selecting: true, selectedIds: state.selectedIds);
  }

  void toggle(String id) {
    final selected = {...state.selectedIds};
    if (!selected.remove(id)) selected.add(id);
    state = SmsChatFocus(selecting: true, selectedIds: selected);
  }

  void selectAll(Iterable<String> ids) {
    state = SmsChatFocus(selecting: true, selectedIds: ids.toSet());
  }

  void cancelSelection() {
    state = SmsChatFocus(replyToId: state.replyToId);
  }

  void setReply(String id) {
    state = SmsChatFocus(replyToId: id);
  }

  void clearReply() {
    state = SmsChatFocus(
      selecting: state.selecting,
      selectedIds: state.selectedIds,
    );
  }

  /// Removes a suggestion from the focus after it is confirmed or dismissed.
  void remove(String id) {
    final selected = {...state.selectedIds}..remove(id);
    state = SmsChatFocus(
      selecting: state.selecting,
      selectedIds: selected,
      replyToId: state.replyToId == id ? null : state.replyToId,
    );
  }

  void clear() {
    state = const SmsChatFocus();
  }
}
