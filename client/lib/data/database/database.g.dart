// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flagsMeta = const VerificationMeta('flags');
  @override
  late final GeneratedColumn<int> flags = GeneratedColumn<int>(
    'flags',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedMeta = const VerificationMeta(
    'removed',
  );
  @override
  late final GeneratedColumn<int> removed = GeneratedColumn<int>(
    'removed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    worldId,
    orderId,
    title,
    content,
    flags,
    timestamp,
    removed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('flags')) {
      context.handle(
        _flagsMeta,
        flags.isAcceptableOrUnknown(data['flags']!, _flagsMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('removed')) {
      context.handle(
        _removedMeta,
        removed.isAcceptableOrUnknown(data['removed']!, _removedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      flags: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flags'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      removed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}removed'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final int id;
  final int? parentId;
  final String worldId;
  final int orderId;
  final String title;
  final String? content;
  final int flags;
  final String timestamp;
  final int removed;
  const TaskRow({
    required this.id,
    this.parentId,
    required this.worldId,
    required this.orderId,
    required this.title,
    this.content,
    required this.flags,
    required this.timestamp,
    required this.removed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['world_id'] = Variable<String>(worldId);
    map['order_id'] = Variable<int>(orderId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['flags'] = Variable<int>(flags);
    map['timestamp'] = Variable<String>(timestamp);
    map['removed'] = Variable<int>(removed);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      worldId: Value(worldId),
      orderId: Value(orderId),
      title: Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      flags: Value(flags),
      timestamp: Value(timestamp),
      removed: Value(removed),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<int>(json['id']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      orderId: serializer.fromJson<int>(json['orderId']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      flags: serializer.fromJson<int>(json['flags']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      removed: serializer.fromJson<int>(json['removed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parentId': serializer.toJson<int?>(parentId),
      'worldId': serializer.toJson<String>(worldId),
      'orderId': serializer.toJson<int>(orderId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String?>(content),
      'flags': serializer.toJson<int>(flags),
      'timestamp': serializer.toJson<String>(timestamp),
      'removed': serializer.toJson<int>(removed),
    };
  }

  TaskRow copyWith({
    int? id,
    Value<int?> parentId = const Value.absent(),
    String? worldId,
    int? orderId,
    String? title,
    Value<String?> content = const Value.absent(),
    int? flags,
    String? timestamp,
    int? removed,
  }) => TaskRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    worldId: worldId ?? this.worldId,
    orderId: orderId ?? this.orderId,
    title: title ?? this.title,
    content: content.present ? content.value : this.content,
    flags: flags ?? this.flags,
    timestamp: timestamp ?? this.timestamp,
    removed: removed ?? this.removed,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      flags: data.flags.present ? data.flags.value : this.flags,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      removed: data.removed.present ? data.removed.value : this.removed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('worldId: $worldId, ')
          ..write('orderId: $orderId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('flags: $flags, ')
          ..write('timestamp: $timestamp, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    worldId,
    orderId,
    title,
    content,
    flags,
    timestamp,
    removed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.worldId == this.worldId &&
          other.orderId == this.orderId &&
          other.title == this.title &&
          other.content == this.content &&
          other.flags == this.flags &&
          other.timestamp == this.timestamp &&
          other.removed == this.removed);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<int> id;
  final Value<int?> parentId;
  final Value<String> worldId;
  final Value<int> orderId;
  final Value<String> title;
  final Value<String?> content;
  final Value<int> flags;
  final Value<String> timestamp;
  final Value<int> removed;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.flags = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.removed = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.orderId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.flags = const Value.absent(),
    required String timestamp,
    this.removed = const Value.absent(),
  }) : timestamp = Value(timestamp);
  static Insertable<TaskRow> custom({
    Expression<int>? id,
    Expression<int>? parentId,
    Expression<String>? worldId,
    Expression<int>? orderId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? flags,
    Expression<String>? timestamp,
    Expression<int>? removed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (worldId != null) 'world_id': worldId,
      if (orderId != null) 'order_id': orderId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (flags != null) 'flags': flags,
      if (timestamp != null) 'timestamp': timestamp,
      if (removed != null) 'removed': removed,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? parentId,
    Value<String>? worldId,
    Value<int>? orderId,
    Value<String>? title,
    Value<String?>? content,
    Value<int>? flags,
    Value<String>? timestamp,
    Value<int>? removed,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      worldId: worldId ?? this.worldId,
      orderId: orderId ?? this.orderId,
      title: title ?? this.title,
      content: content ?? this.content,
      flags: flags ?? this.flags,
      timestamp: timestamp ?? this.timestamp,
      removed: removed ?? this.removed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (flags.present) {
      map['flags'] = Variable<int>(flags.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (removed.present) {
      map['removed'] = Variable<int>(removed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('worldId: $worldId, ')
          ..write('orderId: $orderId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('flags: $flags, ')
          ..write('timestamp: $timestamp, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }
}

class $TimelineTable extends Timeline
    with TableInfo<$TimelineTable, TimelineEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedMeta = const VerificationMeta(
    'removed',
  );
  @override
  late final GeneratedColumn<int> removed = GeneratedColumn<int>(
    'removed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    worldId,
    startTime,
    endTime,
    timestamp,
    removed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('removed')) {
      context.handle(
        _removedMeta,
        removed.isAcceptableOrUnknown(data['removed']!, _removedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimelineEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      removed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}removed'],
      )!,
    );
  }

  @override
  $TimelineTable createAlias(String alias) {
    return $TimelineTable(attachedDatabase, alias);
  }
}

class TimelineEntry extends DataClass implements Insertable<TimelineEntry> {
  final int id;
  final int taskId;
  final String worldId;
  final String startTime;
  final String? endTime;
  final String timestamp;
  final int removed;
  const TimelineEntry({
    required this.id,
    required this.taskId,
    required this.worldId,
    required this.startTime,
    this.endTime,
    required this.timestamp,
    required this.removed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['world_id'] = Variable<String>(worldId);
    map['start_time'] = Variable<String>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['timestamp'] = Variable<String>(timestamp);
    map['removed'] = Variable<int>(removed);
    return map;
  }

  TimelineCompanion toCompanion(bool nullToAbsent) {
    return TimelineCompanion(
      id: Value(id),
      taskId: Value(taskId),
      worldId: Value(worldId),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      timestamp: Value(timestamp),
      removed: Value(removed),
    );
  }

  factory TimelineEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineEntry(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      removed: serializer.fromJson<int>(json['removed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'worldId': serializer.toJson<String>(worldId),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'timestamp': serializer.toJson<String>(timestamp),
      'removed': serializer.toJson<int>(removed),
    };
  }

  TimelineEntry copyWith({
    int? id,
    int? taskId,
    String? worldId,
    String? startTime,
    Value<String?> endTime = const Value.absent(),
    String? timestamp,
    int? removed,
  }) => TimelineEntry(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    worldId: worldId ?? this.worldId,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    timestamp: timestamp ?? this.timestamp,
    removed: removed ?? this.removed,
  );
  TimelineEntry copyWithCompanion(TimelineCompanion data) {
    return TimelineEntry(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      removed: data.removed.present ? data.removed.value : this.removed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineEntry(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('worldId: $worldId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('timestamp: $timestamp, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, worldId, startTime, endTime, timestamp, removed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineEntry &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.worldId == this.worldId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.timestamp == this.timestamp &&
          other.removed == this.removed);
}

class TimelineCompanion extends UpdateCompanion<TimelineEntry> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<String> worldId;
  final Value<String> startTime;
  final Value<String?> endTime;
  final Value<String> timestamp;
  final Value<int> removed;
  const TimelineCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.removed = const Value.absent(),
  });
  TimelineCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    this.worldId = const Value.absent(),
    required String startTime,
    this.endTime = const Value.absent(),
    required String timestamp,
    this.removed = const Value.absent(),
  }) : taskId = Value(taskId),
       startTime = Value(startTime),
       timestamp = Value(timestamp);
  static Insertable<TimelineEntry> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? worldId,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? timestamp,
    Expression<int>? removed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (worldId != null) 'world_id': worldId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (timestamp != null) 'timestamp': timestamp,
      if (removed != null) 'removed': removed,
    });
  }

  TimelineCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<String>? worldId,
    Value<String>? startTime,
    Value<String?>? endTime,
    Value<String>? timestamp,
    Value<int>? removed,
  }) {
    return TimelineCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      worldId: worldId ?? this.worldId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timestamp: timestamp ?? this.timestamp,
      removed: removed ?? this.removed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (removed.present) {
      map['removed'] = Variable<int>(removed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('worldId: $worldId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('timestamp: $timestamp, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }
}

class $FilesTable extends Files with TableInfo<$FilesTable, FileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<Uint8List> content = GeneratedColumn<Uint8List>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedMeta = const VerificationMeta(
    'removed',
  );
  @override
  late final GeneratedColumn<int> removed = GeneratedColumn<int>(
    'removed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    worldId,
    filename,
    content,
    contentHash,
    orderId,
    timestamp,
    removed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('removed')) {
      context.handle(
        _removedMeta,
        removed.isAcceptableOrUnknown(data['removed']!, _removedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}content'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      removed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}removed'],
      )!,
    );
  }

  @override
  $FilesTable createAlias(String alias) {
    return $FilesTable(attachedDatabase, alias);
  }
}

class FileEntry extends DataClass implements Insertable<FileEntry> {
  final int id;
  final int taskId;
  final String worldId;
  final String filename;
  final Uint8List? content;

  /// SHA-256 of [content], lowercase hex — the attachment's identity in the
  /// sync blob store (docs/P2P_SYNC.md §3.5). Packets carry this instead of
  /// the bytes, and this table doubles as the node's blob store: any row with
  /// this hash and a non-null content can serve the bytes.
  ///
  /// A row with a hash but **null content** is an attachment this device knows
  /// about but has not fetched yet — the reference arrived in a packet, the
  /// bytes come separately, from whichever node has them.
  final String contentHash;
  final int orderId;
  final String timestamp;
  final int removed;
  const FileEntry({
    required this.id,
    required this.taskId,
    required this.worldId,
    required this.filename,
    this.content,
    required this.contentHash,
    required this.orderId,
    required this.timestamp,
    required this.removed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['world_id'] = Variable<String>(worldId);
    map['filename'] = Variable<String>(filename);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<Uint8List>(content);
    }
    map['content_hash'] = Variable<String>(contentHash);
    map['order_id'] = Variable<int>(orderId);
    map['timestamp'] = Variable<String>(timestamp);
    map['removed'] = Variable<int>(removed);
    return map;
  }

  FilesCompanion toCompanion(bool nullToAbsent) {
    return FilesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      worldId: Value(worldId),
      filename: Value(filename),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      contentHash: Value(contentHash),
      orderId: Value(orderId),
      timestamp: Value(timestamp),
      removed: Value(removed),
    );
  }

  factory FileEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileEntry(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      filename: serializer.fromJson<String>(json['filename']),
      content: serializer.fromJson<Uint8List?>(json['content']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      orderId: serializer.fromJson<int>(json['orderId']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      removed: serializer.fromJson<int>(json['removed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'worldId': serializer.toJson<String>(worldId),
      'filename': serializer.toJson<String>(filename),
      'content': serializer.toJson<Uint8List?>(content),
      'contentHash': serializer.toJson<String>(contentHash),
      'orderId': serializer.toJson<int>(orderId),
      'timestamp': serializer.toJson<String>(timestamp),
      'removed': serializer.toJson<int>(removed),
    };
  }

  FileEntry copyWith({
    int? id,
    int? taskId,
    String? worldId,
    String? filename,
    Value<Uint8List?> content = const Value.absent(),
    String? contentHash,
    int? orderId,
    String? timestamp,
    int? removed,
  }) => FileEntry(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    worldId: worldId ?? this.worldId,
    filename: filename ?? this.filename,
    content: content.present ? content.value : this.content,
    contentHash: contentHash ?? this.contentHash,
    orderId: orderId ?? this.orderId,
    timestamp: timestamp ?? this.timestamp,
    removed: removed ?? this.removed,
  );
  FileEntry copyWithCompanion(FilesCompanion data) {
    return FileEntry(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      filename: data.filename.present ? data.filename.value : this.filename,
      content: data.content.present ? data.content.value : this.content,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      removed: data.removed.present ? data.removed.value : this.removed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileEntry(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('worldId: $worldId, ')
          ..write('filename: $filename, ')
          ..write('content: $content, ')
          ..write('contentHash: $contentHash, ')
          ..write('orderId: $orderId, ')
          ..write('timestamp: $timestamp, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    worldId,
    filename,
    $driftBlobEquality.hash(content),
    contentHash,
    orderId,
    timestamp,
    removed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileEntry &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.worldId == this.worldId &&
          other.filename == this.filename &&
          $driftBlobEquality.equals(other.content, this.content) &&
          other.contentHash == this.contentHash &&
          other.orderId == this.orderId &&
          other.timestamp == this.timestamp &&
          other.removed == this.removed);
}

class FilesCompanion extends UpdateCompanion<FileEntry> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<String> worldId;
  final Value<String> filename;
  final Value<Uint8List?> content;
  final Value<String> contentHash;
  final Value<int> orderId;
  final Value<String> timestamp;
  final Value<int> removed;
  const FilesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.filename = const Value.absent(),
    this.content = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.orderId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.removed = const Value.absent(),
  });
  FilesCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    this.worldId = const Value.absent(),
    this.filename = const Value.absent(),
    this.content = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.orderId = const Value.absent(),
    required String timestamp,
    this.removed = const Value.absent(),
  }) : taskId = Value(taskId),
       timestamp = Value(timestamp);
  static Insertable<FileEntry> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? worldId,
    Expression<String>? filename,
    Expression<Uint8List>? content,
    Expression<String>? contentHash,
    Expression<int>? orderId,
    Expression<String>? timestamp,
    Expression<int>? removed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (worldId != null) 'world_id': worldId,
      if (filename != null) 'filename': filename,
      if (content != null) 'content': content,
      if (contentHash != null) 'content_hash': contentHash,
      if (orderId != null) 'order_id': orderId,
      if (timestamp != null) 'timestamp': timestamp,
      if (removed != null) 'removed': removed,
    });
  }

  FilesCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<String>? worldId,
    Value<String>? filename,
    Value<Uint8List?>? content,
    Value<String>? contentHash,
    Value<int>? orderId,
    Value<String>? timestamp,
    Value<int>? removed,
  }) {
    return FilesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      worldId: worldId ?? this.worldId,
      filename: filename ?? this.filename,
      content: content ?? this.content,
      contentHash: contentHash ?? this.contentHash,
      orderId: orderId ?? this.orderId,
      timestamp: timestamp ?? this.timestamp,
      removed: removed ?? this.removed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (content.present) {
      map['content'] = Variable<Uint8List>(content.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (removed.present) {
      map['removed'] = Variable<int>(removed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('worldId: $worldId, ')
          ..write('filename: $filename, ')
          ..write('content: $content, ')
          ..write('contentHash: $contentHash, ')
          ..write('orderId: $orderId, ')
          ..write('timestamp: $timestamp, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }
}

class $PropertiesTable extends Properties
    with TableInfo<$PropertiesTable, Property> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PropertiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [type, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'properties';
  @override
  VerificationContext validateIntegrity(
    Insertable<Property> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {type};
  @override
  Property map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Property(
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PropertiesTable createAlias(String alias) {
    return $PropertiesTable(attachedDatabase, alias);
  }
}

class Property extends DataClass implements Insertable<Property> {
  final String type;
  final String value;
  const Property({required this.type, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type'] = Variable<String>(type);
    map['value'] = Variable<String>(value);
    return map;
  }

  PropertiesCompanion toCompanion(bool nullToAbsent) {
    return PropertiesCompanion(type: Value(type), value: Value(value));
  }

  factory Property.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Property(
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<String>(value),
    };
  }

  Property copyWith({String? type, String? value}) =>
      Property(type: type ?? this.type, value: value ?? this.value);
  Property copyWithCompanion(PropertiesCompanion data) {
    return Property(
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Property(')
          ..write('type: $type, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(type, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Property &&
          other.type == this.type &&
          other.value == this.value);
}

class PropertiesCompanion extends UpdateCompanion<Property> {
  final Value<String> type;
  final Value<String> value;
  final Value<int> rowid;
  const PropertiesCompanion({
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PropertiesCompanion.insert({
    required String type,
    required String value,
    this.rowid = const Value.absent(),
  }) : type = Value(type),
       value = Value(value);
  static Insertable<Property> custom({
    Expression<String>? type,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PropertiesCompanion copyWith({
    Value<String>? type,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PropertiesCompanion(
      type: type ?? this.type,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PropertiesCompanion(')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryTaskTable extends HistoryTask
    with TableInfo<$HistoryTaskTable, HistoryTaskData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTaskTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oldValueMeta = const VerificationMeta(
    'oldValue',
  );
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
    'old_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newValueMeta = const VerificationMeta(
    'newValue',
  );
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
    'new_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRemoteMeta = const VerificationMeta(
    'isRemote',
  );
  @override
  late final GeneratedColumn<int> isRemote = GeneratedColumn<int>(
    'is_remote',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    worldId,
    field,
    oldValue,
    newValue,
    timestamp,
    isRemote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_task';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryTaskData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('old_value')) {
      context.handle(
        _oldValueMeta,
        oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta),
      );
    }
    if (data.containsKey('new_value')) {
      context.handle(
        _newValueMeta,
        newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_remote')) {
      context.handle(
        _isRemoteMeta,
        isRemote.isAcceptableOrUnknown(data['is_remote']!, _isRemoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryTaskData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryTaskData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      oldValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_value'],
      ),
      newValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_value'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      isRemote: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_remote'],
      )!,
    );
  }

  @override
  $HistoryTaskTable createAlias(String alias) {
    return $HistoryTaskTable(attachedDatabase, alias);
  }
}

class HistoryTaskData extends DataClass implements Insertable<HistoryTaskData> {
  final int id;
  final int taskId;
  final String worldId;
  final String field;
  final String? oldValue;
  final String? newValue;
  final String timestamp;

  /// 1 when this row was produced by applying a change pulled from another
  /// device. Remote-origin rows are excluded from push (no echo) but still
  /// participate in conflict resolution.
  final int isRemote;
  const HistoryTaskData({
    required this.id,
    required this.taskId,
    required this.worldId,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.timestamp,
    required this.isRemote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['world_id'] = Variable<String>(worldId);
    map['field'] = Variable<String>(field);
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    map['timestamp'] = Variable<String>(timestamp);
    map['is_remote'] = Variable<int>(isRemote);
    return map;
  }

  HistoryTaskCompanion toCompanion(bool nullToAbsent) {
    return HistoryTaskCompanion(
      id: Value(id),
      taskId: Value(taskId),
      worldId: Value(worldId),
      field: Value(field),
      oldValue: oldValue == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
      timestamp: Value(timestamp),
      isRemote: Value(isRemote),
    );
  }

  factory HistoryTaskData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryTaskData(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      field: serializer.fromJson<String>(json['field']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      isRemote: serializer.fromJson<int>(json['isRemote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'worldId': serializer.toJson<String>(worldId),
      'field': serializer.toJson<String>(field),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
      'timestamp': serializer.toJson<String>(timestamp),
      'isRemote': serializer.toJson<int>(isRemote),
    };
  }

  HistoryTaskData copyWith({
    int? id,
    int? taskId,
    String? worldId,
    String? field,
    Value<String?> oldValue = const Value.absent(),
    Value<String?> newValue = const Value.absent(),
    String? timestamp,
    int? isRemote,
  }) => HistoryTaskData(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    worldId: worldId ?? this.worldId,
    field: field ?? this.field,
    oldValue: oldValue.present ? oldValue.value : this.oldValue,
    newValue: newValue.present ? newValue.value : this.newValue,
    timestamp: timestamp ?? this.timestamp,
    isRemote: isRemote ?? this.isRemote,
  );
  HistoryTaskData copyWithCompanion(HistoryTaskCompanion data) {
    return HistoryTaskData(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      field: data.field.present ? data.field.value : this.field,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isRemote: data.isRemote.present ? data.isRemote.value : this.isRemote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryTaskData(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRemote: $isRemote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    worldId,
    field,
    oldValue,
    newValue,
    timestamp,
    isRemote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryTaskData &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.worldId == this.worldId &&
          other.field == this.field &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue &&
          other.timestamp == this.timestamp &&
          other.isRemote == this.isRemote);
}

class HistoryTaskCompanion extends UpdateCompanion<HistoryTaskData> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<String> worldId;
  final Value<String> field;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<String> timestamp;
  final Value<int> isRemote;
  const HistoryTaskCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.field = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isRemote = const Value.absent(),
  });
  HistoryTaskCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    this.worldId = const Value.absent(),
    required String field,
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    required String timestamp,
    this.isRemote = const Value.absent(),
  }) : taskId = Value(taskId),
       field = Value(field),
       timestamp = Value(timestamp);
  static Insertable<HistoryTaskData> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? worldId,
    Expression<String>? field,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<String>? timestamp,
    Expression<int>? isRemote,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (worldId != null) 'world_id': worldId,
      if (field != null) 'field': field,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (timestamp != null) 'timestamp': timestamp,
      if (isRemote != null) 'is_remote': isRemote,
    });
  }

  HistoryTaskCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<String>? worldId,
    Value<String>? field,
    Value<String?>? oldValue,
    Value<String?>? newValue,
    Value<String>? timestamp,
    Value<int>? isRemote,
  }) {
    return HistoryTaskCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      worldId: worldId ?? this.worldId,
      field: field ?? this.field,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      timestamp: timestamp ?? this.timestamp,
      isRemote: isRemote ?? this.isRemote,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (isRemote.present) {
      map['is_remote'] = Variable<int>(isRemote.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryTaskCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRemote: $isRemote')
          ..write(')'))
        .toString();
  }
}

class $HistoryFileTable extends HistoryFile
    with TableInfo<$HistoryFileTable, HistoryFileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryFileTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<int> fileId = GeneratedColumn<int>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oldValueMeta = const VerificationMeta(
    'oldValue',
  );
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
    'old_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newValueMeta = const VerificationMeta(
    'newValue',
  );
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
    'new_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRemoteMeta = const VerificationMeta(
    'isRemote',
  );
  @override
  late final GeneratedColumn<int> isRemote = GeneratedColumn<int>(
    'is_remote',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileId,
    worldId,
    field,
    oldValue,
    newValue,
    timestamp,
    isRemote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_file';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryFileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('old_value')) {
      context.handle(
        _oldValueMeta,
        oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta),
      );
    }
    if (data.containsKey('new_value')) {
      context.handle(
        _newValueMeta,
        newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_remote')) {
      context.handle(
        _isRemoteMeta,
        isRemote.isAcceptableOrUnknown(data['is_remote']!, _isRemoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryFileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryFileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      oldValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_value'],
      ),
      newValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_value'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      isRemote: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_remote'],
      )!,
    );
  }

  @override
  $HistoryFileTable createAlias(String alias) {
    return $HistoryFileTable(attachedDatabase, alias);
  }
}

class HistoryFileData extends DataClass implements Insertable<HistoryFileData> {
  final int id;
  final int fileId;
  final String worldId;
  final String field;
  final String? oldValue;
  final String? newValue;
  final String timestamp;
  final int isRemote;
  const HistoryFileData({
    required this.id,
    required this.fileId,
    required this.worldId,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.timestamp,
    required this.isRemote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_id'] = Variable<int>(fileId);
    map['world_id'] = Variable<String>(worldId);
    map['field'] = Variable<String>(field);
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    map['timestamp'] = Variable<String>(timestamp);
    map['is_remote'] = Variable<int>(isRemote);
    return map;
  }

  HistoryFileCompanion toCompanion(bool nullToAbsent) {
    return HistoryFileCompanion(
      id: Value(id),
      fileId: Value(fileId),
      worldId: Value(worldId),
      field: Value(field),
      oldValue: oldValue == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
      timestamp: Value(timestamp),
      isRemote: Value(isRemote),
    );
  }

  factory HistoryFileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryFileData(
      id: serializer.fromJson<int>(json['id']),
      fileId: serializer.fromJson<int>(json['fileId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      field: serializer.fromJson<String>(json['field']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      isRemote: serializer.fromJson<int>(json['isRemote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileId': serializer.toJson<int>(fileId),
      'worldId': serializer.toJson<String>(worldId),
      'field': serializer.toJson<String>(field),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
      'timestamp': serializer.toJson<String>(timestamp),
      'isRemote': serializer.toJson<int>(isRemote),
    };
  }

  HistoryFileData copyWith({
    int? id,
    int? fileId,
    String? worldId,
    String? field,
    Value<String?> oldValue = const Value.absent(),
    Value<String?> newValue = const Value.absent(),
    String? timestamp,
    int? isRemote,
  }) => HistoryFileData(
    id: id ?? this.id,
    fileId: fileId ?? this.fileId,
    worldId: worldId ?? this.worldId,
    field: field ?? this.field,
    oldValue: oldValue.present ? oldValue.value : this.oldValue,
    newValue: newValue.present ? newValue.value : this.newValue,
    timestamp: timestamp ?? this.timestamp,
    isRemote: isRemote ?? this.isRemote,
  );
  HistoryFileData copyWithCompanion(HistoryFileCompanion data) {
    return HistoryFileData(
      id: data.id.present ? data.id.value : this.id,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      field: data.field.present ? data.field.value : this.field,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isRemote: data.isRemote.present ? data.isRemote.value : this.isRemote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryFileData(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRemote: $isRemote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileId,
    worldId,
    field,
    oldValue,
    newValue,
    timestamp,
    isRemote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryFileData &&
          other.id == this.id &&
          other.fileId == this.fileId &&
          other.worldId == this.worldId &&
          other.field == this.field &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue &&
          other.timestamp == this.timestamp &&
          other.isRemote == this.isRemote);
}

class HistoryFileCompanion extends UpdateCompanion<HistoryFileData> {
  final Value<int> id;
  final Value<int> fileId;
  final Value<String> worldId;
  final Value<String> field;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<String> timestamp;
  final Value<int> isRemote;
  const HistoryFileCompanion({
    this.id = const Value.absent(),
    this.fileId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.field = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isRemote = const Value.absent(),
  });
  HistoryFileCompanion.insert({
    this.id = const Value.absent(),
    required int fileId,
    this.worldId = const Value.absent(),
    required String field,
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    required String timestamp,
    this.isRemote = const Value.absent(),
  }) : fileId = Value(fileId),
       field = Value(field),
       timestamp = Value(timestamp);
  static Insertable<HistoryFileData> custom({
    Expression<int>? id,
    Expression<int>? fileId,
    Expression<String>? worldId,
    Expression<String>? field,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<String>? timestamp,
    Expression<int>? isRemote,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileId != null) 'file_id': fileId,
      if (worldId != null) 'world_id': worldId,
      if (field != null) 'field': field,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (timestamp != null) 'timestamp': timestamp,
      if (isRemote != null) 'is_remote': isRemote,
    });
  }

  HistoryFileCompanion copyWith({
    Value<int>? id,
    Value<int>? fileId,
    Value<String>? worldId,
    Value<String>? field,
    Value<String?>? oldValue,
    Value<String?>? newValue,
    Value<String>? timestamp,
    Value<int>? isRemote,
  }) {
    return HistoryFileCompanion(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      worldId: worldId ?? this.worldId,
      field: field ?? this.field,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      timestamp: timestamp ?? this.timestamp,
      isRemote: isRemote ?? this.isRemote,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<int>(fileId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (isRemote.present) {
      map['is_remote'] = Variable<int>(isRemote.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryFileCompanion(')
          ..write('id: $id, ')
          ..write('fileId: $fileId, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRemote: $isRemote')
          ..write(')'))
        .toString();
  }
}

class $HistoryTimelineTable extends HistoryTimeline
    with TableInfo<$HistoryTimelineTable, HistoryTimelineData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTimelineTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _timelineIdMeta = const VerificationMeta(
    'timelineId',
  );
  @override
  late final GeneratedColumn<int> timelineId = GeneratedColumn<int>(
    'timeline_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oldValueMeta = const VerificationMeta(
    'oldValue',
  );
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
    'old_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newValueMeta = const VerificationMeta(
    'newValue',
  );
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
    'new_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRemoteMeta = const VerificationMeta(
    'isRemote',
  );
  @override
  late final GeneratedColumn<int> isRemote = GeneratedColumn<int>(
    'is_remote',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timelineId,
    worldId,
    field,
    oldValue,
    newValue,
    timestamp,
    isRemote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_timeline';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryTimelineData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timeline_id')) {
      context.handle(
        _timelineIdMeta,
        timelineId.isAcceptableOrUnknown(data['timeline_id']!, _timelineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_timelineIdMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('old_value')) {
      context.handle(
        _oldValueMeta,
        oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta),
      );
    }
    if (data.containsKey('new_value')) {
      context.handle(
        _newValueMeta,
        newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_remote')) {
      context.handle(
        _isRemoteMeta,
        isRemote.isAcceptableOrUnknown(data['is_remote']!, _isRemoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryTimelineData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryTimelineData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timelineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timeline_id'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      oldValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_value'],
      ),
      newValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_value'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      isRemote: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_remote'],
      )!,
    );
  }

  @override
  $HistoryTimelineTable createAlias(String alias) {
    return $HistoryTimelineTable(attachedDatabase, alias);
  }
}

class HistoryTimelineData extends DataClass
    implements Insertable<HistoryTimelineData> {
  final int id;
  final int timelineId;
  final String worldId;
  final String field;
  final String? oldValue;
  final String? newValue;
  final String timestamp;
  final int isRemote;
  const HistoryTimelineData({
    required this.id,
    required this.timelineId,
    required this.worldId,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.timestamp,
    required this.isRemote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timeline_id'] = Variable<int>(timelineId);
    map['world_id'] = Variable<String>(worldId);
    map['field'] = Variable<String>(field);
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    map['timestamp'] = Variable<String>(timestamp);
    map['is_remote'] = Variable<int>(isRemote);
    return map;
  }

  HistoryTimelineCompanion toCompanion(bool nullToAbsent) {
    return HistoryTimelineCompanion(
      id: Value(id),
      timelineId: Value(timelineId),
      worldId: Value(worldId),
      field: Value(field),
      oldValue: oldValue == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
      timestamp: Value(timestamp),
      isRemote: Value(isRemote),
    );
  }

  factory HistoryTimelineData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryTimelineData(
      id: serializer.fromJson<int>(json['id']),
      timelineId: serializer.fromJson<int>(json['timelineId']),
      worldId: serializer.fromJson<String>(json['worldId']),
      field: serializer.fromJson<String>(json['field']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      isRemote: serializer.fromJson<int>(json['isRemote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timelineId': serializer.toJson<int>(timelineId),
      'worldId': serializer.toJson<String>(worldId),
      'field': serializer.toJson<String>(field),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
      'timestamp': serializer.toJson<String>(timestamp),
      'isRemote': serializer.toJson<int>(isRemote),
    };
  }

  HistoryTimelineData copyWith({
    int? id,
    int? timelineId,
    String? worldId,
    String? field,
    Value<String?> oldValue = const Value.absent(),
    Value<String?> newValue = const Value.absent(),
    String? timestamp,
    int? isRemote,
  }) => HistoryTimelineData(
    id: id ?? this.id,
    timelineId: timelineId ?? this.timelineId,
    worldId: worldId ?? this.worldId,
    field: field ?? this.field,
    oldValue: oldValue.present ? oldValue.value : this.oldValue,
    newValue: newValue.present ? newValue.value : this.newValue,
    timestamp: timestamp ?? this.timestamp,
    isRemote: isRemote ?? this.isRemote,
  );
  HistoryTimelineData copyWithCompanion(HistoryTimelineCompanion data) {
    return HistoryTimelineData(
      id: data.id.present ? data.id.value : this.id,
      timelineId: data.timelineId.present
          ? data.timelineId.value
          : this.timelineId,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      field: data.field.present ? data.field.value : this.field,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isRemote: data.isRemote.present ? data.isRemote.value : this.isRemote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryTimelineData(')
          ..write('id: $id, ')
          ..write('timelineId: $timelineId, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRemote: $isRemote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timelineId,
    worldId,
    field,
    oldValue,
    newValue,
    timestamp,
    isRemote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryTimelineData &&
          other.id == this.id &&
          other.timelineId == this.timelineId &&
          other.worldId == this.worldId &&
          other.field == this.field &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue &&
          other.timestamp == this.timestamp &&
          other.isRemote == this.isRemote);
}

class HistoryTimelineCompanion extends UpdateCompanion<HistoryTimelineData> {
  final Value<int> id;
  final Value<int> timelineId;
  final Value<String> worldId;
  final Value<String> field;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<String> timestamp;
  final Value<int> isRemote;
  const HistoryTimelineCompanion({
    this.id = const Value.absent(),
    this.timelineId = const Value.absent(),
    this.worldId = const Value.absent(),
    this.field = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isRemote = const Value.absent(),
  });
  HistoryTimelineCompanion.insert({
    this.id = const Value.absent(),
    required int timelineId,
    this.worldId = const Value.absent(),
    required String field,
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    required String timestamp,
    this.isRemote = const Value.absent(),
  }) : timelineId = Value(timelineId),
       field = Value(field),
       timestamp = Value(timestamp);
  static Insertable<HistoryTimelineData> custom({
    Expression<int>? id,
    Expression<int>? timelineId,
    Expression<String>? worldId,
    Expression<String>? field,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<String>? timestamp,
    Expression<int>? isRemote,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timelineId != null) 'timeline_id': timelineId,
      if (worldId != null) 'world_id': worldId,
      if (field != null) 'field': field,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (timestamp != null) 'timestamp': timestamp,
      if (isRemote != null) 'is_remote': isRemote,
    });
  }

  HistoryTimelineCompanion copyWith({
    Value<int>? id,
    Value<int>? timelineId,
    Value<String>? worldId,
    Value<String>? field,
    Value<String?>? oldValue,
    Value<String?>? newValue,
    Value<String>? timestamp,
    Value<int>? isRemote,
  }) {
    return HistoryTimelineCompanion(
      id: id ?? this.id,
      timelineId: timelineId ?? this.timelineId,
      worldId: worldId ?? this.worldId,
      field: field ?? this.field,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      timestamp: timestamp ?? this.timestamp,
      isRemote: isRemote ?? this.isRemote,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timelineId.present) {
      map['timeline_id'] = Variable<int>(timelineId.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (isRemote.present) {
      map['is_remote'] = Variable<int>(isRemote.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryTimelineCompanion(')
          ..write('id: $id, ')
          ..write('timelineId: $timelineId, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('timestamp: $timestamp, ')
          ..write('isRemote: $isRemote')
          ..write(')'))
        .toString();
  }
}

class $SyncsTable extends Syncs with TableInfo<$SyncsTable, Sync> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timestamp, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syncs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sync> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sync map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sync(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $SyncsTable createAlias(String alias) {
    return $SyncsTable(attachedDatabase, alias);
  }
}

class Sync extends DataClass implements Insertable<Sync> {
  final int id;
  final String timestamp;
  final int status;
  const Sync({required this.id, required this.timestamp, required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<String>(timestamp);
    map['status'] = Variable<int>(status);
    return map;
  }

  SyncsCompanion toCompanion(bool nullToAbsent) {
    return SyncsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      status: Value(status),
    );
  }

  factory Sync.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sync(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<String>(timestamp),
      'status': serializer.toJson<int>(status),
    };
  }

  Sync copyWith({int? id, String? timestamp, int? status}) => Sync(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    status: status ?? this.status,
  );
  Sync copyWithCompanion(SyncsCompanion data) {
    return Sync(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sync(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timestamp, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sync &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.status == this.status);
}

class SyncsCompanion extends UpdateCompanion<Sync> {
  final Value<int> id;
  final Value<String> timestamp;
  final Value<int> status;
  const SyncsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncsCompanion.insert({
    this.id = const Value.absent(),
    required String timestamp,
    required int status,
  }) : timestamp = Value(timestamp),
       status = Value(status);
  static Insertable<Sync> custom({
    Expression<int>? id,
    Expression<String>? timestamp,
    Expression<int>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (status != null) 'status': status,
    });
  }

  SyncsCompanion copyWith({
    Value<int>? id,
    Value<String>? timestamp,
    Value<int>? status,
  }) {
    return SyncsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $SyncPacketsTable extends SyncPackets
    with TableInfo<$SyncPacketsTable, SyncPacketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPacketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _originDeviceIdMeta = const VerificationMeta(
    'originDeviceId',
  );
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
    'origin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterMeta = const VerificationMeta(
    'counter',
  );
  @override
  late final GeneratedColumn<int> counter = GeneratedColumn<int>(
    'counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedAtMeta = const VerificationMeta(
    'storedAt',
  );
  @override
  late final GeneratedColumn<String> storedAt = GeneratedColumn<String>(
    'stored_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  @override
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    originDeviceId,
    counter,
    payload,
    storedAt,
    payloadHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_packets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPacketRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('origin_device_id')) {
      context.handle(
        _originDeviceIdMeta,
        originDeviceId.isAcceptableOrUnknown(
          data['origin_device_id']!,
          _originDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('counter')) {
      context.handle(
        _counterMeta,
        counter.isAcceptableOrUnknown(data['counter']!, _counterMeta),
      );
    } else if (isInserting) {
      context.missing(_counterMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('stored_at')) {
      context.handle(
        _storedAtMeta,
        storedAt.isAcceptableOrUnknown(data['stored_at']!, _storedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_storedAtMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {originDeviceId, counter};
  @override
  SyncPacketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPacketRow(
      originDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device_id'],
      )!,
      counter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counter'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
      storedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_at'],
      )!,
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      )!,
    );
  }

  @override
  $SyncPacketsTable createAlias(String alias) {
    return $SyncPacketsTable(attachedDatabase, alias);
  }
}

class SyncPacketRow extends DataClass implements Insertable<SyncPacketRow> {
  final String originDeviceId;
  final int counter;
  final Uint8List payload;

  /// Local receive/creation time (informational only).
  final String storedAt;

  /// SHA-256 of [payload], lowercase hex — the packet's *content* identity,
  /// as opposed to the `(origin device, counter)` slot it occupies.
  ///
  /// The slot rule (docs/P2P_SYNC.md §5.2) assumes an occupied slot always
  /// holds the same bytes everywhere, and treats a second arrival as a
  /// duplicate. A device restored from a backup breaks that assumption: it
  /// re-issues counters it has already used, with different content. Keeping
  /// the hash lets a node say which of the two it means, so divergence is a
  /// detectable event at a named counter rather than a silent no-op.
  ///
  /// Empty for rows written before the column existed and never re-hashed —
  /// treated as "unknown", never as a mismatch.
  final String payloadHash;
  const SyncPacketRow({
    required this.originDeviceId,
    required this.counter,
    required this.payload,
    required this.storedAt,
    required this.payloadHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['counter'] = Variable<int>(counter);
    map['payload'] = Variable<Uint8List>(payload);
    map['stored_at'] = Variable<String>(storedAt);
    map['payload_hash'] = Variable<String>(payloadHash);
    return map;
  }

  SyncPacketsCompanion toCompanion(bool nullToAbsent) {
    return SyncPacketsCompanion(
      originDeviceId: Value(originDeviceId),
      counter: Value(counter),
      payload: Value(payload),
      storedAt: Value(storedAt),
      payloadHash: Value(payloadHash),
    );
  }

  factory SyncPacketRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPacketRow(
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      counter: serializer.fromJson<int>(json['counter']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
      storedAt: serializer.fromJson<String>(json['storedAt']),
      payloadHash: serializer.fromJson<String>(json['payloadHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'counter': serializer.toJson<int>(counter),
      'payload': serializer.toJson<Uint8List>(payload),
      'storedAt': serializer.toJson<String>(storedAt),
      'payloadHash': serializer.toJson<String>(payloadHash),
    };
  }

  SyncPacketRow copyWith({
    String? originDeviceId,
    int? counter,
    Uint8List? payload,
    String? storedAt,
    String? payloadHash,
  }) => SyncPacketRow(
    originDeviceId: originDeviceId ?? this.originDeviceId,
    counter: counter ?? this.counter,
    payload: payload ?? this.payload,
    storedAt: storedAt ?? this.storedAt,
    payloadHash: payloadHash ?? this.payloadHash,
  );
  SyncPacketRow copyWithCompanion(SyncPacketsCompanion data) {
    return SyncPacketRow(
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      counter: data.counter.present ? data.counter.value : this.counter,
      payload: data.payload.present ? data.payload.value : this.payload,
      storedAt: data.storedAt.present ? data.storedAt.value : this.storedAt,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPacketRow(')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('counter: $counter, ')
          ..write('payload: $payload, ')
          ..write('storedAt: $storedAt, ')
          ..write('payloadHash: $payloadHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    originDeviceId,
    counter,
    $driftBlobEquality.hash(payload),
    storedAt,
    payloadHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPacketRow &&
          other.originDeviceId == this.originDeviceId &&
          other.counter == this.counter &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          other.storedAt == this.storedAt &&
          other.payloadHash == this.payloadHash);
}

class SyncPacketsCompanion extends UpdateCompanion<SyncPacketRow> {
  final Value<String> originDeviceId;
  final Value<int> counter;
  final Value<Uint8List> payload;
  final Value<String> storedAt;
  final Value<String> payloadHash;
  final Value<int> rowid;
  const SyncPacketsCompanion({
    this.originDeviceId = const Value.absent(),
    this.counter = const Value.absent(),
    this.payload = const Value.absent(),
    this.storedAt = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPacketsCompanion.insert({
    required String originDeviceId,
    required int counter,
    required Uint8List payload,
    required String storedAt,
    this.payloadHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : originDeviceId = Value(originDeviceId),
       counter = Value(counter),
       payload = Value(payload),
       storedAt = Value(storedAt);
  static Insertable<SyncPacketRow> custom({
    Expression<String>? originDeviceId,
    Expression<int>? counter,
    Expression<Uint8List>? payload,
    Expression<String>? storedAt,
    Expression<String>? payloadHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (counter != null) 'counter': counter,
      if (payload != null) 'payload': payload,
      if (storedAt != null) 'stored_at': storedAt,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPacketsCompanion copyWith({
    Value<String>? originDeviceId,
    Value<int>? counter,
    Value<Uint8List>? payload,
    Value<String>? storedAt,
    Value<String>? payloadHash,
    Value<int>? rowid,
  }) {
    return SyncPacketsCompanion(
      originDeviceId: originDeviceId ?? this.originDeviceId,
      counter: counter ?? this.counter,
      payload: payload ?? this.payload,
      storedAt: storedAt ?? this.storedAt,
      payloadHash: payloadHash ?? this.payloadHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (counter.present) {
      map['counter'] = Variable<int>(counter.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (storedAt.present) {
      map['stored_at'] = Variable<String>(storedAt.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPacketsCompanion(')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('counter: $counter, ')
          ..write('payload: $payload, ')
          ..write('storedAt: $storedAt, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOrphansTable extends SyncOrphans
    with TableInfo<$SyncOrphansTable, SyncOrphanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOrphansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCreationMeta = const VerificationMeta(
    'isCreation',
  );
  @override
  late final GeneratedColumn<int> isCreation = GeneratedColumn<int>(
    'is_creation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _parentWorldIdMeta = const VerificationMeta(
    'parentWorldId',
  );
  @override
  late final GeneratedColumn<String> parentWorldId = GeneratedColumn<String>(
    'parent_world_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstSeenMeta = const VerificationMeta(
    'firstSeen',
  );
  @override
  late final GeneratedColumn<String> firstSeen = GeneratedColumn<String>(
    'first_seen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entityType,
    worldId,
    field,
    value,
    timestamp,
    isCreation,
    parentWorldId,
    firstSeen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_orphans';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOrphanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_worldIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('is_creation')) {
      context.handle(
        _isCreationMeta,
        isCreation.isAcceptableOrUnknown(data['is_creation']!, _isCreationMeta),
      );
    }
    if (data.containsKey('parent_world_id')) {
      context.handle(
        _parentWorldIdMeta,
        parentWorldId.isAcceptableOrUnknown(
          data['parent_world_id']!,
          _parentWorldIdMeta,
        ),
      );
    }
    if (data.containsKey('first_seen')) {
      context.handle(
        _firstSeenMeta,
        firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, worldId, field};
  @override
  SyncOrphanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOrphanRow(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      isCreation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_creation'],
      )!,
      parentWorldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_world_id'],
      ),
      firstSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_seen'],
      )!,
    );
  }

  @override
  $SyncOrphansTable createAlias(String alias) {
    return $SyncOrphansTable(attachedDatabase, alias);
  }
}

class SyncOrphanRow extends DataClass implements Insertable<SyncOrphanRow> {
  final String entityType;
  final String worldId;
  final String field;
  final String? value;
  final String timestamp;
  final int isCreation;
  final String? parentWorldId;
  final String firstSeen;
  const SyncOrphanRow({
    required this.entityType,
    required this.worldId,
    required this.field,
    this.value,
    required this.timestamp,
    required this.isCreation,
    this.parentWorldId,
    required this.firstSeen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['world_id'] = Variable<String>(worldId);
    map['field'] = Variable<String>(field);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['timestamp'] = Variable<String>(timestamp);
    map['is_creation'] = Variable<int>(isCreation);
    if (!nullToAbsent || parentWorldId != null) {
      map['parent_world_id'] = Variable<String>(parentWorldId);
    }
    map['first_seen'] = Variable<String>(firstSeen);
    return map;
  }

  SyncOrphansCompanion toCompanion(bool nullToAbsent) {
    return SyncOrphansCompanion(
      entityType: Value(entityType),
      worldId: Value(worldId),
      field: Value(field),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      timestamp: Value(timestamp),
      isCreation: Value(isCreation),
      parentWorldId: parentWorldId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentWorldId),
      firstSeen: Value(firstSeen),
    );
  }

  factory SyncOrphanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOrphanRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      worldId: serializer.fromJson<String>(json['worldId']),
      field: serializer.fromJson<String>(json['field']),
      value: serializer.fromJson<String?>(json['value']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      isCreation: serializer.fromJson<int>(json['isCreation']),
      parentWorldId: serializer.fromJson<String?>(json['parentWorldId']),
      firstSeen: serializer.fromJson<String>(json['firstSeen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'worldId': serializer.toJson<String>(worldId),
      'field': serializer.toJson<String>(field),
      'value': serializer.toJson<String?>(value),
      'timestamp': serializer.toJson<String>(timestamp),
      'isCreation': serializer.toJson<int>(isCreation),
      'parentWorldId': serializer.toJson<String?>(parentWorldId),
      'firstSeen': serializer.toJson<String>(firstSeen),
    };
  }

  SyncOrphanRow copyWith({
    String? entityType,
    String? worldId,
    String? field,
    Value<String?> value = const Value.absent(),
    String? timestamp,
    int? isCreation,
    Value<String?> parentWorldId = const Value.absent(),
    String? firstSeen,
  }) => SyncOrphanRow(
    entityType: entityType ?? this.entityType,
    worldId: worldId ?? this.worldId,
    field: field ?? this.field,
    value: value.present ? value.value : this.value,
    timestamp: timestamp ?? this.timestamp,
    isCreation: isCreation ?? this.isCreation,
    parentWorldId: parentWorldId.present
        ? parentWorldId.value
        : this.parentWorldId,
    firstSeen: firstSeen ?? this.firstSeen,
  );
  SyncOrphanRow copyWithCompanion(SyncOrphansCompanion data) {
    return SyncOrphanRow(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      field: data.field.present ? data.field.value : this.field,
      value: data.value.present ? data.value.value : this.value,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isCreation: data.isCreation.present
          ? data.isCreation.value
          : this.isCreation,
      parentWorldId: data.parentWorldId.present
          ? data.parentWorldId.value
          : this.parentWorldId,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOrphanRow(')
          ..write('entityType: $entityType, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('value: $value, ')
          ..write('timestamp: $timestamp, ')
          ..write('isCreation: $isCreation, ')
          ..write('parentWorldId: $parentWorldId, ')
          ..write('firstSeen: $firstSeen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entityType,
    worldId,
    field,
    value,
    timestamp,
    isCreation,
    parentWorldId,
    firstSeen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOrphanRow &&
          other.entityType == this.entityType &&
          other.worldId == this.worldId &&
          other.field == this.field &&
          other.value == this.value &&
          other.timestamp == this.timestamp &&
          other.isCreation == this.isCreation &&
          other.parentWorldId == this.parentWorldId &&
          other.firstSeen == this.firstSeen);
}

class SyncOrphansCompanion extends UpdateCompanion<SyncOrphanRow> {
  final Value<String> entityType;
  final Value<String> worldId;
  final Value<String> field;
  final Value<String?> value;
  final Value<String> timestamp;
  final Value<int> isCreation;
  final Value<String?> parentWorldId;
  final Value<String> firstSeen;
  final Value<int> rowid;
  const SyncOrphansCompanion({
    this.entityType = const Value.absent(),
    this.worldId = const Value.absent(),
    this.field = const Value.absent(),
    this.value = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isCreation = const Value.absent(),
    this.parentWorldId = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOrphansCompanion.insert({
    required String entityType,
    required String worldId,
    required String field,
    this.value = const Value.absent(),
    required String timestamp,
    this.isCreation = const Value.absent(),
    this.parentWorldId = const Value.absent(),
    required String firstSeen,
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       worldId = Value(worldId),
       field = Value(field),
       timestamp = Value(timestamp),
       firstSeen = Value(firstSeen);
  static Insertable<SyncOrphanRow> custom({
    Expression<String>? entityType,
    Expression<String>? worldId,
    Expression<String>? field,
    Expression<String>? value,
    Expression<String>? timestamp,
    Expression<int>? isCreation,
    Expression<String>? parentWorldId,
    Expression<String>? firstSeen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (worldId != null) 'world_id': worldId,
      if (field != null) 'field': field,
      if (value != null) 'value': value,
      if (timestamp != null) 'timestamp': timestamp,
      if (isCreation != null) 'is_creation': isCreation,
      if (parentWorldId != null) 'parent_world_id': parentWorldId,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOrphansCompanion copyWith({
    Value<String>? entityType,
    Value<String>? worldId,
    Value<String>? field,
    Value<String?>? value,
    Value<String>? timestamp,
    Value<int>? isCreation,
    Value<String?>? parentWorldId,
    Value<String>? firstSeen,
    Value<int>? rowid,
  }) {
    return SyncOrphansCompanion(
      entityType: entityType ?? this.entityType,
      worldId: worldId ?? this.worldId,
      field: field ?? this.field,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      isCreation: isCreation ?? this.isCreation,
      parentWorldId: parentWorldId ?? this.parentWorldId,
      firstSeen: firstSeen ?? this.firstSeen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (isCreation.present) {
      map['is_creation'] = Variable<int>(isCreation.value);
    }
    if (parentWorldId.present) {
      map['parent_world_id'] = Variable<String>(parentWorldId.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<String>(firstSeen.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOrphansCompanion(')
          ..write('entityType: $entityType, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('value: $value, ')
          ..write('timestamp: $timestamp, ')
          ..write('isCreation: $isCreation, ')
          ..write('parentWorldId: $parentWorldId, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncPushLogTable extends SyncPushLog
    with TableInfo<$SyncPushLogTable, SyncPushLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPushLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _counterMeta = const VerificationMeta(
    'counter',
  );
  @override
  late final GeneratedColumn<int> counter = GeneratedColumn<int>(
    'counter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskHistoryIdMeta = const VerificationMeta(
    'taskHistoryId',
  );
  @override
  late final GeneratedColumn<int> taskHistoryId = GeneratedColumn<int>(
    'task_history_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [counter, taskHistoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_push_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPushLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('counter')) {
      context.handle(
        _counterMeta,
        counter.isAcceptableOrUnknown(data['counter']!, _counterMeta),
      );
    }
    if (data.containsKey('task_history_id')) {
      context.handle(
        _taskHistoryIdMeta,
        taskHistoryId.isAcceptableOrUnknown(
          data['task_history_id']!,
          _taskHistoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taskHistoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {counter};
  @override
  SyncPushLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPushLogData(
      counter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counter'],
      )!,
      taskHistoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_history_id'],
      )!,
    );
  }

  @override
  $SyncPushLogTable createAlias(String alias) {
    return $SyncPushLogTable(attachedDatabase, alias);
  }
}

class SyncPushLogData extends DataClass implements Insertable<SyncPushLogData> {
  final int counter;
  final int taskHistoryId;
  const SyncPushLogData({required this.counter, required this.taskHistoryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['counter'] = Variable<int>(counter);
    map['task_history_id'] = Variable<int>(taskHistoryId);
    return map;
  }

  SyncPushLogCompanion toCompanion(bool nullToAbsent) {
    return SyncPushLogCompanion(
      counter: Value(counter),
      taskHistoryId: Value(taskHistoryId),
    );
  }

  factory SyncPushLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPushLogData(
      counter: serializer.fromJson<int>(json['counter']),
      taskHistoryId: serializer.fromJson<int>(json['taskHistoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'counter': serializer.toJson<int>(counter),
      'taskHistoryId': serializer.toJson<int>(taskHistoryId),
    };
  }

  SyncPushLogData copyWith({int? counter, int? taskHistoryId}) =>
      SyncPushLogData(
        counter: counter ?? this.counter,
        taskHistoryId: taskHistoryId ?? this.taskHistoryId,
      );
  SyncPushLogData copyWithCompanion(SyncPushLogCompanion data) {
    return SyncPushLogData(
      counter: data.counter.present ? data.counter.value : this.counter,
      taskHistoryId: data.taskHistoryId.present
          ? data.taskHistoryId.value
          : this.taskHistoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPushLogData(')
          ..write('counter: $counter, ')
          ..write('taskHistoryId: $taskHistoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(counter, taskHistoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPushLogData &&
          other.counter == this.counter &&
          other.taskHistoryId == this.taskHistoryId);
}

class SyncPushLogCompanion extends UpdateCompanion<SyncPushLogData> {
  final Value<int> counter;
  final Value<int> taskHistoryId;
  const SyncPushLogCompanion({
    this.counter = const Value.absent(),
    this.taskHistoryId = const Value.absent(),
  });
  SyncPushLogCompanion.insert({
    this.counter = const Value.absent(),
    required int taskHistoryId,
  }) : taskHistoryId = Value(taskHistoryId);
  static Insertable<SyncPushLogData> custom({
    Expression<int>? counter,
    Expression<int>? taskHistoryId,
  }) {
    return RawValuesInsertable({
      if (counter != null) 'counter': counter,
      if (taskHistoryId != null) 'task_history_id': taskHistoryId,
    });
  }

  SyncPushLogCompanion copyWith({
    Value<int>? counter,
    Value<int>? taskHistoryId,
  }) {
    return SyncPushLogCompanion(
      counter: counter ?? this.counter,
      taskHistoryId: taskHistoryId ?? this.taskHistoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (counter.present) {
      map['counter'] = Variable<int>(counter.value);
    }
    if (taskHistoryId.present) {
      map['task_history_id'] = Variable<int>(taskHistoryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPushLogCompanion(')
          ..write('counter: $counter, ')
          ..write('taskHistoryId: $taskHistoryId')
          ..write(')'))
        .toString();
  }
}

class $BlobFetchesTable extends BlobFetches
    with TableInfo<$BlobFetchesTable, BlobFetche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlobFetchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedMeta = const VerificationMeta(
    'received',
  );
  @override
  late final GeneratedColumn<Uint8List> received = GeneratedColumn<Uint8List>(
    'received',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [hash, received, total, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blob_fetches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlobFetche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('received')) {
      context.handle(
        _receivedMeta,
        received.isAcceptableOrUnknown(data['received']!, _receivedMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {hash};
  @override
  BlobFetche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlobFetche(
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      received: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}received'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BlobFetchesTable createAlias(String alias) {
    return $BlobFetchesTable(attachedDatabase, alias);
  }
}

class BlobFetche extends DataClass implements Insertable<BlobFetche> {
  /// Content id of the blob being fetched — sha256 of the *plaintext*, so the
  /// row is named by what it will become, not by what it holds.
  final String hash;

  /// Ciphertext received so far, always a prefix starting at offset 0.
  final Uint8List received;

  /// Full ciphertext length, once a node has said what it is. Null while no
  /// answer has reported one.
  final int? total;

  /// When this row last grew. Stale rows are dropped rather than resumed: the
  /// node holding the blob may have re-encrypted it since.
  final String updatedAt;
  const BlobFetche({
    required this.hash,
    required this.received,
    this.total,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hash'] = Variable<String>(hash);
    map['received'] = Variable<Uint8List>(received);
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<int>(total);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BlobFetchesCompanion toCompanion(bool nullToAbsent) {
    return BlobFetchesCompanion(
      hash: Value(hash),
      received: Value(received),
      total: total == null && nullToAbsent
          ? const Value.absent()
          : Value(total),
      updatedAt: Value(updatedAt),
    );
  }

  factory BlobFetche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlobFetche(
      hash: serializer.fromJson<String>(json['hash']),
      received: serializer.fromJson<Uint8List>(json['received']),
      total: serializer.fromJson<int?>(json['total']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hash': serializer.toJson<String>(hash),
      'received': serializer.toJson<Uint8List>(received),
      'total': serializer.toJson<int?>(total),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  BlobFetche copyWith({
    String? hash,
    Uint8List? received,
    Value<int?> total = const Value.absent(),
    String? updatedAt,
  }) => BlobFetche(
    hash: hash ?? this.hash,
    received: received ?? this.received,
    total: total.present ? total.value : this.total,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BlobFetche copyWithCompanion(BlobFetchesCompanion data) {
    return BlobFetche(
      hash: data.hash.present ? data.hash.value : this.hash,
      received: data.received.present ? data.received.value : this.received,
      total: data.total.present ? data.total.value : this.total,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlobFetche(')
          ..write('hash: $hash, ')
          ..write('received: $received, ')
          ..write('total: $total, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(hash, $driftBlobEquality.hash(received), total, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlobFetche &&
          other.hash == this.hash &&
          $driftBlobEquality.equals(other.received, this.received) &&
          other.total == this.total &&
          other.updatedAt == this.updatedAt);
}

class BlobFetchesCompanion extends UpdateCompanion<BlobFetche> {
  final Value<String> hash;
  final Value<Uint8List> received;
  final Value<int?> total;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const BlobFetchesCompanion({
    this.hash = const Value.absent(),
    this.received = const Value.absent(),
    this.total = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlobFetchesCompanion.insert({
    required String hash,
    required Uint8List received,
    this.total = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       received = Value(received),
       updatedAt = Value(updatedAt);
  static Insertable<BlobFetche> custom({
    Expression<String>? hash,
    Expression<Uint8List>? received,
    Expression<int>? total,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hash != null) 'hash': hash,
      if (received != null) 'received': received,
      if (total != null) 'total': total,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlobFetchesCompanion copyWith({
    Value<String>? hash,
    Value<Uint8List>? received,
    Value<int?>? total,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return BlobFetchesCompanion(
      hash: hash ?? this.hash,
      received: received ?? this.received,
      total: total ?? this.total,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (received.present) {
      map['received'] = Variable<Uint8List>(received.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlobFetchesCompanion(')
          ..write('hash: $hash, ')
          ..write('received: $received, ')
          ..write('total: $total, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncLogRunsTable extends SyncLogRuns
    with TableInfo<$SyncLogRunsTable, SyncLogRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogRunsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<String> finishedAt = GeneratedColumn<String>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteMeta = const VerificationMeta('remote');
  @override
  late final GeneratedColumn<String> remote = GeneratedColumn<String>(
    'remote',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('running'),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countsJsonMeta = const VerificationMeta(
    'countsJson',
  );
  @override
  late final GeneratedColumn<String> countsJson = GeneratedColumn<String>(
    'counts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    finishedAt,
    trigger,
    remote,
    deviceId,
    outcome,
    error,
    countsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    } else if (isInserting) {
      context.missing(_triggerMeta);
    }
    if (data.containsKey('remote')) {
      context.handle(
        _remoteMeta,
        remote.isAcceptableOrUnknown(data['remote']!, _remoteMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('counts_json')) {
      context.handle(
        _countsJsonMeta,
        countsJson.isAcceptableOrUnknown(data['counts_json']!, _countsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finished_at'],
      ),
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      )!,
      remote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      countsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counts_json'],
      )!,
    );
  }

  @override
  $SyncLogRunsTable createAlias(String alias) {
    return $SyncLogRunsTable(attachedDatabase, alias);
  }
}

class SyncLogRunRow extends DataClass implements Insertable<SyncLogRunRow> {
  final int id;
  final String startedAt;

  /// Null while the run is in progress — and forever for one the process did
  /// not survive, which is itself worth seeing.
  final String? finishedAt;

  /// What started it: relay, lan, lan-serve, compaction, identity-reset,
  /// attachment, blob-collect.
  final String trigger;

  /// The other side: 'relay', 'peer <device>@host:port', a peer device id.
  final String? remote;

  /// This device's id when the run started (it changes on identity reset).
  final String deviceId;

  /// running, ok, failed, declined, busy, interrupted.
  final String outcome;
  final String? error;

  /// Counters for the run list: packets in/out, changes applied, warnings…
  final String countsJson;
  const SyncLogRunRow({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.trigger,
    this.remote,
    required this.deviceId,
    required this.outcome,
    this.error,
    required this.countsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<String>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<String>(finishedAt);
    }
    map['trigger'] = Variable<String>(trigger);
    if (!nullToAbsent || remote != null) {
      map['remote'] = Variable<String>(remote);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['outcome'] = Variable<String>(outcome);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['counts_json'] = Variable<String>(countsJson);
    return map;
  }

  SyncLogRunsCompanion toCompanion(bool nullToAbsent) {
    return SyncLogRunsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      trigger: Value(trigger),
      remote: remote == null && nullToAbsent
          ? const Value.absent()
          : Value(remote),
      deviceId: Value(deviceId),
      outcome: Value(outcome),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      countsJson: Value(countsJson),
    );
  }

  factory SyncLogRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogRunRow(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<String>(json['startedAt']),
      finishedAt: serializer.fromJson<String?>(json['finishedAt']),
      trigger: serializer.fromJson<String>(json['trigger']),
      remote: serializer.fromJson<String?>(json['remote']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      outcome: serializer.fromJson<String>(json['outcome']),
      error: serializer.fromJson<String?>(json['error']),
      countsJson: serializer.fromJson<String>(json['countsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<String>(startedAt),
      'finishedAt': serializer.toJson<String?>(finishedAt),
      'trigger': serializer.toJson<String>(trigger),
      'remote': serializer.toJson<String?>(remote),
      'deviceId': serializer.toJson<String>(deviceId),
      'outcome': serializer.toJson<String>(outcome),
      'error': serializer.toJson<String?>(error),
      'countsJson': serializer.toJson<String>(countsJson),
    };
  }

  SyncLogRunRow copyWith({
    int? id,
    String? startedAt,
    Value<String?> finishedAt = const Value.absent(),
    String? trigger,
    Value<String?> remote = const Value.absent(),
    String? deviceId,
    String? outcome,
    Value<String?> error = const Value.absent(),
    String? countsJson,
  }) => SyncLogRunRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    trigger: trigger ?? this.trigger,
    remote: remote.present ? remote.value : this.remote,
    deviceId: deviceId ?? this.deviceId,
    outcome: outcome ?? this.outcome,
    error: error.present ? error.value : this.error,
    countsJson: countsJson ?? this.countsJson,
  );
  SyncLogRunRow copyWithCompanion(SyncLogRunsCompanion data) {
    return SyncLogRunRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      remote: data.remote.present ? data.remote.value : this.remote,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      error: data.error.present ? data.error.value : this.error,
      countsJson: data.countsJson.present
          ? data.countsJson.value
          : this.countsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogRunRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('trigger: $trigger, ')
          ..write('remote: $remote, ')
          ..write('deviceId: $deviceId, ')
          ..write('outcome: $outcome, ')
          ..write('error: $error, ')
          ..write('countsJson: $countsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    finishedAt,
    trigger,
    remote,
    deviceId,
    outcome,
    error,
    countsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogRunRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.trigger == this.trigger &&
          other.remote == this.remote &&
          other.deviceId == this.deviceId &&
          other.outcome == this.outcome &&
          other.error == this.error &&
          other.countsJson == this.countsJson);
}

class SyncLogRunsCompanion extends UpdateCompanion<SyncLogRunRow> {
  final Value<int> id;
  final Value<String> startedAt;
  final Value<String?> finishedAt;
  final Value<String> trigger;
  final Value<String?> remote;
  final Value<String> deviceId;
  final Value<String> outcome;
  final Value<String?> error;
  final Value<String> countsJson;
  const SyncLogRunsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.trigger = const Value.absent(),
    this.remote = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.error = const Value.absent(),
    this.countsJson = const Value.absent(),
  });
  SyncLogRunsCompanion.insert({
    this.id = const Value.absent(),
    required String startedAt,
    this.finishedAt = const Value.absent(),
    required String trigger,
    this.remote = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.error = const Value.absent(),
    this.countsJson = const Value.absent(),
  }) : startedAt = Value(startedAt),
       trigger = Value(trigger);
  static Insertable<SyncLogRunRow> custom({
    Expression<int>? id,
    Expression<String>? startedAt,
    Expression<String>? finishedAt,
    Expression<String>? trigger,
    Expression<String>? remote,
    Expression<String>? deviceId,
    Expression<String>? outcome,
    Expression<String>? error,
    Expression<String>? countsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (trigger != null) 'trigger': trigger,
      if (remote != null) 'remote': remote,
      if (deviceId != null) 'device_id': deviceId,
      if (outcome != null) 'outcome': outcome,
      if (error != null) 'error': error,
      if (countsJson != null) 'counts_json': countsJson,
    });
  }

  SyncLogRunsCompanion copyWith({
    Value<int>? id,
    Value<String>? startedAt,
    Value<String?>? finishedAt,
    Value<String>? trigger,
    Value<String?>? remote,
    Value<String>? deviceId,
    Value<String>? outcome,
    Value<String?>? error,
    Value<String>? countsJson,
  }) {
    return SyncLogRunsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      trigger: trigger ?? this.trigger,
      remote: remote ?? this.remote,
      deviceId: deviceId ?? this.deviceId,
      outcome: outcome ?? this.outcome,
      error: error ?? this.error,
      countsJson: countsJson ?? this.countsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<String>(finishedAt.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (remote.present) {
      map['remote'] = Variable<String>(remote.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (countsJson.present) {
      map['counts_json'] = Variable<String>(countsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogRunsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('trigger: $trigger, ')
          ..write('remote: $remote, ')
          ..write('deviceId: $deviceId, ')
          ..write('outcome: $outcome, ')
          ..write('error: $error, ')
          ..write('countsJson: $countsJson')
          ..write(')'))
        .toString();
  }
}

class $SyncLogEventsTable extends SyncLogEvents
    with TableInfo<$SyncLogEventsTable, SyncLogEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<int> runId = GeneratedColumn<int>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _originDeviceMeta = const VerificationMeta(
    'originDevice',
  );
  @override
  late final GeneratedColumn<String> originDevice = GeneratedColumn<String>(
    'origin_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterMeta = const VerificationMeta(
    'counter',
  );
  @override
  late final GeneratedColumn<int> counter = GeneratedColumn<int>(
    'counter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packetHashMeta = const VerificationMeta(
    'packetHash',
  );
  @override
  late final GeneratedColumn<String> packetHash = GeneratedColumn<String>(
    'packet_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _worldIdMeta = const VerificationMeta(
    'worldId',
  );
  @override
  late final GeneratedColumn<String> worldId = GeneratedColumn<String>(
    'world_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteTsMeta = const VerificationMeta(
    'remoteTs',
  );
  @override
  late final GeneratedColumn<String> remoteTs = GeneratedColumn<String>(
    'remote_ts',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localTsMeta = const VerificationMeta(
    'localTs',
  );
  @override
  late final GeneratedColumn<String> localTs = GeneratedColumn<String>(
    'local_ts',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueHashMeta = const VerificationMeta(
    'valueHash',
  );
  @override
  late final GeneratedColumn<String> valueHash = GeneratedColumn<String>(
    'value_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valuePreviewMeta = const VerificationMeta(
    'valuePreview',
  );
  @override
  late final GeneratedColumn<String> valuePreview = GeneratedColumn<String>(
    'value_preview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailJsonMeta = const VerificationMeta(
    'detailJson',
  );
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
    'detail_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    seq,
    at,
    level,
    kind,
    direction,
    originDevice,
    counter,
    packetHash,
    entityType,
    worldId,
    field,
    remoteTs,
    localTs,
    valueHash,
    valuePreview,
    message,
    detailJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('origin_device')) {
      context.handle(
        _originDeviceMeta,
        originDevice.isAcceptableOrUnknown(
          data['origin_device']!,
          _originDeviceMeta,
        ),
      );
    }
    if (data.containsKey('counter')) {
      context.handle(
        _counterMeta,
        counter.isAcceptableOrUnknown(data['counter']!, _counterMeta),
      );
    }
    if (data.containsKey('packet_hash')) {
      context.handle(
        _packetHashMeta,
        packetHash.isAcceptableOrUnknown(data['packet_hash']!, _packetHashMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('world_id')) {
      context.handle(
        _worldIdMeta,
        worldId.isAcceptableOrUnknown(data['world_id']!, _worldIdMeta),
      );
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    }
    if (data.containsKey('remote_ts')) {
      context.handle(
        _remoteTsMeta,
        remoteTs.isAcceptableOrUnknown(data['remote_ts']!, _remoteTsMeta),
      );
    }
    if (data.containsKey('local_ts')) {
      context.handle(
        _localTsMeta,
        localTs.isAcceptableOrUnknown(data['local_ts']!, _localTsMeta),
      );
    }
    if (data.containsKey('value_hash')) {
      context.handle(
        _valueHashMeta,
        valueHash.isAcceptableOrUnknown(data['value_hash']!, _valueHashMeta),
      );
    }
    if (data.containsKey('value_preview')) {
      context.handle(
        _valuePreviewMeta,
        valuePreview.isAcceptableOrUnknown(
          data['value_preview']!,
          _valuePreviewMeta,
        ),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('detail_json')) {
      context.handle(
        _detailJsonMeta,
        detailJson.isAcceptableOrUnknown(data['detail_json']!, _detailJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      originDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_device'],
      ),
      counter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}counter'],
      ),
      packetHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}packet_hash'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      ),
      worldId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world_id'],
      ),
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      ),
      remoteTs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_ts'],
      ),
      localTs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_ts'],
      ),
      valueHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_hash'],
      ),
      valuePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_preview'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      detailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_json'],
      ),
    );
  }

  @override
  $SyncLogEventsTable createAlias(String alias) {
    return $SyncLogEventsTable(attachedDatabase, alias);
  }
}

class SyncLogEventRow extends DataClass implements Insertable<SyncLogEventRow> {
  final int id;
  final int runId;

  /// Order within the run.
  final int seq;
  final String at;

  /// 0 info, 1 warning, 2 error.
  final int level;

  /// What happened, e.g. `packet-stored`, `lww-lost`, `conflict-copy`.
  final String kind;

  /// in, out, or local.
  final String direction;
  final String? originDevice;
  final int? counter;

  /// SHA-256 of the packet ciphertext, as in `sync_packets.payload_hash`.
  final String? packetHash;
  final String? entityType;
  final String? worldId;
  final String? field;

  /// Origin timestamp of the incoming value, and of the local value it was
  /// compared against.
  final String? remoteTs;
  final String? localTs;

  /// SHA-256 (truncated) of the field value, so two logs can be compared
  /// without holding the values themselves.
  final String? valueHash;

  /// Short preview of the value for text-like fields; size or reference for
  /// attachment content.
  final String? valuePreview;

  /// One line for people.
  final String? message;

  /// Anything else structured (vectors, byte counts, errors).
  final String? detailJson;
  const SyncLogEventRow({
    required this.id,
    required this.runId,
    required this.seq,
    required this.at,
    required this.level,
    required this.kind,
    required this.direction,
    this.originDevice,
    this.counter,
    this.packetHash,
    this.entityType,
    this.worldId,
    this.field,
    this.remoteTs,
    this.localTs,
    this.valueHash,
    this.valuePreview,
    this.message,
    this.detailJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<int>(runId);
    map['seq'] = Variable<int>(seq);
    map['at'] = Variable<String>(at);
    map['level'] = Variable<int>(level);
    map['kind'] = Variable<String>(kind);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || originDevice != null) {
      map['origin_device'] = Variable<String>(originDevice);
    }
    if (!nullToAbsent || counter != null) {
      map['counter'] = Variable<int>(counter);
    }
    if (!nullToAbsent || packetHash != null) {
      map['packet_hash'] = Variable<String>(packetHash);
    }
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || worldId != null) {
      map['world_id'] = Variable<String>(worldId);
    }
    if (!nullToAbsent || field != null) {
      map['field'] = Variable<String>(field);
    }
    if (!nullToAbsent || remoteTs != null) {
      map['remote_ts'] = Variable<String>(remoteTs);
    }
    if (!nullToAbsent || localTs != null) {
      map['local_ts'] = Variable<String>(localTs);
    }
    if (!nullToAbsent || valueHash != null) {
      map['value_hash'] = Variable<String>(valueHash);
    }
    if (!nullToAbsent || valuePreview != null) {
      map['value_preview'] = Variable<String>(valuePreview);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    if (!nullToAbsent || detailJson != null) {
      map['detail_json'] = Variable<String>(detailJson);
    }
    return map;
  }

  SyncLogEventsCompanion toCompanion(bool nullToAbsent) {
    return SyncLogEventsCompanion(
      id: Value(id),
      runId: Value(runId),
      seq: Value(seq),
      at: Value(at),
      level: Value(level),
      kind: Value(kind),
      direction: Value(direction),
      originDevice: originDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(originDevice),
      counter: counter == null && nullToAbsent
          ? const Value.absent()
          : Value(counter),
      packetHash: packetHash == null && nullToAbsent
          ? const Value.absent()
          : Value(packetHash),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      worldId: worldId == null && nullToAbsent
          ? const Value.absent()
          : Value(worldId),
      field: field == null && nullToAbsent
          ? const Value.absent()
          : Value(field),
      remoteTs: remoteTs == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteTs),
      localTs: localTs == null && nullToAbsent
          ? const Value.absent()
          : Value(localTs),
      valueHash: valueHash == null && nullToAbsent
          ? const Value.absent()
          : Value(valueHash),
      valuePreview: valuePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(valuePreview),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      detailJson: detailJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailJson),
    );
  }

  factory SyncLogEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogEventRow(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<int>(json['runId']),
      seq: serializer.fromJson<int>(json['seq']),
      at: serializer.fromJson<String>(json['at']),
      level: serializer.fromJson<int>(json['level']),
      kind: serializer.fromJson<String>(json['kind']),
      direction: serializer.fromJson<String>(json['direction']),
      originDevice: serializer.fromJson<String?>(json['originDevice']),
      counter: serializer.fromJson<int?>(json['counter']),
      packetHash: serializer.fromJson<String?>(json['packetHash']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      worldId: serializer.fromJson<String?>(json['worldId']),
      field: serializer.fromJson<String?>(json['field']),
      remoteTs: serializer.fromJson<String?>(json['remoteTs']),
      localTs: serializer.fromJson<String?>(json['localTs']),
      valueHash: serializer.fromJson<String?>(json['valueHash']),
      valuePreview: serializer.fromJson<String?>(json['valuePreview']),
      message: serializer.fromJson<String?>(json['message']),
      detailJson: serializer.fromJson<String?>(json['detailJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<int>(runId),
      'seq': serializer.toJson<int>(seq),
      'at': serializer.toJson<String>(at),
      'level': serializer.toJson<int>(level),
      'kind': serializer.toJson<String>(kind),
      'direction': serializer.toJson<String>(direction),
      'originDevice': serializer.toJson<String?>(originDevice),
      'counter': serializer.toJson<int?>(counter),
      'packetHash': serializer.toJson<String?>(packetHash),
      'entityType': serializer.toJson<String?>(entityType),
      'worldId': serializer.toJson<String?>(worldId),
      'field': serializer.toJson<String?>(field),
      'remoteTs': serializer.toJson<String?>(remoteTs),
      'localTs': serializer.toJson<String?>(localTs),
      'valueHash': serializer.toJson<String?>(valueHash),
      'valuePreview': serializer.toJson<String?>(valuePreview),
      'message': serializer.toJson<String?>(message),
      'detailJson': serializer.toJson<String?>(detailJson),
    };
  }

  SyncLogEventRow copyWith({
    int? id,
    int? runId,
    int? seq,
    String? at,
    int? level,
    String? kind,
    String? direction,
    Value<String?> originDevice = const Value.absent(),
    Value<int?> counter = const Value.absent(),
    Value<String?> packetHash = const Value.absent(),
    Value<String?> entityType = const Value.absent(),
    Value<String?> worldId = const Value.absent(),
    Value<String?> field = const Value.absent(),
    Value<String?> remoteTs = const Value.absent(),
    Value<String?> localTs = const Value.absent(),
    Value<String?> valueHash = const Value.absent(),
    Value<String?> valuePreview = const Value.absent(),
    Value<String?> message = const Value.absent(),
    Value<String?> detailJson = const Value.absent(),
  }) => SyncLogEventRow(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    seq: seq ?? this.seq,
    at: at ?? this.at,
    level: level ?? this.level,
    kind: kind ?? this.kind,
    direction: direction ?? this.direction,
    originDevice: originDevice.present ? originDevice.value : this.originDevice,
    counter: counter.present ? counter.value : this.counter,
    packetHash: packetHash.present ? packetHash.value : this.packetHash,
    entityType: entityType.present ? entityType.value : this.entityType,
    worldId: worldId.present ? worldId.value : this.worldId,
    field: field.present ? field.value : this.field,
    remoteTs: remoteTs.present ? remoteTs.value : this.remoteTs,
    localTs: localTs.present ? localTs.value : this.localTs,
    valueHash: valueHash.present ? valueHash.value : this.valueHash,
    valuePreview: valuePreview.present ? valuePreview.value : this.valuePreview,
    message: message.present ? message.value : this.message,
    detailJson: detailJson.present ? detailJson.value : this.detailJson,
  );
  SyncLogEventRow copyWithCompanion(SyncLogEventsCompanion data) {
    return SyncLogEventRow(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      seq: data.seq.present ? data.seq.value : this.seq,
      at: data.at.present ? data.at.value : this.at,
      level: data.level.present ? data.level.value : this.level,
      kind: data.kind.present ? data.kind.value : this.kind,
      direction: data.direction.present ? data.direction.value : this.direction,
      originDevice: data.originDevice.present
          ? data.originDevice.value
          : this.originDevice,
      counter: data.counter.present ? data.counter.value : this.counter,
      packetHash: data.packetHash.present
          ? data.packetHash.value
          : this.packetHash,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      worldId: data.worldId.present ? data.worldId.value : this.worldId,
      field: data.field.present ? data.field.value : this.field,
      remoteTs: data.remoteTs.present ? data.remoteTs.value : this.remoteTs,
      localTs: data.localTs.present ? data.localTs.value : this.localTs,
      valueHash: data.valueHash.present ? data.valueHash.value : this.valueHash,
      valuePreview: data.valuePreview.present
          ? data.valuePreview.value
          : this.valuePreview,
      message: data.message.present ? data.message.value : this.message,
      detailJson: data.detailJson.present
          ? data.detailJson.value
          : this.detailJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogEventRow(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('seq: $seq, ')
          ..write('at: $at, ')
          ..write('level: $level, ')
          ..write('kind: $kind, ')
          ..write('direction: $direction, ')
          ..write('originDevice: $originDevice, ')
          ..write('counter: $counter, ')
          ..write('packetHash: $packetHash, ')
          ..write('entityType: $entityType, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('remoteTs: $remoteTs, ')
          ..write('localTs: $localTs, ')
          ..write('valueHash: $valueHash, ')
          ..write('valuePreview: $valuePreview, ')
          ..write('message: $message, ')
          ..write('detailJson: $detailJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    seq,
    at,
    level,
    kind,
    direction,
    originDevice,
    counter,
    packetHash,
    entityType,
    worldId,
    field,
    remoteTs,
    localTs,
    valueHash,
    valuePreview,
    message,
    detailJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogEventRow &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.seq == this.seq &&
          other.at == this.at &&
          other.level == this.level &&
          other.kind == this.kind &&
          other.direction == this.direction &&
          other.originDevice == this.originDevice &&
          other.counter == this.counter &&
          other.packetHash == this.packetHash &&
          other.entityType == this.entityType &&
          other.worldId == this.worldId &&
          other.field == this.field &&
          other.remoteTs == this.remoteTs &&
          other.localTs == this.localTs &&
          other.valueHash == this.valueHash &&
          other.valuePreview == this.valuePreview &&
          other.message == this.message &&
          other.detailJson == this.detailJson);
}

class SyncLogEventsCompanion extends UpdateCompanion<SyncLogEventRow> {
  final Value<int> id;
  final Value<int> runId;
  final Value<int> seq;
  final Value<String> at;
  final Value<int> level;
  final Value<String> kind;
  final Value<String> direction;
  final Value<String?> originDevice;
  final Value<int?> counter;
  final Value<String?> packetHash;
  final Value<String?> entityType;
  final Value<String?> worldId;
  final Value<String?> field;
  final Value<String?> remoteTs;
  final Value<String?> localTs;
  final Value<String?> valueHash;
  final Value<String?> valuePreview;
  final Value<String?> message;
  final Value<String?> detailJson;
  const SyncLogEventsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.seq = const Value.absent(),
    this.at = const Value.absent(),
    this.level = const Value.absent(),
    this.kind = const Value.absent(),
    this.direction = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.counter = const Value.absent(),
    this.packetHash = const Value.absent(),
    this.entityType = const Value.absent(),
    this.worldId = const Value.absent(),
    this.field = const Value.absent(),
    this.remoteTs = const Value.absent(),
    this.localTs = const Value.absent(),
    this.valueHash = const Value.absent(),
    this.valuePreview = const Value.absent(),
    this.message = const Value.absent(),
    this.detailJson = const Value.absent(),
  });
  SyncLogEventsCompanion.insert({
    this.id = const Value.absent(),
    required int runId,
    required int seq,
    required String at,
    this.level = const Value.absent(),
    required String kind,
    this.direction = const Value.absent(),
    this.originDevice = const Value.absent(),
    this.counter = const Value.absent(),
    this.packetHash = const Value.absent(),
    this.entityType = const Value.absent(),
    this.worldId = const Value.absent(),
    this.field = const Value.absent(),
    this.remoteTs = const Value.absent(),
    this.localTs = const Value.absent(),
    this.valueHash = const Value.absent(),
    this.valuePreview = const Value.absent(),
    this.message = const Value.absent(),
    this.detailJson = const Value.absent(),
  }) : runId = Value(runId),
       seq = Value(seq),
       at = Value(at),
       kind = Value(kind);
  static Insertable<SyncLogEventRow> custom({
    Expression<int>? id,
    Expression<int>? runId,
    Expression<int>? seq,
    Expression<String>? at,
    Expression<int>? level,
    Expression<String>? kind,
    Expression<String>? direction,
    Expression<String>? originDevice,
    Expression<int>? counter,
    Expression<String>? packetHash,
    Expression<String>? entityType,
    Expression<String>? worldId,
    Expression<String>? field,
    Expression<String>? remoteTs,
    Expression<String>? localTs,
    Expression<String>? valueHash,
    Expression<String>? valuePreview,
    Expression<String>? message,
    Expression<String>? detailJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (seq != null) 'seq': seq,
      if (at != null) 'at': at,
      if (level != null) 'level': level,
      if (kind != null) 'kind': kind,
      if (direction != null) 'direction': direction,
      if (originDevice != null) 'origin_device': originDevice,
      if (counter != null) 'counter': counter,
      if (packetHash != null) 'packet_hash': packetHash,
      if (entityType != null) 'entity_type': entityType,
      if (worldId != null) 'world_id': worldId,
      if (field != null) 'field': field,
      if (remoteTs != null) 'remote_ts': remoteTs,
      if (localTs != null) 'local_ts': localTs,
      if (valueHash != null) 'value_hash': valueHash,
      if (valuePreview != null) 'value_preview': valuePreview,
      if (message != null) 'message': message,
      if (detailJson != null) 'detail_json': detailJson,
    });
  }

  SyncLogEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? runId,
    Value<int>? seq,
    Value<String>? at,
    Value<int>? level,
    Value<String>? kind,
    Value<String>? direction,
    Value<String?>? originDevice,
    Value<int?>? counter,
    Value<String?>? packetHash,
    Value<String?>? entityType,
    Value<String?>? worldId,
    Value<String?>? field,
    Value<String?>? remoteTs,
    Value<String?>? localTs,
    Value<String?>? valueHash,
    Value<String?>? valuePreview,
    Value<String?>? message,
    Value<String?>? detailJson,
  }) {
    return SyncLogEventsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      seq: seq ?? this.seq,
      at: at ?? this.at,
      level: level ?? this.level,
      kind: kind ?? this.kind,
      direction: direction ?? this.direction,
      originDevice: originDevice ?? this.originDevice,
      counter: counter ?? this.counter,
      packetHash: packetHash ?? this.packetHash,
      entityType: entityType ?? this.entityType,
      worldId: worldId ?? this.worldId,
      field: field ?? this.field,
      remoteTs: remoteTs ?? this.remoteTs,
      localTs: localTs ?? this.localTs,
      valueHash: valueHash ?? this.valueHash,
      valuePreview: valuePreview ?? this.valuePreview,
      message: message ?? this.message,
      detailJson: detailJson ?? this.detailJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<int>(runId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (originDevice.present) {
      map['origin_device'] = Variable<String>(originDevice.value);
    }
    if (counter.present) {
      map['counter'] = Variable<int>(counter.value);
    }
    if (packetHash.present) {
      map['packet_hash'] = Variable<String>(packetHash.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (worldId.present) {
      map['world_id'] = Variable<String>(worldId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (remoteTs.present) {
      map['remote_ts'] = Variable<String>(remoteTs.value);
    }
    if (localTs.present) {
      map['local_ts'] = Variable<String>(localTs.value);
    }
    if (valueHash.present) {
      map['value_hash'] = Variable<String>(valueHash.value);
    }
    if (valuePreview.present) {
      map['value_preview'] = Variable<String>(valuePreview.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogEventsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('seq: $seq, ')
          ..write('at: $at, ')
          ..write('level: $level, ')
          ..write('kind: $kind, ')
          ..write('direction: $direction, ')
          ..write('originDevice: $originDevice, ')
          ..write('counter: $counter, ')
          ..write('packetHash: $packetHash, ')
          ..write('entityType: $entityType, ')
          ..write('worldId: $worldId, ')
          ..write('field: $field, ')
          ..write('remoteTs: $remoteTs, ')
          ..write('localTs: $localTs, ')
          ..write('valueHash: $valueHash, ')
          ..write('valuePreview: $valuePreview, ')
          ..write('message: $message, ')
          ..write('detailJson: $detailJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$NooDatabase extends GeneratedDatabase {
  _$NooDatabase(QueryExecutor e) : super(e);
  $NooDatabaseManager get managers => $NooDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TimelineTable timeline = $TimelineTable(this);
  late final $FilesTable files = $FilesTable(this);
  late final $PropertiesTable properties = $PropertiesTable(this);
  late final $HistoryTaskTable historyTask = $HistoryTaskTable(this);
  late final $HistoryFileTable historyFile = $HistoryFileTable(this);
  late final $HistoryTimelineTable historyTimeline = $HistoryTimelineTable(
    this,
  );
  late final $SyncsTable syncs = $SyncsTable(this);
  late final $SyncPacketsTable syncPackets = $SyncPacketsTable(this);
  late final $SyncOrphansTable syncOrphans = $SyncOrphansTable(this);
  late final $SyncPushLogTable syncPushLog = $SyncPushLogTable(this);
  late final $BlobFetchesTable blobFetches = $BlobFetchesTable(this);
  late final $SyncLogRunsTable syncLogRuns = $SyncLogRunsTable(this);
  late final $SyncLogEventsTable syncLogEvents = $SyncLogEventsTable(this);
  late final Index idxTasksWorldId = Index(
    'idx_tasks_world_id',
    'CREATE INDEX idx_tasks_world_id ON tasks (world_id)',
  );
  late final Index idxTasksParentId = Index(
    'idx_tasks_parent_id',
    'CREATE INDEX idx_tasks_parent_id ON tasks (parent_id)',
  );
  late final Index idxTimelineWorldId = Index(
    'idx_timeline_world_id',
    'CREATE INDEX idx_timeline_world_id ON timeline (world_id)',
  );
  late final Index idxTimelineTaskId = Index(
    'idx_timeline_task_id',
    'CREATE INDEX idx_timeline_task_id ON timeline (task_id)',
  );
  late final Index idxFileWorldId = Index(
    'idx_file_world_id',
    'CREATE INDEX idx_file_world_id ON file (world_id)',
  );
  late final Index idxFileTaskId = Index(
    'idx_file_task_id',
    'CREATE INDEX idx_file_task_id ON file (task_id)',
  );
  late final Index idxFileContentHash = Index(
    'idx_file_content_hash',
    'CREATE INDEX idx_file_content_hash ON file (content_hash)',
  );
  late final Index idxHistoryTaskLookup = Index(
    'idx_history_task_lookup',
    'CREATE INDEX idx_history_task_lookup ON history_task (task_id, field, timestamp)',
  );
  late final Index idxHistoryFileLookup = Index(
    'idx_history_file_lookup',
    'CREATE INDEX idx_history_file_lookup ON history_file (file_id, field, timestamp)',
  );
  late final Index idxHistoryTimelineLookup = Index(
    'idx_history_timeline_lookup',
    'CREATE INDEX idx_history_timeline_lookup ON history_timeline (timeline_id, field, timestamp)',
  );
  late final Index idxSyncLogRunsStarted = Index(
    'idx_sync_log_runs_started',
    'CREATE INDEX idx_sync_log_runs_started ON sync_log_runs (started_at)',
  );
  late final Index idxSyncLogEventsRun = Index(
    'idx_sync_log_events_run',
    'CREATE INDEX idx_sync_log_events_run ON sync_log_events (run_id, seq)',
  );
  late final Index idxSyncLogEventsWorld = Index(
    'idx_sync_log_events_world',
    'CREATE INDEX idx_sync_log_events_world ON sync_log_events (world_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    timeline,
    files,
    properties,
    historyTask,
    historyFile,
    historyTimeline,
    syncs,
    syncPackets,
    syncOrphans,
    syncPushLog,
    blobFetches,
    syncLogRuns,
    syncLogEvents,
    idxTasksWorldId,
    idxTasksParentId,
    idxTimelineWorldId,
    idxTimelineTaskId,
    idxFileWorldId,
    idxFileTaskId,
    idxFileContentHash,
    idxHistoryTaskLookup,
    idxHistoryFileLookup,
    idxHistoryTimelineLookup,
    idxSyncLogRunsStarted,
    idxSyncLogEventsRun,
    idxSyncLogEventsWorld,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<int?> parentId,
      Value<String> worldId,
      Value<int> orderId,
      Value<String> title,
      Value<String?> content,
      Value<int> flags,
      required String timestamp,
      Value<int> removed,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<int> id,
      Value<int?> parentId,
      Value<String> worldId,
      Value<int> orderId,
      Value<String> title,
      Value<String?> content,
      Value<int> flags,
      Value<String> timestamp,
      Value<int> removed,
    });

class $$TasksTableFilterComposer extends Composer<_$NooDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$NooDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$NooDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<int> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get flags =>
      $composableBuilder(column: $table.flags, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get removed =>
      $composableBuilder(column: $table.removed, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, BaseReferences<_$NooDatabase, $TasksTable, TaskRow>),
          TaskRow,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$NooDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<int> orderId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> flags = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> removed = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                parentId: parentId,
                worldId: worldId,
                orderId: orderId,
                title: title,
                content: content,
                flags: flags,
                timestamp: timestamp,
                removed: removed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<int> orderId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> flags = const Value.absent(),
                required String timestamp,
                Value<int> removed = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                parentId: parentId,
                worldId: worldId,
                orderId: orderId,
                title: title,
                content: content,
                flags: flags,
                timestamp: timestamp,
                removed: removed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, BaseReferences<_$NooDatabase, $TasksTable, TaskRow>),
      TaskRow,
      PrefetchHooks Function()
    >;
typedef $$TimelineTableCreateCompanionBuilder =
    TimelineCompanion Function({
      Value<int> id,
      required int taskId,
      Value<String> worldId,
      required String startTime,
      Value<String?> endTime,
      required String timestamp,
      Value<int> removed,
    });
typedef $$TimelineTableUpdateCompanionBuilder =
    TimelineCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<String> worldId,
      Value<String> startTime,
      Value<String?> endTime,
      Value<String> timestamp,
      Value<int> removed,
    });

class $$TimelineTableFilterComposer
    extends Composer<_$NooDatabase, $TimelineTable> {
  $$TimelineTableFilterComposer({
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

  ColumnFilters<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimelineTableOrderingComposer
    extends Composer<_$NooDatabase, $TimelineTable> {
  $$TimelineTableOrderingComposer({
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

  ColumnOrderings<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimelineTableAnnotationComposer
    extends Composer<_$NooDatabase, $TimelineTable> {
  $$TimelineTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get removed =>
      $composableBuilder(column: $table.removed, builder: (column) => column);
}

class $$TimelineTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $TimelineTable,
          TimelineEntry,
          $$TimelineTableFilterComposer,
          $$TimelineTableOrderingComposer,
          $$TimelineTableAnnotationComposer,
          $$TimelineTableCreateCompanionBuilder,
          $$TimelineTableUpdateCompanionBuilder,
          (
            TimelineEntry,
            BaseReferences<_$NooDatabase, $TimelineTable, TimelineEntry>,
          ),
          TimelineEntry,
          PrefetchHooks Function()
        > {
  $$TimelineTableTableManager(_$NooDatabase db, $TimelineTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> removed = const Value.absent(),
              }) => TimelineCompanion(
                id: id,
                taskId: taskId,
                worldId: worldId,
                startTime: startTime,
                endTime: endTime,
                timestamp: timestamp,
                removed: removed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                Value<String> worldId = const Value.absent(),
                required String startTime,
                Value<String?> endTime = const Value.absent(),
                required String timestamp,
                Value<int> removed = const Value.absent(),
              }) => TimelineCompanion.insert(
                id: id,
                taskId: taskId,
                worldId: worldId,
                startTime: startTime,
                endTime: endTime,
                timestamp: timestamp,
                removed: removed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimelineTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $TimelineTable,
      TimelineEntry,
      $$TimelineTableFilterComposer,
      $$TimelineTableOrderingComposer,
      $$TimelineTableAnnotationComposer,
      $$TimelineTableCreateCompanionBuilder,
      $$TimelineTableUpdateCompanionBuilder,
      (
        TimelineEntry,
        BaseReferences<_$NooDatabase, $TimelineTable, TimelineEntry>,
      ),
      TimelineEntry,
      PrefetchHooks Function()
    >;
typedef $$FilesTableCreateCompanionBuilder =
    FilesCompanion Function({
      Value<int> id,
      required int taskId,
      Value<String> worldId,
      Value<String> filename,
      Value<Uint8List?> content,
      Value<String> contentHash,
      Value<int> orderId,
      required String timestamp,
      Value<int> removed,
    });
typedef $$FilesTableUpdateCompanionBuilder =
    FilesCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<String> worldId,
      Value<String> filename,
      Value<Uint8List?> content,
      Value<String> contentHash,
      Value<int> orderId,
      Value<String> timestamp,
      Value<int> removed,
    });

class $$FilesTableFilterComposer extends Composer<_$NooDatabase, $FilesTable> {
  $$FilesTableFilterComposer({
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

  ColumnFilters<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilesTableOrderingComposer
    extends Composer<_$NooDatabase, $FilesTable> {
  $$FilesTableOrderingComposer({
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

  ColumnOrderings<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilesTableAnnotationComposer
    extends Composer<_$NooDatabase, $FilesTable> {
  $$FilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<Uint8List> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get removed =>
      $composableBuilder(column: $table.removed, builder: (column) => column);
}

class $$FilesTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $FilesTable,
          FileEntry,
          $$FilesTableFilterComposer,
          $$FilesTableOrderingComposer,
          $$FilesTableAnnotationComposer,
          $$FilesTableCreateCompanionBuilder,
          $$FilesTableUpdateCompanionBuilder,
          (FileEntry, BaseReferences<_$NooDatabase, $FilesTable, FileEntry>),
          FileEntry,
          PrefetchHooks Function()
        > {
  $$FilesTableTableManager(_$NooDatabase db, $FilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<Uint8List?> content = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<int> orderId = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> removed = const Value.absent(),
              }) => FilesCompanion(
                id: id,
                taskId: taskId,
                worldId: worldId,
                filename: filename,
                content: content,
                contentHash: contentHash,
                orderId: orderId,
                timestamp: timestamp,
                removed: removed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                Value<String> worldId = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<Uint8List?> content = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<int> orderId = const Value.absent(),
                required String timestamp,
                Value<int> removed = const Value.absent(),
              }) => FilesCompanion.insert(
                id: id,
                taskId: taskId,
                worldId: worldId,
                filename: filename,
                content: content,
                contentHash: contentHash,
                orderId: orderId,
                timestamp: timestamp,
                removed: removed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilesTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $FilesTable,
      FileEntry,
      $$FilesTableFilterComposer,
      $$FilesTableOrderingComposer,
      $$FilesTableAnnotationComposer,
      $$FilesTableCreateCompanionBuilder,
      $$FilesTableUpdateCompanionBuilder,
      (FileEntry, BaseReferences<_$NooDatabase, $FilesTable, FileEntry>),
      FileEntry,
      PrefetchHooks Function()
    >;
typedef $$PropertiesTableCreateCompanionBuilder =
    PropertiesCompanion Function({
      required String type,
      required String value,
      Value<int> rowid,
    });
typedef $$PropertiesTableUpdateCompanionBuilder =
    PropertiesCompanion Function({
      Value<String> type,
      Value<String> value,
      Value<int> rowid,
    });

class $$PropertiesTableFilterComposer
    extends Composer<_$NooDatabase, $PropertiesTable> {
  $$PropertiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PropertiesTableOrderingComposer
    extends Composer<_$NooDatabase, $PropertiesTable> {
  $$PropertiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PropertiesTableAnnotationComposer
    extends Composer<_$NooDatabase, $PropertiesTable> {
  $$PropertiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PropertiesTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $PropertiesTable,
          Property,
          $$PropertiesTableFilterComposer,
          $$PropertiesTableOrderingComposer,
          $$PropertiesTableAnnotationComposer,
          $$PropertiesTableCreateCompanionBuilder,
          $$PropertiesTableUpdateCompanionBuilder,
          (Property, BaseReferences<_$NooDatabase, $PropertiesTable, Property>),
          Property,
          PrefetchHooks Function()
        > {
  $$PropertiesTableTableManager(_$NooDatabase db, $PropertiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PropertiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PropertiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PropertiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> type = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropertiesCompanion(type: type, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String type,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PropertiesCompanion.insert(
                type: type,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PropertiesTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $PropertiesTable,
      Property,
      $$PropertiesTableFilterComposer,
      $$PropertiesTableOrderingComposer,
      $$PropertiesTableAnnotationComposer,
      $$PropertiesTableCreateCompanionBuilder,
      $$PropertiesTableUpdateCompanionBuilder,
      (Property, BaseReferences<_$NooDatabase, $PropertiesTable, Property>),
      Property,
      PrefetchHooks Function()
    >;
typedef $$HistoryTaskTableCreateCompanionBuilder =
    HistoryTaskCompanion Function({
      Value<int> id,
      required int taskId,
      Value<String> worldId,
      required String field,
      Value<String?> oldValue,
      Value<String?> newValue,
      required String timestamp,
      Value<int> isRemote,
    });
typedef $$HistoryTaskTableUpdateCompanionBuilder =
    HistoryTaskCompanion Function({
      Value<int> id,
      Value<int> taskId,
      Value<String> worldId,
      Value<String> field,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<String> timestamp,
      Value<int> isRemote,
    });

class $$HistoryTaskTableFilterComposer
    extends Composer<_$NooDatabase, $HistoryTaskTable> {
  $$HistoryTaskTableFilterComposer({
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

  ColumnFilters<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isRemote => $composableBuilder(
    column: $table.isRemote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryTaskTableOrderingComposer
    extends Composer<_$NooDatabase, $HistoryTaskTable> {
  $$HistoryTaskTableOrderingComposer({
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

  ColumnOrderings<int> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isRemote => $composableBuilder(
    column: $table.isRemote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryTaskTableAnnotationComposer
    extends Composer<_$NooDatabase, $HistoryTaskTable> {
  $$HistoryTaskTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get isRemote =>
      $composableBuilder(column: $table.isRemote, builder: (column) => column);
}

class $$HistoryTaskTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $HistoryTaskTable,
          HistoryTaskData,
          $$HistoryTaskTableFilterComposer,
          $$HistoryTaskTableOrderingComposer,
          $$HistoryTaskTableAnnotationComposer,
          $$HistoryTaskTableCreateCompanionBuilder,
          $$HistoryTaskTableUpdateCompanionBuilder,
          (
            HistoryTaskData,
            BaseReferences<_$NooDatabase, $HistoryTaskTable, HistoryTaskData>,
          ),
          HistoryTaskData,
          PrefetchHooks Function()
        > {
  $$HistoryTaskTableTableManager(_$NooDatabase db, $HistoryTaskTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryTaskTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryTaskTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryTaskTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> isRemote = const Value.absent(),
              }) => HistoryTaskCompanion(
                id: id,
                taskId: taskId,
                worldId: worldId,
                field: field,
                oldValue: oldValue,
                newValue: newValue,
                timestamp: timestamp,
                isRemote: isRemote,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                Value<String> worldId = const Value.absent(),
                required String field,
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                required String timestamp,
                Value<int> isRemote = const Value.absent(),
              }) => HistoryTaskCompanion.insert(
                id: id,
                taskId: taskId,
                worldId: worldId,
                field: field,
                oldValue: oldValue,
                newValue: newValue,
                timestamp: timestamp,
                isRemote: isRemote,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryTaskTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $HistoryTaskTable,
      HistoryTaskData,
      $$HistoryTaskTableFilterComposer,
      $$HistoryTaskTableOrderingComposer,
      $$HistoryTaskTableAnnotationComposer,
      $$HistoryTaskTableCreateCompanionBuilder,
      $$HistoryTaskTableUpdateCompanionBuilder,
      (
        HistoryTaskData,
        BaseReferences<_$NooDatabase, $HistoryTaskTable, HistoryTaskData>,
      ),
      HistoryTaskData,
      PrefetchHooks Function()
    >;
typedef $$HistoryFileTableCreateCompanionBuilder =
    HistoryFileCompanion Function({
      Value<int> id,
      required int fileId,
      Value<String> worldId,
      required String field,
      Value<String?> oldValue,
      Value<String?> newValue,
      required String timestamp,
      Value<int> isRemote,
    });
typedef $$HistoryFileTableUpdateCompanionBuilder =
    HistoryFileCompanion Function({
      Value<int> id,
      Value<int> fileId,
      Value<String> worldId,
      Value<String> field,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<String> timestamp,
      Value<int> isRemote,
    });

class $$HistoryFileTableFilterComposer
    extends Composer<_$NooDatabase, $HistoryFileTable> {
  $$HistoryFileTableFilterComposer({
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

  ColumnFilters<int> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isRemote => $composableBuilder(
    column: $table.isRemote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryFileTableOrderingComposer
    extends Composer<_$NooDatabase, $HistoryFileTable> {
  $$HistoryFileTableOrderingComposer({
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

  ColumnOrderings<int> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isRemote => $composableBuilder(
    column: $table.isRemote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryFileTableAnnotationComposer
    extends Composer<_$NooDatabase, $HistoryFileTable> {
  $$HistoryFileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get isRemote =>
      $composableBuilder(column: $table.isRemote, builder: (column) => column);
}

class $$HistoryFileTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $HistoryFileTable,
          HistoryFileData,
          $$HistoryFileTableFilterComposer,
          $$HistoryFileTableOrderingComposer,
          $$HistoryFileTableAnnotationComposer,
          $$HistoryFileTableCreateCompanionBuilder,
          $$HistoryFileTableUpdateCompanionBuilder,
          (
            HistoryFileData,
            BaseReferences<_$NooDatabase, $HistoryFileTable, HistoryFileData>,
          ),
          HistoryFileData,
          PrefetchHooks Function()
        > {
  $$HistoryFileTableTableManager(_$NooDatabase db, $HistoryFileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryFileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryFileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryFileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fileId = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> isRemote = const Value.absent(),
              }) => HistoryFileCompanion(
                id: id,
                fileId: fileId,
                worldId: worldId,
                field: field,
                oldValue: oldValue,
                newValue: newValue,
                timestamp: timestamp,
                isRemote: isRemote,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fileId,
                Value<String> worldId = const Value.absent(),
                required String field,
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                required String timestamp,
                Value<int> isRemote = const Value.absent(),
              }) => HistoryFileCompanion.insert(
                id: id,
                fileId: fileId,
                worldId: worldId,
                field: field,
                oldValue: oldValue,
                newValue: newValue,
                timestamp: timestamp,
                isRemote: isRemote,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryFileTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $HistoryFileTable,
      HistoryFileData,
      $$HistoryFileTableFilterComposer,
      $$HistoryFileTableOrderingComposer,
      $$HistoryFileTableAnnotationComposer,
      $$HistoryFileTableCreateCompanionBuilder,
      $$HistoryFileTableUpdateCompanionBuilder,
      (
        HistoryFileData,
        BaseReferences<_$NooDatabase, $HistoryFileTable, HistoryFileData>,
      ),
      HistoryFileData,
      PrefetchHooks Function()
    >;
typedef $$HistoryTimelineTableCreateCompanionBuilder =
    HistoryTimelineCompanion Function({
      Value<int> id,
      required int timelineId,
      Value<String> worldId,
      required String field,
      Value<String?> oldValue,
      Value<String?> newValue,
      required String timestamp,
      Value<int> isRemote,
    });
typedef $$HistoryTimelineTableUpdateCompanionBuilder =
    HistoryTimelineCompanion Function({
      Value<int> id,
      Value<int> timelineId,
      Value<String> worldId,
      Value<String> field,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<String> timestamp,
      Value<int> isRemote,
    });

class $$HistoryTimelineTableFilterComposer
    extends Composer<_$NooDatabase, $HistoryTimelineTable> {
  $$HistoryTimelineTableFilterComposer({
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

  ColumnFilters<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isRemote => $composableBuilder(
    column: $table.isRemote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryTimelineTableOrderingComposer
    extends Composer<_$NooDatabase, $HistoryTimelineTable> {
  $$HistoryTimelineTableOrderingComposer({
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

  ColumnOrderings<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isRemote => $composableBuilder(
    column: $table.isRemote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryTimelineTableAnnotationComposer
    extends Composer<_$NooDatabase, $HistoryTimelineTable> {
  $$HistoryTimelineTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timelineId => $composableBuilder(
    column: $table.timelineId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get isRemote =>
      $composableBuilder(column: $table.isRemote, builder: (column) => column);
}

class $$HistoryTimelineTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $HistoryTimelineTable,
          HistoryTimelineData,
          $$HistoryTimelineTableFilterComposer,
          $$HistoryTimelineTableOrderingComposer,
          $$HistoryTimelineTableAnnotationComposer,
          $$HistoryTimelineTableCreateCompanionBuilder,
          $$HistoryTimelineTableUpdateCompanionBuilder,
          (
            HistoryTimelineData,
            BaseReferences<
              _$NooDatabase,
              $HistoryTimelineTable,
              HistoryTimelineData
            >,
          ),
          HistoryTimelineData,
          PrefetchHooks Function()
        > {
  $$HistoryTimelineTableTableManager(
    _$NooDatabase db,
    $HistoryTimelineTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryTimelineTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryTimelineTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryTimelineTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timelineId = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> isRemote = const Value.absent(),
              }) => HistoryTimelineCompanion(
                id: id,
                timelineId: timelineId,
                worldId: worldId,
                field: field,
                oldValue: oldValue,
                newValue: newValue,
                timestamp: timestamp,
                isRemote: isRemote,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timelineId,
                Value<String> worldId = const Value.absent(),
                required String field,
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                required String timestamp,
                Value<int> isRemote = const Value.absent(),
              }) => HistoryTimelineCompanion.insert(
                id: id,
                timelineId: timelineId,
                worldId: worldId,
                field: field,
                oldValue: oldValue,
                newValue: newValue,
                timestamp: timestamp,
                isRemote: isRemote,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryTimelineTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $HistoryTimelineTable,
      HistoryTimelineData,
      $$HistoryTimelineTableFilterComposer,
      $$HistoryTimelineTableOrderingComposer,
      $$HistoryTimelineTableAnnotationComposer,
      $$HistoryTimelineTableCreateCompanionBuilder,
      $$HistoryTimelineTableUpdateCompanionBuilder,
      (
        HistoryTimelineData,
        BaseReferences<
          _$NooDatabase,
          $HistoryTimelineTable,
          HistoryTimelineData
        >,
      ),
      HistoryTimelineData,
      PrefetchHooks Function()
    >;
typedef $$SyncsTableCreateCompanionBuilder =
    SyncsCompanion Function({
      Value<int> id,
      required String timestamp,
      required int status,
    });
typedef $$SyncsTableUpdateCompanionBuilder =
    SyncsCompanion Function({
      Value<int> id,
      Value<String> timestamp,
      Value<int> status,
    });

class $$SyncsTableFilterComposer extends Composer<_$NooDatabase, $SyncsTable> {
  $$SyncsTableFilterComposer({
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

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncsTableOrderingComposer
    extends Composer<_$NooDatabase, $SyncsTable> {
  $$SyncsTableOrderingComposer({
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

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncsTableAnnotationComposer
    extends Composer<_$NooDatabase, $SyncsTable> {
  $$SyncsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncsTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $SyncsTable,
          Sync,
          $$SyncsTableFilterComposer,
          $$SyncsTableOrderingComposer,
          $$SyncsTableAnnotationComposer,
          $$SyncsTableCreateCompanionBuilder,
          $$SyncsTableUpdateCompanionBuilder,
          (Sync, BaseReferences<_$NooDatabase, $SyncsTable, Sync>),
          Sync,
          PrefetchHooks Function()
        > {
  $$SyncsTableTableManager(_$NooDatabase db, $SyncsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> status = const Value.absent(),
              }) =>
                  SyncsCompanion(id: id, timestamp: timestamp, status: status),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String timestamp,
                required int status,
              }) => SyncsCompanion.insert(
                id: id,
                timestamp: timestamp,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncsTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $SyncsTable,
      Sync,
      $$SyncsTableFilterComposer,
      $$SyncsTableOrderingComposer,
      $$SyncsTableAnnotationComposer,
      $$SyncsTableCreateCompanionBuilder,
      $$SyncsTableUpdateCompanionBuilder,
      (Sync, BaseReferences<_$NooDatabase, $SyncsTable, Sync>),
      Sync,
      PrefetchHooks Function()
    >;
typedef $$SyncPacketsTableCreateCompanionBuilder =
    SyncPacketsCompanion Function({
      required String originDeviceId,
      required int counter,
      required Uint8List payload,
      required String storedAt,
      Value<String> payloadHash,
      Value<int> rowid,
    });
typedef $$SyncPacketsTableUpdateCompanionBuilder =
    SyncPacketsCompanion Function({
      Value<String> originDeviceId,
      Value<int> counter,
      Value<Uint8List> payload,
      Value<String> storedAt,
      Value<String> payloadHash,
      Value<int> rowid,
    });

class $$SyncPacketsTableFilterComposer
    extends Composer<_$NooDatabase, $SyncPacketsTable> {
  $$SyncPacketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storedAt => $composableBuilder(
    column: $table.storedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncPacketsTableOrderingComposer
    extends Composer<_$NooDatabase, $SyncPacketsTable> {
  $$SyncPacketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storedAt => $composableBuilder(
    column: $table.storedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncPacketsTableAnnotationComposer
    extends Composer<_$NooDatabase, $SyncPacketsTable> {
  $$SyncPacketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get originDeviceId => $composableBuilder(
    column: $table.originDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get counter =>
      $composableBuilder(column: $table.counter, builder: (column) => column);

  GeneratedColumn<Uint8List> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get storedAt =>
      $composableBuilder(column: $table.storedAt, builder: (column) => column);

  GeneratedColumn<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => column,
  );
}

class $$SyncPacketsTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $SyncPacketsTable,
          SyncPacketRow,
          $$SyncPacketsTableFilterComposer,
          $$SyncPacketsTableOrderingComposer,
          $$SyncPacketsTableAnnotationComposer,
          $$SyncPacketsTableCreateCompanionBuilder,
          $$SyncPacketsTableUpdateCompanionBuilder,
          (
            SyncPacketRow,
            BaseReferences<_$NooDatabase, $SyncPacketsTable, SyncPacketRow>,
          ),
          SyncPacketRow,
          PrefetchHooks Function()
        > {
  $$SyncPacketsTableTableManager(_$NooDatabase db, $SyncPacketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPacketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPacketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPacketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> originDeviceId = const Value.absent(),
                Value<int> counter = const Value.absent(),
                Value<Uint8List> payload = const Value.absent(),
                Value<String> storedAt = const Value.absent(),
                Value<String> payloadHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPacketsCompanion(
                originDeviceId: originDeviceId,
                counter: counter,
                payload: payload,
                storedAt: storedAt,
                payloadHash: payloadHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String originDeviceId,
                required int counter,
                required Uint8List payload,
                required String storedAt,
                Value<String> payloadHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPacketsCompanion.insert(
                originDeviceId: originDeviceId,
                counter: counter,
                payload: payload,
                storedAt: storedAt,
                payloadHash: payloadHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncPacketsTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $SyncPacketsTable,
      SyncPacketRow,
      $$SyncPacketsTableFilterComposer,
      $$SyncPacketsTableOrderingComposer,
      $$SyncPacketsTableAnnotationComposer,
      $$SyncPacketsTableCreateCompanionBuilder,
      $$SyncPacketsTableUpdateCompanionBuilder,
      (
        SyncPacketRow,
        BaseReferences<_$NooDatabase, $SyncPacketsTable, SyncPacketRow>,
      ),
      SyncPacketRow,
      PrefetchHooks Function()
    >;
typedef $$SyncOrphansTableCreateCompanionBuilder =
    SyncOrphansCompanion Function({
      required String entityType,
      required String worldId,
      required String field,
      Value<String?> value,
      required String timestamp,
      Value<int> isCreation,
      Value<String?> parentWorldId,
      required String firstSeen,
      Value<int> rowid,
    });
typedef $$SyncOrphansTableUpdateCompanionBuilder =
    SyncOrphansCompanion Function({
      Value<String> entityType,
      Value<String> worldId,
      Value<String> field,
      Value<String?> value,
      Value<String> timestamp,
      Value<int> isCreation,
      Value<String?> parentWorldId,
      Value<String> firstSeen,
      Value<int> rowid,
    });

class $$SyncOrphansTableFilterComposer
    extends Composer<_$NooDatabase, $SyncOrphansTable> {
  $$SyncOrphansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isCreation => $composableBuilder(
    column: $table.isCreation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentWorldId => $composableBuilder(
    column: $table.parentWorldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOrphansTableOrderingComposer
    extends Composer<_$NooDatabase, $SyncOrphansTable> {
  $$SyncOrphansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isCreation => $composableBuilder(
    column: $table.isCreation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentWorldId => $composableBuilder(
    column: $table.parentWorldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstSeen => $composableBuilder(
    column: $table.firstSeen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOrphansTableAnnotationComposer
    extends Composer<_$NooDatabase, $SyncOrphansTable> {
  $$SyncOrphansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get isCreation => $composableBuilder(
    column: $table.isCreation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentWorldId => $composableBuilder(
    column: $table.parentWorldId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);
}

class $$SyncOrphansTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $SyncOrphansTable,
          SyncOrphanRow,
          $$SyncOrphansTableFilterComposer,
          $$SyncOrphansTableOrderingComposer,
          $$SyncOrphansTableAnnotationComposer,
          $$SyncOrphansTableCreateCompanionBuilder,
          $$SyncOrphansTableUpdateCompanionBuilder,
          (
            SyncOrphanRow,
            BaseReferences<_$NooDatabase, $SyncOrphansTable, SyncOrphanRow>,
          ),
          SyncOrphanRow,
          PrefetchHooks Function()
        > {
  $$SyncOrphansTableTableManager(_$NooDatabase db, $SyncOrphansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOrphansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOrphansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOrphansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<String> worldId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> isCreation = const Value.absent(),
                Value<String?> parentWorldId = const Value.absent(),
                Value<String> firstSeen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOrphansCompanion(
                entityType: entityType,
                worldId: worldId,
                field: field,
                value: value,
                timestamp: timestamp,
                isCreation: isCreation,
                parentWorldId: parentWorldId,
                firstSeen: firstSeen,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required String worldId,
                required String field,
                Value<String?> value = const Value.absent(),
                required String timestamp,
                Value<int> isCreation = const Value.absent(),
                Value<String?> parentWorldId = const Value.absent(),
                required String firstSeen,
                Value<int> rowid = const Value.absent(),
              }) => SyncOrphansCompanion.insert(
                entityType: entityType,
                worldId: worldId,
                field: field,
                value: value,
                timestamp: timestamp,
                isCreation: isCreation,
                parentWorldId: parentWorldId,
                firstSeen: firstSeen,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOrphansTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $SyncOrphansTable,
      SyncOrphanRow,
      $$SyncOrphansTableFilterComposer,
      $$SyncOrphansTableOrderingComposer,
      $$SyncOrphansTableAnnotationComposer,
      $$SyncOrphansTableCreateCompanionBuilder,
      $$SyncOrphansTableUpdateCompanionBuilder,
      (
        SyncOrphanRow,
        BaseReferences<_$NooDatabase, $SyncOrphansTable, SyncOrphanRow>,
      ),
      SyncOrphanRow,
      PrefetchHooks Function()
    >;
typedef $$SyncPushLogTableCreateCompanionBuilder =
    SyncPushLogCompanion Function({
      Value<int> counter,
      required int taskHistoryId,
    });
typedef $$SyncPushLogTableUpdateCompanionBuilder =
    SyncPushLogCompanion Function({
      Value<int> counter,
      Value<int> taskHistoryId,
    });

class $$SyncPushLogTableFilterComposer
    extends Composer<_$NooDatabase, $SyncPushLogTable> {
  $$SyncPushLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taskHistoryId => $composableBuilder(
    column: $table.taskHistoryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncPushLogTableOrderingComposer
    extends Composer<_$NooDatabase, $SyncPushLogTable> {
  $$SyncPushLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taskHistoryId => $composableBuilder(
    column: $table.taskHistoryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncPushLogTableAnnotationComposer
    extends Composer<_$NooDatabase, $SyncPushLogTable> {
  $$SyncPushLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get counter =>
      $composableBuilder(column: $table.counter, builder: (column) => column);

  GeneratedColumn<int> get taskHistoryId => $composableBuilder(
    column: $table.taskHistoryId,
    builder: (column) => column,
  );
}

class $$SyncPushLogTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $SyncPushLogTable,
          SyncPushLogData,
          $$SyncPushLogTableFilterComposer,
          $$SyncPushLogTableOrderingComposer,
          $$SyncPushLogTableAnnotationComposer,
          $$SyncPushLogTableCreateCompanionBuilder,
          $$SyncPushLogTableUpdateCompanionBuilder,
          (
            SyncPushLogData,
            BaseReferences<_$NooDatabase, $SyncPushLogTable, SyncPushLogData>,
          ),
          SyncPushLogData,
          PrefetchHooks Function()
        > {
  $$SyncPushLogTableTableManager(_$NooDatabase db, $SyncPushLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPushLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPushLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPushLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> counter = const Value.absent(),
                Value<int> taskHistoryId = const Value.absent(),
              }) => SyncPushLogCompanion(
                counter: counter,
                taskHistoryId: taskHistoryId,
              ),
          createCompanionCallback:
              ({
                Value<int> counter = const Value.absent(),
                required int taskHistoryId,
              }) => SyncPushLogCompanion.insert(
                counter: counter,
                taskHistoryId: taskHistoryId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncPushLogTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $SyncPushLogTable,
      SyncPushLogData,
      $$SyncPushLogTableFilterComposer,
      $$SyncPushLogTableOrderingComposer,
      $$SyncPushLogTableAnnotationComposer,
      $$SyncPushLogTableCreateCompanionBuilder,
      $$SyncPushLogTableUpdateCompanionBuilder,
      (
        SyncPushLogData,
        BaseReferences<_$NooDatabase, $SyncPushLogTable, SyncPushLogData>,
      ),
      SyncPushLogData,
      PrefetchHooks Function()
    >;
typedef $$BlobFetchesTableCreateCompanionBuilder =
    BlobFetchesCompanion Function({
      required String hash,
      required Uint8List received,
      Value<int?> total,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$BlobFetchesTableUpdateCompanionBuilder =
    BlobFetchesCompanion Function({
      Value<String> hash,
      Value<Uint8List> received,
      Value<int?> total,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$BlobFetchesTableFilterComposer
    extends Composer<_$NooDatabase, $BlobFetchesTable> {
  $$BlobFetchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get received => $composableBuilder(
    column: $table.received,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlobFetchesTableOrderingComposer
    extends Composer<_$NooDatabase, $BlobFetchesTable> {
  $$BlobFetchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get received => $composableBuilder(
    column: $table.received,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlobFetchesTableAnnotationComposer
    extends Composer<_$NooDatabase, $BlobFetchesTable> {
  $$BlobFetchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<Uint8List> get received =>
      $composableBuilder(column: $table.received, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BlobFetchesTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $BlobFetchesTable,
          BlobFetche,
          $$BlobFetchesTableFilterComposer,
          $$BlobFetchesTableOrderingComposer,
          $$BlobFetchesTableAnnotationComposer,
          $$BlobFetchesTableCreateCompanionBuilder,
          $$BlobFetchesTableUpdateCompanionBuilder,
          (
            BlobFetche,
            BaseReferences<_$NooDatabase, $BlobFetchesTable, BlobFetche>,
          ),
          BlobFetche,
          PrefetchHooks Function()
        > {
  $$BlobFetchesTableTableManager(_$NooDatabase db, $BlobFetchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlobFetchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlobFetchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlobFetchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> hash = const Value.absent(),
                Value<Uint8List> received = const Value.absent(),
                Value<int?> total = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlobFetchesCompanion(
                hash: hash,
                received: received,
                total: total,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String hash,
                required Uint8List received,
                Value<int?> total = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BlobFetchesCompanion.insert(
                hash: hash,
                received: received,
                total: total,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlobFetchesTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $BlobFetchesTable,
      BlobFetche,
      $$BlobFetchesTableFilterComposer,
      $$BlobFetchesTableOrderingComposer,
      $$BlobFetchesTableAnnotationComposer,
      $$BlobFetchesTableCreateCompanionBuilder,
      $$BlobFetchesTableUpdateCompanionBuilder,
      (
        BlobFetche,
        BaseReferences<_$NooDatabase, $BlobFetchesTable, BlobFetche>,
      ),
      BlobFetche,
      PrefetchHooks Function()
    >;
typedef $$SyncLogRunsTableCreateCompanionBuilder =
    SyncLogRunsCompanion Function({
      Value<int> id,
      required String startedAt,
      Value<String?> finishedAt,
      required String trigger,
      Value<String?> remote,
      Value<String> deviceId,
      Value<String> outcome,
      Value<String?> error,
      Value<String> countsJson,
    });
typedef $$SyncLogRunsTableUpdateCompanionBuilder =
    SyncLogRunsCompanion Function({
      Value<int> id,
      Value<String> startedAt,
      Value<String?> finishedAt,
      Value<String> trigger,
      Value<String?> remote,
      Value<String> deviceId,
      Value<String> outcome,
      Value<String?> error,
      Value<String> countsJson,
    });

class $$SyncLogRunsTableFilterComposer
    extends Composer<_$NooDatabase, $SyncLogRunsTable> {
  $$SyncLogRunsTableFilterComposer({
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

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remote => $composableBuilder(
    column: $table.remote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countsJson => $composableBuilder(
    column: $table.countsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLogRunsTableOrderingComposer
    extends Composer<_$NooDatabase, $SyncLogRunsTable> {
  $$SyncLogRunsTableOrderingComposer({
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

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remote => $composableBuilder(
    column: $table.remote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countsJson => $composableBuilder(
    column: $table.countsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLogRunsTableAnnotationComposer
    extends Composer<_$NooDatabase, $SyncLogRunsTable> {
  $$SyncLogRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get remote =>
      $composableBuilder(column: $table.remote, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get countsJson => $composableBuilder(
    column: $table.countsJson,
    builder: (column) => column,
  );
}

class $$SyncLogRunsTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $SyncLogRunsTable,
          SyncLogRunRow,
          $$SyncLogRunsTableFilterComposer,
          $$SyncLogRunsTableOrderingComposer,
          $$SyncLogRunsTableAnnotationComposer,
          $$SyncLogRunsTableCreateCompanionBuilder,
          $$SyncLogRunsTableUpdateCompanionBuilder,
          (
            SyncLogRunRow,
            BaseReferences<_$NooDatabase, $SyncLogRunsTable, SyncLogRunRow>,
          ),
          SyncLogRunRow,
          PrefetchHooks Function()
        > {
  $$SyncLogRunsTableTableManager(_$NooDatabase db, $SyncLogRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<String?> finishedAt = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<String?> remote = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String> countsJson = const Value.absent(),
              }) => SyncLogRunsCompanion(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                trigger: trigger,
                remote: remote,
                deviceId: deviceId,
                outcome: outcome,
                error: error,
                countsJson: countsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String startedAt,
                Value<String?> finishedAt = const Value.absent(),
                required String trigger,
                Value<String?> remote = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String> countsJson = const Value.absent(),
              }) => SyncLogRunsCompanion.insert(
                id: id,
                startedAt: startedAt,
                finishedAt: finishedAt,
                trigger: trigger,
                remote: remote,
                deviceId: deviceId,
                outcome: outcome,
                error: error,
                countsJson: countsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $SyncLogRunsTable,
      SyncLogRunRow,
      $$SyncLogRunsTableFilterComposer,
      $$SyncLogRunsTableOrderingComposer,
      $$SyncLogRunsTableAnnotationComposer,
      $$SyncLogRunsTableCreateCompanionBuilder,
      $$SyncLogRunsTableUpdateCompanionBuilder,
      (
        SyncLogRunRow,
        BaseReferences<_$NooDatabase, $SyncLogRunsTable, SyncLogRunRow>,
      ),
      SyncLogRunRow,
      PrefetchHooks Function()
    >;
typedef $$SyncLogEventsTableCreateCompanionBuilder =
    SyncLogEventsCompanion Function({
      Value<int> id,
      required int runId,
      required int seq,
      required String at,
      Value<int> level,
      required String kind,
      Value<String> direction,
      Value<String?> originDevice,
      Value<int?> counter,
      Value<String?> packetHash,
      Value<String?> entityType,
      Value<String?> worldId,
      Value<String?> field,
      Value<String?> remoteTs,
      Value<String?> localTs,
      Value<String?> valueHash,
      Value<String?> valuePreview,
      Value<String?> message,
      Value<String?> detailJson,
    });
typedef $$SyncLogEventsTableUpdateCompanionBuilder =
    SyncLogEventsCompanion Function({
      Value<int> id,
      Value<int> runId,
      Value<int> seq,
      Value<String> at,
      Value<int> level,
      Value<String> kind,
      Value<String> direction,
      Value<String?> originDevice,
      Value<int?> counter,
      Value<String?> packetHash,
      Value<String?> entityType,
      Value<String?> worldId,
      Value<String?> field,
      Value<String?> remoteTs,
      Value<String?> localTs,
      Value<String?> valueHash,
      Value<String?> valuePreview,
      Value<String?> message,
      Value<String?> detailJson,
    });

class $$SyncLogEventsTableFilterComposer
    extends Composer<_$NooDatabase, $SyncLogEventsTable> {
  $$SyncLogEventsTableFilterComposer({
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

  ColumnFilters<int> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originDevice => $composableBuilder(
    column: $table.originDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packetHash => $composableBuilder(
    column: $table.packetHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteTs => $composableBuilder(
    column: $table.remoteTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localTs => $composableBuilder(
    column: $table.localTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueHash => $composableBuilder(
    column: $table.valueHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valuePreview => $composableBuilder(
    column: $table.valuePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLogEventsTableOrderingComposer
    extends Composer<_$NooDatabase, $SyncLogEventsTable> {
  $$SyncLogEventsTableOrderingComposer({
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

  ColumnOrderings<int> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originDevice => $composableBuilder(
    column: $table.originDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get counter => $composableBuilder(
    column: $table.counter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packetHash => $composableBuilder(
    column: $table.packetHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get worldId => $composableBuilder(
    column: $table.worldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteTs => $composableBuilder(
    column: $table.remoteTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localTs => $composableBuilder(
    column: $table.localTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueHash => $composableBuilder(
    column: $table.valueHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valuePreview => $composableBuilder(
    column: $table.valuePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLogEventsTableAnnotationComposer
    extends Composer<_$NooDatabase, $SyncLogEventsTable> {
  $$SyncLogEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get originDevice => $composableBuilder(
    column: $table.originDevice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get counter =>
      $composableBuilder(column: $table.counter, builder: (column) => column);

  GeneratedColumn<String> get packetHash => $composableBuilder(
    column: $table.packetHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get worldId =>
      $composableBuilder(column: $table.worldId, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get remoteTs =>
      $composableBuilder(column: $table.remoteTs, builder: (column) => column);

  GeneratedColumn<String> get localTs =>
      $composableBuilder(column: $table.localTs, builder: (column) => column);

  GeneratedColumn<String> get valueHash =>
      $composableBuilder(column: $table.valueHash, builder: (column) => column);

  GeneratedColumn<String> get valuePreview => $composableBuilder(
    column: $table.valuePreview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => column,
  );
}

class $$SyncLogEventsTableTableManager
    extends
        RootTableManager<
          _$NooDatabase,
          $SyncLogEventsTable,
          SyncLogEventRow,
          $$SyncLogEventsTableFilterComposer,
          $$SyncLogEventsTableOrderingComposer,
          $$SyncLogEventsTableAnnotationComposer,
          $$SyncLogEventsTableCreateCompanionBuilder,
          $$SyncLogEventsTableUpdateCompanionBuilder,
          (
            SyncLogEventRow,
            BaseReferences<_$NooDatabase, $SyncLogEventsTable, SyncLogEventRow>,
          ),
          SyncLogEventRow,
          PrefetchHooks Function()
        > {
  $$SyncLogEventsTableTableManager(_$NooDatabase db, $SyncLogEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> runId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String?> originDevice = const Value.absent(),
                Value<int?> counter = const Value.absent(),
                Value<String?> packetHash = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> worldId = const Value.absent(),
                Value<String?> field = const Value.absent(),
                Value<String?> remoteTs = const Value.absent(),
                Value<String?> localTs = const Value.absent(),
                Value<String?> valueHash = const Value.absent(),
                Value<String?> valuePreview = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<String?> detailJson = const Value.absent(),
              }) => SyncLogEventsCompanion(
                id: id,
                runId: runId,
                seq: seq,
                at: at,
                level: level,
                kind: kind,
                direction: direction,
                originDevice: originDevice,
                counter: counter,
                packetHash: packetHash,
                entityType: entityType,
                worldId: worldId,
                field: field,
                remoteTs: remoteTs,
                localTs: localTs,
                valueHash: valueHash,
                valuePreview: valuePreview,
                message: message,
                detailJson: detailJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int runId,
                required int seq,
                required String at,
                Value<int> level = const Value.absent(),
                required String kind,
                Value<String> direction = const Value.absent(),
                Value<String?> originDevice = const Value.absent(),
                Value<int?> counter = const Value.absent(),
                Value<String?> packetHash = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> worldId = const Value.absent(),
                Value<String?> field = const Value.absent(),
                Value<String?> remoteTs = const Value.absent(),
                Value<String?> localTs = const Value.absent(),
                Value<String?> valueHash = const Value.absent(),
                Value<String?> valuePreview = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<String?> detailJson = const Value.absent(),
              }) => SyncLogEventsCompanion.insert(
                id: id,
                runId: runId,
                seq: seq,
                at: at,
                level: level,
                kind: kind,
                direction: direction,
                originDevice: originDevice,
                counter: counter,
                packetHash: packetHash,
                entityType: entityType,
                worldId: worldId,
                field: field,
                remoteTs: remoteTs,
                localTs: localTs,
                valueHash: valueHash,
                valuePreview: valuePreview,
                message: message,
                detailJson: detailJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$NooDatabase,
      $SyncLogEventsTable,
      SyncLogEventRow,
      $$SyncLogEventsTableFilterComposer,
      $$SyncLogEventsTableOrderingComposer,
      $$SyncLogEventsTableAnnotationComposer,
      $$SyncLogEventsTableCreateCompanionBuilder,
      $$SyncLogEventsTableUpdateCompanionBuilder,
      (
        SyncLogEventRow,
        BaseReferences<_$NooDatabase, $SyncLogEventsTable, SyncLogEventRow>,
      ),
      SyncLogEventRow,
      PrefetchHooks Function()
    >;

class $NooDatabaseManager {
  final _$NooDatabase _db;
  $NooDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TimelineTableTableManager get timeline =>
      $$TimelineTableTableManager(_db, _db.timeline);
  $$FilesTableTableManager get files =>
      $$FilesTableTableManager(_db, _db.files);
  $$PropertiesTableTableManager get properties =>
      $$PropertiesTableTableManager(_db, _db.properties);
  $$HistoryTaskTableTableManager get historyTask =>
      $$HistoryTaskTableTableManager(_db, _db.historyTask);
  $$HistoryFileTableTableManager get historyFile =>
      $$HistoryFileTableTableManager(_db, _db.historyFile);
  $$HistoryTimelineTableTableManager get historyTimeline =>
      $$HistoryTimelineTableTableManager(_db, _db.historyTimeline);
  $$SyncsTableTableManager get syncs =>
      $$SyncsTableTableManager(_db, _db.syncs);
  $$SyncPacketsTableTableManager get syncPackets =>
      $$SyncPacketsTableTableManager(_db, _db.syncPackets);
  $$SyncOrphansTableTableManager get syncOrphans =>
      $$SyncOrphansTableTableManager(_db, _db.syncOrphans);
  $$SyncPushLogTableTableManager get syncPushLog =>
      $$SyncPushLogTableTableManager(_db, _db.syncPushLog);
  $$BlobFetchesTableTableManager get blobFetches =>
      $$BlobFetchesTableTableManager(_db, _db.blobFetches);
  $$SyncLogRunsTableTableManager get syncLogRuns =>
      $$SyncLogRunsTableTableManager(_db, _db.syncLogRuns);
  $$SyncLogEventsTableTableManager get syncLogEvents =>
      $$SyncLogEventsTableTableManager(_db, _db.syncLogEvents);
}
