import 'package:drift/drift.dart';

import 'financial_tables.dart';

@DataClassName('SmsSenderLink')
class SmsSenderLinks extends Table {
  TextColumn get sender => text()();
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get importFrom => dateTime()();

  @override
  Set<Column> get primaryKey => {sender, accountId};
}

@DataClassName('SmsSuggestionRow')
class SmsSuggestions extends Table {
  TextColumn get id => text()();
  TextColumn get sender => text()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get template => text()();
  TextColumn get contextKey => text().nullable()();
  TextColumn get contextMessageId => text().nullable().unique()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SmsPatternRow')
class SmsPatterns extends Table {
  TextColumn get key => text()();
  TextColumn get rule => text()();

  @override
  Set<Column> get primaryKey => {key};
}
