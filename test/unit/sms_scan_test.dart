import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/accounts/domain/account.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/ai/domain/ai_provider.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/sms/data/sms_ai_classifier.dart';
import 'package:daram/features/sms/data/sms_inbox.dart';
import 'package:daram/features/sms/data/sms_review_repository.dart';
import 'package:daram/features/sms/data/sms_scan_service.dart';
import 'package:daram/features/sms/domain/sms_message.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:daram/features/transactions/domain/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

class _Inbox extends SmsInbox {
  final messages = <InboxSms>[];

  @override
  Stream<InboxSms> readSince(DateTime since) =>
      Stream.fromIterable(messages.where((sms) => !sms.date.isBefore(since)));
}

class _ClassifierProvider implements AIProvider {
  List<AIMessage>? request;

  @override
  Stream<AIStreamEvent> streamChat({
    required AIConfig config,
    required List<AIMessage> messages,
    required List<ToolDefinition> tools,
  }) async* {
    request = messages;
    expect(tools, isEmpty);
    final id = RegExp(r'"id":"([^"]+)"')
        .firstMatch(messages.last.content)!
        .group(1);
    yield AIStreamText(
      '[{"id":"$id","kind":"income","slot":0,"multiplier":1,'
      '"categoryId":"cat_salary","description":"حقوق"}]',
    );
    yield const AIStreamDone();
  }

  @override
  Future<AIConnectionResult> testConnection(AIConfig config) async =>
      const AIConnectionResult.success('ok');
}

