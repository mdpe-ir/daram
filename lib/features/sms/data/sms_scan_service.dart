import 'dart:convert';

import '../../../core/domain/enums.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../chat/domain/drafts.dart';
import '../domain/sms_message.dart';
import 'sms_ai_classifier.dart';
import 'sms_inbox.dart';
import 'sms_review_repository.dart';

typedef SenderCandidate = ({String sender, int count, List<String> accountIds});

class SmsScanService {
  const SmsScanService(this.inbox, this.repository);

  final SmsInbox inbox;
  final SmsReviewRepository repository;

  static const history = Duration(days: 30);
  static const matchWindow = Duration(minutes: 4);

  Future<List<SenderCandidate>> scan({
    required DateTime now,
    required DateTime? lastScan,
    required List<Account> accounts,
    required List<Category> categories,
    SmsAiClassifier? classifier,
    bool Function()? isEnabled,
    bool Function()? canUseAi,
  }) async {
    final active = {for (final account in accounts) account.id: account};
    final links = await repository.links();
    final bySender = <String, List<SmsSenderLink>>{};
    for (final link in links) {
      if (active.containsKey(link.accountId)) {
        bySender.putIfAbsent(link.sender, () => []).add(link);
      }
    }

    final recent = now.subtract(history);
    final since = lastScan != null && lastScan.isBefore(recent)
        ? lastScan.subtract(matchWindow)
        : recent;
    final old = {
      for (final row in await repository.suggestionsSince(since)) row.id: row,
    };
    final patterns = await repository.patterns();
    final bankMessages = <_Candidate>[];
    final receipts = <int, List<_Receipt>>{};
    final unknown = <String, List<Set<String>>>{};

    await for (final message in inbox.readSince(since)) {
      if (isEnabled?.call() == false) return [];
      final shape = SmsShape(message);
      if (shape.isAuthentication || shape.isFailed) continue;
      final local = shape.localRule();
      final senderLinks = bySender[message.sender];
      if (senderLinks == null) {
        if (!message.date.isBefore(recent) &&
            local?.transactionType != null &&
            shape.resemblesBankNotice &&
            (RegExp(r'^\d{3,12}$').hasMatch(message.sender) ||
                shape.text.contains('بانک'))) {
          final possible = accounts
              .where((account) {
                final name = account.bankName.replaceFirst('بانک ', '').trim();
                return shape.cardSuffixes.contains(account.cardLastFour) ||
                    (name.length > 2 && shape.text.contains(name));
              })
              .map((account) => account.id)
              .toSet();
          unknown.putIfAbsent(message.sender, () => []).add(possible);
        }
        if (!shape.resemblesBankNotice) {
          final receipt = shape.localRule(receipt: true);
          final amount = receipt == null ? null : shape.amount(receipt);
          if (amount != null) {
            receipts
                .putIfAbsent(amount.value, () => [])
                .add(_Receipt(message, shape));
          }
        }
        continue;
      }

      if (local?.kind == SmsKind.ignore) continue;
      // Include recent, already-resolved movements for collision detection.
      final eligible = senderLinks
          .where((link) => !message.date.isBefore(link.importFrom))
          .toList();
      if (eligible.isEmpty ||
          shape.numbers.isEmpty ||
          (local == null && !shape.hasFinanceCue)) {
        continue;
      }
      final key = SmsReviewRepository.patternKey(
        message.sender,
        shape.template,
      );
      if (patterns.containsKey('ignore:$key')) continue;
      final matching = eligible
          .where(
            (link) => shape.cardSuffixes.contains(
              active[link.accountId]?.cardLastFour,
            ),
          )
          .toList();
      final account = matching.length == 1
          ? active[matching.single.accountId]
          : eligible.length == 1 &&
                (shape.cardSuffixes.isEmpty ||
                    active[eligible.single.accountId]
                            ?.cardLastFour
                            ?.isNotEmpty !=
                        true)
          ? active[eligible.single.accountId]
          : null;
      bankMessages.add(_Candidate(message, shape, key, local, account));
    }

    final aiSamples = <String, (String, SmsRule?)>{};
    if (classifier != null) {
      // Unknown templates come first. Each model request has a bounded size.
      for (final unresolved in [true, false]) {
        for (final candidate in bankMessages) {
          if (aiSamples.length >= 12) break;
          if (patterns.containsKey(candidate.key) ||
              (candidate.localRule == null) != unresolved ||
              candidate.shape.aiTemplate.isEmpty ||
              candidate.shape.aiTemplate.length > 420) {
            continue;
          }
          aiSamples[candidate.key] = (
            candidate.shape.template,
            candidate.localRule,
          );
        }
      }
    }
    if (isEnabled?.call() == false) return [];
    final aiCategories = {
      for (final category in categories)
        category.id: '${category.type.name} / ${category.name}',
    };
    final inferred = canUseAi?.call() == false
        ? <String, SmsRule>{}
        : await classifier?.classify(aiSamples, aiCategories) ??
              <String, SmsRule>{};
    if (canUseAi?.call() == false) inferred.clear();
    // Drop rules with a missing or invalid monetary slot.
    inferred.removeWhere(
      (key, rule) =>
          rule.kind != SmsKind.ignore &&
          !bankMessages.any(
            (candidate) =>
                candidate.key == key && candidate.shape.amount(rule) != null,
          ),
    );

    final matchedById = <String, List<_Receipt>>{};
    final owners = <String, Set<String>>{};
    final amounts = <String, Rial>{};
    final types = <String, TransactionType>{};
    final bankEnrichment = <String, SmsRule>{};

    for (final candidate in bankMessages) {
      final cached = patterns[candidate.key];
      final ai = cached == null
          ? inferred[candidate.key]
          : SmsRule.fromJson(cached);
      if (ai?.kind == SmsKind.ignore && candidate.localRule == null) {
        continue;
      }
      final rule = candidate.localRule ?? ai;
      final amount = rule == null ? null : candidate.shape.amount(rule);
      final type =
          TransactionType.tryParse(
            patterns['direction:${candidate.key}']?['type'],
          ) ??
          rule?.transactionType;
      if (amount == null || type == null) continue;
      final id = candidate.message.id;
      amounts[id] = amount;
      types[id] = type;
      if (ai != null) bankEnrichment[id] = ai;

      final nearby = (receipts[amount.value] ?? const <_Receipt>[])
          .where(
            (receipt) =>
                receipt.message.date.difference(candidate.message.date).abs() <=
                    matchWindow &&
                (type == TransactionType.income
                    ? _incomeContext.hasMatch(receipt.shape.semanticText)
                    : !_incomeContext.hasMatch(receipt.shape.semanticText)),
          )
          .toList();
      matchedById[id] = nearby;
      for (final receipt in nearby) {
        owners.putIfAbsent(receipt.message.id, () => {}).add(id);
      }
    }

    final relatedById = {
      for (final entry in matchedById.entries)
        if (entry.value.length == 1 &&
            owners[entry.value.single.message.id]?.length == 1)
          entry.key: entry.value.single,
    };
    final receiptKeys = <String, String>{};
    final receiptSamples = <String, (String, SmsRule?)>{};
    for (final entry in relatedById.entries) {
      final receipt = entry.value;
      final type = types[entry.key]!;
      final key = SmsReviewRepository.patternKey(
        receipt.message.sender,
        receipt.shape.template,
      );
      final enrichmentKey = 'receipt:$key:${type.name}';
      receiptKeys[entry.key] = enrichmentKey;
      final sample = receipt.shape.aiTemplate;
      if (classifier != null &&
          receiptSamples.length < 8 &&
          !patterns.containsKey(enrichmentKey) &&
          sample.isNotEmpty &&
          sample.length <= 420 &&
          !_hints.any((hint) => hint.$1.hasMatch(receipt.shape.semanticText))) {
        receiptSamples[enrichmentKey] = (
          sample,
          SmsRule(
            type == TransactionType.income ? SmsKind.income : SmsKind.expense,
          ),
        );
      }
    }
    if (isEnabled?.call() == false) return [];
    if (canUseAi?.call() != false && classifier != null) {
      final enriched = await classifier.classify(receiptSamples, aiCategories);
      if (canUseAi?.call() != false) inferred.addAll(enriched);
    }
    final manuallyRecorded = bankMessages.isEmpty
        ? const <(String, int, TransactionType, int)>{}
        : await repository.manualTransactionKeys(since);
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final rows = <SmsSuggestionRow>[];
    for (final candidate in bankMessages) {
      final message = candidate.message;
      final previous = old[message.id];
      if (previous != null &&
          !SmsReviewRepository.openStatuses.contains(previous.status)) {
        continue;
      }
      final amount = amounts[message.id];
      final type = types[message.id];
      final cached = patterns[candidate.key];
      if (amount == null &&
          (inferred[candidate.key]?.kind == SmsKind.ignore ||
              cached?['kind'] == 'ignore' ||
              !candidate.shape.resemblesBankNotice)) {
        continue;
      }
      final related = relatedById[message.id];
      final receiptKey = receiptKeys[message.id];
      final savedReceipt = patterns[receiptKey];
      final enrichment = savedReceipt != null
          ? SmsRule.fromJson(savedReceipt)
          : inferred[receiptKey] ?? bankEnrichment[message.id];
      final evidence =
          related?.shape.semanticText ?? candidate.shape.semanticText;
      final hint = _hints
          .where((hint) => hint.$1.hasMatch(evidence))
          .firstOrNull;
      final contextKey = related != null
          ? SmsReviewRepository.patternKey(
              related.message.sender,
              related.shape.template,
            )
          : hint == null
          ? null
          : candidate.key;
      final effectiveType = type ?? TransactionType.expense;
      final accountId = candidate.account?.id ?? '';
      final date = CalendarDate.fromDateTime(message.date.toLocal());
      final recurring = amount == null || accountId.isEmpty
          ? null
          : patterns[SmsReviewRepository.recurringKey(
              candidate.key,
              accountId,
              effectiveType,
              amount.value,
            )];
      final learned =
          patterns['context:$contextKey:${effectiveType.name}'] ??
          ((recurring?['count'] as int? ?? 0) >= 2 ? recurring : null);
      final possibleDuplicate = manuallyRecorded.contains((
        accountId,
        date.stored.millisecondsSinceEpoch,
        effectiveType,
        amount?.value ?? 0,
      ));
      final categoryType = effectiveType == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense;
      Category? category;
      for (final id in [
        learned?['categoryId'],
        hint?.$2,
        enrichment?.categoryId,
        effectiveType == TransactionType.income
            ? 'cat_other_income'
            : 'cat_other_expense',
      ]) {
        final candidate = categoryById[id];
        if (candidate?.type == categoryType) {
          category = candidate;
          break;
        }
      }

      final draft = TransactionDraft(
        type: effectiveType,
        amountRial: amount ?? Rial.zero,
        accountId: accountId,
        accountName: candidate.account?.accountName ?? '',
        categoryId: category?.id,
        categoryName: category?.name,
        date: date,
        description:
            learned?['description'] as String? ??
            hint?.$3 ??
            enrichment?.description ??
            (related != null ? _brief(evidence) : null) ??
            (type == TransactionType.income
                ? 'واریز بانکی'
                : type == TransactionType.expense
                ? 'برداشت بانکی'
                : null),
      );
      rows.add(
        SmsSuggestionRow(
          id: message.id,
          sender: message.sender,
          receivedAt: message.date,
          template: candidate.shape.template,
          contextKey: contextKey,
          contextMessageId: related?.message.id,
          payload: jsonEncode(draft.toPayload()),
          status: possibleDuplicate
              ? 'possibleDuplicate'
              : amount == null || candidate.account == null
              ? 'needsReview'
              : 'pending',
        ),
      );
    }

    if (isEnabled?.call() == false) return [];
    await repository.saveScan(
      suggestions: rows,
      inferred: inferred,
      scannedLinks: links,
    );
    final suggestions = [
      for (final entry in unknown.entries)
        (
          sender: entry.key,
          count: entry.value.length,
          accountIds: [
            for (final account in accounts)
              if (entry.value.any((ids) => ids.contains(account.id)))
                account.id,
          ],
        ),
    ];
    suggestions.sort((first, second) => second.count.compareTo(first.count));
    return suggestions;
  }

