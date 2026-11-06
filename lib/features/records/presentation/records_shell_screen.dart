import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../accounts/presentation/accounts_section.dart';
import '../../loans/presentation/loans_section.dart';
import '../../transactions/presentation/transactions_section.dart';
import '../../../app/theme/daram_colors.dart';

enum RecordsSection {
  accounts('حساب‌ها', LucideIcons.landmark),
  transactions('تراکنش‌ها', LucideIcons.receiptText),
  loans('وام‌ها', LucideIcons.banknote);

  const RecordsSection(this.label, this.icon);

  final String label;
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
                          switch (section) {
                            RecordsSection.accounts =>
                              'حساب‌ها، موجودی و کارت‌ها',
                            RecordsSection.transactions =>
                              'همه درآمدها، هزینه‌ها و انتقال‌ها',
                            RecordsSection.loans => 'بدهی‌ها و جدول اقساط',
                          },
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
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text(switch (section) {
                      RecordsSection.accounts => 'حساب',
                      RecordsSection.transactions => 'تراکنش',
                      RecordsSection.loans => 'وام',
                    }),
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
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    for (final item in RecordsSection.values)
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => context.go(switch (item) {
                            RecordsSection.accounts => '/records/accounts',
                            RecordsSection.transactions =>
                              '/records/transactions',
                            RecordsSection.loans => '/records/loans',
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: item == section
                                  ? colors.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: item == section && !colors.isDark
                                  ? [
                                      BoxShadow(
                                        color: colors.shadow,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 14,
                                  color: item == section
                                      ? colors.accent
                                      : colors.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
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
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: switch (section) {
                RecordsSection.accounts => const AccountsSection(),
                RecordsSection.transactions => const TransactionsSection(),
                RecordsSection.loans => const LoansSection(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
