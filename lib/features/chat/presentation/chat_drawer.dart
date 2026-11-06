import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/branding/daram_logo.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/localization/fa_strings.dart';
import '../../../core/time/calendar_date.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/chat_models.dart';
import 'chat_controller.dart';

/// Conversation history drawer with search, rename and delete.
class ChatHistoryDrawer extends ConsumerStatefulWidget {
  const ChatHistoryDrawer({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends ConsumerState<ChatHistoryDrawer> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _rename(ChatSession session) async {
    final controller = TextEditingController(text: session.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغییر عنوان گفتگو'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'عنوان جدید'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(FaStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text(FaStrings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.trim().isNotEmpty) {
      await ref
          .read(chatControllerProvider.notifier)
          .renameSession(session.id, result.trim());
    }
  }

  Future<void> _delete(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف گفتگو'),
        content: Text(
          'گفتگوی «${session.title}» و پیام‌هایش حذف شود؟ این کار برگشت‌پذیر نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(FaStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.daram.expense,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(FaStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(chatControllerProvider.notifier).deleteSession(session.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final state = ref.watch(chatControllerProvider);
    final settings =
        ref.watch(settingsControllerProvider).value ??
        const AppSettings.defaults();
    final sessions = state.filteredSessions;
    final format = DaramFormatScope.of(context);

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.86,
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: DaramLogo(markSize: 34, showEnglish: true),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () async {
                    widget.onClose();
                    await ref
                        .read(chatControllerProvider.notifier)
                        .newSession();
                  },
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text(FaStrings.newChat),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accentSoft,
                    foregroundColor: colors.accent,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(chatControllerProvider.notifier)
                    .setSearchQuery(value),
                decoration: InputDecoration(
                  hintText: FaStrings.searchConversations,
                  prefixIcon: const Icon(LucideIcons.search, size: 17),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              child: Row(
                children: [
                  Text(
                    FaStrings.conversations,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: colors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    '${PersianDigits.toPersian('${sessions.length}')} گفتگو',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text(
                        FaStrings.noConversations,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final selected = session.id == state.activeSession?.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Material(
                            color: selected
                                ? colors.accentSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                widget.onClose();
                                await ref
                                    .read(chatControllerProvider.notifier)
                                    .selectSession(session.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  4,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.messageSquare,
                                      size: 16,
                                      color: selected
                                          ? colors.accent
                                          : colors.textMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: selected
                                                      ? colors.accent
                                                      : colors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            session.preview ??
                                                format.dates.relative(
                                                  CalendarDate.fromStored(
                                                    session.updatedAt,
                                                  ),
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: colors.textMuted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        LucideIcons.ellipsisVertical,
                                        size: 16,
                                        color: colors.textMuted,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'rename') _rename(session);
                                        if (value == 'delete') _delete(session);
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'rename',
                                          child: Text('تغییر عنوان'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('حذف گفتگو'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(height: 1, color: colors.divider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  widget.onClose();
                  context.push('/settings/ai');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: settings.isAIConfigured
                              ? colors.income
                              : colors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          settings.isAIConfigured
                              ? 'دستیار متصل است — ${isolateLtr(settings.aiConfig.model)}'
                              : 'دستیار هنوز تنظیم نشده است',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronLeft,
                        size: 15,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