void main() {
  late AppDatabase db;
  late SmsReviewRepository reviews;
  late SmsScanService scanner;
  late TransactionRepository transactions;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late Account account;
  late _Inbox inbox;
  late DateTime now;

  setUp(() async {
    db = AppDatabase.memory();
    final operations = OperationRepository(db);
    transactions = TransactionRepository(db, operations);
    reviews = SmsReviewRepository(db, transactions);
    accounts = AccountRepository(db, operations);
    categories = CategoryRepository(db);
    inbox = _Inbox();
    scanner = SmsScanService(inbox, reviews);
    now = DateTime.now().toUtc();
    await categories.ensureDefaults();
    account = await accounts.create(
      bankId: 'mellat',
      bankName: 'بانک ملت',
      accountName: 'ملت',
      accountType: AccountType.bank,
      initialBalance: Rial.zero,
      operationId: 'create-account',
    );
  });
  tearDown(() => db.close());

  void add(String id, String sender, String body, {int seconds = 0}) {
    inbox.messages.add(
      InboxSms(
        id: id,
        sender: sender,
        body: body,
        date: now.subtract(Duration(seconds: seconds)),
      ),
    );
  }

  Future<List<SenderCandidate>> scan({SmsAiClassifier? classifier}) async =>
      scanner.scan(
        now: now,
        lastScan: null,
        accounts: await accounts.list(),
        categories: await categories.list(),
        classifier: classifier,
      );

  Future<List<SmsSuggestionRow>> pending() => reviews.watchOpen().first;

  test(
    'detects multiple bank senders and does not turn OTP into a draft',
    () async {
      add('1', '1001', 'بانک ملت\nبرداشت: ۲۰٬۰۰۰ تومان\nموجودی: ۷۰۰٬۰۰۰ تومان');
      add('2', '1002', 'بانک ملت\n+500,000\nمانده: 700,000');
      add('3', '1003', 'رمز دوم: 345678\nمبلغ خرید: ۲۰٬۰۰۰ تومان');
      final discovered = await scan();
      expect(
        discovered.map((item) => item.sender),
        unorderedEquals(['1001', '1002']),
      );
      expect(discovered.first.accountIds, [account.id]);
      expect(await pending(), isEmpty);

      await reviews.setSenders(account.id, {
        '1001',
        '1002',
        '1003',
      }, includeHistory: true);
      await scan();
      final rows = await pending();
      expect(rows.map((row) => row.id), unorderedEquals(['1', '2']));
      final income = SmsReviewRepository.draftOf(
        rows.singleWhere((row) => row.id == '2'),
      );
      expect(income.type, TransactionType.income);
      expect(income.amountRial, Rial(500000));
      expect(await transactions.list(const TransactionFilter()), isEmpty);
    },
  );

  test('matches parking across units and learns confirmed edits', () async {
    await reviews.setSenders(account.id, {'1001'}, includeHistory: true);
    add('bank-1', '1001', 'بانک ملت\nبرداشت: ۲۰۰٬۰۰۰ ریال', seconds: 1000);
    add('receipt-1', '2002', 'صورت حساب پارکینگ: ۲۰ هزار تومن', seconds: 1001);
    await scan();
    final row = (await pending()).single;
    final draft = SmsReviewRepository.draftOf(row);
    expect(row.contextMessageId, 'receipt-1');
    expect(draft.amountRial, Rial.fromToman(20000));
    expect(draft.description, 'پارکینگ');
    expect(draft.categoryId, 'cat_transport');
    await Future.wait([
      reviews.confirm(
        row.id,
        edited: draft.copyWith(description: 'پارکینگ محل کار'),
      ),
      reviews.confirm(
        row.id,
        edited: draft.copyWith(description: 'پارکینگ محل کار'),
      ),
    ]);
    await scan();
    expect(await pending(), isEmpty);
    expect(await transactions.list(const TransactionFilter()), hasLength(1));

    add('bank-2', '1001', 'بانک ملت\nبرداشت: ۳۰۰٬۰۰۰ ریال');
    add('receipt-2', '2002', 'صورت حساب پارکینگ: ۳۰ هزار تومن', seconds: 30);
    await scan();
    expect(
      SmsReviewRepository.draftOf((await pending()).single).description,
      'پارکینگ محل کار',
    );
  });

  test(
    'drops the proposed match when a second same-amount movement arrives',
    () async {
      await reviews.setSenders(account.id, {'1001'}, includeHistory: true);
      add('bank-1', '1001', 'برداشت: ۲۰۰٬۰۰۰ ریال', seconds: 25);
      add('receipt-1', '2002', 'رسید پارکینگ: ۲۰٬۰۰۰ تومان', seconds: 24);
      await scan();
      expect((await pending()).single.contextMessageId, 'receipt-1');
      add('bank-2', '1001', 'برداشت: ۲۰۰٬۰۰۰ ریال', seconds: 5);
      await scan();
      final rows = await pending();
      expect(rows, hasLength(2));
      expect(rows.every((row) => row.contextMessageId == null), isTrue);
    },
  );

  test(
    'shared sender requires an account unless the card suffix identifies it',
    () async {
      final second = await accounts.create(
        bankId: 'mellat',
        bankName: 'بانک ملت',
        accountName: 'ملت دوم',
        accountType: AccountType.bank,
        initialBalance: Rial.zero,
        operationId: 'second',
        cardLastFour: '4422',
      );
      await reviews.setSenders(account.id, {'1001'}, includeHistory: true);
      await reviews.setSenders(second.id, {'1001'}, includeHistory: true);
      add('ambiguous', '1001', 'برداشت: ۲۰۰٬۰۰۰ ریال');
      add('matched', '1001', 'برداشت: ۲۰۰٬۰۰۰ ریال\nکارت: ****4422');
      await scan();
      final rows = await pending();
      expect(
        rows.singleWhere((row) => row.id == 'ambiguous').status,
        'needsReview',
      );
      final selected = rows.singleWhere((row) => row.id == 'matched');
      expect(selected.status, 'pending');
      expect(SmsReviewRepository.draftOf(selected).accountId, second.id);
    },
  );

  test(
    'messages that match a manual record require individual review',
    () async {
      await reviews.setSenders(account.id, {'1001'}, includeHistory: true);
      await transactions.create(
        type: TransactionType.expense,
        amount: Rial.fromToman(20000),
        accountId: account.id,
        date: CalendarDate.fromDateTime(now.toLocal()),
        operationId: 'manual-parking',
      );
      add('bank-1', '1001', 'برداشت: ۲۰۰٬۰۰۰ ریال');
      await scan();
      final row = (await pending()).single;
      expect(row.status, 'possibleDuplicate');
      await expectLater(reviews.confirm(row.id), throwsA(isA<Exception>()));
      expect(await transactions.list(const TransactionFilter()), hasLength(1));
    },
  );

  test(
    'uses a learned AI slot without sending original values or unrelated SMS',
    () async {
      final provider = _ClassifierProvider();
      final classifier = SmsAiClassifier(
        provider,
        const AIConfig(
          provider: AIProviderKind.openAICompatible,
          baseUrl: 'https://example.test',
          model: 'test',
          apiKey: 'fake',
        ),
      );
      await reviews.setSenders(account.id, {'1001'}, includeHistory: true);
      add('ai-1', '1001', 'مجوز پایا: ۸۰۰٬۰۰۰ ریال\nمانده: ۱٬۶۰۰٬۰۰۰ ریال');
      add('otp-1', '1001', 'رمز خرید: 999899\nمبلغ خرید: 800000 ریال');
      add('private-1', '09120000000', 'متن خانوادگی خصوصی 77112');
      await scan(classifier: classifier);
      final input = provider.request!.last.content;
      expect(input, contains('[n0]'));
      expect(input, isNot(contains('"sender"')));
      for (final private in [
        '800000',
        '800٬000',
        '999899',
        '77112',
        'خانوادگی',
      ]) {
        if (private == '1001') {
          expect(input, isNot(contains('"sender"')));
        } else {
          expect(input, isNot(contains(private)));
        }
      }
      final first = SmsReviewRepository.draftOf((await pending()).single);
      expect(first.type, TransactionType.income);
      expect(first.description, 'حقوق');
      add('ai-2', '1001', 'مجوز پایا: ۹۰۰٬۰۰۰ ریال\nمانده: ۲٬۵۰۰٬۰۰۰ ریال');
      await scan();
      expect(
        (await pending()).map(
          (row) => SmsReviewRepository.draftOf(row).amountRial,
        ),
        unorderedEquals([Rial(800000), Rial(900000)]),
      );
    },
  );
}