  static String? _brief(String evidence) {
    final text = evidence.replaceAll(RegExp(r'\s*[:،,.\-]+\s*$'), '').trim();
    if (text.isEmpty) return null;
    return String.fromCharCodes(text.runes.take(96));
  }

  static final _incomeContext = RegExp(r'حقوق|دستمزد|درآمد|پاداش');
  static final _hints = <(RegExp, String, String)>[
    (RegExp(r'پارکینگ|پارکومتر'), 'cat_transport', 'پارکینگ'),
    (RegExp(r'عوارض|کرایه|تاکسی|اسنپ|تپسی'), 'cat_transport', 'حمل‌ونقل'),
    (RegExp(r'حقوق|دستمزد'), 'cat_salary', 'حقوق'),
    (RegExp(r'سود سپرده'), 'cat_investment', 'سود سپرده'),
    (RegExp(r'قبض|آب بها'), 'cat_bills', 'پرداخت قبض'),
    (RegExp(r'اشتراک'), 'cat_subscriptions', 'اشتراک'),
    (RegExp(r'داروخانه|درمان|بیمارستان'), 'cat_health', 'درمان'),
    (RegExp(r'رستوران|کافه|غذا'), 'cat_food', 'خوراک'),
    (RegExp(r'خرید از فروشگاه|سفارش فروشگاه'), 'cat_shopping', 'خرید'),
  ];
}

class _Candidate {
  const _Candidate(
    this.message,
    this.shape,
    this.key,
    this.localRule,
    this.account,
  );

  final InboxSms message;
  final SmsShape shape;
  final String key;
  final SmsRule? localRule;
  final Account? account;
}

class _Receipt {
  const _Receipt(this.message, this.shape);

  final InboxSms message;
  final SmsShape shape;
}
