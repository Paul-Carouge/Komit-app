// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, HabitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _colorArgbMeta = const VerificationMeta('colorArgb');
  @override
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderMinuteOfDayMeta = const VerificationMeta('reminderMinuteOfDay');
  @override
  late final GeneratedColumn<int> reminderMinuteOfDay = GeneratedColumn<int>(
    'reminder_minute_of_day',
    aliasedName,
    true,
    check: () => ComparableExpr(reminderMinuteOfDay).isBetweenValues(0, 1439),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledWeekdayMaskMeta = const VerificationMeta('scheduledWeekdayMask');
  @override
  late final GeneratedColumn<int> scheduledWeekdayMask = GeneratedColumn<int>(
    'scheduled_weekday_mask',
    aliasedName,
    false,
    check: () => ComparableExpr(scheduledWeekdayMask).isBetweenValues(1, everyWeekdayMask),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0x7F),
  );
  static const VerificationMeta _targetDaysPerWeekMeta = const VerificationMeta('targetDaysPerWeek');
  @override
  late final GeneratedColumn<int> targetDaysPerWeek = GeneratedColumn<int>(
    'target_days_per_week',
    aliasedName,
    true,
    check: () => ComparableExpr(targetDaysPerWeek).isBetweenValues(minimumTargetDaysPerWeek, maximumTargetDaysPerWeek),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restDaysPerWeekMeta = const VerificationMeta('restDaysPerWeek');
  @override
  late final GeneratedColumn<int> restDaysPerWeek = GeneratedColumn<int>(
    'rest_days_per_week',
    aliasedName,
    false,
    check: () => ComparableExpr(restDaysPerWeek).isBetweenValues(0, maximumRestDaysPerWeek),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    colorArgb,
    iconName,
    reminderMinuteOfDay,
    sortOrder,
    createdAt,
    scheduledWeekdayMask,
    targetDaysPerWeek,
    archivedAt,
    restDaysPerWeek,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(Insertable<HabitRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(_descriptionMeta, description.isAcceptableOrUnknown(data['description']!, _descriptionMeta));
    }
    if (data.containsKey('color_argb')) {
      context.handle(_colorArgbMeta, colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta));
    } else if (isInserting) {
      context.missing(_colorArgbMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta, iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('reminder_minute_of_day')) {
      context.handle(
        _reminderMinuteOfDayMeta,
        reminderMinuteOfDay.isAcceptableOrUnknown(data['reminder_minute_of_day']!, _reminderMinuteOfDayMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('scheduled_weekday_mask')) {
      context.handle(
        _scheduledWeekdayMaskMeta,
        scheduledWeekdayMask.isAcceptableOrUnknown(data['scheduled_weekday_mask']!, _scheduledWeekdayMaskMeta),
      );
    }
    if (data.containsKey('target_days_per_week')) {
      context.handle(
        _targetDaysPerWeekMeta,
        targetDaysPerWeek.isAcceptableOrUnknown(data['target_days_per_week']!, _targetDaysPerWeekMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(_archivedAtMeta, archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('rest_days_per_week')) {
      context.handle(
        _restDaysPerWeekMeta,
        restDaysPerWeek.isAcceptableOrUnknown(data['rest_days_per_week']!, _restDaysPerWeekMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      colorArgb: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color_argb'])!,
      iconName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon_name'])!,
      reminderMinuteOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute_of_day'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      scheduledWeekdayMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_weekday_mask'],
      )!,
      targetDaysPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_days_per_week'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
      restDaysPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_days_per_week'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class HabitRow extends DataClass implements Insertable<HabitRow> {
  final int id;
  final String title;
  final String description;
  final int colorArgb;
  final String iconName;

  /// Minutes after local midnight; null when the daily reminder is off.
  final int? reminderMinuteOfDay;
  final int sortOrder;
  final DateTime createdAt;
  final int scheduledWeekdayMask;

  /// Null for a daily habit; otherwise the habit succeeds on weeks with this many success days.
  final int? targetDaysPerWeek;

  /// Null while the habit is active.
  final DateTime? archivedAt;

  /// Missed scheduled days per ISO week that keep a daily or weekday streak alive (docs/adr/0007).
  final int restDaysPerWeek;
  const HabitRow({
    required this.id,
    required this.title,
    required this.description,
    required this.colorArgb,
    required this.iconName,
    this.reminderMinuteOfDay,
    required this.sortOrder,
    required this.createdAt,
    required this.scheduledWeekdayMask,
    this.targetDaysPerWeek,
    this.archivedAt,
    required this.restDaysPerWeek,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['color_argb'] = Variable<int>(colorArgb);
    map['icon_name'] = Variable<String>(iconName);
    if (!nullToAbsent || reminderMinuteOfDay != null) {
      map['reminder_minute_of_day'] = Variable<int>(reminderMinuteOfDay);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['scheduled_weekday_mask'] = Variable<int>(scheduledWeekdayMask);
    if (!nullToAbsent || targetDaysPerWeek != null) {
      map['target_days_per_week'] = Variable<int>(targetDaysPerWeek);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['rest_days_per_week'] = Variable<int>(restDaysPerWeek);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      colorArgb: Value(colorArgb),
      iconName: Value(iconName),
      reminderMinuteOfDay: reminderMinuteOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinuteOfDay),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      scheduledWeekdayMask: Value(scheduledWeekdayMask),
      targetDaysPerWeek: targetDaysPerWeek == null && nullToAbsent ? const Value.absent() : Value(targetDaysPerWeek),
      archivedAt: archivedAt == null && nullToAbsent ? const Value.absent() : Value(archivedAt),
      restDaysPerWeek: Value(restDaysPerWeek),
    );
  }

  factory HabitRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      colorArgb: serializer.fromJson<int>(json['colorArgb']),
      iconName: serializer.fromJson<String>(json['iconName']),
      reminderMinuteOfDay: serializer.fromJson<int?>(json['reminderMinuteOfDay']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      scheduledWeekdayMask: serializer.fromJson<int>(json['scheduledWeekdayMask']),
      targetDaysPerWeek: serializer.fromJson<int?>(json['targetDaysPerWeek']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      restDaysPerWeek: serializer.fromJson<int>(json['restDaysPerWeek']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'colorArgb': serializer.toJson<int>(colorArgb),
      'iconName': serializer.toJson<String>(iconName),
      'reminderMinuteOfDay': serializer.toJson<int?>(reminderMinuteOfDay),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'scheduledWeekdayMask': serializer.toJson<int>(scheduledWeekdayMask),
      'targetDaysPerWeek': serializer.toJson<int?>(targetDaysPerWeek),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'restDaysPerWeek': serializer.toJson<int>(restDaysPerWeek),
    };
  }

  HabitRow copyWith({
    int? id,
    String? title,
    String? description,
    int? colorArgb,
    String? iconName,
    Value<int?> reminderMinuteOfDay = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    int? scheduledWeekdayMask,
    Value<int?> targetDaysPerWeek = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    int? restDaysPerWeek,
  }) => HabitRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    colorArgb: colorArgb ?? this.colorArgb,
    iconName: iconName ?? this.iconName,
    reminderMinuteOfDay: reminderMinuteOfDay.present ? reminderMinuteOfDay.value : this.reminderMinuteOfDay,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    scheduledWeekdayMask: scheduledWeekdayMask ?? this.scheduledWeekdayMask,
    targetDaysPerWeek: targetDaysPerWeek.present ? targetDaysPerWeek.value : this.targetDaysPerWeek,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    restDaysPerWeek: restDaysPerWeek ?? this.restDaysPerWeek,
  );
  HabitRow copyWithCompanion(HabitsCompanion data) {
    return HabitRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present ? data.description.value : this.description,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      reminderMinuteOfDay: data.reminderMinuteOfDay.present ? data.reminderMinuteOfDay.value : this.reminderMinuteOfDay,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      scheduledWeekdayMask: data.scheduledWeekdayMask.present
          ? data.scheduledWeekdayMask.value
          : this.scheduledWeekdayMask,
      targetDaysPerWeek: data.targetDaysPerWeek.present ? data.targetDaysPerWeek.value : this.targetDaysPerWeek,
      archivedAt: data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      restDaysPerWeek: data.restDaysPerWeek.present ? data.restDaysPerWeek.value : this.restDaysPerWeek,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('iconName: $iconName, ')
          ..write('reminderMinuteOfDay: $reminderMinuteOfDay, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('scheduledWeekdayMask: $scheduledWeekdayMask, ')
          ..write('targetDaysPerWeek: $targetDaysPerWeek, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('restDaysPerWeek: $restDaysPerWeek')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    colorArgb,
    iconName,
    reminderMinuteOfDay,
    sortOrder,
    createdAt,
    scheduledWeekdayMask,
    targetDaysPerWeek,
    archivedAt,
    restDaysPerWeek,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.colorArgb == this.colorArgb &&
          other.iconName == this.iconName &&
          other.reminderMinuteOfDay == this.reminderMinuteOfDay &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.scheduledWeekdayMask == this.scheduledWeekdayMask &&
          other.targetDaysPerWeek == this.targetDaysPerWeek &&
          other.archivedAt == this.archivedAt &&
          other.restDaysPerWeek == this.restDaysPerWeek);
}

class HabitsCompanion extends UpdateCompanion<HabitRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> description;
  final Value<int> colorArgb;
  final Value<String> iconName;
  final Value<int?> reminderMinuteOfDay;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> scheduledWeekdayMask;
  final Value<int?> targetDaysPerWeek;
  final Value<DateTime?> archivedAt;
  final Value<int> restDaysPerWeek;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.iconName = const Value.absent(),
    this.reminderMinuteOfDay = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.scheduledWeekdayMask = const Value.absent(),
    this.targetDaysPerWeek = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.restDaysPerWeek = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int colorArgb,
    required String iconName,
    this.reminderMinuteOfDay = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.scheduledWeekdayMask = const Value.absent(),
    this.targetDaysPerWeek = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.restDaysPerWeek = const Value.absent(),
  }) : title = Value(title),
       colorArgb = Value(colorArgb),
       iconName = Value(iconName),
       createdAt = Value(createdAt);
  static Insertable<HabitRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? colorArgb,
    Expression<String>? iconName,
    Expression<int>? reminderMinuteOfDay,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? scheduledWeekdayMask,
    Expression<int>? targetDaysPerWeek,
    Expression<DateTime>? archivedAt,
    Expression<int>? restDaysPerWeek,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (iconName != null) 'icon_name': iconName,
      if (reminderMinuteOfDay != null) 'reminder_minute_of_day': reminderMinuteOfDay,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (scheduledWeekdayMask != null) 'scheduled_weekday_mask': scheduledWeekdayMask,
      if (targetDaysPerWeek != null) 'target_days_per_week': targetDaysPerWeek,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (restDaysPerWeek != null) 'rest_days_per_week': restDaysPerWeek,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? description,
    Value<int>? colorArgb,
    Value<String>? iconName,
    Value<int?>? reminderMinuteOfDay,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? scheduledWeekdayMask,
    Value<int?>? targetDaysPerWeek,
    Value<DateTime?>? archivedAt,
    Value<int>? restDaysPerWeek,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      colorArgb: colorArgb ?? this.colorArgb,
      iconName: iconName ?? this.iconName,
      reminderMinuteOfDay: reminderMinuteOfDay ?? this.reminderMinuteOfDay,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      scheduledWeekdayMask: scheduledWeekdayMask ?? this.scheduledWeekdayMask,
      targetDaysPerWeek: targetDaysPerWeek ?? this.targetDaysPerWeek,
      archivedAt: archivedAt ?? this.archivedAt,
      restDaysPerWeek: restDaysPerWeek ?? this.restDaysPerWeek,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (reminderMinuteOfDay.present) {
      map['reminder_minute_of_day'] = Variable<int>(reminderMinuteOfDay.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (scheduledWeekdayMask.present) {
      map['scheduled_weekday_mask'] = Variable<int>(scheduledWeekdayMask.value);
    }
    if (targetDaysPerWeek.present) {
      map['target_days_per_week'] = Variable<int>(targetDaysPerWeek.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (restDaysPerWeek.present) {
      map['rest_days_per_week'] = Variable<int>(restDaysPerWeek.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('iconName: $iconName, ')
          ..write('reminderMinuteOfDay: $reminderMinuteOfDay, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('scheduledWeekdayMask: $scheduledWeekdayMask, ')
          ..write('targetDaysPerWeek: $targetDaysPerWeek, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('restDaysPerWeek: $restDaysPerWeek')
          ..write(')'))
        .toString();
  }
}

class $ObjectivesTable extends Objectives with TableInfo<$ObjectivesTable, ObjectiveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObjectivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES habits (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorArgbMeta = const VerificationMeta('colorArgb');
  @override
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countsAsSuccessMeta = const VerificationMeta('countsAsSuccess');
  @override
  late final GeneratedColumn<bool> countsAsSuccess = GeneratedColumn<bool>(
    'counts_as_success',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("counts_as_success" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, title, colorArgb, sortOrder, countsAsSuccess];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'objectives';
  @override
  VerificationContext validateIntegrity(Insertable<ObjectiveRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta, habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('color_argb')) {
      context.handle(_colorArgbMeta, colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta));
    } else if (isInserting) {
      context.missing(_colorArgbMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('counts_as_success')) {
      context.handle(
        _countsAsSuccessMeta,
        countsAsSuccess.isAcceptableOrUnknown(data['counts_as_success']!, _countsAsSuccessMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, title},
  ];
  @override
  ObjectiveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObjectiveRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}habit_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      colorArgb: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color_argb'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      countsAsSuccess: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counts_as_success'],
      )!,
    );
  }

  @override
  $ObjectivesTable createAlias(String alias) {
    return $ObjectivesTable(attachedDatabase, alias);
  }
}

class ObjectiveRow extends DataClass implements Insertable<ObjectiveRow> {
  final int id;
  final int habitId;
  final String title;
  final int colorArgb;
  final int sortOrder;

  /// False for outcomes such as "Skipped" that are logged but must not extend a streak.
  final bool countsAsSuccess;
  const ObjectiveRow({
    required this.id,
    required this.habitId,
    required this.title,
    required this.colorArgb,
    required this.sortOrder,
    required this.countsAsSuccess,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['title'] = Variable<String>(title);
    map['color_argb'] = Variable<int>(colorArgb);
    map['sort_order'] = Variable<int>(sortOrder);
    map['counts_as_success'] = Variable<bool>(countsAsSuccess);
    return map;
  }

  ObjectivesCompanion toCompanion(bool nullToAbsent) {
    return ObjectivesCompanion(
      id: Value(id),
      habitId: Value(habitId),
      title: Value(title),
      colorArgb: Value(colorArgb),
      sortOrder: Value(sortOrder),
      countsAsSuccess: Value(countsAsSuccess),
    );
  }

  factory ObjectiveRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObjectiveRow(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      title: serializer.fromJson<String>(json['title']),
      colorArgb: serializer.fromJson<int>(json['colorArgb']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      countsAsSuccess: serializer.fromJson<bool>(json['countsAsSuccess']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'title': serializer.toJson<String>(title),
      'colorArgb': serializer.toJson<int>(colorArgb),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'countsAsSuccess': serializer.toJson<bool>(countsAsSuccess),
    };
  }

  ObjectiveRow copyWith({
    int? id,
    int? habitId,
    String? title,
    int? colorArgb,
    int? sortOrder,
    bool? countsAsSuccess,
  }) => ObjectiveRow(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    title: title ?? this.title,
    colorArgb: colorArgb ?? this.colorArgb,
    sortOrder: sortOrder ?? this.sortOrder,
    countsAsSuccess: countsAsSuccess ?? this.countsAsSuccess,
  );
  ObjectiveRow copyWithCompanion(ObjectivesCompanion data) {
    return ObjectiveRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      title: data.title.present ? data.title.value : this.title,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      countsAsSuccess: data.countsAsSuccess.present ? data.countsAsSuccess.value : this.countsAsSuccess,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObjectiveRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('title: $title, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('countsAsSuccess: $countsAsSuccess')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, title, colorArgb, sortOrder, countsAsSuccess);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObjectiveRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.title == this.title &&
          other.colorArgb == this.colorArgb &&
          other.sortOrder == this.sortOrder &&
          other.countsAsSuccess == this.countsAsSuccess);
}

class ObjectivesCompanion extends UpdateCompanion<ObjectiveRow> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<String> title;
  final Value<int> colorArgb;
  final Value<int> sortOrder;
  final Value<bool> countsAsSuccess;
  const ObjectivesCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.title = const Value.absent(),
    this.colorArgb = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.countsAsSuccess = const Value.absent(),
  });
  ObjectivesCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required String title,
    required int colorArgb,
    required int sortOrder,
    this.countsAsSuccess = const Value.absent(),
  }) : habitId = Value(habitId),
       title = Value(title),
       colorArgb = Value(colorArgb),
       sortOrder = Value(sortOrder);
  static Insertable<ObjectiveRow> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<String>? title,
    Expression<int>? colorArgb,
    Expression<int>? sortOrder,
    Expression<bool>? countsAsSuccess,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (title != null) 'title': title,
      if (colorArgb != null) 'color_argb': colorArgb,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (countsAsSuccess != null) 'counts_as_success': countsAsSuccess,
    });
  }

  ObjectivesCompanion copyWith({
    Value<int>? id,
    Value<int>? habitId,
    Value<String>? title,
    Value<int>? colorArgb,
    Value<int>? sortOrder,
    Value<bool>? countsAsSuccess,
  }) {
    return ObjectivesCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      title: title ?? this.title,
      colorArgb: colorArgb ?? this.colorArgb,
      sortOrder: sortOrder ?? this.sortOrder,
      countsAsSuccess: countsAsSuccess ?? this.countsAsSuccess,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (countsAsSuccess.present) {
      map['counts_as_success'] = Variable<bool>(countsAsSuccess.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObjectivesCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('title: $title, ')
          ..write('colorArgb: $colorArgb, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('countsAsSuccess: $countsAsSuccess')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTable extends HabitLogs with TableInfo<$HabitLogsTable, HabitLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES habits (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _objectiveIdMeta = const VerificationMeta('objectiveId');
  @override
  late final GeneratedColumn<int> objectiveId = GeneratedColumn<int>(
    'objective_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES objectives (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, objectiveId, day];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<HabitLogRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta, habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('objective_id')) {
      context.handle(_objectiveIdMeta, objectiveId.isAcceptableOrUnknown(data['objective_id']!, _objectiveIdMeta));
    } else if (isInserting) {
      context.missing(_objectiveIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, day},
  ];
  @override
  HabitLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLogRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}habit_id'])!,
      objectiveId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}objective_id'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
    );
  }

  @override
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }
}

class HabitLogRow extends DataClass implements Insertable<HabitLogRow> {
  final int id;
  final int habitId;
  final int objectiveId;

  /// A [CalendarDay], so one log per habit per calendar day.
  final int day;
  const HabitLogRow({required this.id, required this.habitId, required this.objectiveId, required this.day});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['objective_id'] = Variable<int>(objectiveId);
    map['day'] = Variable<int>(day);
    return map;
  }

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(id: Value(id), habitId: Value(habitId), objectiveId: Value(objectiveId), day: Value(day));
  }

  factory HabitLogRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLogRow(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      objectiveId: serializer.fromJson<int>(json['objectiveId']),
      day: serializer.fromJson<int>(json['day']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'objectiveId': serializer.toJson<int>(objectiveId),
      'day': serializer.toJson<int>(day),
    };
  }

  HabitLogRow copyWith({int? id, int? habitId, int? objectiveId, int? day}) => HabitLogRow(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    objectiveId: objectiveId ?? this.objectiveId,
    day: day ?? this.day,
  );
  HabitLogRow copyWithCompanion(HabitLogsCompanion data) {
    return HabitLogRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      objectiveId: data.objectiveId.present ? data.objectiveId.value : this.objectiveId,
      day: data.day.present ? data.day.value : this.day,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('objectiveId: $objectiveId, ')
          ..write('day: $day')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, objectiveId, day);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLogRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.objectiveId == this.objectiveId &&
          other.day == this.day);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLogRow> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<int> objectiveId;
  final Value<int> day;
  const HabitLogsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.objectiveId = const Value.absent(),
    this.day = const Value.absent(),
  });
  HabitLogsCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required int objectiveId,
    required int day,
  }) : habitId = Value(habitId),
       objectiveId = Value(objectiveId),
       day = Value(day);
  static Insertable<HabitLogRow> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<int>? objectiveId,
    Expression<int>? day,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (objectiveId != null) 'objective_id': objectiveId,
      if (day != null) 'day': day,
    });
  }

  HabitLogsCompanion copyWith({Value<int>? id, Value<int>? habitId, Value<int>? objectiveId, Value<int>? day}) {
    return HabitLogsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      objectiveId: objectiveId ?? this.objectiveId,
      day: day ?? this.day,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (objectiveId.present) {
      map['objective_id'] = Variable<int>(objectiveId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('objectiveId: $objectiveId, ')
          ..write('day: $day')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, content, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<NoteRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta, content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final int id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NoteRow({required this.id, required this.content, required this.createdAt, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NoteRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NoteRow copyWith({int? id, String? content, DateTime? createdAt, DateTime? updatedAt}) => NoteRow(
    id: id ?? this.id,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<int> id;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NoteRow> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HabitPausesTable extends HabitPauses with TableInfo<$HabitPausesTable, HabitPauseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitPausesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES habits (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _startDayMeta = const VerificationMeta('startDay');
  @override
  late final GeneratedColumn<int> startDay = GeneratedColumn<int>(
    'start_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDayMeta = const VerificationMeta('endDay');
  @override
  late final GeneratedColumn<int> endDay = GeneratedColumn<int>(
    'end_day',
    aliasedName,
    true,
    check: () => ComparableExpr(endDay).isBiggerOrEqual(startDay),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, startDay, endDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_pauses';
  @override
  VerificationContext validateIntegrity(Insertable<HabitPauseRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta, habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('start_day')) {
      context.handle(_startDayMeta, startDay.isAcceptableOrUnknown(data['start_day']!, _startDayMeta));
    } else if (isInserting) {
      context.missing(_startDayMeta);
    }
    if (data.containsKey('end_day')) {
      context.handle(_endDayMeta, endDay.isAcceptableOrUnknown(data['end_day']!, _endDayMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitPauseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitPauseRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}habit_id'])!,
      startDay: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}start_day'])!,
      endDay: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}end_day']),
    );
  }

  @override
  $HabitPausesTable createAlias(String alias) {
    return $HabitPausesTable(attachedDatabase, alias);
  }
}

class HabitPauseRow extends DataClass implements Insertable<HabitPauseRow> {
  final int id;
  final int habitId;

  /// A [CalendarDay], included.
  final int startDay;

  /// A [CalendarDay], included; null while the pause is open.
  final int? endDay;
  const HabitPauseRow({required this.id, required this.habitId, required this.startDay, this.endDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['start_day'] = Variable<int>(startDay);
    if (!nullToAbsent || endDay != null) {
      map['end_day'] = Variable<int>(endDay);
    }
    return map;
  }

  HabitPausesCompanion toCompanion(bool nullToAbsent) {
    return HabitPausesCompanion(
      id: Value(id),
      habitId: Value(habitId),
      startDay: Value(startDay),
      endDay: endDay == null && nullToAbsent ? const Value.absent() : Value(endDay),
    );
  }

  factory HabitPauseRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitPauseRow(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      startDay: serializer.fromJson<int>(json['startDay']),
      endDay: serializer.fromJson<int?>(json['endDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'startDay': serializer.toJson<int>(startDay),
      'endDay': serializer.toJson<int?>(endDay),
    };
  }

  HabitPauseRow copyWith({int? id, int? habitId, int? startDay, Value<int?> endDay = const Value.absent()}) =>
      HabitPauseRow(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        startDay: startDay ?? this.startDay,
        endDay: endDay.present ? endDay.value : this.endDay,
      );
  HabitPauseRow copyWithCompanion(HabitPausesCompanion data) {
    return HabitPauseRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      endDay: data.endDay.present ? data.endDay.value : this.endDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitPauseRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('startDay: $startDay, ')
          ..write('endDay: $endDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, startDay, endDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitPauseRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.startDay == this.startDay &&
          other.endDay == this.endDay);
}

class HabitPausesCompanion extends UpdateCompanion<HabitPauseRow> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<int> startDay;
  final Value<int?> endDay;
  const HabitPausesCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.startDay = const Value.absent(),
    this.endDay = const Value.absent(),
  });
  HabitPausesCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required int startDay,
    this.endDay = const Value.absent(),
  }) : habitId = Value(habitId),
       startDay = Value(startDay);
  static Insertable<HabitPauseRow> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<int>? startDay,
    Expression<int>? endDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (startDay != null) 'start_day': startDay,
      if (endDay != null) 'end_day': endDay,
    });
  }

  HabitPausesCompanion copyWith({Value<int>? id, Value<int>? habitId, Value<int>? startDay, Value<int?>? endDay}) {
    return HabitPausesCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      startDay: startDay ?? this.startDay,
      endDay: endDay ?? this.endDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (startDay.present) {
      map['start_day'] = Variable<int>(startDay.value);
    }
    if (endDay.present) {
      map['end_day'] = Variable<int>(endDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitPausesCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('startDay: $startDay, ')
          ..write('endDay: $endDay')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $ObjectivesTable objectives = $ObjectivesTable(this);
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $HabitPausesTable habitPauses = $HabitPausesTable(this);
  late final Index habitLogsDay = Index('habit_logs_day', 'CREATE INDEX habit_logs_day ON habit_logs (day)');
  late final Index habitLogsObjective = Index(
    'habit_logs_objective',
    'CREATE INDEX habit_logs_objective ON habit_logs (objective_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    objectives,
    habitLogs,
    notes,
    habitPauses,
    habitLogsDay,
    habitLogsObjective,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('habits', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('objectives', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('habits', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('habit_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('objectives', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('habit_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('habits', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('habit_pauses', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  required String title,
  Value<String> description,
  required int colorArgb,
  required String iconName,
  Value<int?> reminderMinuteOfDay,
  Value<int> sortOrder,
  required DateTime createdAt,
  Value<int> scheduledWeekdayMask,
  Value<int?> targetDaysPerWeek,
  Value<DateTime?> archivedAt,
  Value<int> restDaysPerWeek,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> description,
  Value<int> colorArgb,
  Value<String> iconName,
  Value<int?> reminderMinuteOfDay,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> scheduledWeekdayMask,
  Value<int?> targetDaysPerWeek,
  Value<DateTime?> archivedAt,
  Value<int> restDaysPerWeek,
});

final class $$HabitsTableReferences extends BaseReferences<_$AppDatabase, $HabitsTable, HabitRow> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ObjectivesTable, List<ObjectiveRow>> _objectivesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.objectives, aliasName: 'habits__id__objectives__habit_id');

  $$ObjectivesTableProcessedTableManager get objectivesRefs {
    final manager = $$ObjectivesTableTableManager(
      $_db,
      $_db.objectives,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_objectivesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$HabitLogsTable, List<HabitLogRow>> _habitLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.habitLogs, aliasName: 'habits__id__habit_logs__habit_id');

  $$HabitLogsTableProcessedTableManager get habitLogsRefs {
    final manager = $$HabitLogsTableTableManager(
      $_db,
      $_db.habitLogs,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitLogsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$HabitPausesTable, List<HabitPauseRow>> _habitPausesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.habitPauses, aliasName: 'habits__id__habit_pauses__habit_id');

  $$HabitPausesTableProcessedTableManager get habitPausesRefs {
    final manager = $$HabitPausesTableTableManager(
      $_db,
      $_db.habitPauses,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitPausesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$HabitsTableFilterComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinuteOfDay =>
      $composableBuilder(column: $table.reminderMinuteOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduledWeekdayMask =>
      $composableBuilder(column: $table.scheduledWeekdayMask, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetDaysPerWeek =>
      $composableBuilder(column: $table.targetDaysPerWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restDaysPerWeek =>
      $composableBuilder(column: $table.restDaysPerWeek, builder: (column) => ColumnFilters(column));

  Expression<bool> objectivesRefs(Expression<bool> Function($$ObjectivesTableFilterComposer f) f) {
    final $$ObjectivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.objectives,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ObjectivesTableFilterComposer(
            $db: $db,
            $table: $db.objectives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitLogsRefs(Expression<bool> Function($$HabitLogsTableFilterComposer f) f) {
    final $$HabitLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitLogsTableFilterComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitPausesRefs(Expression<bool> Function($$HabitPausesTableFilterComposer f) f) {
    final $$HabitPausesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitPauses,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitPausesTableFilterComposer(
            $db: $db,
            $table: $db.habitPauses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinuteOfDay =>
      $composableBuilder(column: $table.reminderMinuteOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduledWeekdayMask =>
      $composableBuilder(column: $table.scheduledWeekdayMask, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetDaysPerWeek =>
      $composableBuilder(column: $table.targetDaysPerWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restDaysPerWeek =>
      $composableBuilder(column: $table.restDaysPerWeek, builder: (column) => ColumnOrderings(column));
}

class $$HabitsTableAnnotationComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get colorArgb => $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumn<String> get iconName => $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<int> get reminderMinuteOfDay =>
      $composableBuilder(column: $table.reminderMinuteOfDay, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get scheduledWeekdayMask =>
      $composableBuilder(column: $table.scheduledWeekdayMask, builder: (column) => column);

  GeneratedColumn<int> get targetDaysPerWeek =>
      $composableBuilder(column: $table.targetDaysPerWeek, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt =>
      $composableBuilder(column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<int> get restDaysPerWeek =>
      $composableBuilder(column: $table.restDaysPerWeek, builder: (column) => column);

  Expression<T> objectivesRefs<T extends Object>(Expression<T> Function($$ObjectivesTableAnnotationComposer a) f) {
    final $$ObjectivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.objectives,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ObjectivesTableAnnotationComposer(
            $db: $db,
            $table: $db.objectives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitLogsRefs<T extends Object>(Expression<T> Function($$HabitLogsTableAnnotationComposer a) f) {
    final $$HabitLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitPausesRefs<T extends Object>(Expression<T> Function($$HabitPausesTableAnnotationComposer a) f) {
    final $$HabitPausesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitPauses,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitPausesTableAnnotationComposer(
            $db: $db,
            $table: $db.habitPauses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          HabitRow,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (HabitRow, $$HabitsTableReferences),
          HabitRow,
          PrefetchHooks Function({bool objectivesRefs, bool habitLogsRefs, bool habitPausesRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> colorArgb = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<int?> reminderMinuteOfDay = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> scheduledWeekdayMask = const Value.absent(),
                Value<int?> targetDaysPerWeek = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> restDaysPerWeek = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                title: title,
                description: description,
                colorArgb: colorArgb,
                iconName: iconName,
                reminderMinuteOfDay: reminderMinuteOfDay,
                sortOrder: sortOrder,
                createdAt: createdAt,
                scheduledWeekdayMask: scheduledWeekdayMask,
                targetDaysPerWeek: targetDaysPerWeek,
                archivedAt: archivedAt,
                restDaysPerWeek: restDaysPerWeek,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String> description = const Value.absent(),
                required int colorArgb,
                required String iconName,
                Value<int?> reminderMinuteOfDay = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                Value<int> scheduledWeekdayMask = const Value.absent(),
                Value<int?> targetDaysPerWeek = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> restDaysPerWeek = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                title: title,
                description: description,
                colorArgb: colorArgb,
                iconName: iconName,
                reminderMinuteOfDay: reminderMinuteOfDay,
                sortOrder: sortOrder,
                createdAt: createdAt,
                scheduledWeekdayMask: scheduledWeekdayMask,
                targetDaysPerWeek: targetDaysPerWeek,
                archivedAt: archivedAt,
                restDaysPerWeek: restDaysPerWeek,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$HabitsTable, HabitRow>(table), $$HabitsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({objectivesRefs = false, habitLogsRefs = false, habitPausesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (objectivesRefs) db.objectives,
                if (habitLogsRefs) db.habitLogs,
                if (habitPausesRefs) db.habitPauses,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (objectivesRefs)
                    await $_getPrefetchedDataByColumns<HabitRow, $HabitsTable, ObjectiveRow, $ObjectivesTable>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences._objectivesRefsTable(db),
                      managerFromTypedResult: (p0) => $$HabitsTableReferences(db, table, p0).objectivesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'habit_id',
                      typedResults: items,
                    ),
                  if (habitLogsRefs)
                    await $_getPrefetchedDataByColumns<HabitRow, $HabitsTable, HabitLogRow, $HabitLogsTable>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences._habitLogsRefsTable(db),
                      managerFromTypedResult: (p0) => $$HabitsTableReferences(db, table, p0).habitLogsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'habit_id',
                      typedResults: items,
                    ),
                  if (habitPausesRefs)
                    await $_getPrefetchedDataByColumns<HabitRow, $HabitsTable, HabitPauseRow, $HabitPausesTable>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences._habitPausesRefsTable(db),
                      managerFromTypedResult: (p0) => $$HabitsTableReferences(db, table, p0).habitPausesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'habit_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      HabitRow,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (HabitRow, $$HabitsTableReferences),
      HabitRow,
      PrefetchHooks Function({bool objectivesRefs, bool habitLogsRefs, bool habitPausesRefs})
    >;
typedef $$ObjectivesTableCreateCompanionBuilder = ObjectivesCompanion Function({
  Value<int> id,
  required int habitId,
  required String title,
  required int colorArgb,
  required int sortOrder,
  Value<bool> countsAsSuccess,
});
typedef $$ObjectivesTableUpdateCompanionBuilder = ObjectivesCompanion Function({
  Value<int> id,
  Value<int> habitId,
  Value<String> title,
  Value<int> colorArgb,
  Value<int> sortOrder,
  Value<bool> countsAsSuccess,
});

final class $$ObjectivesTableReferences extends BaseReferences<_$AppDatabase, $ObjectivesTable, ObjectiveRow> {
  $$ObjectivesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias('objectives__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager($_db, $_db.habits).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$HabitLogsTable, List<HabitLogRow>> _habitLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.habitLogs, aliasName: 'objectives__id__habit_logs__objective_id');

  $$HabitLogsTableProcessedTableManager get habitLogsRefs {
    final manager = $$HabitLogsTableTableManager(
      $_db,
      $_db.habitLogs,
    ).filter((f) => f.objectiveId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitLogsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ObjectivesTableFilterComposer extends Composer<_$AppDatabase, $ObjectivesTable> {
  $$ObjectivesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get countsAsSuccess =>
      $composableBuilder(column: $table.countsAsSuccess, builder: (column) => ColumnFilters(column));

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> habitLogsRefs(Expression<bool> Function($$HabitLogsTableFilterComposer f) f) {
    final $$HabitLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.objectiveId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitLogsTableFilterComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ObjectivesTableOrderingComposer extends Composer<_$AppDatabase, $ObjectivesTable> {
  $$ObjectivesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get countsAsSuccess =>
      $composableBuilder(column: $table.countsAsSuccess, builder: (column) => ColumnOrderings(column));

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObjectivesTableAnnotationComposer extends Composer<_$AppDatabase, $ObjectivesTable> {
  $$ObjectivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get colorArgb => $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get countsAsSuccess =>
      $composableBuilder(column: $table.countsAsSuccess, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> habitLogsRefs<T extends Object>(Expression<T> Function($$HabitLogsTableAnnotationComposer a) f) {
    final $$HabitLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.objectiveId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ObjectivesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ObjectivesTable,
          ObjectiveRow,
          $$ObjectivesTableFilterComposer,
          $$ObjectivesTableOrderingComposer,
          $$ObjectivesTableAnnotationComposer,
          $$ObjectivesTableCreateCompanionBuilder,
          $$ObjectivesTableUpdateCompanionBuilder,
          (ObjectiveRow, $$ObjectivesTableReferences),
          ObjectiveRow,
          PrefetchHooks Function({bool habitId, bool habitLogsRefs})
        > {
  $$ObjectivesTableTableManager(_$AppDatabase db, $ObjectivesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ObjectivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ObjectivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ObjectivesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> habitId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> colorArgb = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> countsAsSuccess = const Value.absent(),
              }) => ObjectivesCompanion(
                id: id,
                habitId: habitId,
                title: title,
                colorArgb: colorArgb,
                sortOrder: sortOrder,
                countsAsSuccess: countsAsSuccess,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int habitId,
                required String title,
                required int colorArgb,
                required int sortOrder,
                Value<bool> countsAsSuccess = const Value.absent(),
              }) => ObjectivesCompanion.insert(
                id: id,
                habitId: habitId,
                title: title,
                colorArgb: colorArgb,
                sortOrder: sortOrder,
                countsAsSuccess: countsAsSuccess,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$ObjectivesTable, ObjectiveRow>(table), $$ObjectivesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false, habitLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (habitLogsRefs) db.habitLogs],
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
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$ObjectivesTableReferences._habitIdTable(db),
                        referencedColumn: $$ObjectivesTableReferences._habitIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (habitLogsRefs)
                    await $_getPrefetchedDataByColumns<ObjectiveRow, $ObjectivesTable, HabitLogRow, $HabitLogsTable>(
                      currentTable: table,
                      referencedTable: $$ObjectivesTableReferences._habitLogsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ObjectivesTableReferences(db, table, p0).habitLogsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'objective_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ObjectivesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ObjectivesTable,
      ObjectiveRow,
      $$ObjectivesTableFilterComposer,
      $$ObjectivesTableOrderingComposer,
      $$ObjectivesTableAnnotationComposer,
      $$ObjectivesTableCreateCompanionBuilder,
      $$ObjectivesTableUpdateCompanionBuilder,
      (ObjectiveRow, $$ObjectivesTableReferences),
      ObjectiveRow,
      PrefetchHooks Function({bool habitId, bool habitLogsRefs})
    >;
typedef $$HabitLogsTableCreateCompanionBuilder = HabitLogsCompanion Function({
  Value<int> id,
  required int habitId,
  required int objectiveId,
  required int day,
});
typedef $$HabitLogsTableUpdateCompanionBuilder = HabitLogsCompanion Function({
  Value<int> id,
  Value<int> habitId,
  Value<int> objectiveId,
  Value<int> day,
});

final class $$HabitLogsTableReferences extends BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLogRow> {
  $$HabitLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias('habit_logs__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager($_db, $_db.habits).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ObjectivesTable _objectiveIdTable(_$AppDatabase db) =>
      db.objectives.createAlias('habit_logs__objective_id__objectives__id');

  $$ObjectivesTableProcessedTableManager get objectiveId {
    final $_column = $_itemColumn<int>('objective_id')!;

    final manager = $$ObjectivesTableTableManager($_db, $_db.objectives).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_objectiveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HabitLogsTableFilterComposer extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ObjectivesTableFilterComposer get objectiveId {
    final $$ObjectivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.objectiveId,
      referencedTable: $db.objectives,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ObjectivesTableFilterComposer(
            $db: $db,
            $table: $db.objectives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableOrderingComposer extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ObjectivesTableOrderingComposer get objectiveId {
    final $$ObjectivesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.objectiveId,
      referencedTable: $db.objectives,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ObjectivesTableOrderingComposer(
            $db: $db,
            $table: $db.objectives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableAnnotationComposer extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ObjectivesTableAnnotationComposer get objectiveId {
    final $$ObjectivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.objectiveId,
      referencedTable: $db.objectives,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ObjectivesTableAnnotationComposer(
            $db: $db,
            $table: $db.objectives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitLogsTable,
          HabitLogRow,
          $$HabitLogsTableFilterComposer,
          $$HabitLogsTableOrderingComposer,
          $$HabitLogsTableAnnotationComposer,
          $$HabitLogsTableCreateCompanionBuilder,
          $$HabitLogsTableUpdateCompanionBuilder,
          (HabitLogRow, $$HabitLogsTableReferences),
          HabitLogRow,
          PrefetchHooks Function({bool habitId, bool objectiveId})
        > {
  $$HabitLogsTableTableManager(_$AppDatabase db, $HabitLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> habitId = const Value.absent(),
            Value<int> objectiveId = const Value.absent(),
            Value<int> day = const Value.absent(),
          }) => HabitLogsCompanion(id: id, habitId: habitId, objectiveId: objectiveId, day: day),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int habitId,
            required int objectiveId,
            required int day,
          }) => HabitLogsCompanion.insert(id: id, habitId: habitId, objectiveId: objectiveId, day: day),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$HabitLogsTable, HabitLogRow>(table), $$HabitLogsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({habitId = false, objectiveId = false}) {
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
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitLogsTableReferences._habitIdTable(db),
                        referencedColumn: $$HabitLogsTableReferences._habitIdTable(db).id,
                      ) as T;
                    }
                    if (objectiveId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.objectiveId,
                        referencedTable: $$HabitLogsTableReferences._objectiveIdTable(db),
                        referencedColumn: $$HabitLogsTableReferences._objectiveIdTable(db).id,
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

typedef $$HabitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitLogsTable,
      HabitLogRow,
      $$HabitLogsTableFilterComposer,
      $$HabitLogsTableOrderingComposer,
      $$HabitLogsTableAnnotationComposer,
      $$HabitLogsTableCreateCompanionBuilder,
      $$HabitLogsTableUpdateCompanionBuilder,
      (HabitLogRow, $$HabitLogsTableReferences),
      HabitLogRow,
      PrefetchHooks Function({bool habitId, bool objectiveId})
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required String content,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> content,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$NotesTableOrderingComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$NotesTableAnnotationComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content => $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) => NotesCompanion(id: id, content: content, createdAt: createdAt, updatedAt: updatedAt),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String content,
            required DateTime createdAt,
            required DateTime updatedAt,
          }) => NotesCompanion.insert(id: id, content: content, createdAt: createdAt, updatedAt: updatedAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, NoteRow>(table),
                  BaseReferences<_$AppDatabase, $NotesTable, NoteRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;
typedef $$HabitPausesTableCreateCompanionBuilder = HabitPausesCompanion Function({
  Value<int> id,
  required int habitId,
  required int startDay,
  Value<int?> endDay,
});
typedef $$HabitPausesTableUpdateCompanionBuilder = HabitPausesCompanion Function({
  Value<int> id,
  Value<int> habitId,
  Value<int> startDay,
  Value<int?> endDay,
});

final class $$HabitPausesTableReferences extends BaseReferences<_$AppDatabase, $HabitPausesTable, HabitPauseRow> {
  $$HabitPausesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias('habit_pauses__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager($_db, $_db.habits).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HabitPausesTableFilterComposer extends Composer<_$AppDatabase, $HabitPausesTable> {
  $$HabitPausesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startDay =>
      $composableBuilder(column: $table.startDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endDay =>
      $composableBuilder(column: $table.endDay, builder: (column) => ColumnFilters(column));

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitPausesTableOrderingComposer extends Composer<_$AppDatabase, $HabitPausesTable> {
  $$HabitPausesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startDay =>
      $composableBuilder(column: $table.startDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endDay =>
      $composableBuilder(column: $table.endDay, builder: (column) => ColumnOrderings(column));

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitPausesTableAnnotationComposer extends Composer<_$AppDatabase, $HabitPausesTable> {
  $$HabitPausesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startDay => $composableBuilder(column: $table.startDay, builder: (column) => column);

  GeneratedColumn<int> get endDay => $composableBuilder(column: $table.endDay, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitPausesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitPausesTable,
          HabitPauseRow,
          $$HabitPausesTableFilterComposer,
          $$HabitPausesTableOrderingComposer,
          $$HabitPausesTableAnnotationComposer,
          $$HabitPausesTableCreateCompanionBuilder,
          $$HabitPausesTableUpdateCompanionBuilder,
          (HabitPauseRow, $$HabitPausesTableReferences),
          HabitPauseRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitPausesTableTableManager(_$AppDatabase db, $HabitPausesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitPausesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitPausesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitPausesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> habitId = const Value.absent(),
            Value<int> startDay = const Value.absent(),
            Value<int?> endDay = const Value.absent(),
          }) => HabitPausesCompanion(id: id, habitId: habitId, startDay: startDay, endDay: endDay),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int habitId,
            required int startDay,
            Value<int?> endDay = const Value.absent(),
          }) => HabitPausesCompanion.insert(id: id, habitId: habitId, startDay: startDay, endDay: endDay),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$HabitPausesTable, HabitPauseRow>(table), $$HabitPausesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
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
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitPausesTableReferences._habitIdTable(db),
                        referencedColumn: $$HabitPausesTableReferences._habitIdTable(db).id,
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

typedef $$HabitPausesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitPausesTable,
      HabitPauseRow,
      $$HabitPausesTableFilterComposer,
      $$HabitPausesTableOrderingComposer,
      $$HabitPausesTableAnnotationComposer,
      $$HabitPausesTableCreateCompanionBuilder,
      $$HabitPausesTableUpdateCompanionBuilder,
      (HabitPauseRow, $$HabitPausesTableReferences),
      HabitPauseRow,
      PrefetchHooks Function({bool habitId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits => $$HabitsTableTableManager(_db, _db.habits);
  $$ObjectivesTableTableManager get objectives => $$ObjectivesTableTableManager(_db, _db.objectives);
  $$HabitLogsTableTableManager get habitLogs => $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$NotesTableTableManager get notes => $$NotesTableTableManager(_db, _db.notes);
  $$HabitPausesTableTableManager get habitPauses => $$HabitPausesTableTableManager(_db, _db.habitPauses);
}
