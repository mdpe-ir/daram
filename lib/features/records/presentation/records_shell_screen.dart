import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/daram_colors.dart';
import '../../accounts/presentation/accounts_section.dart';
import '../../assets/presentation/assets_section.dart';
import '../../loans/presentation/loans_section.dart';
import '../../obligations/presentation/obligations_section.dart';
import '../../transactions/presentation/transactions_section.dart';

enum RecordsSection {
  accounts(
    'حساب‌ها',
    'حساب',
    'حساب‌ها، موجودی و کارت‌ها',
    LucideIcons.landmark,
  ),
  transactions(
    'تراکنش‌ها',
    'تراکنش',
    'درآمدها، هزینه‌ها و انتقال‌ها',
    LucideIcons.receiptText,
  ),
  loans('وام‌ها', 'وام', 'وام‌ها و جدول اقساط', LucideIcons.banknote),
  obligations(
    'بدهی و طلب',
    'بدهی یا طلب',
    'مانده‌ها، سررسیدها و پرداخت‌ها',
    LucideIcons.handshake,
  ),
  assets(
    'دارایی‌ها',
    'دارایی',
    'موجودی طلا، نقره، ارز و رمزارز',
    LucideIcons.gem,
  );

  const RecordsSection(this.label, this.addLabel, this.description, this.icon);

  final String label;
  final String addLabel;
  final String description;
  final IconData icon;
}

class RecordsShellScreen extends ConsumerWidget {
  const RecordsShellScreen({super.key, required this.section});

  final RecordsSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اطلاعات مالی',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          section.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => switch (section) {
                      RecordsSection.accounts => showAccountEditor(
                        context,
                        ref,
                      ),
                      RecordsSection.transactions => showTransactionEditor(
                        context,
                        ref,
                      ),
                      RecordsSection.loans => showLoanEditor(context, ref),
                      RecordsSection.obligations => showObligationEditor(
                        context,
                      ),
                      RecordsSection.assets => showAssetEditor(context),
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text(section.addLabel),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RecordTabs(section: section),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: switch (section) {
                RecordsSection.accounts => const AccountsSection(),
                RecordsSection.transactions => const TransactionsSection(),
                RecordsSection.loans => const LoansSection(),
                RecordsSection.obligations => const ObligationsSection(),
                RecordsSection.assets => const AssetsSection(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordTabs extends StatelessWidget {
  const _RecordTabs({required this.section});

  final RecordsSection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return Row(
            children: [
              for (final item in RecordsSection.values)
                Expanded(
                  child: Semantics(
                    selected: item == section,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => context.go('/records/${item.name}'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: compact ? 52 : 44,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: item == section
                              ? colors.surface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Flex(
                          direction: compact ? Axis.vertical : Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 16,
                              color: item == section
                                  ? colors.accent
                                  : colors.textMuted,
                            ),
                            const SizedBox(width: 5, height: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.label,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: item == section
                                            ? colors.accent
                                            : colors.textMuted,
                                        fontWeight: item == section
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
