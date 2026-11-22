// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> accountType =
      GeneratedColumn<String>(
        'account_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($AccountsTable.$converteraccountType);
  static const VerificationMeta _initialBalanceRialMeta =
      const VerificationMeta('initialBalanceRial');
  @override
  late final GeneratedColumn<int> initialBalanceRial = GeneratedColumn<int>(
    'initial_balance_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardLastFourMeta = const VerificationMeta(
    'cardLastFour',
  );
  @override
  late final GeneratedColumn<String> cardLastFour = GeneratedColumn<String>(
    'card_last_four',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankId,
    bankName,
    accountName,
    accountType,
    initialBalanceRial,
    cardLastFour,
    description,
    createdAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIdMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountNameMeta);
    }
    if (data.containsKey('initial_balance_rial')) {
      context.handle(
        _initialBalanceRialMeta,
        initialBalanceRial.isAcceptableOrUnknown(
          data['initial_balance_rial']!,
          _initialBalanceRialMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialBalanceRialMeta);
    }
    if (data.containsKey('card_last_four')) {
      context.handle(
        _cardLastFourMeta,
        cardLastFour.isAcceptableOrUnknown(
          data['card_last_four']!,
          _cardLastFourMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      )!,
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      )!,
      accountType: $AccountsTable.$converteraccountType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}account_type'],
        )!,
      ),
      initialBalanceRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_balance_rial'],
      )!,
      cardLastFour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_last_four'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $converteraccountType =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String bankId;
  final String bankName;
  final String accountName;
  final AccountType accountType;
  final int initialBalanceRial;
  final String? cardLastFour;
  final String? description;
  final DateTime createdAt;
  final DateTime? archivedAt;
  const AccountRow({
    required this.id,
    required this.bankId,
    required this.bankName,
    required this.accountName,
    required this.accountType,
    required this.initialBalanceRial,
    this.cardLastFour,
    this.description,
    required this.createdAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bank_id'] = Variable<String>(bankId);
    map['bank_name'] = Variable<String>(bankName);
    map['account_name'] = Variable<String>(accountName);
    {
      map['account_type'] = Variable<String>(
        $AccountsTable.$converteraccountType.toSql(accountType),
      );
    }
    map['initial_balance_rial'] = Variable<int>(initialBalanceRial);
    if (!nullToAbsent || cardLastFour != null) {
      map['card_last_four'] = Variable<String>(cardLastFour);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      bankId: Value(bankId),
      bankName: Value(bankName),
      accountName: Value(accountName),
      accountType: Value(accountType),
      initialBalanceRial: Value(initialBalanceRial),
      cardLastFour: cardLastFour == null && nullToAbsent
          ? const Value.absent()
          : Value(cardLastFour),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      bankId: serializer.fromJson<String>(json['bankId']),
      bankName: serializer.fromJson<String>(json['bankName']),
      accountName: serializer.fromJson<String>(json['accountName']),
      accountType: $AccountsTable.$converteraccountType.fromJson(
        serializer.fromJson<String>(json['accountType']),
      ),
      initialBalanceRial: serializer.fromJson<int>(json['initialBalanceRial']),
      cardLastFour: serializer.fromJson<String?>(json['cardLastFour']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bankId': serializer.toJson<String>(bankId),
      'bankName': serializer.toJson<String>(bankName),
      'accountName': serializer.toJson<String>(accountName),
      'accountType': serializer.toJson<String>(
        $AccountsTable.$converteraccountType.toJson(accountType),
      ),
      'initialBalanceRial': serializer.toJson<int>(initialBalanceRial),
      'cardLastFour': serializer.toJson<String?>(cardLastFour),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  AccountRow copyWith({
    String? id,
    String? bankId,
    String? bankName,
    String? accountName,
    AccountType? accountType,
    int? initialBalanceRial,
    Value<String?> cardLastFour = const Value.absent(),
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => AccountRow(
    id: id ?? this.id,
    bankId: bankId ?? this.bankId,
    bankName: bankName ?? this.bankName,
    accountName: accountName ?? this.accountName,
    accountType: accountType ?? this.accountType,
    initialBalanceRial: initialBalanceRial ?? this.initialBalanceRial,
    cardLastFour: cardLastFour.present ? cardLastFour.value : this.cardLastFour,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      initialBalanceRial: data.initialBalanceRial.present
          ? data.initialBalanceRial.value
          : this.initialBalanceRial,
      cardLastFour: data.cardLastFour.present
          ? data.cardLastFour.value
          : this.cardLastFour,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('bankName: $bankName, ')
          ..write('accountName: $accountName, ')
          ..write('accountType: $accountType, ')
          ..write('initialBalanceRial: $initialBalanceRial, ')
          ..write('cardLastFour: $cardLastFour, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankId,
    bankName,
    accountName,
    accountType,
    initialBalanceRial,
    cardLastFour,
    description,
    createdAt,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.bankId == this.bankId &&
          other.bankName == this.bankName &&
          other.accountName == this.accountName &&
          other.accountType == this.accountType &&
          other.initialBalanceRial == this.initialBalanceRial &&
          other.cardLastFour == this.cardLastFour &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String> bankId;
  final Value<String> bankName;
  final Value<String> accountName;
  final Value<AccountType> accountType;
  final Value<int> initialBalanceRial;
  final Value<String?> cardLastFour;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.bankId = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.initialBalanceRial = const Value.absent(),
    this.cardLastFour = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String bankId,
    required String bankName,
    required String accountName,
    required AccountType accountType,
    required int initialBalanceRial,
    this.cardLastFour = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bankId = Value(bankId),
       bankName = Value(bankName),
       accountName = Value(accountName),
       accountType = Value(accountType),
       initialBalanceRial = Value(initialBalanceRial),
       createdAt = Value(createdAt);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? bankId,
    Expression<String>? bankName,
    Expression<String>? accountName,
    Expression<String>? accountType,
    Expression<int>? initialBalanceRial,
    Expression<String>? cardLastFour,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankId != null) 'bank_id': bankId,
      if (bankName != null) 'bank_name': bankName,
      if (accountName != null) 'account_name': accountName,
      if (accountType != null) 'account_type': accountType,
      if (initialBalanceRial != null)
        'initial_balance_rial': initialBalanceRial,
      if (cardLastFour != null) 'card_last_four': cardLastFour,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? bankId,
    Value<String>? bankName,
    Value<String>? accountName,
    Value<AccountType>? accountType,
    Value<int>? initialBalanceRial,
    Value<String?>? cardLastFour,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      initialBalanceRial: initialBalanceRial ?? this.initialBalanceRial,
      cardLastFour: cardLastFour ?? this.cardLastFour,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(
        $AccountsTable.$converteraccountType.toSql(accountType.value),
      );
    }
    if (initialBalanceRial.present) {
      map['initial_balance_rial'] = Variable<int>(initialBalanceRial.value);
    }
    if (cardLastFour.present) {
      map['card_last_four'] = Variable<String>(cardLastFour.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('bankName: $bankName, ')
          ..write('accountName: $accountName, ')
          ..write('accountType: $accountType, ')
          ..write('initialBalanceRial: $initialBalanceRial, ')
          ..write('cardLastFour: $cardLastFour, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryType>($CategoriesTable.$convertertype);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    icon,
    colorHex,
    isDefault,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $CategoriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryType, String, String> $convertertype =
      const EnumNameConverter<CategoryType>(CategoryType.values);
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final CategoryType type;
  final String icon;
  final String colorHex;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorHex,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $CategoriesTable.$convertertype.toSql(type),
      );
    }
    map['icon'] = Variable<String>(icon);
    map['color_hex'] = Variable<String>(colorHex);
    map['is_default'] = Variable<bool>(isDefault);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      icon: Value(icon),
      colorHex: Value(colorHex),
      isDefault: Value(isDefault),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $CategoriesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      icon: serializer.fromJson<String>(json['icon']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $CategoriesTable.$convertertype.toJson(type),
      ),
      'icon': serializer.toJson<String>(icon),
      'colorHex': serializer.toJson<String>(colorHex),
      'isDefault': serializer.toJson<bool>(isDefault),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? icon,
    String? colorHex,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    icon: icon ?? this.icon,
    colorHex: colorHex ?? this.colorHex,
    isDefault: isDefault ?? this.isDefault,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      icon: data.icon.present ? data.icon.value : this.icon,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('colorHex: $colorHex, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    icon,
    colorHex,
    isDefault,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.icon == this.icon &&
          other.colorHex == this.colorHex &&
          other.isDefault == this.isDefault &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<CategoryType> type;
  final Value<String> icon;
  final Value<String> colorHex;
  final Value<bool> isDefault;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required CategoryType type,
    required String icon,
    required String colorHex,
    this.isDefault = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       icon = Value(icon),
       colorHex = Value(colorHex),
       createdAt = Value(createdAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? icon,
    Expression<String>? colorHex,
    Expression<bool>? isDefault,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
      if (colorHex != null) 'color_hex': colorHex,
      if (isDefault != null) 'is_default': isDefault,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<CategoryType>? type,
    Value<String>? icon,
    Value<String>? colorHex,
    Value<bool>? isDefault,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CategoriesTable.$convertertype.toSql(type.value),
      );
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('colorHex: $colorHex, ')
          ..write('isDefault: $isDefault, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($TransactionsTable.$convertertype);
  static const VerificationMeta _amountRialMeta = const VerificationMeta(
    'amountRial',
  );
  @override
  late final GeneratedColumn<int> amountRial = GeneratedColumn<int>(
    'amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amountRial,
    categoryId,
    accountId,
    transactionDate,
    description,
    operationId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount_rial')) {
      context.handle(
        _amountRialMeta,
        amountRial.isAcceptableOrUnknown(data['amount_rial']!, _amountRialMeta),
      );
    } else if (isInserting) {
      context.missing(_amountRialMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      amountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_rial'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, String, String> $convertertype =
      const EnumNameConverter<TransactionType>(TransactionType.values);
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final TransactionType type;
  final int amountRial;
  final String? categoryId;
  final String accountId;
  final DateTime transactionDate;
  final String? description;

  /// Idempotency key of the operation that created this row.
  final String operationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransactionRow({
    required this.id,
    required this.type,
    required this.amountRial,
    this.categoryId,
    required this.accountId,
    required this.transactionDate,
    this.description,
    required this.operationId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    map['amount_rial'] = Variable<int>(amountRial);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['account_id'] = Variable<String>(accountId);
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['operation_id'] = Variable<String>(operationId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amountRial: Value(amountRial),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: Value(accountId),
      transactionDate: Value(transactionDate),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      operationId: Value(operationId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      amountRial: serializer.fromJson<int>(json['amountRial']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      description: serializer.fromJson<String?>(json['description']),
      operationId: serializer.fromJson<String>(json['operationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'amountRial': serializer.toJson<int>(amountRial),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String>(accountId),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'description': serializer.toJson<String?>(description),
      'operationId': serializer.toJson<String>(operationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransactionRow copyWith({
    String? id,
    TransactionType? type,
    int? amountRial,
    Value<String?> categoryId = const Value.absent(),
    String? accountId,
    DateTime? transactionDate,
    Value<String?> description = const Value.absent(),
    String? operationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransactionRow(
    id: id ?? this.id,
    type: type ?? this.type,
    amountRial: amountRial ?? this.amountRial,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId ?? this.accountId,
    transactionDate: transactionDate ?? this.transactionDate,
    description: description.present ? description.value : this.description,
    operationId: operationId ?? this.operationId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amountRial: data.amountRial.present
          ? data.amountRial.value
          : this.amountRial,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      description: data.description.present
          ? data.description.value
          : this.description,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountRial: $amountRial, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('description: $description, ')
          ..write('operationId: $operationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amountRial,
    categoryId,
    accountId,
    transactionDate,
    description,
    operationId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.amountRial == this.amountRial &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.transactionDate == this.transactionDate &&
          other.description == this.description &&
          other.operationId == this.operationId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<TransactionType> type;
  final Value<int> amountRial;
  final Value<String?> categoryId;
  final Value<String> accountId;
  final Value<DateTime> transactionDate;
  final Value<String?> description;
  final Value<String> operationId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amountRial = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.description = const Value.absent(),
    this.operationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required TransactionType type,
    required int amountRial,
    this.categoryId = const Value.absent(),
    required String accountId,
    required DateTime transactionDate,
    this.description = const Value.absent(),
    required String operationId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       amountRial = Value(amountRial),
       accountId = Value(accountId),
       transactionDate = Value(transactionDate),
       operationId = Value(operationId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? amountRial,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<DateTime>? transactionDate,
    Expression<String>? description,
    Expression<String>? operationId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amountRial != null) 'amount_rial': amountRial,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (description != null) 'description': description,
      if (operationId != null) 'operation_id': operationId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<TransactionType>? type,
    Value<int>? amountRial,
    Value<String?>? categoryId,
    Value<String>? accountId,
    Value<DateTime>? transactionDate,
    Value<String?>? description,
    Value<String>? operationId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amountRial: amountRial ?? this.amountRial,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      operationId: operationId ?? this.operationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (amountRial.present) {
      map['amount_rial'] = Variable<int>(amountRial.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountRial: $amountRial, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('description: $description, ')
          ..write('operationId: $operationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, TransferRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceAccountIdMeta = const VerificationMeta(
    'sourceAccountId',
  );
  @override
  late final GeneratedColumn<String> sourceAccountId = GeneratedColumn<String>(
    'source_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<String> destinationAccountId =
      GeneratedColumn<String>(
        'destination_account_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id)',
        ),
      );
  static const VerificationMeta _amountRialMeta = const VerificationMeta(
    'amountRial',
  );
  @override
  late final GeneratedColumn<int> amountRial = GeneratedColumn<int>(
    'amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feeRialMeta = const VerificationMeta(
    'feeRial',
  );
  @override
  late final GeneratedColumn<int> feeRial = GeneratedColumn<int>(
    'fee_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transferDateMeta = const VerificationMeta(
    'transferDate',
  );
  @override
  late final GeneratedColumn<DateTime> transferDate = GeneratedColumn<DateTime>(
    'transfer_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceAccountId,
    destinationAccountId,
    amountRial,
    feeRial,
    transferDate,
    description,
    operationId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_account_id')) {
      context.handle(
        _sourceAccountIdMeta,
        sourceAccountId.isAcceptableOrUnknown(
          data['source_account_id']!,
          _sourceAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceAccountIdMeta);
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
        _destinationAccountIdMeta,
        destinationAccountId.isAcceptableOrUnknown(
          data['destination_account_id']!,
          _destinationAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationAccountIdMeta);
    }
    if (data.containsKey('amount_rial')) {
      context.handle(
        _amountRialMeta,
        amountRial.isAcceptableOrUnknown(data['amount_rial']!, _amountRialMeta),
      );
    } else if (isInserting) {
      context.missing(_amountRialMeta);
    }
    if (data.containsKey('fee_rial')) {
      context.handle(
        _feeRialMeta,
        feeRial.isAcceptableOrUnknown(data['fee_rial']!, _feeRialMeta),
      );
    }
    if (data.containsKey('transfer_date')) {
      context.handle(
        _transferDateMeta,
        transferDate.isAcceptableOrUnknown(
          data['transfer_date']!,
          _transferDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferDateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_account_id'],
      )!,
      destinationAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_account_id'],
      )!,
      amountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_rial'],
      )!,
      feeRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fee_rial'],
      )!,
      transferDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transfer_date'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }
}

class TransferRow extends DataClass implements Insertable<TransferRow> {
  final String id;
  final String sourceAccountId;
  final String destinationAccountId;
  final int amountRial;
  final int feeRial;
  final DateTime transferDate;
  final String? description;
  final String operationId;
  final DateTime createdAt;
  const TransferRow({
    required this.id,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountRial,
    required this.feeRial,
    required this.transferDate,
    this.description,
    required this.operationId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_account_id'] = Variable<String>(sourceAccountId);
    map['destination_account_id'] = Variable<String>(destinationAccountId);
    map['amount_rial'] = Variable<int>(amountRial);
    map['fee_rial'] = Variable<int>(feeRial);
    map['transfer_date'] = Variable<DateTime>(transferDate);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['operation_id'] = Variable<String>(operationId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      id: Value(id),
      sourceAccountId: Value(sourceAccountId),
      destinationAccountId: Value(destinationAccountId),
      amountRial: Value(amountRial),
      feeRial: Value(feeRial),
      transferDate: Value(transferDate),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      operationId: Value(operationId),
      createdAt: Value(createdAt),
    );
  }

  factory TransferRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferRow(
      id: serializer.fromJson<String>(json['id']),
      sourceAccountId: serializer.fromJson<String>(json['sourceAccountId']),
      destinationAccountId: serializer.fromJson<String>(
        json['destinationAccountId'],
      ),
      amountRial: serializer.fromJson<int>(json['amountRial']),
      feeRial: serializer.fromJson<int>(json['feeRial']),
      transferDate: serializer.fromJson<DateTime>(json['transferDate']),
      description: serializer.fromJson<String?>(json['description']),
      operationId: serializer.fromJson<String>(json['operationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceAccountId': serializer.toJson<String>(sourceAccountId),
      'destinationAccountId': serializer.toJson<String>(destinationAccountId),
      'amountRial': serializer.toJson<int>(amountRial),
      'feeRial': serializer.toJson<int>(feeRial),
      'transferDate': serializer.toJson<DateTime>(transferDate),
      'description': serializer.toJson<String?>(description),
      'operationId': serializer.toJson<String>(operationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransferRow copyWith({
    String? id,
    String? sourceAccountId,
    String? destinationAccountId,
    int? amountRial,
    int? feeRial,
    DateTime? transferDate,
    Value<String?> description = const Value.absent(),
    String? operationId,
    DateTime? createdAt,
  }) => TransferRow(
    id: id ?? this.id,
    sourceAccountId: sourceAccountId ?? this.sourceAccountId,
    destinationAccountId: destinationAccountId ?? this.destinationAccountId,
    amountRial: amountRial ?? this.amountRial,
    feeRial: feeRial ?? this.feeRial,
    transferDate: transferDate ?? this.transferDate,
    description: description.present ? description.value : this.description,
    operationId: operationId ?? this.operationId,
    createdAt: createdAt ?? this.createdAt,
  );
  TransferRow copyWithCompanion(TransfersCompanion data) {
    return TransferRow(
      id: data.id.present ? data.id.value : this.id,
      sourceAccountId: data.sourceAccountId.present
          ? data.sourceAccountId.value
          : this.sourceAccountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      amountRial: data.amountRial.present
          ? data.amountRial.value
          : this.amountRial,
      feeRial: data.feeRial.present ? data.feeRial.value : this.feeRial,
      transferDate: data.transferDate.present
          ? data.transferDate.value
          : this.transferDate,
      description: data.description.present
          ? data.description.value
          : this.description,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferRow(')
          ..write('id: $id, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('amountRial: $amountRial, ')
          ..write('feeRial: $feeRial, ')
          ..write('transferDate: $transferDate, ')
          ..write('description: $description, ')
          ..write('operationId: $operationId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceAccountId,
    destinationAccountId,
    amountRial,
    feeRial,
    transferDate,
    description,
    operationId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferRow &&
          other.id == this.id &&
          other.sourceAccountId == this.sourceAccountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.amountRial == this.amountRial &&
          other.feeRial == this.feeRial &&
          other.transferDate == this.transferDate &&
          other.description == this.description &&
          other.operationId == this.operationId &&
          other.createdAt == this.createdAt);
}

class TransfersCompanion extends UpdateCompanion<TransferRow> {
  final Value<String> id;
  final Value<String> sourceAccountId;
  final Value<String> destinationAccountId;
  final Value<int> amountRial;
  final Value<int> feeRial;
  final Value<DateTime> transferDate;
  final Value<String?> description;
  final Value<String> operationId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.amountRial = const Value.absent(),
    this.feeRial = const Value.absent(),
    this.transferDate = const Value.absent(),
    this.description = const Value.absent(),
    this.operationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransfersCompanion.insert({
    required String id,
    required String sourceAccountId,
    required String destinationAccountId,
    required int amountRial,
    this.feeRial = const Value.absent(),
    required DateTime transferDate,
    this.description = const Value.absent(),
    required String operationId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceAccountId = Value(sourceAccountId),
       destinationAccountId = Value(destinationAccountId),
       amountRial = Value(amountRial),
       transferDate = Value(transferDate),
       operationId = Value(operationId),
       createdAt = Value(createdAt);
  static Insertable<TransferRow> custom({
    Expression<String>? id,
    Expression<String>? sourceAccountId,
    Expression<String>? destinationAccountId,
    Expression<int>? amountRial,
    Expression<int>? feeRial,
    Expression<DateTime>? transferDate,
    Expression<String>? description,
    Expression<String>? operationId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceAccountId != null) 'source_account_id': sourceAccountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (amountRial != null) 'amount_rial': amountRial,
      if (feeRial != null) 'fee_rial': feeRial,
      if (transferDate != null) 'transfer_date': transferDate,
      if (description != null) 'description': description,
      if (operationId != null) 'operation_id': operationId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransfersCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceAccountId,
    Value<String>? destinationAccountId,
    Value<int>? amountRial,
    Value<int>? feeRial,
    Value<DateTime>? transferDate,
    Value<String?>? description,
    Value<String>? operationId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TransfersCompanion(
      id: id ?? this.id,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      amountRial: amountRial ?? this.amountRial,
      feeRial: feeRial ?? this.feeRial,
      transferDate: transferDate ?? this.transferDate,
      description: description ?? this.description,
      operationId: operationId ?? this.operationId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<String>(sourceAccountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] = Variable<String>(
        destinationAccountId.value,
      );
    }
    if (amountRial.present) {
      map['amount_rial'] = Variable<int>(amountRial.value);
    }
    if (feeRial.present) {
      map['fee_rial'] = Variable<int>(feeRial.value);
    }
    if (transferDate.present) {
      map['transfer_date'] = Variable<DateTime>(transferDate.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransfersCompanion(')
          ..write('id: $id, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('amountRial: $amountRial, ')
          ..write('feeRial: $feeRial, ')
          ..write('transferDate: $transferDate, ')
          ..write('description: $description, ')
          ..write('operationId: $operationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _deltaRialMeta = const VerificationMeta(
    'deltaRial',
  );
  @override
  late final GeneratedColumn<int> deltaRial = GeneratedColumn<int>(
    'delta_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryDateMeta = const VerificationMeta(
    'entryDate',
  );
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
    'entry_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LedgerSource, String> sourceType =
      GeneratedColumn<String>(
        'source_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LedgerSource>($LedgerEntriesTable.$convertersourceType);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    deltaRial,
    entryDate,
    sourceType,
    sourceId,
    operationId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('delta_rial')) {
      context.handle(
        _deltaRialMeta,
        deltaRial.isAcceptableOrUnknown(data['delta_rial']!, _deltaRialMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaRialMeta);
    }
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      deltaRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta_rial'],
      )!,
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entry_date'],
      )!,
      sourceType: $LedgerEntriesTable.$convertersourceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_type'],
        )!,
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LedgerSource, String, String> $convertersourceType =
      const EnumNameConverter<LedgerSource>(LedgerSource.values);
}

class LedgerEntryRow extends DataClass implements Insertable<LedgerEntryRow> {
  final int id;
  final String accountId;
  final int deltaRial;
  final DateTime entryDate;
  final LedgerSource sourceType;
  final String sourceId;
  final String operationId;
  final DateTime createdAt;
  const LedgerEntryRow({
    required this.id,
    required this.accountId,
    required this.deltaRial,
    required this.entryDate,
    required this.sourceType,
    required this.sourceId,
    required this.operationId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<String>(accountId);
    map['delta_rial'] = Variable<int>(deltaRial);
    map['entry_date'] = Variable<DateTime>(entryDate);
    {
      map['source_type'] = Variable<String>(
        $LedgerEntriesTable.$convertersourceType.toSql(sourceType),
      );
    }
    map['source_id'] = Variable<String>(sourceId);
    map['operation_id'] = Variable<String>(operationId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      deltaRial: Value(deltaRial),
      entryDate: Value(entryDate),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      operationId: Value(operationId),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntryRow(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      deltaRial: serializer.fromJson<int>(json['deltaRial']),
      entryDate: serializer.fromJson<DateTime>(json['entryDate']),
      sourceType: $LedgerEntriesTable.$convertersourceType.fromJson(
        serializer.fromJson<String>(json['sourceType']),
      ),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      operationId: serializer.fromJson<String>(json['operationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<String>(accountId),
      'deltaRial': serializer.toJson<int>(deltaRial),
      'entryDate': serializer.toJson<DateTime>(entryDate),
      'sourceType': serializer.toJson<String>(
        $LedgerEntriesTable.$convertersourceType.toJson(sourceType),
      ),
      'sourceId': serializer.toJson<String>(sourceId),
      'operationId': serializer.toJson<String>(operationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LedgerEntryRow copyWith({
    int? id,
    String? accountId,
    int? deltaRial,
    DateTime? entryDate,
    LedgerSource? sourceType,
    String? sourceId,
    String? operationId,
    DateTime? createdAt,
  }) => LedgerEntryRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    deltaRial: deltaRial ?? this.deltaRial,
    entryDate: entryDate ?? this.entryDate,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId ?? this.sourceId,
    operationId: operationId ?? this.operationId,
    createdAt: createdAt ?? this.createdAt,
  );
  LedgerEntryRow copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntryRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      deltaRial: data.deltaRial.present ? data.deltaRial.value : this.deltaRial,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntryRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('deltaRial: $deltaRial, ')
          ..write('entryDate: $entryDate, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('operationId: $operationId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    deltaRial,
    entryDate,
    sourceType,
    sourceId,
    operationId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntryRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.deltaRial == this.deltaRial &&
          other.entryDate == this.entryDate &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.operationId == this.operationId &&
          other.createdAt == this.createdAt);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntryRow> {
  final Value<int> id;
  final Value<String> accountId;
  final Value<int> deltaRial;
  final Value<DateTime> entryDate;
  final Value<LedgerSource> sourceType;
  final Value<String> sourceId;
  final Value<String> operationId;
  final Value<DateTime> createdAt;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.deltaRial = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.operationId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    required int deltaRial,
    required DateTime entryDate,
    required LedgerSource sourceType,
    required String sourceId,
    required String operationId,
    required DateTime createdAt,
  }) : accountId = Value(accountId),
       deltaRial = Value(deltaRial),
       entryDate = Value(entryDate),
       sourceType = Value(sourceType),
       sourceId = Value(sourceId),
       operationId = Value(operationId),
       createdAt = Value(createdAt);
  static Insertable<LedgerEntryRow> custom({
    Expression<int>? id,
    Expression<String>? accountId,
    Expression<int>? deltaRial,
    Expression<DateTime>? entryDate,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? operationId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (deltaRial != null) 'delta_rial': deltaRial,
      if (entryDate != null) 'entry_date': entryDate,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (operationId != null) 'operation_id': operationId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? accountId,
    Value<int>? deltaRial,
    Value<DateTime>? entryDate,
    Value<LedgerSource>? sourceType,
    Value<String>? sourceId,
    Value<String>? operationId,
    Value<DateTime>? createdAt,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      deltaRial: deltaRial ?? this.deltaRial,
      entryDate: entryDate ?? this.entryDate,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      operationId: operationId ?? this.operationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (deltaRial.present) {
      map['delta_rial'] = Variable<int>(deltaRial.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(
        $LedgerEntriesTable.$convertersourceType.toSql(sourceType.value),
      );
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('deltaRial: $deltaRial, ')
          ..write('entryDate: $entryDate, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('operationId: $operationId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, LoanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalAmountRialMeta =
      const VerificationMeta('principalAmountRial');
  @override
  late final GeneratedColumn<int> principalAmountRial = GeneratedColumn<int>(
    'principal_amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interestAmountRialMeta =
      const VerificationMeta('interestAmountRial');
  @override
  late final GeneratedColumn<int> interestAmountRial = GeneratedColumn<int>(
    'interest_amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _installmentCountMeta = const VerificationMeta(
    'installmentCount',
  );
  @override
  late final GeneratedColumn<int> installmentCount = GeneratedColumn<int>(
    'installment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installmentAmountRialMeta =
      const VerificationMeta('installmentAmountRial');
  @override
  late final GeneratedColumn<int> installmentAmountRial = GeneratedColumn<int>(
    'installment_amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LoanStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LoanStatus>($LoansTable.$converterstatus);
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    principalAmountRial,
    interestAmountRial,
    installmentCount,
    installmentAmountRial,
    accountId,
    startDate,
    status,
    description,
    operationId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('principal_amount_rial')) {
      context.handle(
        _principalAmountRialMeta,
        principalAmountRial.isAcceptableOrUnknown(
          data['principal_amount_rial']!,
          _principalAmountRialMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_principalAmountRialMeta);
    }
    if (data.containsKey('interest_amount_rial')) {
      context.handle(
        _interestAmountRialMeta,
        interestAmountRial.isAcceptableOrUnknown(
          data['interest_amount_rial']!,
          _interestAmountRialMeta,
        ),
      );
    }
    if (data.containsKey('installment_count')) {
      context.handle(
        _installmentCountMeta,
        installmentCount.isAcceptableOrUnknown(
          data['installment_count']!,
          _installmentCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentCountMeta);
    }
    if (data.containsKey('installment_amount_rial')) {
      context.handle(
        _installmentAmountRialMeta,
        installmentAmountRial.isAcceptableOrUnknown(
          data['installment_amount_rial']!,
          _installmentAmountRialMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentAmountRialMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      principalAmountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal_amount_rial'],
      )!,
      interestAmountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interest_amount_rial'],
      )!,
      installmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_count'],
      )!,
      installmentAmountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_amount_rial'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      status: $LoansTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LoanStatus, String, String> $converterstatus =
      const EnumNameConverter<LoanStatus>(LoanStatus.values);
}

class LoanRow extends DataClass implements Insertable<LoanRow> {
  final String id;
  final String title;
  final int principalAmountRial;
  final int interestAmountRial;
  final int installmentCount;
  final int installmentAmountRial;
  final String? accountId;
  final DateTime startDate;
  final LoanStatus status;
  final String? description;
  final String operationId;
  final DateTime createdAt;
  const LoanRow({
    required this.id,
    required this.title,
    required this.principalAmountRial,
    required this.interestAmountRial,
    required this.installmentCount,
    required this.installmentAmountRial,
    this.accountId,
    required this.startDate,
    required this.status,
    this.description,
    required this.operationId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['principal_amount_rial'] = Variable<int>(principalAmountRial);
    map['interest_amount_rial'] = Variable<int>(interestAmountRial);
    map['installment_count'] = Variable<int>(installmentCount);
    map['installment_amount_rial'] = Variable<int>(installmentAmountRial);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    {
      map['status'] = Variable<String>(
        $LoansTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['operation_id'] = Variable<String>(operationId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      title: Value(title),
      principalAmountRial: Value(principalAmountRial),
      interestAmountRial: Value(interestAmountRial),
      installmentCount: Value(installmentCount),
      installmentAmountRial: Value(installmentAmountRial),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      startDate: Value(startDate),
      status: Value(status),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      operationId: Value(operationId),
      createdAt: Value(createdAt),
    );
  }

  factory LoanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoanRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      principalAmountRial: serializer.fromJson<int>(
        json['principalAmountRial'],
      ),
      interestAmountRial: serializer.fromJson<int>(json['interestAmountRial']),
      installmentCount: serializer.fromJson<int>(json['installmentCount']),
      installmentAmountRial: serializer.fromJson<int>(
        json['installmentAmountRial'],
      ),
      accountId: serializer.fromJson<String?>(json['accountId']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      status: $LoansTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      description: serializer.fromJson<String?>(json['description']),
      operationId: serializer.fromJson<String>(json['operationId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'principalAmountRial': serializer.toJson<int>(principalAmountRial),
      'interestAmountRial': serializer.toJson<int>(interestAmountRial),
      'installmentCount': serializer.toJson<int>(installmentCount),
      'installmentAmountRial': serializer.toJson<int>(installmentAmountRial),
      'accountId': serializer.toJson<String?>(accountId),
      'startDate': serializer.toJson<DateTime>(startDate),
      'status': serializer.toJson<String>(
        $LoansTable.$converterstatus.toJson(status),
      ),
      'description': serializer.toJson<String?>(description),
      'operationId': serializer.toJson<String>(operationId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LoanRow copyWith({
    String? id,
    String? title,
    int? principalAmountRial,
    int? interestAmountRial,
    int? installmentCount,
    int? installmentAmountRial,
    Value<String?> accountId = const Value.absent(),
    DateTime? startDate,
    LoanStatus? status,
    Value<String?> description = const Value.absent(),
    String? operationId,
    DateTime? createdAt,
  }) => LoanRow(
    id: id ?? this.id,
    title: title ?? this.title,
    principalAmountRial: principalAmountRial ?? this.principalAmountRial,
    interestAmountRial: interestAmountRial ?? this.interestAmountRial,
    installmentCount: installmentCount ?? this.installmentCount,
    installmentAmountRial: installmentAmountRial ?? this.installmentAmountRial,
    accountId: accountId.present ? accountId.value : this.accountId,
    startDate: startDate ?? this.startDate,
    status: status ?? this.status,
    description: description.present ? description.value : this.description,
    operationId: operationId ?? this.operationId,
    createdAt: createdAt ?? this.createdAt,
  );
  LoanRow copyWithCompanion(LoansCompanion data) {
    return LoanRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      principalAmountRial: data.principalAmountRial.present
          ? data.principalAmountRial.value
          : this.principalAmountRial,
      interestAmountRial: data.interestAmountRial.present
          ? data.interestAmountRial.value
          : this.interestAmountRial,
      installmentCount: data.installmentCount.present
          ? data.installmentCount.value
          : this.installmentCount,
      installmentAmountRial: data.installmentAmountRial.present
          ? data.installmentAmountRial.value
          : this.installmentAmountRial,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      status: data.status.present ? data.status.value : this.status,
      description: data.description.present
          ? data.description.value
          : this.description,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoanRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('principalAmountRial: $principalAmountRial, ')
          ..write('interestAmountRial: $interestAmountRial, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('installmentAmountRial: $installmentAmountRial, ')
          ..write('accountId: $accountId, ')
          ..write('startDate: $startDate, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('operationId: $operationId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    principalAmountRial,
    interestAmountRial,
    installmentCount,
    installmentAmountRial,
    accountId,
    startDate,
    status,
    description,
    operationId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoanRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.principalAmountRial == this.principalAmountRial &&
          other.interestAmountRial == this.interestAmountRial &&
          other.installmentCount == this.installmentCount &&
          other.installmentAmountRial == this.installmentAmountRial &&
          other.accountId == this.accountId &&
          other.startDate == this.startDate &&
          other.status == this.status &&
          other.description == this.description &&
          other.operationId == this.operationId &&
          other.createdAt == this.createdAt);
}

class LoansCompanion extends UpdateCompanion<LoanRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> principalAmountRial;
  final Value<int> interestAmountRial;
  final Value<int> installmentCount;
  final Value<int> installmentAmountRial;
  final Value<String?> accountId;
  final Value<DateTime> startDate;
  final Value<LoanStatus> status;
  final Value<String?> description;
  final Value<String> operationId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.principalAmountRial = const Value.absent(),
    this.interestAmountRial = const Value.absent(),
    this.installmentCount = const Value.absent(),
    this.installmentAmountRial = const Value.absent(),
    this.accountId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.status = const Value.absent(),
    this.description = const Value.absent(),
    this.operationId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoansCompanion.insert({
    required String id,
    required String title,
    required int principalAmountRial,
    this.interestAmountRial = const Value.absent(),
    required int installmentCount,
    required int installmentAmountRial,
    this.accountId = const Value.absent(),
    required DateTime startDate,
    required LoanStatus status,
    this.description = const Value.absent(),
    required String operationId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       principalAmountRial = Value(principalAmountRial),
       installmentCount = Value(installmentCount),
       installmentAmountRial = Value(installmentAmountRial),
       startDate = Value(startDate),
       status = Value(status),
       operationId = Value(operationId),
       createdAt = Value(createdAt);
  static Insertable<LoanRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? principalAmountRial,
    Expression<int>? interestAmountRial,
    Expression<int>? installmentCount,
    Expression<int>? installmentAmountRial,
    Expression<String>? accountId,
    Expression<DateTime>? startDate,
    Expression<String>? status,
    Expression<String>? description,
    Expression<String>? operationId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (principalAmountRial != null)
        'principal_amount_rial': principalAmountRial,
      if (interestAmountRial != null)
        'interest_amount_rial': interestAmountRial,
      if (installmentCount != null) 'installment_count': installmentCount,
      if (installmentAmountRial != null)
        'installment_amount_rial': installmentAmountRial,
      if (accountId != null) 'account_id': accountId,
      if (startDate != null) 'start_date': startDate,
      if (status != null) 'status': status,
      if (description != null) 'description': description,
      if (operationId != null) 'operation_id': operationId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoansCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? principalAmountRial,
    Value<int>? interestAmountRial,
    Value<int>? installmentCount,
    Value<int>? installmentAmountRial,
    Value<String?>? accountId,
    Value<DateTime>? startDate,
    Value<LoanStatus>? status,
    Value<String?>? description,
    Value<String>? operationId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LoansCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      principalAmountRial: principalAmountRial ?? this.principalAmountRial,
      interestAmountRial: interestAmountRial ?? this.interestAmountRial,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentAmountRial:
          installmentAmountRial ?? this.installmentAmountRial,
      accountId: accountId ?? this.accountId,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      description: description ?? this.description,
      operationId: operationId ?? this.operationId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (principalAmountRial.present) {
      map['principal_amount_rial'] = Variable<int>(principalAmountRial.value);
    }
    if (interestAmountRial.present) {
      map['interest_amount_rial'] = Variable<int>(interestAmountRial.value);
    }
    if (installmentCount.present) {
      map['installment_count'] = Variable<int>(installmentCount.value);
    }
    if (installmentAmountRial.present) {
      map['installment_amount_rial'] = Variable<int>(
        installmentAmountRial.value,
      );
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $LoansTable.$converterstatus.toSql(status.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('principalAmountRial: $principalAmountRial, ')
          ..write('interestAmountRial: $interestAmountRial, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('installmentAmountRial: $installmentAmountRial, ')
          ..write('accountId: $accountId, ')
          ..write('startDate: $startDate, ')
          ..write('status: $status, ')
          ..write('description: $description, ')
          ..write('operationId: $operationId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallmentsTable extends Installments
    with TableInfo<$InstallmentsTable, InstallmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<String> loanId = GeneratedColumn<String>(
    'loan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES loans (id)',
    ),
  );
  static const VerificationMeta _installmentNumberMeta = const VerificationMeta(
    'installmentNumber',
  );
  @override
  late final GeneratedColumn<int> installmentNumber = GeneratedColumn<int>(
    'installment_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountRialMeta = const VerificationMeta(
    'amountRial',
  );
  @override
  late final GeneratedColumn<int> amountRial = GeneratedColumn<int>(
    'amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalRialMeta = const VerificationMeta(
    'principalRial',
  );
  @override
  late final GeneratedColumn<int> principalRial = GeneratedColumn<int>(
    'principal_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interestRialMeta = const VerificationMeta(
    'interestRial',
  );
  @override
  late final GeneratedColumn<int> interestRial = GeneratedColumn<int>(
    'interest_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<InstallmentStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<InstallmentStatus>($InstallmentsTable.$converterstatus);
  static const VerificationMeta _paidAmountRialMeta = const VerificationMeta(
    'paidAmountRial',
  );
  @override
  late final GeneratedColumn<int> paidAmountRial = GeneratedColumn<int>(
    'paid_amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loanId,
    installmentNumber,
    dueDate,
    amountRial,
    principalRial,
    interestRial,
    status,
    paidAmountRial,
    paidAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('loan_id')) {
      context.handle(
        _loanIdMeta,
        loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_loanIdMeta);
    }
    if (data.containsKey('installment_number')) {
      context.handle(
        _installmentNumberMeta,
        installmentNumber.isAcceptableOrUnknown(
          data['installment_number']!,
          _installmentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentNumberMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('amount_rial')) {
      context.handle(
        _amountRialMeta,
        amountRial.isAcceptableOrUnknown(data['amount_rial']!, _amountRialMeta),
      );
    } else if (isInserting) {
      context.missing(_amountRialMeta);
    }
    if (data.containsKey('principal_rial')) {
      context.handle(
        _principalRialMeta,
        principalRial.isAcceptableOrUnknown(
          data['principal_rial']!,
          _principalRialMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_principalRialMeta);
    }
    if (data.containsKey('interest_rial')) {
      context.handle(
        _interestRialMeta,
        interestRial.isAcceptableOrUnknown(
          data['interest_rial']!,
          _interestRialMeta,
        ),
      );
    }
    if (data.containsKey('paid_amount_rial')) {
      context.handle(
        _paidAmountRialMeta,
        paidAmountRial.isAcceptableOrUnknown(
          data['paid_amount_rial']!,
          _paidAmountRialMeta,
        ),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstallmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      loanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loan_id'],
      )!,
      installmentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_number'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      amountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_rial'],
      )!,
      principalRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal_rial'],
      )!,
      interestRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interest_rial'],
      )!,
      status: $InstallmentsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      paidAmountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_amount_rial'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $InstallmentsTable createAlias(String alias) {
    return $InstallmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<InstallmentStatus, String, String>
  $converterstatus = const EnumNameConverter<InstallmentStatus>(
    InstallmentStatus.values,
  );
}

class InstallmentRow extends DataClass implements Insertable<InstallmentRow> {
  final String id;
  final String loanId;
  final int installmentNumber;
  final DateTime dueDate;
  final int amountRial;
  final int principalRial;
  final int interestRial;
  final InstallmentStatus status;
  final int paidAmountRial;
  final DateTime? paidAt;
  final DateTime createdAt;
  const InstallmentRow({
    required this.id,
    required this.loanId,
    required this.installmentNumber,
    required this.dueDate,
    required this.amountRial,
    required this.principalRial,
    required this.interestRial,
    required this.status,
    required this.paidAmountRial,
    this.paidAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['loan_id'] = Variable<String>(loanId);
    map['installment_number'] = Variable<int>(installmentNumber);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['amount_rial'] = Variable<int>(amountRial);
    map['principal_rial'] = Variable<int>(principalRial);
    map['interest_rial'] = Variable<int>(interestRial);
    {
      map['status'] = Variable<String>(
        $InstallmentsTable.$converterstatus.toSql(status),
      );
    }
    map['paid_amount_rial'] = Variable<int>(paidAmountRial);
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InstallmentsCompanion toCompanion(bool nullToAbsent) {
    return InstallmentsCompanion(
      id: Value(id),
      loanId: Value(loanId),
      installmentNumber: Value(installmentNumber),
      dueDate: Value(dueDate),
      amountRial: Value(amountRial),
      principalRial: Value(principalRial),
      interestRial: Value(interestRial),
      status: Value(status),
      paidAmountRial: Value(paidAmountRial),
      paidAt: paidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAt),
      createdAt: Value(createdAt),
    );
  }

  factory InstallmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentRow(
      id: serializer.fromJson<String>(json['id']),
      loanId: serializer.fromJson<String>(json['loanId']),
      installmentNumber: serializer.fromJson<int>(json['installmentNumber']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      amountRial: serializer.fromJson<int>(json['amountRial']),
      principalRial: serializer.fromJson<int>(json['principalRial']),
      interestRial: serializer.fromJson<int>(json['interestRial']),
      status: $InstallmentsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      paidAmountRial: serializer.fromJson<int>(json['paidAmountRial']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'loanId': serializer.toJson<String>(loanId),
      'installmentNumber': serializer.toJson<int>(installmentNumber),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'amountRial': serializer.toJson<int>(amountRial),
      'principalRial': serializer.toJson<int>(principalRial),
      'interestRial': serializer.toJson<int>(interestRial),
      'status': serializer.toJson<String>(
        $InstallmentsTable.$converterstatus.toJson(status),
      ),
      'paidAmountRial': serializer.toJson<int>(paidAmountRial),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InstallmentRow copyWith({
    String? id,
    String? loanId,
    int? installmentNumber,
    DateTime? dueDate,
    int? amountRial,
    int? principalRial,
    int? interestRial,
    InstallmentStatus? status,
    int? paidAmountRial,
    Value<DateTime?> paidAt = const Value.absent(),
    DateTime? createdAt,
  }) => InstallmentRow(
    id: id ?? this.id,
    loanId: loanId ?? this.loanId,
    installmentNumber: installmentNumber ?? this.installmentNumber,
    dueDate: dueDate ?? this.dueDate,
    amountRial: amountRial ?? this.amountRial,
    principalRial: principalRial ?? this.principalRial,
    interestRial: interestRial ?? this.interestRial,
    status: status ?? this.status,
    paidAmountRial: paidAmountRial ?? this.paidAmountRial,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
    createdAt: createdAt ?? this.createdAt,
  );
  InstallmentRow copyWithCompanion(InstallmentsCompanion data) {
    return InstallmentRow(
      id: data.id.present ? data.id.value : this.id,
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      installmentNumber: data.installmentNumber.present
          ? data.installmentNumber.value
          : this.installmentNumber,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      amountRial: data.amountRial.present
          ? data.amountRial.value
          : this.amountRial,
      principalRial: data.principalRial.present
          ? data.principalRial.value
          : this.principalRial,
      interestRial: data.interestRial.present
          ? data.interestRial.value
          : this.interestRial,
      status: data.status.present ? data.status.value : this.status,
      paidAmountRial: data.paidAmountRial.present
          ? data.paidAmountRial.value
          : this.paidAmountRial,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentRow(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('installmentNumber: $installmentNumber, ')
          ..write('dueDate: $dueDate, ')
          ..write('amountRial: $amountRial, ')
          ..write('principalRial: $principalRial, ')
          ..write('interestRial: $interestRial, ')
          ..write('status: $status, ')
          ..write('paidAmountRial: $paidAmountRial, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    loanId,
    installmentNumber,
    dueDate,
    amountRial,
    principalRial,
    interestRial,
    status,
    paidAmountRial,
    paidAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentRow &&
          other.id == this.id &&
          other.loanId == this.loanId &&
          other.installmentNumber == this.installmentNumber &&
          other.dueDate == this.dueDate &&
          other.amountRial == this.amountRial &&
          other.principalRial == this.principalRial &&
          other.interestRial == this.interestRial &&
          other.status == this.status &&
          other.paidAmountRial == this.paidAmountRial &&
          other.paidAt == this.paidAt &&
          other.createdAt == this.createdAt);
}

class InstallmentsCompanion extends UpdateCompanion<InstallmentRow> {
  final Value<String> id;
  final Value<String> loanId;
  final Value<int> installmentNumber;
  final Value<DateTime> dueDate;
  final Value<int> amountRial;
  final Value<int> principalRial;
  final Value<int> interestRial;
  final Value<InstallmentStatus> status;
  final Value<int> paidAmountRial;
  final Value<DateTime?> paidAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InstallmentsCompanion({
    this.id = const Value.absent(),
    this.loanId = const Value.absent(),
    this.installmentNumber = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.amountRial = const Value.absent(),
    this.principalRial = const Value.absent(),
    this.interestRial = const Value.absent(),
    this.status = const Value.absent(),
    this.paidAmountRial = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstallmentsCompanion.insert({
    required String id,
    required String loanId,
    required int installmentNumber,
    required DateTime dueDate,
    required int amountRial,
    required int principalRial,
    this.interestRial = const Value.absent(),
    required InstallmentStatus status,
    this.paidAmountRial = const Value.absent(),
    this.paidAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       loanId = Value(loanId),
       installmentNumber = Value(installmentNumber),
       dueDate = Value(dueDate),
       amountRial = Value(amountRial),
       principalRial = Value(principalRial),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<InstallmentRow> custom({
    Expression<String>? id,
    Expression<String>? loanId,
    Expression<int>? installmentNumber,
    Expression<DateTime>? dueDate,
    Expression<int>? amountRial,
    Expression<int>? principalRial,
    Expression<int>? interestRial,
    Expression<String>? status,
    Expression<int>? paidAmountRial,
    Expression<DateTime>? paidAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loanId != null) 'loan_id': loanId,
      if (installmentNumber != null) 'installment_number': installmentNumber,
      if (dueDate != null) 'due_date': dueDate,
      if (amountRial != null) 'amount_rial': amountRial,
      if (principalRial != null) 'principal_rial': principalRial,
      if (interestRial != null) 'interest_rial': interestRial,
      if (status != null) 'status': status,
      if (paidAmountRial != null) 'paid_amount_rial': paidAmountRial,
      if (paidAt != null) 'paid_at': paidAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstallmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? loanId,
    Value<int>? installmentNumber,
    Value<DateTime>? dueDate,
    Value<int>? amountRial,
    Value<int>? principalRial,
    Value<int>? interestRial,
    Value<InstallmentStatus>? status,
    Value<int>? paidAmountRial,
    Value<DateTime?>? paidAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return InstallmentsCompanion(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      dueDate: dueDate ?? this.dueDate,
      amountRial: amountRial ?? this.amountRial,
      principalRial: principalRial ?? this.principalRial,
      interestRial: interestRial ?? this.interestRial,
      status: status ?? this.status,
      paidAmountRial: paidAmountRial ?? this.paidAmountRial,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (loanId.present) {
      map['loan_id'] = Variable<String>(loanId.value);
    }
    if (installmentNumber.present) {
      map['installment_number'] = Variable<int>(installmentNumber.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (amountRial.present) {
      map['amount_rial'] = Variable<int>(amountRial.value);
    }
    if (principalRial.present) {
      map['principal_rial'] = Variable<int>(principalRial.value);
    }
    if (interestRial.present) {
      map['interest_rial'] = Variable<int>(interestRial.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $InstallmentsTable.$converterstatus.toSql(status.value),
      );
    }
    if (paidAmountRial.present) {
      map['paid_amount_rial'] = Variable<int>(paidAmountRial.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentsCompanion(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('installmentNumber: $installmentNumber, ')
          ..write('dueDate: $dueDate, ')
          ..write('amountRial: $amountRial, ')
          ..write('principalRial: $principalRial, ')
          ..write('interestRial: $interestRial, ')
          ..write('status: $status, ')
          ..write('paidAmountRial: $paidAmountRial, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatSessionsTable extends ChatSessions
    with TableInfo<$ChatSessionsTable, ChatSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChatSessionsTable createAlias(String alias) {
    return $ChatSessionsTable(attachedDatabase, alias);
  }
}

class ChatSessionRow extends DataClass implements Insertable<ChatSessionRow> {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChatSessionRow({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChatSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChatSessionsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChatSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSessionRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChatSessionRow copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChatSessionRow(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChatSessionRow copyWithCompanion(ChatSessionsCompanion data) {
    return ChatSessionRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSessionRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSessionRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChatSessionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ChatSessionRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChatSessionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chat_sessions (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChatRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ChatRole>($ChatMessagesTable.$converterrole);
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChatMessageType, String>
  messageType = GeneratedColumn<String>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ChatMessageType>($ChatMessagesTable.$convertermessageType);
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    role,
    content,
    messageType,
    metadataJson,
    sequence,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      role: $ChatMessagesTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      messageType: $ChatMessagesTable.$convertermessageType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}message_type'],
        )!,
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChatRole, String, String> $converterrole =
      const EnumNameConverter<ChatRole>(ChatRole.values);
  static JsonTypeConverter2<ChatMessageType, String, String>
  $convertermessageType = const EnumNameConverter<ChatMessageType>(
    ChatMessageType.values,
  );
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  final String id;
  final String sessionId;
  final ChatRole role;
  final String content;
  final ChatMessageType messageType;
  final String metadataJson;

  /// Monotonic per-session ordering. SQLite/Dart timestamps are not precise
  /// enough to order rapid assistant/user messages deterministically.
  final int sequence;
  final DateTime createdAt;
  const ChatMessageRow({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.messageType,
    required this.metadataJson,
    required this.sequence,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    {
      map['role'] = Variable<String>(
        $ChatMessagesTable.$converterrole.toSql(role),
      );
    }
    map['content'] = Variable<String>(content);
    {
      map['message_type'] = Variable<String>(
        $ChatMessagesTable.$convertermessageType.toSql(messageType),
      );
    }
    map['metadata_json'] = Variable<String>(metadataJson);
    map['sequence'] = Variable<int>(sequence);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      role: Value(role),
      content: Value(content),
      messageType: Value(messageType),
      metadataJson: Value(metadataJson),
      sequence: Value(sequence),
      createdAt: Value(createdAt),
    );
  }

  factory ChatMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      role: $ChatMessagesTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      content: serializer.fromJson<String>(json['content']),
      messageType: $ChatMessagesTable.$convertermessageType.fromJson(
        serializer.fromJson<String>(json['messageType']),
      ),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      sequence: serializer.fromJson<int>(json['sequence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'role': serializer.toJson<String>(
        $ChatMessagesTable.$converterrole.toJson(role),
      ),
      'content': serializer.toJson<String>(content),
      'messageType': serializer.toJson<String>(
        $ChatMessagesTable.$convertermessageType.toJson(messageType),
      ),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'sequence': serializer.toJson<int>(sequence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatMessageRow copyWith({
    String? id,
    String? sessionId,
    ChatRole? role,
    String? content,
    ChatMessageType? messageType,
    String? metadataJson,
    int? sequence,
    DateTime? createdAt,
  }) => ChatMessageRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    role: role ?? this.role,
    content: content ?? this.content,
    messageType: messageType ?? this.messageType,
    metadataJson: metadataJson ?? this.metadataJson,
    sequence: sequence ?? this.sequence,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatMessageRow copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      messageType: data.messageType.present
          ? data.messageType.value
          : this.messageType,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('sequence: $sequence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    role,
    content,
    messageType,
    metadataJson,
    sequence,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.messageType == this.messageType &&
          other.metadataJson == this.metadataJson &&
          other.sequence == this.sequence &&
          other.createdAt == this.createdAt);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<ChatRole> role;
  final Value<String> content;
  final Value<ChatMessageType> messageType;
  final Value<String> metadataJson;
  final Value<int> sequence;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.messageType = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.sequence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required String sessionId,
    required ChatRole role,
    required String content,
    required ChatMessageType messageType,
    this.metadataJson = const Value.absent(),
    this.sequence = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       role = Value(role),
       content = Value(content),
       messageType = Value(messageType),
       createdAt = Value(createdAt);
  static Insertable<ChatMessageRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? messageType,
    Expression<String>? metadataJson,
    Expression<int>? sequence,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (messageType != null) 'message_type': messageType,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (sequence != null) 'sequence': sequence,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<ChatRole>? role,
    Value<String>? content,
    Value<ChatMessageType>? messageType,
    Value<String>? metadataJson,
    Value<int>? sequence,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      metadataJson: metadataJson ?? this.metadataJson,
      sequence: sequence ?? this.sequence,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $ChatMessagesTable.$converterrole.toSql(role.value),
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(
        $ChatMessagesTable.$convertermessageType.toSql(messageType.value),
      );
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('sequence: $sequence, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingActionsTable extends PendingActions
    with TableInfo<$PendingActionsTable, PendingActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chat_sessions (id)',
    ),
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PendingActionStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PendingActionStatus>($PendingActionsTable.$converterstatus);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    messageId,
    actionType,
    payloadJson,
    status,
    operationId,
    errorMessage,
    createdAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingActionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingActionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      ),
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: $PendingActionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $PendingActionsTable createAlias(String alias) {
    return $PendingActionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PendingActionStatus, String, String>
  $converterstatus = const EnumNameConverter<PendingActionStatus>(
    PendingActionStatus.values,
  );
}

class PendingActionRow extends DataClass
    implements Insertable<PendingActionRow> {
  final String id;
  final String sessionId;
  final String? messageId;
  final String actionType;
  final String payloadJson;
  final PendingActionStatus status;
  final String operationId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  const PendingActionRow({
    required this.id,
    required this.sessionId,
    this.messageId,
    required this.actionType,
    required this.payloadJson,
    required this.status,
    required this.operationId,
    this.errorMessage,
    required this.createdAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['action_type'] = Variable<String>(actionType);
    map['payload_json'] = Variable<String>(payloadJson);
    {
      map['status'] = Variable<String>(
        $PendingActionsTable.$converterstatus.toSql(status),
      );
    }
    map['operation_id'] = Variable<String>(operationId);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  PendingActionsCompanion toCompanion(bool nullToAbsent) {
    return PendingActionsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      actionType: Value(actionType),
      payloadJson: Value(payloadJson),
      status: Value(status),
      operationId: Value(operationId),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory PendingActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingActionRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: $PendingActionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      operationId: serializer.fromJson<String>(json['operationId']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'messageId': serializer.toJson<String?>(messageId),
      'actionType': serializer.toJson<String>(actionType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(
        $PendingActionsTable.$converterstatus.toJson(status),
      ),
      'operationId': serializer.toJson<String>(operationId),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  PendingActionRow copyWith({
    String? id,
    String? sessionId,
    Value<String?> messageId = const Value.absent(),
    String? actionType,
    String? payloadJson,
    PendingActionStatus? status,
    String? operationId,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => PendingActionRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    messageId: messageId.present ? messageId.value : this.messageId,
    actionType: actionType ?? this.actionType,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    operationId: operationId ?? this.operationId,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  PendingActionRow copyWithCompanion(PendingActionsCompanion data) {
    return PendingActionRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('actionType: $actionType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('operationId: $operationId, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    messageId,
    actionType,
    payloadJson,
    status,
    operationId,
    errorMessage,
    createdAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingActionRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.messageId == this.messageId &&
          other.actionType == this.actionType &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.operationId == this.operationId &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt);
}

class PendingActionsCompanion extends UpdateCompanion<PendingActionRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String?> messageId;
  final Value<String> actionType;
  final Value<String> payloadJson;
  final Value<PendingActionStatus> status;
  final Value<String> operationId;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const PendingActionsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.operationId = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingActionsCompanion.insert({
    required String id,
    required String sessionId,
    this.messageId = const Value.absent(),
    required String actionType,
    required String payloadJson,
    required PendingActionStatus status,
    required String operationId,
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       actionType = Value(actionType),
       payloadJson = Value(payloadJson),
       status = Value(status),
       operationId = Value(operationId),
       createdAt = Value(createdAt);
  static Insertable<PendingActionRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? messageId,
    Expression<String>? actionType,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<String>? operationId,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (messageId != null) 'message_id': messageId,
      if (actionType != null) 'action_type': actionType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (operationId != null) 'operation_id': operationId,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingActionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String?>? messageId,
    Value<String>? actionType,
    Value<String>? payloadJson,
    Value<PendingActionStatus>? status,
    Value<String>? operationId,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return PendingActionsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      messageId: messageId ?? this.messageId,
      actionType: actionType ?? this.actionType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      operationId: operationId ?? this.operationId,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PendingActionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('messageId: $messageId, ')
          ..write('actionType: $actionType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('operationId: $operationId, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinancialOperationsTable extends FinancialOperations
    with TableInfo<$FinancialOperationsTable, FinancialOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FinancialOperationKind, String>
  kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FinancialOperationKind>(
        $FinancialOperationsTable.$converterkind,
      );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('applied'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _undoneAtMeta = const VerificationMeta(
    'undoneAt',
  );
  @override
  late final GeneratedColumn<DateTime> undoneAt = GeneratedColumn<DateTime>(
    'undone_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    entityId,
    summary,
    payloadJson,
    status,
    createdAt,
    undoneAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinancialOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('undone_at')) {
      context.handle(
        _undoneAtMeta,
        undoneAt.isAcceptableOrUnknown(data['undone_at']!, _undoneAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinancialOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialOperationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: $FinancialOperationsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      undoneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}undone_at'],
      ),
    );
  }

  @override
  $FinancialOperationsTable createAlias(String alias) {
    return $FinancialOperationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FinancialOperationKind, String, String>
  $converterkind = const EnumNameConverter<FinancialOperationKind>(
    FinancialOperationKind.values,
  );
}

class FinancialOperationRow extends DataClass
    implements Insertable<FinancialOperationRow> {
  final String id;
  final FinancialOperationKind kind;
  final String entityId;
  final String summary;
  final String payloadJson;
  final String status;
  final DateTime createdAt;
  final DateTime? undoneAt;
  const FinancialOperationRow({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.summary,
    required this.payloadJson,
    required this.status,
    required this.createdAt,
    this.undoneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['kind'] = Variable<String>(
        $FinancialOperationsTable.$converterkind.toSql(kind),
      );
    }
    map['entity_id'] = Variable<String>(entityId);
    map['summary'] = Variable<String>(summary);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || undoneAt != null) {
      map['undone_at'] = Variable<DateTime>(undoneAt);
    }
    return map;
  }

  FinancialOperationsCompanion toCompanion(bool nullToAbsent) {
    return FinancialOperationsCompanion(
      id: Value(id),
      kind: Value(kind),
      entityId: Value(entityId),
      summary: Value(summary),
      payloadJson: Value(payloadJson),
      status: Value(status),
      createdAt: Value(createdAt),
      undoneAt: undoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(undoneAt),
    );
  }

  factory FinancialOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialOperationRow(
      id: serializer.fromJson<String>(json['id']),
      kind: $FinancialOperationsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      entityId: serializer.fromJson<String>(json['entityId']),
      summary: serializer.fromJson<String>(json['summary']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      undoneAt: serializer.fromJson<DateTime?>(json['undoneAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(
        $FinancialOperationsTable.$converterkind.toJson(kind),
      ),
      'entityId': serializer.toJson<String>(entityId),
      'summary': serializer.toJson<String>(summary),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'undoneAt': serializer.toJson<DateTime?>(undoneAt),
    };
  }

  FinancialOperationRow copyWith({
    String? id,
    FinancialOperationKind? kind,
    String? entityId,
    String? summary,
    String? payloadJson,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> undoneAt = const Value.absent(),
  }) => FinancialOperationRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    entityId: entityId ?? this.entityId,
    summary: summary ?? this.summary,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    undoneAt: undoneAt.present ? undoneAt.value : this.undoneAt,
  );
  FinancialOperationRow copyWithCompanion(FinancialOperationsCompanion data) {
    return FinancialOperationRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      summary: data.summary.present ? data.summary.value : this.summary,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      undoneAt: data.undoneAt.present ? data.undoneAt.value : this.undoneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialOperationRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('entityId: $entityId, ')
          ..write('summary: $summary, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('undoneAt: $undoneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    entityId,
    summary,
    payloadJson,
    status,
    createdAt,
    undoneAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialOperationRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.entityId == this.entityId &&
          other.summary == this.summary &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.undoneAt == this.undoneAt);
}

class FinancialOperationsCompanion
    extends UpdateCompanion<FinancialOperationRow> {
  final Value<String> id;
  final Value<FinancialOperationKind> kind;
  final Value<String> entityId;
  final Value<String> summary;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> undoneAt;
  final Value<int> rowid;
  const FinancialOperationsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.entityId = const Value.absent(),
    this.summary = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.undoneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinancialOperationsCompanion.insert({
    required String id,
    required FinancialOperationKind kind,
    required String entityId,
    required String summary,
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.undoneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       entityId = Value(entityId),
       summary = Value(summary),
       createdAt = Value(createdAt);
  static Insertable<FinancialOperationRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? entityId,
    Expression<String>? summary,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? undoneAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (entityId != null) 'entity_id': entityId,
      if (summary != null) 'summary': summary,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (undoneAt != null) 'undone_at': undoneAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinancialOperationsCompanion copyWith({
    Value<String>? id,
    Value<FinancialOperationKind>? kind,
    Value<String>? entityId,
    Value<String>? summary,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? undoneAt,
    Value<int>? rowid,
  }) {
    return FinancialOperationsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      entityId: entityId ?? this.entityId,
      summary: summary ?? this.summary,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      undoneAt: undoneAt ?? this.undoneAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $FinancialOperationsTable.$converterkind.toSql(kind.value),
      );
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (undoneAt.present) {
      map['undone_at'] = Variable<DateTime>(undoneAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialOperationsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('entityId: $entityId, ')
          ..write('summary: $summary, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmsSenderLinksTable extends SmsSenderLinks
    with TableInfo<$SmsSenderLinksTable, SmsSenderLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsSenderLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _importFromMeta = const VerificationMeta(
    'importFrom',
  );
  @override
  late final GeneratedColumn<DateTime> importFrom = GeneratedColumn<DateTime>(
    'import_from',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sender, accountId, importFrom];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_sender_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmsSenderLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('import_from')) {
      context.handle(
        _importFromMeta,
        importFrom.isAcceptableOrUnknown(data['import_from']!, _importFromMeta),
      );
    } else if (isInserting) {
      context.missing(_importFromMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sender, accountId};
  @override
  SmsSenderLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsSenderLink(
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      importFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}import_from'],
      )!,
    );
  }

  @override
  $SmsSenderLinksTable createAlias(String alias) {
    return $SmsSenderLinksTable(attachedDatabase, alias);
  }
}

class SmsSenderLink extends DataClass implements Insertable<SmsSenderLink> {
  final String sender;
  final String accountId;
  final DateTime importFrom;
  const SmsSenderLink({
    required this.sender,
    required this.accountId,
    required this.importFrom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sender'] = Variable<String>(sender);
    map['account_id'] = Variable<String>(accountId);
    map['import_from'] = Variable<DateTime>(importFrom);
    return map;
  }

  SmsSenderLinksCompanion toCompanion(bool nullToAbsent) {
    return SmsSenderLinksCompanion(
      sender: Value(sender),
      accountId: Value(accountId),
      importFrom: Value(importFrom),
    );
  }

  factory SmsSenderLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsSenderLink(
      sender: serializer.fromJson<String>(json['sender']),
      accountId: serializer.fromJson<String>(json['accountId']),
      importFrom: serializer.fromJson<DateTime>(json['importFrom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sender': serializer.toJson<String>(sender),
      'accountId': serializer.toJson<String>(accountId),
      'importFrom': serializer.toJson<DateTime>(importFrom),
    };
  }

  SmsSenderLink copyWith({
    String? sender,
    String? accountId,
    DateTime? importFrom,
  }) => SmsSenderLink(
    sender: sender ?? this.sender,
    accountId: accountId ?? this.accountId,
    importFrom: importFrom ?? this.importFrom,
  );
  SmsSenderLink copyWithCompanion(SmsSenderLinksCompanion data) {
    return SmsSenderLink(
      sender: data.sender.present ? data.sender.value : this.sender,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      importFrom: data.importFrom.present
          ? data.importFrom.value
          : this.importFrom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsSenderLink(')
          ..write('sender: $sender, ')
          ..write('accountId: $accountId, ')
          ..write('importFrom: $importFrom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sender, accountId, importFrom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsSenderLink &&
          other.sender == this.sender &&
          other.accountId == this.accountId &&
          other.importFrom == this.importFrom);
}

class SmsSenderLinksCompanion extends UpdateCompanion<SmsSenderLink> {
  final Value<String> sender;
  final Value<String> accountId;
  final Value<DateTime> importFrom;
  final Value<int> rowid;
  const SmsSenderLinksCompanion({
    this.sender = const Value.absent(),
    this.accountId = const Value.absent(),
    this.importFrom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsSenderLinksCompanion.insert({
    required String sender,
    required String accountId,
    required DateTime importFrom,
    this.rowid = const Value.absent(),
  }) : sender = Value(sender),
       accountId = Value(accountId),
       importFrom = Value(importFrom);
  static Insertable<SmsSenderLink> custom({
    Expression<String>? sender,
    Expression<String>? accountId,
    Expression<DateTime>? importFrom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sender != null) 'sender': sender,
      if (accountId != null) 'account_id': accountId,
      if (importFrom != null) 'import_from': importFrom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsSenderLinksCompanion copyWith({
    Value<String>? sender,
    Value<String>? accountId,
    Value<DateTime>? importFrom,
    Value<int>? rowid,
  }) {
    return SmsSenderLinksCompanion(
      sender: sender ?? this.sender,
      accountId: accountId ?? this.accountId,
      importFrom: importFrom ?? this.importFrom,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (importFrom.present) {
      map['import_from'] = Variable<DateTime>(importFrom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsSenderLinksCompanion(')
          ..write('sender: $sender, ')
          ..write('accountId: $accountId, ')
          ..write('importFrom: $importFrom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmsSuggestionsTable extends SmsSuggestions
    with TableInfo<$SmsSuggestionsTable, SmsSuggestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsSuggestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateMeta = const VerificationMeta(
    'template',
  );
  @override
  late final GeneratedColumn<String> template = GeneratedColumn<String>(
    'template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextKeyMeta = const VerificationMeta(
    'contextKey',
  );
  @override
  late final GeneratedColumn<String> contextKey = GeneratedColumn<String>(
    'context_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextMessageIdMeta = const VerificationMeta(
    'contextMessageId',
  );
  @override
  late final GeneratedColumn<String> contextMessageId = GeneratedColumn<String>(
    'context_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sender,
    receivedAt,
    template,
    contextKey,
    contextMessageId,
    payload,
    status,
    editedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_suggestions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmsSuggestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('template')) {
      context.handle(
        _templateMeta,
        template.isAcceptableOrUnknown(data['template']!, _templateMeta),
      );
    } else if (isInserting) {
      context.missing(_templateMeta);
    }
    if (data.containsKey('context_key')) {
      context.handle(
        _contextKeyMeta,
        contextKey.isAcceptableOrUnknown(data['context_key']!, _contextKeyMeta),
      );
    }
    if (data.containsKey('context_message_id')) {
      context.handle(
        _contextMessageIdMeta,
        contextMessageId.isAcceptableOrUnknown(
          data['context_message_id']!,
          _contextMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmsSuggestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsSuggestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      template: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template'],
      )!,
      contextKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_key'],
      ),
      contextMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_message_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}edited_at'],
      ),
    );
  }

  @override
  $SmsSuggestionsTable createAlias(String alias) {
    return $SmsSuggestionsTable(attachedDatabase, alias);
  }
}

class SmsSuggestionRow extends DataClass
    implements Insertable<SmsSuggestionRow> {
  final String id;
  final String sender;
  final DateTime receivedAt;
  final String template;
  final String? contextKey;
  final String? contextMessageId;
  final String payload;
  final String status;

  /// Set when the user or the assistant edits the draft. A later inbox rescan
  /// must not overwrite an edited draft with the auto-derived one.
  final DateTime? editedAt;
  const SmsSuggestionRow({
    required this.id,
    required this.sender,
    required this.receivedAt,
    required this.template,
    this.contextKey,
    this.contextMessageId,
    required this.payload,
    required this.status,
    this.editedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sender'] = Variable<String>(sender);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['template'] = Variable<String>(template);
    if (!nullToAbsent || contextKey != null) {
      map['context_key'] = Variable<String>(contextKey);
    }
    if (!nullToAbsent || contextMessageId != null) {
      map['context_message_id'] = Variable<String>(contextMessageId);
    }
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    return map;
  }

  SmsSuggestionsCompanion toCompanion(bool nullToAbsent) {
    return SmsSuggestionsCompanion(
      id: Value(id),
      sender: Value(sender),
      receivedAt: Value(receivedAt),
      template: Value(template),
      contextKey: contextKey == null && nullToAbsent
          ? const Value.absent()
          : Value(contextKey),
      contextMessageId: contextMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(contextMessageId),
      payload: Value(payload),
      status: Value(status),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
    );
  }

  factory SmsSuggestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsSuggestionRow(
      id: serializer.fromJson<String>(json['id']),
      sender: serializer.fromJson<String>(json['sender']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      template: serializer.fromJson<String>(json['template']),
      contextKey: serializer.fromJson<String?>(json['contextKey']),
      contextMessageId: serializer.fromJson<String?>(json['contextMessageId']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sender': serializer.toJson<String>(sender),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'template': serializer.toJson<String>(template),
      'contextKey': serializer.toJson<String?>(contextKey),
      'contextMessageId': serializer.toJson<String?>(contextMessageId),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
    };
  }

  SmsSuggestionRow copyWith({
    String? id,
    String? sender,
    DateTime? receivedAt,
    String? template,
    Value<String?> contextKey = const Value.absent(),
    Value<String?> contextMessageId = const Value.absent(),
    String? payload,
    String? status,
    Value<DateTime?> editedAt = const Value.absent(),
  }) => SmsSuggestionRow(
    id: id ?? this.id,
    sender: sender ?? this.sender,
    receivedAt: receivedAt ?? this.receivedAt,
    template: template ?? this.template,
    contextKey: contextKey.present ? contextKey.value : this.contextKey,
    contextMessageId: contextMessageId.present
        ? contextMessageId.value
        : this.contextMessageId,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
  );
  SmsSuggestionRow copyWithCompanion(SmsSuggestionsCompanion data) {
    return SmsSuggestionRow(
      id: data.id.present ? data.id.value : this.id,
      sender: data.sender.present ? data.sender.value : this.sender,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      template: data.template.present ? data.template.value : this.template,
      contextKey: data.contextKey.present
          ? data.contextKey.value
          : this.contextKey,
      contextMessageId: data.contextMessageId.present
          ? data.contextMessageId.value
          : this.contextMessageId,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsSuggestionRow(')
          ..write('id: $id, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('template: $template, ')
          ..write('contextKey: $contextKey, ')
          ..write('contextMessageId: $contextMessageId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sender,
    receivedAt,
    template,
    contextKey,
    contextMessageId,
    payload,
    status,
    editedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsSuggestionRow &&
          other.id == this.id &&
          other.sender == this.sender &&
          other.receivedAt == this.receivedAt &&
          other.template == this.template &&
          other.contextKey == this.contextKey &&
          other.contextMessageId == this.contextMessageId &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.editedAt == this.editedAt);
}

class SmsSuggestionsCompanion extends UpdateCompanion<SmsSuggestionRow> {
  final Value<String> id;
  final Value<String> sender;
  final Value<DateTime> receivedAt;
  final Value<String> template;
  final Value<String?> contextKey;
  final Value<String?> contextMessageId;
  final Value<String> payload;
  final Value<String> status;
  final Value<DateTime?> editedAt;
  final Value<int> rowid;
  const SmsSuggestionsCompanion({
    this.id = const Value.absent(),
    this.sender = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.template = const Value.absent(),
    this.contextKey = const Value.absent(),
    this.contextMessageId = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsSuggestionsCompanion.insert({
    required String id,
    required String sender,
    required DateTime receivedAt,
    required String template,
    this.contextKey = const Value.absent(),
    this.contextMessageId = const Value.absent(),
    required String payload,
    this.status = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sender = Value(sender),
       receivedAt = Value(receivedAt),
       template = Value(template),
       payload = Value(payload);
  static Insertable<SmsSuggestionRow> custom({
    Expression<String>? id,
    Expression<String>? sender,
    Expression<DateTime>? receivedAt,
    Expression<String>? template,
    Expression<String>? contextKey,
    Expression<String>? contextMessageId,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<DateTime>? editedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sender != null) 'sender': sender,
      if (receivedAt != null) 'received_at': receivedAt,
      if (template != null) 'template': template,
      if (contextKey != null) 'context_key': contextKey,
      if (contextMessageId != null) 'context_message_id': contextMessageId,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (editedAt != null) 'edited_at': editedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsSuggestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sender,
    Value<DateTime>? receivedAt,
    Value<String>? template,
    Value<String?>? contextKey,
    Value<String?>? contextMessageId,
    Value<String>? payload,
    Value<String>? status,
    Value<DateTime?>? editedAt,
    Value<int>? rowid,
  }) {
    return SmsSuggestionsCompanion(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receivedAt: receivedAt ?? this.receivedAt,
      template: template ?? this.template,
      contextKey: contextKey ?? this.contextKey,
      contextMessageId: contextMessageId ?? this.contextMessageId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      editedAt: editedAt ?? this.editedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (template.present) {
      map['template'] = Variable<String>(template.value);
    }
    if (contextKey.present) {
      map['context_key'] = Variable<String>(contextKey.value);
    }
    if (contextMessageId.present) {
      map['context_message_id'] = Variable<String>(contextMessageId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsSuggestionsCompanion(')
          ..write('id: $id, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('template: $template, ')
          ..write('contextKey: $contextKey, ')
          ..write('contextMessageId: $contextMessageId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('editedAt: $editedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmsPatternsTable extends SmsPatterns
    with TableInfo<$SmsPatternsTable, SmsPatternRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsPatternsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleMeta = const VerificationMeta('rule');
  @override
  late final GeneratedColumn<String> rule = GeneratedColumn<String>(
    'rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, rule];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_patterns';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmsPatternRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('rule')) {
      context.handle(
        _ruleMeta,
        rule.isAcceptableOrUnknown(data['rule']!, _ruleMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SmsPatternRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsPatternRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      rule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule'],
      )!,
    );
  }

  @override
  $SmsPatternsTable createAlias(String alias) {
    return $SmsPatternsTable(attachedDatabase, alias);
  }
}

class SmsPatternRow extends DataClass implements Insertable<SmsPatternRow> {
  final String key;
  final String rule;
  const SmsPatternRow({required this.key, required this.rule});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['rule'] = Variable<String>(rule);
    return map;
  }

  SmsPatternsCompanion toCompanion(bool nullToAbsent) {
    return SmsPatternsCompanion(key: Value(key), rule: Value(rule));
  }

  factory SmsPatternRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsPatternRow(
      key: serializer.fromJson<String>(json['key']),
      rule: serializer.fromJson<String>(json['rule']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'rule': serializer.toJson<String>(rule),
    };
  }

  SmsPatternRow copyWith({String? key, String? rule}) =>
      SmsPatternRow(key: key ?? this.key, rule: rule ?? this.rule);
  SmsPatternRow copyWithCompanion(SmsPatternsCompanion data) {
    return SmsPatternRow(
      key: data.key.present ? data.key.value : this.key,
      rule: data.rule.present ? data.rule.value : this.rule,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsPatternRow(')
          ..write('key: $key, ')
          ..write('rule: $rule')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, rule);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsPatternRow &&
          other.key == this.key &&
          other.rule == this.rule);
}

class SmsPatternsCompanion extends UpdateCompanion<SmsPatternRow> {
  final Value<String> key;
  final Value<String> rule;
  final Value<int> rowid;
  const SmsPatternsCompanion({
    this.key = const Value.absent(),
    this.rule = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsPatternsCompanion.insert({
    required String key,
    required String rule,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       rule = Value(rule);
  static Insertable<SmsPatternRow> custom({
    Expression<String>? key,
    Expression<String>? rule,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (rule != null) 'rule': rule,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsPatternsCompanion copyWith({
    Value<String>? key,
    Value<String>? rule,
    Value<int>? rowid,
  }) {
    return SmsPatternsCompanion(
      key: key ?? this.key,
      rule: rule ?? this.rule,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (rule.present) {
      map['rule'] = Variable<String>(rule.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsPatternsCompanion(')
          ..write('key: $key, ')
          ..write('rule: $rule, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmsSenderDismissalsTable extends SmsSenderDismissals
    with TableInfo<$SmsSenderDismissalsTable, SmsSenderDismissal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsSenderDismissalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sender];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_sender_dismissals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmsSenderDismissal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sender};
  @override
  SmsSenderDismissal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsSenderDismissal(
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
    );
  }

  @override
  $SmsSenderDismissalsTable createAlias(String alias) {
    return $SmsSenderDismissalsTable(attachedDatabase, alias);
  }
}

class SmsSenderDismissal extends DataClass
    implements Insertable<SmsSenderDismissal> {
  final String sender;
  const SmsSenderDismissal({required this.sender});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sender'] = Variable<String>(sender);
    return map;
  }

  SmsSenderDismissalsCompanion toCompanion(bool nullToAbsent) {
    return SmsSenderDismissalsCompanion(sender: Value(sender));
  }

  factory SmsSenderDismissal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsSenderDismissal(
      sender: serializer.fromJson<String>(json['sender']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'sender': serializer.toJson<String>(sender)};
  }

  SmsSenderDismissal copyWith({String? sender}) =>
      SmsSenderDismissal(sender: sender ?? this.sender);
  SmsSenderDismissal copyWithCompanion(SmsSenderDismissalsCompanion data) {
    return SmsSenderDismissal(
      sender: data.sender.present ? data.sender.value : this.sender,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsSenderDismissal(')
          ..write('sender: $sender')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => sender.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsSenderDismissal && other.sender == this.sender);
}

class SmsSenderDismissalsCompanion extends UpdateCompanion<SmsSenderDismissal> {
  final Value<String> sender;
  final Value<int> rowid;
  const SmsSenderDismissalsCompanion({
    this.sender = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsSenderDismissalsCompanion.insert({
    required String sender,
    this.rowid = const Value.absent(),
  }) : sender = Value(sender);
  static Insertable<SmsSenderDismissal> custom({
    Expression<String>? sender,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sender != null) 'sender': sender,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsSenderDismissalsCompanion copyWith({
    Value<String>? sender,
    Value<int>? rowid,
  }) {
    return SmsSenderDismissalsCompanion(
      sender: sender ?? this.sender,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsSenderDismissalsCompanion(')
          ..write('sender: $sender, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ObligationsTable extends Obligations
    with TableInfo<$ObligationsTable, ObligationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObligationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta(
    'counterparty',
  );
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReceivableMeta = const VerificationMeta(
    'isReceivable',
  );
  @override
  late final GeneratedColumn<bool> isReceivable = GeneratedColumn<bool>(
    'is_receivable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_receivable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _amountRialMeta = const VerificationMeta(
    'amountRial',
  );
  @override
  late final GeneratedColumn<int> amountRial = GeneratedColumn<int>(
    'amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    counterparty,
    isReceivable,
    amountRial,
    dueDate,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'obligations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObligationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('counterparty')) {
      context.handle(
        _counterpartyMeta,
        counterparty.isAcceptableOrUnknown(
          data['counterparty']!,
          _counterpartyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_counterpartyMeta);
    }
    if (data.containsKey('is_receivable')) {
      context.handle(
        _isReceivableMeta,
        isReceivable.isAcceptableOrUnknown(
          data['is_receivable']!,
          _isReceivableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isReceivableMeta);
    }
    if (data.containsKey('amount_rial')) {
      context.handle(
        _amountRialMeta,
        amountRial.isAcceptableOrUnknown(data['amount_rial']!, _amountRialMeta),
      );
    } else if (isInserting) {
      context.missing(_amountRialMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ObligationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObligationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      )!,
      isReceivable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_receivable'],
      )!,
      amountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_rial'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ObligationsTable createAlias(String alias) {
    return $ObligationsTable(attachedDatabase, alias);
  }
}

class ObligationRow extends DataClass implements Insertable<ObligationRow> {
  final String id;
  final String counterparty;
  final bool isReceivable;
  final int amountRial;
  final DateTime? dueDate;
  final String? note;
  final DateTime createdAt;
  const ObligationRow({
    required this.id,
    required this.counterparty,
    required this.isReceivable,
    required this.amountRial,
    this.dueDate,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['counterparty'] = Variable<String>(counterparty);
    map['is_receivable'] = Variable<bool>(isReceivable);
    map['amount_rial'] = Variable<int>(amountRial);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ObligationsCompanion toCompanion(bool nullToAbsent) {
    return ObligationsCompanion(
      id: Value(id),
      counterparty: Value(counterparty),
      isReceivable: Value(isReceivable),
      amountRial: Value(amountRial),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory ObligationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObligationRow(
      id: serializer.fromJson<String>(json['id']),
      counterparty: serializer.fromJson<String>(json['counterparty']),
      isReceivable: serializer.fromJson<bool>(json['isReceivable']),
      amountRial: serializer.fromJson<int>(json['amountRial']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'counterparty': serializer.toJson<String>(counterparty),
      'isReceivable': serializer.toJson<bool>(isReceivable),
      'amountRial': serializer.toJson<int>(amountRial),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ObligationRow copyWith({
    String? id,
    String? counterparty,
    bool? isReceivable,
    int? amountRial,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => ObligationRow(
    id: id ?? this.id,
    counterparty: counterparty ?? this.counterparty,
    isReceivable: isReceivable ?? this.isReceivable,
    amountRial: amountRial ?? this.amountRial,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  ObligationRow copyWithCompanion(ObligationsCompanion data) {
    return ObligationRow(
      id: data.id.present ? data.id.value : this.id,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      isReceivable: data.isReceivable.present
          ? data.isReceivable.value
          : this.isReceivable,
      amountRial: data.amountRial.present
          ? data.amountRial.value
          : this.amountRial,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObligationRow(')
          ..write('id: $id, ')
          ..write('counterparty: $counterparty, ')
          ..write('isReceivable: $isReceivable, ')
          ..write('amountRial: $amountRial, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    counterparty,
    isReceivable,
    amountRial,
    dueDate,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObligationRow &&
          other.id == this.id &&
          other.counterparty == this.counterparty &&
          other.isReceivable == this.isReceivable &&
          other.amountRial == this.amountRial &&
          other.dueDate == this.dueDate &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class ObligationsCompanion extends UpdateCompanion<ObligationRow> {
  final Value<String> id;
  final Value<String> counterparty;
  final Value<bool> isReceivable;
  final Value<int> amountRial;
  final Value<DateTime?> dueDate;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ObligationsCompanion({
    this.id = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.isReceivable = const Value.absent(),
    this.amountRial = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObligationsCompanion.insert({
    required String id,
    required String counterparty,
    required bool isReceivable,
    required int amountRial,
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       counterparty = Value(counterparty),
       isReceivable = Value(isReceivable),
       amountRial = Value(amountRial),
       createdAt = Value(createdAt);
  static Insertable<ObligationRow> custom({
    Expression<String>? id,
    Expression<String>? counterparty,
    Expression<bool>? isReceivable,
    Expression<int>? amountRial,
    Expression<DateTime>? dueDate,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (counterparty != null) 'counterparty': counterparty,
      if (isReceivable != null) 'is_receivable': isReceivable,
      if (amountRial != null) 'amount_rial': amountRial,
      if (dueDate != null) 'due_date': dueDate,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObligationsCompanion copyWith({
    Value<String>? id,
    Value<String>? counterparty,
    Value<bool>? isReceivable,
    Value<int>? amountRial,
    Value<DateTime?>? dueDate,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ObligationsCompanion(
      id: id ?? this.id,
      counterparty: counterparty ?? this.counterparty,
      isReceivable: isReceivable ?? this.isReceivable,
      amountRial: amountRial ?? this.amountRial,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (isReceivable.present) {
      map['is_receivable'] = Variable<bool>(isReceivable.value);
    }
    if (amountRial.present) {
      map['amount_rial'] = Variable<int>(amountRial.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObligationsCompanion(')
          ..write('id: $id, ')
          ..write('counterparty: $counterparty, ')
          ..write('isReceivable: $isReceivable, ')
          ..write('amountRial: $amountRial, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ObligationPaymentsTable extends ObligationPayments
    with TableInfo<$ObligationPaymentsTable, ObligationPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObligationPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _obligationIdMeta = const VerificationMeta(
    'obligationId',
  );
  @override
  late final GeneratedColumn<String> obligationId = GeneratedColumn<String>(
    'obligation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES obligations (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountRialMeta = const VerificationMeta(
    'amountRial',
  );
  @override
  late final GeneratedColumn<int> amountRial = GeneratedColumn<int>(
    'amount_rial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidOnMeta = const VerificationMeta('paidOn');
  @override
  late final GeneratedColumn<DateTime> paidOn = GeneratedColumn<DateTime>(
    'paid_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, obligationId, amountRial, paidOn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'obligation_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObligationPaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('obligation_id')) {
      context.handle(
        _obligationIdMeta,
        obligationId.isAcceptableOrUnknown(
          data['obligation_id']!,
          _obligationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_obligationIdMeta);
    }
    if (data.containsKey('amount_rial')) {
      context.handle(
        _amountRialMeta,
        amountRial.isAcceptableOrUnknown(data['amount_rial']!, _amountRialMeta),
      );
    } else if (isInserting) {
      context.missing(_amountRialMeta);
    }
    if (data.containsKey('paid_on')) {
      context.handle(
        _paidOnMeta,
        paidOn.isAcceptableOrUnknown(data['paid_on']!, _paidOnMeta),
      );
    } else if (isInserting) {
      context.missing(_paidOnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ObligationPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObligationPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      obligationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}obligation_id'],
      )!,
      amountRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_rial'],
      )!,
      paidOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_on'],
      )!,
    );
  }

  @override
  $ObligationPaymentsTable createAlias(String alias) {
    return $ObligationPaymentsTable(attachedDatabase, alias);
  }
}

class ObligationPaymentRow extends DataClass
    implements Insertable<ObligationPaymentRow> {
  final String id;
  final String obligationId;
  final int amountRial;
  final DateTime paidOn;
  const ObligationPaymentRow({
    required this.id,
    required this.obligationId,
    required this.amountRial,
    required this.paidOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['obligation_id'] = Variable<String>(obligationId);
    map['amount_rial'] = Variable<int>(amountRial);
    map['paid_on'] = Variable<DateTime>(paidOn);
    return map;
  }

  ObligationPaymentsCompanion toCompanion(bool nullToAbsent) {
    return ObligationPaymentsCompanion(
      id: Value(id),
      obligationId: Value(obligationId),
      amountRial: Value(amountRial),
      paidOn: Value(paidOn),
    );
  }

  factory ObligationPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObligationPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      obligationId: serializer.fromJson<String>(json['obligationId']),
      amountRial: serializer.fromJson<int>(json['amountRial']),
      paidOn: serializer.fromJson<DateTime>(json['paidOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'obligationId': serializer.toJson<String>(obligationId),
      'amountRial': serializer.toJson<int>(amountRial),
      'paidOn': serializer.toJson<DateTime>(paidOn),
    };
  }

  ObligationPaymentRow copyWith({
    String? id,
    String? obligationId,
    int? amountRial,
    DateTime? paidOn,
  }) => ObligationPaymentRow(
    id: id ?? this.id,
    obligationId: obligationId ?? this.obligationId,
    amountRial: amountRial ?? this.amountRial,
    paidOn: paidOn ?? this.paidOn,
  );
  ObligationPaymentRow copyWithCompanion(ObligationPaymentsCompanion data) {
    return ObligationPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      obligationId: data.obligationId.present
          ? data.obligationId.value
          : this.obligationId,
      amountRial: data.amountRial.present
          ? data.amountRial.value
          : this.amountRial,
      paidOn: data.paidOn.present ? data.paidOn.value : this.paidOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObligationPaymentRow(')
          ..write('id: $id, ')
          ..write('obligationId: $obligationId, ')
          ..write('amountRial: $amountRial, ')
          ..write('paidOn: $paidOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, obligationId, amountRial, paidOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObligationPaymentRow &&
          other.id == this.id &&
          other.obligationId == this.obligationId &&
          other.amountRial == this.amountRial &&
          other.paidOn == this.paidOn);
}

class ObligationPaymentsCompanion
    extends UpdateCompanion<ObligationPaymentRow> {
  final Value<String> id;
  final Value<String> obligationId;
  final Value<int> amountRial;
  final Value<DateTime> paidOn;
  final Value<int> rowid;
  const ObligationPaymentsCompanion({
    this.id = const Value.absent(),
    this.obligationId = const Value.absent(),
    this.amountRial = const Value.absent(),
    this.paidOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObligationPaymentsCompanion.insert({
    required String id,
    required String obligationId,
    required int amountRial,
    required DateTime paidOn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       obligationId = Value(obligationId),
       amountRial = Value(amountRial),
       paidOn = Value(paidOn);
  static Insertable<ObligationPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? obligationId,
    Expression<int>? amountRial,
    Expression<DateTime>? paidOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (obligationId != null) 'obligation_id': obligationId,
      if (amountRial != null) 'amount_rial': amountRial,
      if (paidOn != null) 'paid_on': paidOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObligationPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? obligationId,
    Value<int>? amountRial,
    Value<DateTime>? paidOn,
    Value<int>? rowid,
  }) {
    return ObligationPaymentsCompanion(
      id: id ?? this.id,
      obligationId: obligationId ?? this.obligationId,
      amountRial: amountRial ?? this.amountRial,
      paidOn: paidOn ?? this.paidOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (obligationId.present) {
      map['obligation_id'] = Variable<String>(obligationId.value);
    }
    if (amountRial.present) {
      map['amount_rial'] = Variable<int>(amountRial.value);
    }
    if (paidOn.present) {
      map['paid_on'] = Variable<DateTime>(paidOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObligationPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('obligationId: $obligationId, ')
          ..write('amountRial: $amountRial, ')
          ..write('paidOn: $paidOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetHoldingsTable extends AssetHoldings
    with TableInfo<$AssetHoldingsTable, AssetHoldingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetHoldingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AssetKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AssetKind>($AssetHoldingsTable.$converterkind);
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMicrosMeta = const VerificationMeta(
    'quantityMicros',
  );
  @override
  late final GeneratedColumn<int> quantityMicros = GeneratedColumn<int>(
    'quantity_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateRialMeta = const VerificationMeta(
    'rateRial',
  );
  @override
  late final GeneratedColumn<int> rateRial = GeneratedColumn<int>(
    'rate_rial',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rateDateMeta = const VerificationMeta(
    'rateDate',
  );
  @override
  late final GeneratedColumn<DateTime> rateDate = GeneratedColumn<DateTime>(
    'rate_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMarketRateMeta = const VerificationMeta(
    'isMarketRate',
  );
  @override
  late final GeneratedColumn<bool> isMarketRate = GeneratedColumn<bool>(
    'is_market_rate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_market_rate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    currencyCode,
    quantityMicros,
    rateRial,
    rateDate,
    isMarketRate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_holdings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetHoldingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('quantity_micros')) {
      context.handle(
        _quantityMicrosMeta,
        quantityMicros.isAcceptableOrUnknown(
          data['quantity_micros']!,
          _quantityMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityMicrosMeta);
    }
    if (data.containsKey('rate_rial')) {
      context.handle(
        _rateRialMeta,
        rateRial.isAcceptableOrUnknown(data['rate_rial']!, _rateRialMeta),
      );
    }
    if (data.containsKey('rate_date')) {
      context.handle(
        _rateDateMeta,
        rateDate.isAcceptableOrUnknown(data['rate_date']!, _rateDateMeta),
      );
    }
    if (data.containsKey('is_market_rate')) {
      context.handle(
        _isMarketRateMeta,
        isMarketRate.isAcceptableOrUnknown(
          data['is_market_rate']!,
          _isMarketRateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetHoldingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetHoldingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: $AssetHoldingsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      ),
      quantityMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_micros'],
      )!,
      rateRial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_rial'],
      ),
      rateDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rate_date'],
      ),
      isMarketRate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_market_rate'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AssetHoldingsTable createAlias(String alias) {
    return $AssetHoldingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetKind, String, String> $converterkind =
      const EnumNameConverter<AssetKind>(AssetKind.values);
}

class AssetHoldingRow extends DataClass implements Insertable<AssetHoldingRow> {
  final String id;
  final String name;
  final AssetKind kind;
  final String? currencyCode;
  final int quantityMicros;
  final int? rateRial;
  final DateTime? rateDate;
  final bool isMarketRate;
  final DateTime createdAt;
  const AssetHoldingRow({
    required this.id,
    required this.name,
    required this.kind,
    this.currencyCode,
    required this.quantityMicros,
    this.rateRial,
    this.rateDate,
    required this.isMarketRate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<String>(
        $AssetHoldingsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || currencyCode != null) {
      map['currency_code'] = Variable<String>(currencyCode);
    }
    map['quantity_micros'] = Variable<int>(quantityMicros);
    if (!nullToAbsent || rateRial != null) {
      map['rate_rial'] = Variable<int>(rateRial);
    }
    if (!nullToAbsent || rateDate != null) {
      map['rate_date'] = Variable<DateTime>(rateDate);
    }
    map['is_market_rate'] = Variable<bool>(isMarketRate);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AssetHoldingsCompanion toCompanion(bool nullToAbsent) {
    return AssetHoldingsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      currencyCode: currencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyCode),
      quantityMicros: Value(quantityMicros),
      rateRial: rateRial == null && nullToAbsent
          ? const Value.absent()
          : Value(rateRial),
      rateDate: rateDate == null && nullToAbsent
          ? const Value.absent()
          : Value(rateDate),
      isMarketRate: Value(isMarketRate),
      createdAt: Value(createdAt),
    );
  }

  factory AssetHoldingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetHoldingRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $AssetHoldingsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      currencyCode: serializer.fromJson<String?>(json['currencyCode']),
      quantityMicros: serializer.fromJson<int>(json['quantityMicros']),
      rateRial: serializer.fromJson<int?>(json['rateRial']),
      rateDate: serializer.fromJson<DateTime?>(json['rateDate']),
      isMarketRate: serializer.fromJson<bool>(json['isMarketRate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(
        $AssetHoldingsTable.$converterkind.toJson(kind),
      ),
      'currencyCode': serializer.toJson<String?>(currencyCode),
      'quantityMicros': serializer.toJson<int>(quantityMicros),
      'rateRial': serializer.toJson<int?>(rateRial),
      'rateDate': serializer.toJson<DateTime?>(rateDate),
      'isMarketRate': serializer.toJson<bool>(isMarketRate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AssetHoldingRow copyWith({
    String? id,
    String? name,
    AssetKind? kind,
    Value<String?> currencyCode = const Value.absent(),
    int? quantityMicros,
    Value<int?> rateRial = const Value.absent(),
    Value<DateTime?> rateDate = const Value.absent(),
    bool? isMarketRate,
    DateTime? createdAt,
  }) => AssetHoldingRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    currencyCode: currencyCode.present ? currencyCode.value : this.currencyCode,
    quantityMicros: quantityMicros ?? this.quantityMicros,
    rateRial: rateRial.present ? rateRial.value : this.rateRial,
    rateDate: rateDate.present ? rateDate.value : this.rateDate,
    isMarketRate: isMarketRate ?? this.isMarketRate,
    createdAt: createdAt ?? this.createdAt,
  );
  AssetHoldingRow copyWithCompanion(AssetHoldingsCompanion data) {
    return AssetHoldingRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      quantityMicros: data.quantityMicros.present
          ? data.quantityMicros.value
          : this.quantityMicros,
      rateRial: data.rateRial.present ? data.rateRial.value : this.rateRial,
      rateDate: data.rateDate.present ? data.rateDate.value : this.rateDate,
      isMarketRate: data.isMarketRate.present
          ? data.isMarketRate.value
          : this.isMarketRate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetHoldingRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('quantityMicros: $quantityMicros, ')
          ..write('rateRial: $rateRial, ')
          ..write('rateDate: $rateDate, ')
          ..write('isMarketRate: $isMarketRate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    currencyCode,
    quantityMicros,
    rateRial,
    rateDate,
    isMarketRate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetHoldingRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.currencyCode == this.currencyCode &&
          other.quantityMicros == this.quantityMicros &&
          other.rateRial == this.rateRial &&
          other.rateDate == this.rateDate &&
          other.isMarketRate == this.isMarketRate &&
          other.createdAt == this.createdAt);
}

class AssetHoldingsCompanion extends UpdateCompanion<AssetHoldingRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<AssetKind> kind;
  final Value<String?> currencyCode;
  final Value<int> quantityMicros;
  final Value<int?> rateRial;
  final Value<DateTime?> rateDate;
  final Value<bool> isMarketRate;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AssetHoldingsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.quantityMicros = const Value.absent(),
    this.rateRial = const Value.absent(),
    this.rateDate = const Value.absent(),
    this.isMarketRate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetHoldingsCompanion.insert({
    required String id,
    required String name,
    required AssetKind kind,
    this.currencyCode = const Value.absent(),
    required int quantityMicros,
    this.rateRial = const Value.absent(),
    this.rateDate = const Value.absent(),
    this.isMarketRate = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       quantityMicros = Value(quantityMicros),
       createdAt = Value(createdAt);
  static Insertable<AssetHoldingRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? currencyCode,
    Expression<int>? quantityMicros,
    Expression<int>? rateRial,
    Expression<DateTime>? rateDate,
    Expression<bool>? isMarketRate,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (quantityMicros != null) 'quantity_micros': quantityMicros,
      if (rateRial != null) 'rate_rial': rateRial,
      if (rateDate != null) 'rate_date': rateDate,
      if (isMarketRate != null) 'is_market_rate': isMarketRate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetHoldingsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<AssetKind>? kind,
    Value<String?>? currencyCode,
    Value<int>? quantityMicros,
    Value<int?>? rateRial,
    Value<DateTime?>? rateDate,
    Value<bool>? isMarketRate,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AssetHoldingsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      currencyCode: currencyCode ?? this.currencyCode,
      quantityMicros: quantityMicros ?? this.quantityMicros,
      rateRial: rateRial ?? this.rateRial,
      rateDate: rateDate ?? this.rateDate,
      isMarketRate: isMarketRate ?? this.isMarketRate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AssetHoldingsTable.$converterkind.toSql(kind.value),
      );
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (quantityMicros.present) {
      map['quantity_micros'] = Variable<int>(quantityMicros.value);
    }
    if (rateRial.present) {
      map['rate_rial'] = Variable<int>(rateRial.value);
    }
    if (rateDate.present) {
      map['rate_date'] = Variable<DateTime>(rateDate.value);
    }
    if (isMarketRate.present) {
      map['is_market_rate'] = Variable<bool>(isMarketRate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetHoldingsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('quantityMicros: $quantityMicros, ')
          ..write('rateRial: $rateRial, ')
          ..write('rateDate: $rateDate, ')
          ..write('isMarketRate: $isMarketRate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $TransfersTable transfers = $TransfersTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $LoansTable loans = $LoansTable(this);
  late final $InstallmentsTable installments = $InstallmentsTable(this);
  late final $ChatSessionsTable chatSessions = $ChatSessionsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $PendingActionsTable pendingActions = $PendingActionsTable(this);
  late final $FinancialOperationsTable financialOperations =
      $FinancialOperationsTable(this);
  late final $SmsSenderLinksTable smsSenderLinks = $SmsSenderLinksTable(this);
  late final $SmsSuggestionsTable smsSuggestions = $SmsSuggestionsTable(this);
  late final $SmsPatternsTable smsPatterns = $SmsPatternsTable(this);
  late final $SmsSenderDismissalsTable smsSenderDismissals =
      $SmsSenderDismissalsTable(this);
  late final $ObligationsTable obligations = $ObligationsTable(this);
  late final $ObligationPaymentsTable obligationPayments =
      $ObligationPaymentsTable(this);
  late final $AssetHoldingsTable assetHoldings = $AssetHoldingsTable(this);
  late final Index idxAccountsBank = Index(
    'idx_accounts_bank',
    'CREATE INDEX idx_accounts_bank ON accounts (bank_id)',
  );
  late final Index idxCategoriesType = Index(
    'idx_categories_type',
    'CREATE INDEX idx_categories_type ON categories (type)',
  );
  late final Index idxTransactionsDate = Index(
    'idx_transactions_date',
    'CREATE INDEX idx_transactions_date ON transactions (transaction_date)',
  );
  late final Index idxTransactionsAccount = Index(
    'idx_transactions_account',
    'CREATE INDEX idx_transactions_account ON transactions (account_id)',
  );
  late final Index idxTransactionsCategory = Index(
    'idx_transactions_category',
    'CREATE INDEX idx_transactions_category ON transactions (category_id)',
  );
  late final Index idxTransfersDate = Index(
    'idx_transfers_date',
    'CREATE INDEX idx_transfers_date ON transfers (transfer_date)',
  );
  late final Index idxLedgerAccount = Index(
    'idx_ledger_account',
    'CREATE INDEX idx_ledger_account ON ledger_entries (account_id)',
  );
  late final Index idxLedgerSource = Index(
    'idx_ledger_source',
    'CREATE INDEX idx_ledger_source ON ledger_entries (source_type, source_id)',
  );
  late final Index idxLedgerOperation = Index(
    'idx_ledger_operation',
    'CREATE INDEX idx_ledger_operation ON ledger_entries (operation_id)',
  );
  late final Index idxInstallmentsLoan = Index(
    'idx_installments_loan',
    'CREATE INDEX idx_installments_loan ON installments (loan_id)',
  );
  late final Index idxInstallmentsDue = Index(
    'idx_installments_due',
    'CREATE INDEX idx_installments_due ON installments (due_date)',
  );
  late final Index idxChatSessionsUpdated = Index(
    'idx_chat_sessions_updated',
    'CREATE INDEX idx_chat_sessions_updated ON chat_sessions (updated_at)',
  );
  late final Index idxChatMessagesSession = Index(
    'idx_chat_messages_session',
    'CREATE INDEX idx_chat_messages_session ON chat_messages (session_id, created_at)',
  );
  late final Index idxPendingSession = Index(
    'idx_pending_session',
    'CREATE INDEX idx_pending_session ON pending_actions (session_id)',
  );
  late final Index idxPendingStatus = Index(
    'idx_pending_status',
    'CREATE INDEX idx_pending_status ON pending_actions (status)',
  );
  late final Index idxOperationsCreated = Index(
    'idx_operations_created',
    'CREATE INDEX idx_operations_created ON financial_operations (created_at)',
  );
  late final Index idxObligationPaymentsParent = Index(
    'idx_obligation_payments_parent',
    'CREATE INDEX idx_obligation_payments_parent ON obligation_payments (obligation_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    transactions,
    transfers,
    ledgerEntries,
    loans,
    installments,
    chatSessions,
    chatMessages,
    pendingActions,
    financialOperations,
    smsSenderLinks,
    smsSuggestions,
    smsPatterns,
    smsSenderDismissals,
    obligations,
    obligationPayments,
    assetHoldings,
    idxAccountsBank,
    idxCategoriesType,
    idxTransactionsDate,
    idxTransactionsAccount,
    idxTransactionsCategory,
    idxTransfersDate,
    idxLedgerAccount,
    idxLedgerSource,
    idxLedgerOperation,
    idxInstallmentsLoan,
    idxInstallmentsDue,
    idxChatSessionsUpdated,
    idxChatMessagesSession,
    idxPendingSession,
    idxPendingStatus,
    idxOperationsCreated,
    idxObligationPaymentsParent,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sms_sender_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'obligations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('obligation_payments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String bankId,
  required String bankName,
  required String accountName,
  required AccountType accountType,
  required int initialBalanceRial,
  Value<String?> cardLastFour,
  Value<String?> description,
  required DateTime createdAt,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> bankId,
  Value<String> bankName,
  Value<String> accountName,
  Value<AccountType> accountType,
  Value<int> initialBalanceRial,
  Value<String?> cardLastFour,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountRow> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'accounts__id__transactions__account_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransfersTable, List<TransferRow>>
  _outgoingTransfersTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transfers,
    aliasName: 'accounts__id__transfers__source_account_id',
  );

  $$TransfersTableProcessedTableManager get outgoingTransfers {
    final manager = $$TransfersTableTableManager($_db, $_db.transfers).filter(
      (f) => f.sourceAccountId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_outgoingTransfersTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransfersTable, List<TransferRow>>
  _incomingTransfersTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transfers,
    aliasName: 'accounts__id__transfers__destination_account_id',
  );

  $$TransfersTableProcessedTableManager get incomingTransfers {
    final manager = $$TransfersTableTableManager($_db, $_db.transfers).filter(
      (f) => f.destinationAccountId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_incomingTransfersTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntryRow>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'accounts__id__ledger_entries__account_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoansTable, List<LoanRow>> _loansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.loans,
    aliasName: 'accounts__id__loans__account_id',
  );

  $$LoansTableProcessedTableManager get loansRefs {
    final manager = $$LoansTableTableManager(
      $_db,
      $_db.loans,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SmsSenderLinksTable, List<SmsSenderLink>>
  _smsSenderLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.smsSenderLinks,
    aliasName: 'accounts__id__sms_sender_links__account_id',
  );

  $$SmsSenderLinksTableProcessedTableManager get smsSenderLinksRefs {
    final manager = $$SmsSenderLinksTableTableManager(
      $_db,
      $_db.smsSenderLinks,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_smsSenderLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String>
  get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get initialBalanceRial => $composableBuilder(
    column: $table.initialBalanceRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardLastFour => $composableBuilder(
    column: $table.cardLastFour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outgoingTransfers(
    Expression<bool> Function($$TransfersTableFilterComposer f) f,
  ) {
    final $$TransfersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transfers,
      getReferencedColumn: (t) => t.sourceAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransfersTableFilterComposer(
            $db: $db,
            $table: $db.transfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingTransfers(
    Expression<bool> Function($$TransfersTableFilterComposer f) f,
  ) {
    final $$TransfersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transfers,
      getReferencedColumn: (t) => t.destinationAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransfersTableFilterComposer(
            $db: $db,
            $table: $db.transfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loansRefs(
    Expression<bool> Function($$LoansTableFilterComposer f) f,
  ) {
    final $$LoansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableFilterComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> smsSenderLinksRefs(
    Expression<bool> Function($$SmsSenderLinksTableFilterComposer f) f,
  ) {
    final $$SmsSenderLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smsSenderLinks,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmsSenderLinksTableFilterComposer(
            $db: $db,
            $table: $db.smsSenderLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialBalanceRial => $composableBuilder(
    column: $table.initialBalanceRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardLastFour => $composableBuilder(
    column: $table.cardLastFour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankId =>
      $composableBuilder(column: $table.bankId, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AccountType, String> get accountType =>
      $composableBuilder(
        column: $table.accountType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get initialBalanceRial => $composableBuilder(
    column: $table.initialBalanceRial,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardLastFour => $composableBuilder(
    column: $table.cardLastFour,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outgoingTransfers<T extends Object>(
    Expression<T> Function($$TransfersTableAnnotationComposer a) f,
  ) {
    final $$TransfersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transfers,
      getReferencedColumn: (t) => t.sourceAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransfersTableAnnotationComposer(
            $db: $db,
            $table: $db.transfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomingTransfers<T extends Object>(
    Expression<T> Function($$TransfersTableAnnotationComposer a) f,
  ) {
    final $$TransfersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transfers,
      getReferencedColumn: (t) => t.destinationAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransfersTableAnnotationComposer(
            $db: $db,
            $table: $db.transfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loansRefs<T extends Object>(
    Expression<T> Function($$LoansTableAnnotationComposer a) f,
  ) {
    final $$LoansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableAnnotationComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> smsSenderLinksRefs<T extends Object>(
    Expression<T> Function($$SmsSenderLinksTableAnnotationComposer a) f,
  ) {
    final $$SmsSenderLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.smsSenderLinks,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SmsSenderLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.smsSenderLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (AccountRow, $$AccountsTableReferences),
          AccountRow,
          PrefetchHooks Function({
            bool transactionsRefs,
            bool outgoingTransfers,
            bool incomingTransfers,
            bool ledgerEntriesRefs,
            bool loansRefs,
            bool smsSenderLinksRefs,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bankId = const Value.absent(),
                Value<String> bankName = const Value.absent(),
                Value<String> accountName = const Value.absent(),
                Value<AccountType> accountType = const Value.absent(),
                Value<int> initialBalanceRial = const Value.absent(),
                Value<String?> cardLastFour = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                bankId: bankId,
                bankName: bankName,
                accountName: accountName,
                accountType: accountType,
                initialBalanceRial: initialBalanceRial,
                cardLastFour: cardLastFour,
                description: description,
                createdAt: createdAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bankId,
                required String bankName,
                required String accountName,
                required AccountType accountType,
                required int initialBalanceRial,
                Value<String?> cardLastFour = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                bankId: bankId,
                bankName: bankName,
                accountName: accountName,
                accountType: accountType,
                initialBalanceRial: initialBalanceRial,
                cardLastFour: cardLastFour,
                description: description,
                createdAt: createdAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, AccountRow>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                transactionsRefs = false,
                outgoingTransfers = false,
                incomingTransfers = false,
                ledgerEntriesRefs = false,
                loansRefs = false,
                smsSenderLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (outgoingTransfers) db.transfers,
                    if (incomingTransfers) db.transfers,
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (loansRefs) db.loans,
                    if (smsSenderLinksRefs) db.smsSenderLinks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          TransactionRow,
                          $TransactionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (outgoingTransfers)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          TransferRow,
                          $TransfersTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._outgoingTransfersTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).outgoingTransfers,
                          currentColumn: 'id',
                          referencedColumn: 'source_account_id',
                          typedResults: items,
                        ),
                      if (incomingTransfers)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          TransferRow,
                          $TransfersTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._incomingTransfersTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingTransfers,
                          currentColumn: 'id',
                          referencedColumn: 'destination_account_id',
                          typedResults: items,
                        ),
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          LedgerEntryRow,
                          $LedgerEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (loansRefs)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          LoanRow,
                          $LoansTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._loansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).loansRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                      if (smsSenderLinksRefs)
                        await $_getPrefetchedDataByColumns<
                          AccountRow,
                          $AccountsTable,
                          SmsSenderLink,
                          $SmsSenderLinksTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._smsSenderLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).smsSenderLinksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, $$AccountsTableReferences),
      AccountRow,
      PrefetchHooks Function({
        bool transactionsRefs,
        bool outgoingTransfers,
        bool incomingTransfers,
        bool ledgerEntriesRefs,
        bool loansRefs,
        bool smsSenderLinksRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required CategoryType type,
  required String icon,
  required String colorHex,
  Value<bool> isDefault,
  Value<int> sortOrder,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<CategoryType> type,
  Value<String> icon,
  Value<String> colorHex,
  Value<bool> isDefault,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'categories__id__transactions__category_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryType, CategoryType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<CategoryType> type = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                type: type,
                icon: icon,
                colorHex: colorHex,
                isDefault: isDefault,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required CategoryType type,
                required String icon,
                required String colorHex,
                Value<bool> isDefault = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                type: type,
                icon: icon,
                colorHex: colorHex,
                isDefault: isDefault,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedDataByColumns<
                      CategoryRow,
                      $CategoriesTable,
                      TransactionRow,
                      $TransactionsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).transactionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required TransactionType type,
      required int amountRial,
      Value<String?> categoryId,
      required String accountId,
      required DateTime transactionDate,
      Value<String?> description,
      required String operationId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<TransactionType> type,
      Value<int> amountRial,
      Value<String?> categoryId,
      Value<String> accountId,
      Value<DateTime> transactionDate,
      Value<String?> description,
      Value<String> operationId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({bool categoryId, bool accountId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<int> amountRial = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                amountRial: amountRial,
                categoryId: categoryId,
                accountId: accountId,
                transactionDate: transactionDate,
                description: description,
                operationId: operationId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required TransactionType type,
                required int amountRial,
                Value<String?> categoryId = const Value.absent(),
                required String accountId,
                required DateTime transactionDate,
                Value<String?> description = const Value.absent(),
                required String operationId,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                amountRial: amountRial,
                categoryId: categoryId,
                accountId: accountId,
                transactionDate: transactionDate,
                description: description,
                operationId: operationId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$TransactionsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$TransactionsTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$TransactionsTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$TransactionsTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({bool categoryId, bool accountId})
    >;
typedef $$TransfersTableCreateCompanionBuilder = TransfersCompanion Function({
  required String id,
  required String sourceAccountId,
  required String destinationAccountId,
  required int amountRial,
  Value<int> feeRial,
  required DateTime transferDate,
  Value<String?> description,
  required String operationId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TransfersTableUpdateCompanionBuilder = TransfersCompanion Function({
  Value<String> id,
  Value<String> sourceAccountId,
  Value<String> destinationAccountId,
  Value<int> amountRial,
  Value<int> feeRial,
  Value<DateTime> transferDate,
  Value<String?> description,
  Value<String> operationId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TransfersTableReferences
    extends BaseReferences<_$AppDatabase, $TransfersTable, TransferRow> {
  $$TransfersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _sourceAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transfers__source_account_id__accounts__id');

  $$AccountsTableProcessedTableManager get sourceAccountId {
    final $_column = $_itemColumn<String>('source_account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _destinationAccountIdTable(_$AppDatabase db) => db
      .accounts
      .createAlias('transfers__destination_account_id__accounts__id');

  $$AccountsTableProcessedTableManager get destinationAccountId {
    final $_column = $_itemColumn<String>('destination_account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _destinationAccountIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransfersTableFilterComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feeRial => $composableBuilder(
    column: $table.feeRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transferDate => $composableBuilder(
    column: $table.transferDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get sourceAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get destinationAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feeRial => $composableBuilder(
    column: $table.feeRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transferDate => $composableBuilder(
    column: $table.transferDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get sourceAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get destinationAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feeRial =>
      $composableBuilder(column: $table.feeRial, builder: (column) => column);

  GeneratedColumn<DateTime> get transferDate => $composableBuilder(
    column: $table.transferDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get sourceAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get destinationAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransfersTable,
          TransferRow,
          $$TransfersTableFilterComposer,
          $$TransfersTableOrderingComposer,
          $$TransfersTableAnnotationComposer,
          $$TransfersTableCreateCompanionBuilder,
          $$TransfersTableUpdateCompanionBuilder,
          (TransferRow, $$TransfersTableReferences),
          TransferRow,
          PrefetchHooks Function({
            bool sourceAccountId,
            bool destinationAccountId,
          })
        > {
  $$TransfersTableTableManager(_$AppDatabase db, $TransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceAccountId = const Value.absent(),
                Value<String> destinationAccountId = const Value.absent(),
                Value<int> amountRial = const Value.absent(),
                Value<int> feeRial = const Value.absent(),
                Value<DateTime> transferDate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion(
                id: id,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                amountRial: amountRial,
                feeRial: feeRial,
                transferDate: transferDate,
                description: description,
                operationId: operationId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceAccountId,
                required String destinationAccountId,
                required int amountRial,
                Value<int> feeRial = const Value.absent(),
                required DateTime transferDate,
                Value<String?> description = const Value.absent(),
                required String operationId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion.insert(
                id: id,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                amountRial: amountRial,
                feeRial: feeRial,
                transferDate: transferDate,
                description: description,
                operationId: operationId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransfersTable, TransferRow>(table),
                  $$TransfersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceAccountId = false, destinationAccountId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceAccountId,
                            referencedTable: $$TransfersTableReferences
                                ._sourceAccountIdTable(db),
                            referencedColumn: $$TransfersTableReferences
                                ._sourceAccountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (destinationAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.destinationAccountId,
                            referencedTable: $$TransfersTableReferences
                                ._destinationAccountIdTable(db),
                            referencedColumn: $$TransfersTableReferences
                                ._destinationAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransfersTable,
      TransferRow,
      $$TransfersTableFilterComposer,
      $$TransfersTableOrderingComposer,
      $$TransfersTableAnnotationComposer,
      $$TransfersTableCreateCompanionBuilder,
      $$TransfersTableUpdateCompanionBuilder,
      (TransferRow, $$TransfersTableReferences),
      TransferRow,
      PrefetchHooks Function({bool sourceAccountId, bool destinationAccountId})
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<int> id,
      required String accountId,
      required int deltaRial,
      required DateTime entryDate,
      required LedgerSource sourceType,
      required String sourceId,
      required String operationId,
      required DateTime createdAt,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<int> id,
      Value<String> accountId,
      Value<int> deltaRial,
      Value<DateTime> entryDate,
      Value<LedgerSource> sourceType,
      Value<String> sourceId,
      Value<String> operationId,
      Value<DateTime> createdAt,
    });

final class $$LedgerEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntryRow> {
  $$LedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('ledger_entries__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deltaRial => $composableBuilder(
    column: $table.deltaRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LedgerSource, LedgerSource, String>
  get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deltaRial => $composableBuilder(
    column: $table.deltaRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get deltaRial =>
      $composableBuilder(column: $table.deltaRial, builder: (column) => column);

  GeneratedColumn<DateTime> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LedgerSource, String> get sourceType =>
      $composableBuilder(
        column: $table.sourceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerEntryRow,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (LedgerEntryRow, $$LedgerEntriesTableReferences),
          LedgerEntryRow,
          PrefetchHooks Function({bool accountId})
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> deltaRial = const Value.absent(),
                Value<DateTime> entryDate = const Value.absent(),
                Value<LedgerSource> sourceType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                accountId: accountId,
                deltaRial: deltaRial,
                entryDate: entryDate,
                sourceType: sourceType,
                sourceId: sourceId,
                operationId: operationId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String accountId,
                required int deltaRial,
                required DateTime entryDate,
                required LedgerSource sourceType,
                required String sourceId,
                required String operationId,
                required DateTime createdAt,
              }) => LedgerEntriesCompanion.insert(
                id: id,
                accountId: accountId,
                deltaRial: deltaRial,
                entryDate: entryDate,
                sourceType: sourceType,
                sourceId: sourceId,
                operationId: operationId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, LedgerEntryRow>(table),
                  $$LedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$LedgerEntriesTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$LedgerEntriesTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerEntryRow,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (LedgerEntryRow, $$LedgerEntriesTableReferences),
      LedgerEntryRow,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$LoansTableCreateCompanionBuilder = LoansCompanion Function({
  required String id,
  required String title,
  required int principalAmountRial,
  Value<int> interestAmountRial,
  required int installmentCount,
  required int installmentAmountRial,
  Value<String?> accountId,
  required DateTime startDate,
  required LoanStatus status,
  Value<String?> description,
  required String operationId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LoansTableUpdateCompanionBuilder = LoansCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<int> principalAmountRial,
  Value<int> interestAmountRial,
  Value<int> installmentCount,
  Value<int> installmentAmountRial,
  Value<String?> accountId,
  Value<DateTime> startDate,
  Value<LoanStatus> status,
  Value<String?> description,
  Value<String> operationId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$LoansTableReferences
    extends BaseReferences<_$AppDatabase, $LoansTable, LoanRow> {
  $$LoansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('loans__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InstallmentsTable, List<InstallmentRow>>
  _installmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.installments,
    aliasName: 'loans__id__installments__loan_id',
  );

  $$InstallmentsTableProcessedTableManager get installmentsRefs {
    final manager = $$InstallmentsTableTableManager(
      $_db,
      $_db.installments,
    ).filter((f) => f.loanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_installmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LoansTableFilterComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get principalAmountRial => $composableBuilder(
    column: $table.principalAmountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interestAmountRial => $composableBuilder(
    column: $table.interestAmountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentAmountRial => $composableBuilder(
    column: $table.installmentAmountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LoanStatus, LoanStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> installmentsRefs(
    Expression<bool> Function($$InstallmentsTableFilterComposer f) f,
  ) {
    final $$InstallmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installments,
      getReferencedColumn: (t) => t.loanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentsTableFilterComposer(
            $db: $db,
            $table: $db.installments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoansTableOrderingComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get principalAmountRial => $composableBuilder(
    column: $table.principalAmountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interestAmountRial => $composableBuilder(
    column: $table.interestAmountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentAmountRial => $composableBuilder(
    column: $table.installmentAmountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get principalAmountRial => $composableBuilder(
    column: $table.principalAmountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get interestAmountRial => $composableBuilder(
    column: $table.interestAmountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get installmentAmountRial => $composableBuilder(
    column: $table.installmentAmountRial,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LoanStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> installmentsRefs<T extends Object>(
    Expression<T> Function($$InstallmentsTableAnnotationComposer a) f,
  ) {
    final $$InstallmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.installments,
      getReferencedColumn: (t) => t.loanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.installments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LoansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoansTable,
          LoanRow,
          $$LoansTableFilterComposer,
          $$LoansTableOrderingComposer,
          $$LoansTableAnnotationComposer,
          $$LoansTableCreateCompanionBuilder,
          $$LoansTableUpdateCompanionBuilder,
          (LoanRow, $$LoansTableReferences),
          LoanRow,
          PrefetchHooks Function({bool accountId, bool installmentsRefs})
        > {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> principalAmountRial = const Value.absent(),
                Value<int> interestAmountRial = const Value.absent(),
                Value<int> installmentCount = const Value.absent(),
                Value<int> installmentAmountRial = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<LoanStatus> status = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoansCompanion(
                id: id,
                title: title,
                principalAmountRial: principalAmountRial,
                interestAmountRial: interestAmountRial,
                installmentCount: installmentCount,
                installmentAmountRial: installmentAmountRial,
                accountId: accountId,
                startDate: startDate,
                status: status,
                description: description,
                operationId: operationId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int principalAmountRial,
                Value<int> interestAmountRial = const Value.absent(),
                required int installmentCount,
                required int installmentAmountRial,
                Value<String?> accountId = const Value.absent(),
                required DateTime startDate,
                required LoanStatus status,
                Value<String?> description = const Value.absent(),
                required String operationId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LoansCompanion.insert(
                id: id,
                title: title,
                principalAmountRial: principalAmountRial,
                interestAmountRial: interestAmountRial,
                installmentCount: installmentCount,
                installmentAmountRial: installmentAmountRial,
                accountId: accountId,
                startDate: startDate,
                status: status,
                description: description,
                operationId: operationId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LoansTable, LoanRow>(table),
                  $$LoansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({accountId = false, installmentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (installmentsRefs) db.installments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$LoansTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$LoansTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (installmentsRefs)
                        await $_getPrefetchedDataByColumns<
                          LoanRow,
                          $LoansTable,
                          InstallmentRow,
                          $InstallmentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$LoansTableReferences
                              ._installmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LoansTableReferences(
                                db,
                                table,
                                p0,
                              ).installmentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'loan_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LoansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoansTable,
      LoanRow,
      $$LoansTableFilterComposer,
      $$LoansTableOrderingComposer,
      $$LoansTableAnnotationComposer,
      $$LoansTableCreateCompanionBuilder,
      $$LoansTableUpdateCompanionBuilder,
      (LoanRow, $$LoansTableReferences),
      LoanRow,
      PrefetchHooks Function({bool accountId, bool installmentsRefs})
    >;
typedef $$InstallmentsTableCreateCompanionBuilder =
    InstallmentsCompanion Function({
      required String id,
      required String loanId,
      required int installmentNumber,
      required DateTime dueDate,
      required int amountRial,
      required int principalRial,
      Value<int> interestRial,
      required InstallmentStatus status,
      Value<int> paidAmountRial,
      Value<DateTime?> paidAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$InstallmentsTableUpdateCompanionBuilder =
    InstallmentsCompanion Function({
      Value<String> id,
      Value<String> loanId,
      Value<int> installmentNumber,
      Value<DateTime> dueDate,
      Value<int> amountRial,
      Value<int> principalRial,
      Value<int> interestRial,
      Value<InstallmentStatus> status,
      Value<int> paidAmountRial,
      Value<DateTime?> paidAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$InstallmentsTableReferences
    extends BaseReferences<_$AppDatabase, $InstallmentsTable, InstallmentRow> {
  $$InstallmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LoansTable _loanIdTable(_$AppDatabase db) =>
      db.loans.createAlias('installments__loan_id__loans__id');

  $$LoansTableProcessedTableManager get loanId {
    final $_column = $_itemColumn<String>('loan_id')!;

    final manager = $$LoansTableTableManager(
      $_db,
      $_db.loans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_loanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstallmentsTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentsTable> {
  $$InstallmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get principalRial => $composableBuilder(
    column: $table.principalRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interestRial => $composableBuilder(
    column: $table.interestRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InstallmentStatus, InstallmentStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get paidAmountRial => $composableBuilder(
    column: $table.paidAmountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LoansTableFilterComposer get loanId {
    final $$LoansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableFilterComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentsTable> {
  $$InstallmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get principalRial => $composableBuilder(
    column: $table.principalRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interestRial => $composableBuilder(
    column: $table.interestRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAmountRial => $composableBuilder(
    column: $table.paidAmountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LoansTableOrderingComposer get loanId {
    final $$LoansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableOrderingComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentsTable> {
  $$InstallmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get principalRial => $composableBuilder(
    column: $table.principalRial,
    builder: (column) => column,
  );

  GeneratedColumn<int> get interestRial => $composableBuilder(
    column: $table.interestRial,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<InstallmentStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get paidAmountRial => $composableBuilder(
    column: $table.paidAmountRial,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LoansTableAnnotationComposer get loanId {
    final $$LoansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.loanId,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableAnnotationComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallmentsTable,
          InstallmentRow,
          $$InstallmentsTableFilterComposer,
          $$InstallmentsTableOrderingComposer,
          $$InstallmentsTableAnnotationComposer,
          $$InstallmentsTableCreateCompanionBuilder,
          $$InstallmentsTableUpdateCompanionBuilder,
          (InstallmentRow, $$InstallmentsTableReferences),
          InstallmentRow,
          PrefetchHooks Function({bool loanId})
        > {
  $$InstallmentsTableTableManager(_$AppDatabase db, $InstallmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstallmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> loanId = const Value.absent(),
                Value<int> installmentNumber = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<int> amountRial = const Value.absent(),
                Value<int> principalRial = const Value.absent(),
                Value<int> interestRial = const Value.absent(),
                Value<InstallmentStatus> status = const Value.absent(),
                Value<int> paidAmountRial = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstallmentsCompanion(
                id: id,
                loanId: loanId,
                installmentNumber: installmentNumber,
                dueDate: dueDate,
                amountRial: amountRial,
                principalRial: principalRial,
                interestRial: interestRial,
                status: status,
                paidAmountRial: paidAmountRial,
                paidAt: paidAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String loanId,
                required int installmentNumber,
                required DateTime dueDate,
                required int amountRial,
                required int principalRial,
                Value<int> interestRial = const Value.absent(),
                required InstallmentStatus status,
                Value<int> paidAmountRial = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => InstallmentsCompanion.insert(
                id: id,
                loanId: loanId,
                installmentNumber: installmentNumber,
                dueDate: dueDate,
                amountRial: amountRial,
                principalRial: principalRial,
                interestRial: interestRial,
                status: status,
                paidAmountRial: paidAmountRial,
                paidAt: paidAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstallmentsTable, InstallmentRow>(table),
                  $$InstallmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({loanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (loanId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.loanId,
                        referencedTable: $$InstallmentsTableReferences
                            ._loanIdTable(db),
                        referencedColumn: $$InstallmentsTableReferences
                            ._loanIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InstallmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallmentsTable,
      InstallmentRow,
      $$InstallmentsTableFilterComposer,
      $$InstallmentsTableOrderingComposer,
      $$InstallmentsTableAnnotationComposer,
      $$InstallmentsTableCreateCompanionBuilder,
      $$InstallmentsTableUpdateCompanionBuilder,
      (InstallmentRow, $$InstallmentsTableReferences),
      InstallmentRow,
      PrefetchHooks Function({bool loanId})
    >;
typedef $$ChatSessionsTableCreateCompanionBuilder =
    ChatSessionsCompanion Function({
      required String id,
      required String title,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChatSessionsTableUpdateCompanionBuilder =
    ChatSessionsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ChatSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $ChatSessionsTable, ChatSessionRow> {
  $$ChatSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessageRow>>
  _messagesTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chatMessages,
    aliasName: 'chat_sessions__id__chat_messages__session_id',
  );

  $$ChatMessagesTableProcessedTableManager get messages {
    final manager = $$ChatMessagesTableTableManager(
      $_db,
      $_db.chatMessages,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PendingActionsTable, List<PendingActionRow>>
  _pendingActionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingActions,
    aliasName: 'chat_sessions__id__pending_actions__session_id',
  );

  $$PendingActionsTableProcessedTableManager get pendingActions {
    final manager = $$PendingActionsTableTableManager(
      $_db,
      $_db.pendingActions,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pendingActionsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChatSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> messages(
    Expression<bool> Function($$ChatMessagesTableFilterComposer f) f,
  ) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessagesTableFilterComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pendingActions(
    Expression<bool> Function($$PendingActionsTableFilterComposer f) f,
  ) {
    final $$PendingActionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingActions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingActionsTableFilterComposer(
            $db: $db,
            $table: $db.pendingActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> messages<T extends Object>(
    Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f,
  ) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pendingActions<T extends Object>(
    Expression<T> Function($$PendingActionsTableAnnotationComposer a) f,
  ) {
    final $$PendingActionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingActions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingActionsTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingActions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatSessionsTable,
          ChatSessionRow,
          $$ChatSessionsTableFilterComposer,
          $$ChatSessionsTableOrderingComposer,
          $$ChatSessionsTableAnnotationComposer,
          $$ChatSessionsTableCreateCompanionBuilder,
          $$ChatSessionsTableUpdateCompanionBuilder,
          (ChatSessionRow, $$ChatSessionsTableReferences),
          ChatSessionRow,
          PrefetchHooks Function({bool messages, bool pendingActions})
        > {
  $$ChatSessionsTableTableManager(_$AppDatabase db, $ChatSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatSessionsCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatSessionsCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChatSessionsTable, ChatSessionRow>(table),
                  $$ChatSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messages = false, pendingActions = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (messages) db.chatMessages,
                if (pendingActions) db.pendingActions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messages)
                    await $_getPrefetchedDataByColumns<
                      ChatSessionRow,
                      $ChatSessionsTable,
                      ChatMessageRow,
                      $ChatMessagesTable
                    >(
                      currentTable: table,
                      referencedTable: $$ChatSessionsTableReferences
                          ._messagesTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChatSessionsTableReferences(db, table, p0).messages,
                      currentColumn: 'id',
                      referencedColumn: 'session_id',
                      typedResults: items,
                    ),
                  if (pendingActions)
                    await $_getPrefetchedDataByColumns<
                      ChatSessionRow,
                      $ChatSessionsTable,
                      PendingActionRow,
                      $PendingActionsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ChatSessionsTableReferences
                          ._pendingActionsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChatSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).pendingActions,
                      currentColumn: 'id',
                      referencedColumn: 'session_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChatSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatSessionsTable,
      ChatSessionRow,
      $$ChatSessionsTableFilterComposer,
      $$ChatSessionsTableOrderingComposer,
      $$ChatSessionsTableAnnotationComposer,
      $$ChatSessionsTableCreateCompanionBuilder,
      $$ChatSessionsTableUpdateCompanionBuilder,
      (ChatSessionRow, $$ChatSessionsTableReferences),
      ChatSessionRow,
      PrefetchHooks Function({bool messages, bool pendingActions})
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      required String id,
      required String sessionId,
      required ChatRole role,
      required String content,
      required ChatMessageType messageType,
      Value<String> metadataJson,
      Value<int> sequence,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<ChatRole> role,
      Value<String> content,
      Value<ChatMessageType> messageType,
      Value<String> metadataJson,
      Value<int> sequence,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ChatMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageRow> {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatSessionsTable _sessionIdTable(_$AppDatabase db) => db.chatSessions
      .createAlias('chat_messages__session_id__chat_sessions__id');

  $$ChatSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$ChatSessionsTableTableManager(
      $_db,
      $_db.chatSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChatRole, ChatRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChatMessageType, ChatMessageType, String>
  get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChatSessionsTableFilterComposer get sessionId {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableFilterComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChatSessionsTableOrderingComposer get sessionId {
    final $$ChatSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChatRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChatMessageType, String> get messageType =>
      $composableBuilder(
        column: $table.messageType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChatSessionsTableAnnotationComposer get sessionId {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessageRow,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (ChatMessageRow, $$ChatMessagesTableReferences),
          ChatMessageRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<ChatRole> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<ChatMessageType> messageType = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                sessionId: sessionId,
                role: role,
                content: content,
                messageType: messageType,
                metadataJson: metadataJson,
                sequence: sequence,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required ChatRole role,
                required String content,
                required ChatMessageType messageType,
                Value<String> metadataJson = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatMessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                role: role,
                content: content,
                messageType: messageType,
                metadataJson: metadataJson,
                sequence: sequence,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChatMessagesTable, ChatMessageRow>(table),
                  $$ChatMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$ChatMessagesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$ChatMessagesTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessageRow,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (ChatMessageRow, $$ChatMessagesTableReferences),
      ChatMessageRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$PendingActionsTableCreateCompanionBuilder =
    PendingActionsCompanion Function({
      required String id,
      required String sessionId,
      Value<String?> messageId,
      required String actionType,
      required String payloadJson,
      required PendingActionStatus status,
      required String operationId,
      Value<String?> errorMessage,
      required DateTime createdAt,
      Value<DateTime?> resolvedAt,
      Value<int> rowid,
    });
typedef $$PendingActionsTableUpdateCompanionBuilder =
    PendingActionsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String?> messageId,
      Value<String> actionType,
      Value<String> payloadJson,
      Value<PendingActionStatus> status,
      Value<String> operationId,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime?> resolvedAt,
      Value<int> rowid,
    });

final class $$PendingActionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PendingActionsTable, PendingActionRow> {
  $$PendingActionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChatSessionsTable _sessionIdTable(_$AppDatabase db) => db.chatSessions
      .createAlias('pending_actions__session_id__chat_sessions__id');

  $$ChatSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$ChatSessionsTableTableManager(
      $_db,
      $_db.chatSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingActionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PendingActionStatus,
    PendingActionStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChatSessionsTableFilterComposer get sessionId {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableFilterComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChatSessionsTableOrderingComposer get sessionId {
    final $$ChatSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PendingActionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  $$ChatSessionsTableAnnotationComposer get sessionId {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingActionsTable,
          PendingActionRow,
          $$PendingActionsTableFilterComposer,
          $$PendingActionsTableOrderingComposer,
          $$PendingActionsTableAnnotationComposer,
          $$PendingActionsTableCreateCompanionBuilder,
          $$PendingActionsTableUpdateCompanionBuilder,
          (PendingActionRow, $$PendingActionsTableReferences),
          PendingActionRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$PendingActionsTableTableManager(
    _$AppDatabase db,
    $PendingActionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<PendingActionStatus> status = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingActionsCompanion(
                id: id,
                sessionId: sessionId,
                messageId: messageId,
                actionType: actionType,
                payloadJson: payloadJson,
                status: status,
                operationId: operationId,
                errorMessage: errorMessage,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                Value<String?> messageId = const Value.absent(),
                required String actionType,
                required String payloadJson,
                required PendingActionStatus status,
                required String operationId,
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingActionsCompanion.insert(
                id: id,
                sessionId: sessionId,
                messageId: messageId,
                actionType: actionType,
                payloadJson: payloadJson,
                status: status,
                operationId: operationId,
                errorMessage: errorMessage,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingActionsTable, PendingActionRow>(table),
                  $$PendingActionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$PendingActionsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$PendingActionsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PendingActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingActionsTable,
      PendingActionRow,
      $$PendingActionsTableFilterComposer,
      $$PendingActionsTableOrderingComposer,
      $$PendingActionsTableAnnotationComposer,
      $$PendingActionsTableCreateCompanionBuilder,
      $$PendingActionsTableUpdateCompanionBuilder,
      (PendingActionRow, $$PendingActionsTableReferences),
      PendingActionRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$FinancialOperationsTableCreateCompanionBuilder =
    FinancialOperationsCompanion Function({
      required String id,
      required FinancialOperationKind kind,
      required String entityId,
      required String summary,
      Value<String> payloadJson,
      Value<String> status,
      required DateTime createdAt,
      Value<DateTime?> undoneAt,
      Value<int> rowid,
    });
typedef $$FinancialOperationsTableUpdateCompanionBuilder =
    FinancialOperationsCompanion Function({
      Value<String> id,
      Value<FinancialOperationKind> kind,
      Value<String> entityId,
      Value<String> summary,
      Value<String> payloadJson,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> undoneAt,
      Value<int> rowid,
    });

class $$FinancialOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialOperationsTable> {
  $$FinancialOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    FinancialOperationKind,
    FinancialOperationKind,
    String
  >
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FinancialOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialOperationsTable> {
  $$FinancialOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinancialOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialOperationsTable> {
  $$FinancialOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FinancialOperationKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get undoneAt =>
      $composableBuilder(column: $table.undoneAt, builder: (column) => column);
}

class $$FinancialOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinancialOperationsTable,
          FinancialOperationRow,
          $$FinancialOperationsTableFilterComposer,
          $$FinancialOperationsTableOrderingComposer,
          $$FinancialOperationsTableAnnotationComposer,
          $$FinancialOperationsTableCreateCompanionBuilder,
          $$FinancialOperationsTableUpdateCompanionBuilder,
          (
            FinancialOperationRow,
            BaseReferences<
              _$AppDatabase,
              $FinancialOperationsTable,
              FinancialOperationRow
            >,
          ),
          FinancialOperationRow,
          PrefetchHooks Function()
        > {
  $$FinancialOperationsTableTableManager(
    _$AppDatabase db,
    $FinancialOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialOperationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinancialOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<FinancialOperationKind> kind = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> undoneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinancialOperationsCompanion(
                id: id,
                kind: kind,
                entityId: entityId,
                summary: summary,
                payloadJson: payloadJson,
                status: status,
                createdAt: createdAt,
                undoneAt: undoneAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required FinancialOperationKind kind,
                required String entityId,
                required String summary,
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> undoneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinancialOperationsCompanion.insert(
                id: id,
                kind: kind,
                entityId: entityId,
                summary: summary,
                payloadJson: payloadJson,
                status: status,
                createdAt: createdAt,
                undoneAt: undoneAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FinancialOperationsTable, FinancialOperationRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $FinancialOperationsTable,
                    FinancialOperationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FinancialOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinancialOperationsTable,
      FinancialOperationRow,
      $$FinancialOperationsTableFilterComposer,
      $$FinancialOperationsTableOrderingComposer,
      $$FinancialOperationsTableAnnotationComposer,
      $$FinancialOperationsTableCreateCompanionBuilder,
      $$FinancialOperationsTableUpdateCompanionBuilder,
      (
        FinancialOperationRow,
        BaseReferences<
          _$AppDatabase,
          $FinancialOperationsTable,
          FinancialOperationRow
        >,
      ),
      FinancialOperationRow,
      PrefetchHooks Function()
    >;
typedef $$SmsSenderLinksTableCreateCompanionBuilder =
    SmsSenderLinksCompanion Function({
      required String sender,
      required String accountId,
      required DateTime importFrom,
      Value<int> rowid,
    });
typedef $$SmsSenderLinksTableUpdateCompanionBuilder =
    SmsSenderLinksCompanion Function({
      Value<String> sender,
      Value<String> accountId,
      Value<DateTime> importFrom,
      Value<int> rowid,
    });

final class $$SmsSenderLinksTableReferences
    extends BaseReferences<_$AppDatabase, $SmsSenderLinksTable, SmsSenderLink> {
  $$SmsSenderLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('sms_sender_links__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SmsSenderLinksTableFilterComposer
    extends Composer<_$AppDatabase, $SmsSenderLinksTable> {
  $$SmsSenderLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importFrom => $composableBuilder(
    column: $table.importFrom,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmsSenderLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsSenderLinksTable> {
  $$SmsSenderLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importFrom => $composableBuilder(
    column: $table.importFrom,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmsSenderLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsSenderLinksTable> {
  $$SmsSenderLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<DateTime> get importFrom => $composableBuilder(
    column: $table.importFrom,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SmsSenderLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmsSenderLinksTable,
          SmsSenderLink,
          $$SmsSenderLinksTableFilterComposer,
          $$SmsSenderLinksTableOrderingComposer,
          $$SmsSenderLinksTableAnnotationComposer,
          $$SmsSenderLinksTableCreateCompanionBuilder,
          $$SmsSenderLinksTableUpdateCompanionBuilder,
          (SmsSenderLink, $$SmsSenderLinksTableReferences),
          SmsSenderLink,
          PrefetchHooks Function({bool accountId})
        > {
  $$SmsSenderLinksTableTableManager(
    _$AppDatabase db,
    $SmsSenderLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsSenderLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsSenderLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsSenderLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sender = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<DateTime> importFrom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsSenderLinksCompanion(
                sender: sender,
                accountId: accountId,
                importFrom: importFrom,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sender,
                required String accountId,
                required DateTime importFrom,
                Value<int> rowid = const Value.absent(),
              }) => SmsSenderLinksCompanion.insert(
                sender: sender,
                accountId: accountId,
                importFrom: importFrom,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmsSenderLinksTable, SmsSenderLink>(table),
                  $$SmsSenderLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$SmsSenderLinksTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$SmsSenderLinksTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SmsSenderLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmsSenderLinksTable,
      SmsSenderLink,
      $$SmsSenderLinksTableFilterComposer,
      $$SmsSenderLinksTableOrderingComposer,
      $$SmsSenderLinksTableAnnotationComposer,
      $$SmsSenderLinksTableCreateCompanionBuilder,
      $$SmsSenderLinksTableUpdateCompanionBuilder,
      (SmsSenderLink, $$SmsSenderLinksTableReferences),
      SmsSenderLink,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$SmsSuggestionsTableCreateCompanionBuilder =
    SmsSuggestionsCompanion Function({
      required String id,
      required String sender,
      required DateTime receivedAt,
      required String template,
      Value<String?> contextKey,
      Value<String?> contextMessageId,
      required String payload,
      Value<String> status,
      Value<DateTime?> editedAt,
      Value<int> rowid,
    });
typedef $$SmsSuggestionsTableUpdateCompanionBuilder =
    SmsSuggestionsCompanion Function({
      Value<String> id,
      Value<String> sender,
      Value<DateTime> receivedAt,
      Value<String> template,
      Value<String?> contextKey,
      Value<String?> contextMessageId,
      Value<String> payload,
      Value<String> status,
      Value<DateTime?> editedAt,
      Value<int> rowid,
    });

class $$SmsSuggestionsTableFilterComposer
    extends Composer<_$AppDatabase, $SmsSuggestionsTable> {
  $$SmsSuggestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextKey => $composableBuilder(
    column: $table.contextKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextMessageId => $composableBuilder(
    column: $table.contextMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmsSuggestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsSuggestionsTable> {
  $$SmsSuggestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get template => $composableBuilder(
    column: $table.template,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextKey => $composableBuilder(
    column: $table.contextKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextMessageId => $composableBuilder(
    column: $table.contextMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmsSuggestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsSuggestionsTable> {
  $$SmsSuggestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get template =>
      $composableBuilder(column: $table.template, builder: (column) => column);

  GeneratedColumn<String> get contextKey => $composableBuilder(
    column: $table.contextKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextMessageId => $composableBuilder(
    column: $table.contextMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);
}

class $$SmsSuggestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmsSuggestionsTable,
          SmsSuggestionRow,
          $$SmsSuggestionsTableFilterComposer,
          $$SmsSuggestionsTableOrderingComposer,
          $$SmsSuggestionsTableAnnotationComposer,
          $$SmsSuggestionsTableCreateCompanionBuilder,
          $$SmsSuggestionsTableUpdateCompanionBuilder,
          (
            SmsSuggestionRow,
            BaseReferences<
              _$AppDatabase,
              $SmsSuggestionsTable,
              SmsSuggestionRow
            >,
          ),
          SmsSuggestionRow,
          PrefetchHooks Function()
        > {
  $$SmsSuggestionsTableTableManager(
    _$AppDatabase db,
    $SmsSuggestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsSuggestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsSuggestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsSuggestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<String> template = const Value.absent(),
                Value<String?> contextKey = const Value.absent(),
                Value<String?> contextMessageId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsSuggestionsCompanion(
                id: id,
                sender: sender,
                receivedAt: receivedAt,
                template: template,
                contextKey: contextKey,
                contextMessageId: contextMessageId,
                payload: payload,
                status: status,
                editedAt: editedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sender,
                required DateTime receivedAt,
                required String template,
                Value<String?> contextKey = const Value.absent(),
                Value<String?> contextMessageId = const Value.absent(),
                required String payload,
                Value<String> status = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsSuggestionsCompanion.insert(
                id: id,
                sender: sender,
                receivedAt: receivedAt,
                template: template,
                contextKey: contextKey,
                contextMessageId: contextMessageId,
                payload: payload,
                status: status,
                editedAt: editedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmsSuggestionsTable, SmsSuggestionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SmsSuggestionsTable,
                    SmsSuggestionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmsSuggestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmsSuggestionsTable,
      SmsSuggestionRow,
      $$SmsSuggestionsTableFilterComposer,
      $$SmsSuggestionsTableOrderingComposer,
      $$SmsSuggestionsTableAnnotationComposer,
      $$SmsSuggestionsTableCreateCompanionBuilder,
      $$SmsSuggestionsTableUpdateCompanionBuilder,
      (
        SmsSuggestionRow,
        BaseReferences<_$AppDatabase, $SmsSuggestionsTable, SmsSuggestionRow>,
      ),
      SmsSuggestionRow,
      PrefetchHooks Function()
    >;
typedef $$SmsPatternsTableCreateCompanionBuilder =
    SmsPatternsCompanion Function({
      required String key,
      required String rule,
      Value<int> rowid,
    });
typedef $$SmsPatternsTableUpdateCompanionBuilder =
    SmsPatternsCompanion Function({
      Value<String> key,
      Value<String> rule,
      Value<int> rowid,
    });

class $$SmsPatternsTableFilterComposer
    extends Composer<_$AppDatabase, $SmsPatternsTable> {
  $$SmsPatternsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmsPatternsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsPatternsTable> {
  $$SmsPatternsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmsPatternsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsPatternsTable> {
  $$SmsPatternsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get rule =>
      $composableBuilder(column: $table.rule, builder: (column) => column);
}

class $$SmsPatternsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmsPatternsTable,
          SmsPatternRow,
          $$SmsPatternsTableFilterComposer,
          $$SmsPatternsTableOrderingComposer,
          $$SmsPatternsTableAnnotationComposer,
          $$SmsPatternsTableCreateCompanionBuilder,
          $$SmsPatternsTableUpdateCompanionBuilder,
          (
            SmsPatternRow,
            BaseReferences<_$AppDatabase, $SmsPatternsTable, SmsPatternRow>,
          ),
          SmsPatternRow,
          PrefetchHooks Function()
        > {
  $$SmsPatternsTableTableManager(_$AppDatabase db, $SmsPatternsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsPatternsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsPatternsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsPatternsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> rule = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SmsPatternsCompanion(key: key, rule: rule, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String rule,
            Value<int> rowid = const Value.absent(),
          }) => SmsPatternsCompanion.insert(key: key, rule: rule, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmsPatternsTable, SmsPatternRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SmsPatternsTable,
                    SmsPatternRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmsPatternsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmsPatternsTable,
      SmsPatternRow,
      $$SmsPatternsTableFilterComposer,
      $$SmsPatternsTableOrderingComposer,
      $$SmsPatternsTableAnnotationComposer,
      $$SmsPatternsTableCreateCompanionBuilder,
      $$SmsPatternsTableUpdateCompanionBuilder,
      (
        SmsPatternRow,
        BaseReferences<_$AppDatabase, $SmsPatternsTable, SmsPatternRow>,
      ),
      SmsPatternRow,
      PrefetchHooks Function()
    >;
typedef $$SmsSenderDismissalsTableCreateCompanionBuilder =
    SmsSenderDismissalsCompanion Function({
      required String sender,
      Value<int> rowid,
    });
typedef $$SmsSenderDismissalsTableUpdateCompanionBuilder =
    SmsSenderDismissalsCompanion Function({
      Value<String> sender,
      Value<int> rowid,
    });

class $$SmsSenderDismissalsTableFilterComposer
    extends Composer<_$AppDatabase, $SmsSenderDismissalsTable> {
  $$SmsSenderDismissalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmsSenderDismissalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsSenderDismissalsTable> {
  $$SmsSenderDismissalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmsSenderDismissalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsSenderDismissalsTable> {
  $$SmsSenderDismissalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);
}

class $$SmsSenderDismissalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmsSenderDismissalsTable,
          SmsSenderDismissal,
          $$SmsSenderDismissalsTableFilterComposer,
          $$SmsSenderDismissalsTableOrderingComposer,
          $$SmsSenderDismissalsTableAnnotationComposer,
          $$SmsSenderDismissalsTableCreateCompanionBuilder,
          $$SmsSenderDismissalsTableUpdateCompanionBuilder,
          (
            SmsSenderDismissal,
            BaseReferences<
              _$AppDatabase,
              $SmsSenderDismissalsTable,
              SmsSenderDismissal
            >,
          ),
          SmsSenderDismissal,
          PrefetchHooks Function()
        > {
  $$SmsSenderDismissalsTableTableManager(
    _$AppDatabase db,
    $SmsSenderDismissalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsSenderDismissalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsSenderDismissalsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SmsSenderDismissalsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback: ({
            Value<String> sender = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SmsSenderDismissalsCompanion(sender: sender, rowid: rowid),
          createCompanionCallback:
              ({
                required String sender,
                Value<int> rowid = const Value.absent(),
              }) => SmsSenderDismissalsCompanion.insert(
                sender: sender,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SmsSenderDismissalsTable, SmsSenderDismissal>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SmsSenderDismissalsTable,
                    SmsSenderDismissal
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmsSenderDismissalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmsSenderDismissalsTable,
      SmsSenderDismissal,
      $$SmsSenderDismissalsTableFilterComposer,
      $$SmsSenderDismissalsTableOrderingComposer,
      $$SmsSenderDismissalsTableAnnotationComposer,
      $$SmsSenderDismissalsTableCreateCompanionBuilder,
      $$SmsSenderDismissalsTableUpdateCompanionBuilder,
      (
        SmsSenderDismissal,
        BaseReferences<
          _$AppDatabase,
          $SmsSenderDismissalsTable,
          SmsSenderDismissal
        >,
      ),
      SmsSenderDismissal,
      PrefetchHooks Function()
    >;
typedef $$ObligationsTableCreateCompanionBuilder =
    ObligationsCompanion Function({
      required String id,
      required String counterparty,
      required bool isReceivable,
      required int amountRial,
      Value<DateTime?> dueDate,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ObligationsTableUpdateCompanionBuilder =
    ObligationsCompanion Function({
      Value<String> id,
      Value<String> counterparty,
      Value<bool> isReceivable,
      Value<int> amountRial,
      Value<DateTime?> dueDate,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ObligationsTableReferences
    extends BaseReferences<_$AppDatabase, $ObligationsTable, ObligationRow> {
  $$ObligationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $ObligationPaymentsTable,
    List<ObligationPaymentRow>
  >
  _obligationPaymentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.obligationPayments,
        aliasName: 'obligations__id__obligation_payments__obligation_id',
      );

  $$ObligationPaymentsTableProcessedTableManager get obligationPaymentsRefs {
    final manager = $$ObligationPaymentsTableTableManager(
      $_db,
      $_db.obligationPayments,
    ).filter((f) => f.obligationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _obligationPaymentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ObligationsTableFilterComposer
    extends Composer<_$AppDatabase, $ObligationsTable> {
  $$ObligationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReceivable => $composableBuilder(
    column: $table.isReceivable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> obligationPaymentsRefs(
    Expression<bool> Function($$ObligationPaymentsTableFilterComposer f) f,
  ) {
    final $$ObligationPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.obligationPayments,
      getReferencedColumn: (t) => t.obligationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObligationPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.obligationPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ObligationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ObligationsTable> {
  $$ObligationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReceivable => $composableBuilder(
    column: $table.isReceivable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ObligationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ObligationsTable> {
  $$ObligationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isReceivable => $composableBuilder(
    column: $table.isReceivable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> obligationPaymentsRefs<T extends Object>(
    Expression<T> Function($$ObligationPaymentsTableAnnotationComposer a) f,
  ) {
    final $$ObligationPaymentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.obligationPayments,
          getReferencedColumn: (t) => t.obligationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ObligationPaymentsTableAnnotationComposer(
                $db: $db,
                $table: $db.obligationPayments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ObligationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ObligationsTable,
          ObligationRow,
          $$ObligationsTableFilterComposer,
          $$ObligationsTableOrderingComposer,
          $$ObligationsTableAnnotationComposer,
          $$ObligationsTableCreateCompanionBuilder,
          $$ObligationsTableUpdateCompanionBuilder,
          (ObligationRow, $$ObligationsTableReferences),
          ObligationRow,
          PrefetchHooks Function({bool obligationPaymentsRefs})
        > {
  $$ObligationsTableTableManager(_$AppDatabase db, $ObligationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObligationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObligationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObligationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> counterparty = const Value.absent(),
                Value<bool> isReceivable = const Value.absent(),
                Value<int> amountRial = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObligationsCompanion(
                id: id,
                counterparty: counterparty,
                isReceivable: isReceivable,
                amountRial: amountRial,
                dueDate: dueDate,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String counterparty,
                required bool isReceivable,
                required int amountRial,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ObligationsCompanion.insert(
                id: id,
                counterparty: counterparty,
                isReceivable: isReceivable,
                amountRial: amountRial,
                dueDate: dueDate,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ObligationsTable, ObligationRow>(table),
                  $$ObligationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({obligationPaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (obligationPaymentsRefs) db.obligationPayments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (obligationPaymentsRefs)
                    await $_getPrefetchedDataByColumns<
                      ObligationRow,
                      $ObligationsTable,
                      ObligationPaymentRow,
                      $ObligationPaymentsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ObligationsTableReferences
                          ._obligationPaymentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ObligationsTableReferences(
                            db,
                            table,
                            p0,
                          ).obligationPaymentsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'obligation_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ObligationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ObligationsTable,
      ObligationRow,
      $$ObligationsTableFilterComposer,
      $$ObligationsTableOrderingComposer,
      $$ObligationsTableAnnotationComposer,
      $$ObligationsTableCreateCompanionBuilder,
      $$ObligationsTableUpdateCompanionBuilder,
      (ObligationRow, $$ObligationsTableReferences),
      ObligationRow,
      PrefetchHooks Function({bool obligationPaymentsRefs})
    >;
typedef $$ObligationPaymentsTableCreateCompanionBuilder =
    ObligationPaymentsCompanion Function({
      required String id,
      required String obligationId,
      required int amountRial,
      required DateTime paidOn,
      Value<int> rowid,
    });
typedef $$ObligationPaymentsTableUpdateCompanionBuilder =
    ObligationPaymentsCompanion Function({
      Value<String> id,
      Value<String> obligationId,
      Value<int> amountRial,
      Value<DateTime> paidOn,
      Value<int> rowid,
    });

final class $$ObligationPaymentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ObligationPaymentsTable,
          ObligationPaymentRow
        > {
  $$ObligationPaymentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ObligationsTable _obligationIdTable(_$AppDatabase db) => db
      .obligations
      .createAlias('obligation_payments__obligation_id__obligations__id');

  $$ObligationsTableProcessedTableManager get obligationId {
    final $_column = $_itemColumn<String>('obligation_id')!;

    final manager = $$ObligationsTableTableManager(
      $_db,
      $_db.obligations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_obligationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ObligationPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $ObligationPaymentsTable> {
  $$ObligationPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnFilters(column),
  );

  $$ObligationsTableFilterComposer get obligationId {
    final $$ObligationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.obligationId,
      referencedTable: $db.obligations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObligationsTableFilterComposer(
            $db: $db,
            $table: $db.obligations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObligationPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ObligationPaymentsTable> {
  $$ObligationPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnOrderings(column),
  );

  $$ObligationsTableOrderingComposer get obligationId {
    final $$ObligationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.obligationId,
      referencedTable: $db.obligations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObligationsTableOrderingComposer(
            $db: $db,
            $table: $db.obligations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObligationPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ObligationPaymentsTable> {
  $$ObligationPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountRial => $composableBuilder(
    column: $table.amountRial,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidOn =>
      $composableBuilder(column: $table.paidOn, builder: (column) => column);

  $$ObligationsTableAnnotationComposer get obligationId {
    final $$ObligationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.obligationId,
      referencedTable: $db.obligations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObligationsTableAnnotationComposer(
            $db: $db,
            $table: $db.obligations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObligationPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ObligationPaymentsTable,
          ObligationPaymentRow,
          $$ObligationPaymentsTableFilterComposer,
          $$ObligationPaymentsTableOrderingComposer,
          $$ObligationPaymentsTableAnnotationComposer,
          $$ObligationPaymentsTableCreateCompanionBuilder,
          $$ObligationPaymentsTableUpdateCompanionBuilder,
          (ObligationPaymentRow, $$ObligationPaymentsTableReferences),
          ObligationPaymentRow,
          PrefetchHooks Function({bool obligationId})
        > {
  $$ObligationPaymentsTableTableManager(
    _$AppDatabase db,
    $ObligationPaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObligationPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObligationPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObligationPaymentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> obligationId = const Value.absent(),
                Value<int> amountRial = const Value.absent(),
                Value<DateTime> paidOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObligationPaymentsCompanion(
                id: id,
                obligationId: obligationId,
                amountRial: amountRial,
                paidOn: paidOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String obligationId,
                required int amountRial,
                required DateTime paidOn,
                Value<int> rowid = const Value.absent(),
              }) => ObligationPaymentsCompanion.insert(
                id: id,
                obligationId: obligationId,
                amountRial: amountRial,
                paidOn: paidOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ObligationPaymentsTable, ObligationPaymentRow>(
                    table,
                  ),
                  $$ObligationPaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({obligationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (obligationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.obligationId,
                        referencedTable: $$ObligationPaymentsTableReferences
                            ._obligationIdTable(db),
                        referencedColumn: $$ObligationPaymentsTableReferences
                            ._obligationIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ObligationPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ObligationPaymentsTable,
      ObligationPaymentRow,
      $$ObligationPaymentsTableFilterComposer,
      $$ObligationPaymentsTableOrderingComposer,
      $$ObligationPaymentsTableAnnotationComposer,
      $$ObligationPaymentsTableCreateCompanionBuilder,
      $$ObligationPaymentsTableUpdateCompanionBuilder,
      (ObligationPaymentRow, $$ObligationPaymentsTableReferences),
      ObligationPaymentRow,
      PrefetchHooks Function({bool obligationId})
    >;
typedef $$AssetHoldingsTableCreateCompanionBuilder =
    AssetHoldingsCompanion Function({
      required String id,
      required String name,
      required AssetKind kind,
      Value<String?> currencyCode,
      required int quantityMicros,
      Value<int?> rateRial,
      Value<DateTime?> rateDate,
      Value<bool> isMarketRate,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AssetHoldingsTableUpdateCompanionBuilder =
    AssetHoldingsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<AssetKind> kind,
      Value<String?> currencyCode,
      Value<int> quantityMicros,
      Value<int?> rateRial,
      Value<DateTime?> rateDate,
      Value<bool> isMarketRate,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AssetHoldingsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetHoldingsTable> {
  $$AssetHoldingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetKind, AssetKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityMicros => $composableBuilder(
    column: $table.quantityMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateRial => $composableBuilder(
    column: $table.rateRial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rateDate => $composableBuilder(
    column: $table.rateDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMarketRate => $composableBuilder(
    column: $table.isMarketRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AssetHoldingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetHoldingsTable> {
  $$AssetHoldingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityMicros => $composableBuilder(
    column: $table.quantityMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateRial => $composableBuilder(
    column: $table.rateRial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rateDate => $composableBuilder(
    column: $table.rateDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMarketRate => $composableBuilder(
    column: $table.isMarketRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetHoldingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetHoldingsTable> {
  $$AssetHoldingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssetKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityMicros => $composableBuilder(
    column: $table.quantityMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rateRial =>
      $composableBuilder(column: $table.rateRial, builder: (column) => column);

  GeneratedColumn<DateTime> get rateDate =>
      $composableBuilder(column: $table.rateDate, builder: (column) => column);

  GeneratedColumn<bool> get isMarketRate => $composableBuilder(
    column: $table.isMarketRate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AssetHoldingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetHoldingsTable,
          AssetHoldingRow,
          $$AssetHoldingsTableFilterComposer,
          $$AssetHoldingsTableOrderingComposer,
          $$AssetHoldingsTableAnnotationComposer,
          $$AssetHoldingsTableCreateCompanionBuilder,
          $$AssetHoldingsTableUpdateCompanionBuilder,
          (
            AssetHoldingRow,
            BaseReferences<_$AppDatabase, $AssetHoldingsTable, AssetHoldingRow>,
          ),
          AssetHoldingRow,
          PrefetchHooks Function()
        > {
  $$AssetHoldingsTableTableManager(_$AppDatabase db, $AssetHoldingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetHoldingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetHoldingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetHoldingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AssetKind> kind = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<int> quantityMicros = const Value.absent(),
                Value<int?> rateRial = const Value.absent(),
                Value<DateTime?> rateDate = const Value.absent(),
                Value<bool> isMarketRate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetHoldingsCompanion(
                id: id,
                name: name,
                kind: kind,
                currencyCode: currencyCode,
                quantityMicros: quantityMicros,
                rateRial: rateRial,
                rateDate: rateDate,
                isMarketRate: isMarketRate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required AssetKind kind,
                Value<String?> currencyCode = const Value.absent(),
                required int quantityMicros,
                Value<int?> rateRial = const Value.absent(),
                Value<DateTime?> rateDate = const Value.absent(),
                Value<bool> isMarketRate = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AssetHoldingsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                currencyCode: currencyCode,
                quantityMicros: quantityMicros,
                rateRial: rateRial,
                rateDate: rateDate,
                isMarketRate: isMarketRate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetHoldingsTable, AssetHoldingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AssetHoldingsTable,
                    AssetHoldingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AssetHoldingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetHoldingsTable,
      AssetHoldingRow,
      $$AssetHoldingsTableFilterComposer,
      $$AssetHoldingsTableOrderingComposer,
      $$AssetHoldingsTableAnnotationComposer,
      $$AssetHoldingsTableCreateCompanionBuilder,
      $$AssetHoldingsTableUpdateCompanionBuilder,
      (
        AssetHoldingRow,
        BaseReferences<_$AppDatabase, $AssetHoldingsTable, AssetHoldingRow>,
      ),
      AssetHoldingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db, _db.loans);
  $$InstallmentsTableTableManager get installments =>
      $$InstallmentsTableTableManager(_db, _db.installments);
  $$ChatSessionsTableTableManager get chatSessions =>
      $$ChatSessionsTableTableManager(_db, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$PendingActionsTableTableManager get pendingActions =>
      $$PendingActionsTableTableManager(_db, _db.pendingActions);
  $$FinancialOperationsTableTableManager get financialOperations =>
      $$FinancialOperationsTableTableManager(_db, _db.financialOperations);
  $$SmsSenderLinksTableTableManager get smsSenderLinks =>
      $$SmsSenderLinksTableTableManager(_db, _db.smsSenderLinks);
  $$SmsSuggestionsTableTableManager get smsSuggestions =>
      $$SmsSuggestionsTableTableManager(_db, _db.smsSuggestions);
  $$SmsPatternsTableTableManager get smsPatterns =>
      $$SmsPatternsTableTableManager(_db, _db.smsPatterns);
  $$SmsSenderDismissalsTableTableManager get smsSenderDismissals =>
      $$SmsSenderDismissalsTableTableManager(_db, _db.smsSenderDismissals);
  $$ObligationsTableTableManager get obligations =>
      $$ObligationsTableTableManager(_db, _db.obligations);
  $$ObligationPaymentsTableTableManager get obligationPayments =>
      $$ObligationPaymentsTableTableManager(_db, _db.obligationPayments);
  $$AssetHoldingsTableTableManager get assetHoldings =>
      $$AssetHoldingsTableTableManager(_db, _db.assetHoldings);
}
