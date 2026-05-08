// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0.1.0'),
  );
  static const VerificationMeta _compWidthMeta = const VerificationMeta(
    'compWidth',
  );
  @override
  late final GeneratedColumn<int> compWidth = GeneratedColumn<int>(
    'comp_width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1920),
  );
  static const VerificationMeta _compHeightMeta = const VerificationMeta(
    'compHeight',
  );
  @override
  late final GeneratedColumn<int> compHeight = GeneratedColumn<int>(
    'comp_height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1080),
  );
  static const VerificationMeta _compFrameRateMeta = const VerificationMeta(
    'compFrameRate',
  );
  @override
  late final GeneratedColumn<double> compFrameRate = GeneratedColumn<double>(
    'comp_frame_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(30.0),
  );
  static const VerificationMeta _compDurationUsMeta = const VerificationMeta(
    'compDurationUs',
  );
  @override
  late final GeneratedColumn<int> compDurationUs = GeneratedColumn<int>(
    'comp_duration_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _compBackgroundColorMeta =
      const VerificationMeta('compBackgroundColor');
  @override
  late final GeneratedColumn<int> compBackgroundColor = GeneratedColumn<int>(
    'comp_background_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF000000),
  );
  static const VerificationMeta _dateCreatedMeta = const VerificationMeta(
    'dateCreated',
  );
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
    'date_created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateModifiedMeta = const VerificationMeta(
    'dateModified',
  );
  @override
  late final GeneratedColumn<DateTime> dateModified = GeneratedColumn<DateTime>(
    'date_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    filePath,
    description,
    version,
    compWidth,
    compHeight,
    compFrameRate,
    compDurationUs,
    compBackgroundColor,
    dateCreated,
    dateModified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
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
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('comp_width')) {
      context.handle(
        _compWidthMeta,
        compWidth.isAcceptableOrUnknown(data['comp_width']!, _compWidthMeta),
      );
    }
    if (data.containsKey('comp_height')) {
      context.handle(
        _compHeightMeta,
        compHeight.isAcceptableOrUnknown(data['comp_height']!, _compHeightMeta),
      );
    }
    if (data.containsKey('comp_frame_rate')) {
      context.handle(
        _compFrameRateMeta,
        compFrameRate.isAcceptableOrUnknown(
          data['comp_frame_rate']!,
          _compFrameRateMeta,
        ),
      );
    }
    if (data.containsKey('comp_duration_us')) {
      context.handle(
        _compDurationUsMeta,
        compDurationUs.isAcceptableOrUnknown(
          data['comp_duration_us']!,
          _compDurationUsMeta,
        ),
      );
    }
    if (data.containsKey('comp_background_color')) {
      context.handle(
        _compBackgroundColorMeta,
        compBackgroundColor.isAcceptableOrUnknown(
          data['comp_background_color']!,
          _compBackgroundColorMeta,
        ),
      );
    }
    if (data.containsKey('date_created')) {
      context.handle(
        _dateCreatedMeta,
        dateCreated.isAcceptableOrUnknown(
          data['date_created']!,
          _dateCreatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateCreatedMeta);
    }
    if (data.containsKey('date_modified')) {
      context.handle(
        _dateModifiedMeta,
        dateModified.isAcceptableOrUnknown(
          data['date_modified']!,
          _dateModifiedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      compWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}comp_width'],
      )!,
      compHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}comp_height'],
      )!,
      compFrameRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}comp_frame_rate'],
      )!,
      compDurationUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}comp_duration_us'],
      )!,
      compBackgroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}comp_background_color'],
      )!,
      dateCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_created'],
      )!,
      dateModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_modified'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String name;
  final String filePath;
  final String description;
  final String version;
  final int compWidth;
  final int compHeight;
  final double compFrameRate;
  final int compDurationUs;
  final int compBackgroundColor;
  final DateTime dateCreated;
  final DateTime dateModified;
  const Project({
    required this.id,
    required this.name,
    required this.filePath,
    required this.description,
    required this.version,
    required this.compWidth,
    required this.compHeight,
    required this.compFrameRate,
    required this.compDurationUs,
    required this.compBackgroundColor,
    required this.dateCreated,
    required this.dateModified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['file_path'] = Variable<String>(filePath);
    map['description'] = Variable<String>(description);
    map['version'] = Variable<String>(version);
    map['comp_width'] = Variable<int>(compWidth);
    map['comp_height'] = Variable<int>(compHeight);
    map['comp_frame_rate'] = Variable<double>(compFrameRate);
    map['comp_duration_us'] = Variable<int>(compDurationUs);
    map['comp_background_color'] = Variable<int>(compBackgroundColor);
    map['date_created'] = Variable<DateTime>(dateCreated);
    map['date_modified'] = Variable<DateTime>(dateModified);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      filePath: Value(filePath),
      description: Value(description),
      version: Value(version),
      compWidth: Value(compWidth),
      compHeight: Value(compHeight),
      compFrameRate: Value(compFrameRate),
      compDurationUs: Value(compDurationUs),
      compBackgroundColor: Value(compBackgroundColor),
      dateCreated: Value(dateCreated),
      dateModified: Value(dateModified),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      filePath: serializer.fromJson<String>(json['filePath']),
      description: serializer.fromJson<String>(json['description']),
      version: serializer.fromJson<String>(json['version']),
      compWidth: serializer.fromJson<int>(json['compWidth']),
      compHeight: serializer.fromJson<int>(json['compHeight']),
      compFrameRate: serializer.fromJson<double>(json['compFrameRate']),
      compDurationUs: serializer.fromJson<int>(json['compDurationUs']),
      compBackgroundColor: serializer.fromJson<int>(
        json['compBackgroundColor'],
      ),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      dateModified: serializer.fromJson<DateTime>(json['dateModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'filePath': serializer.toJson<String>(filePath),
      'description': serializer.toJson<String>(description),
      'version': serializer.toJson<String>(version),
      'compWidth': serializer.toJson<int>(compWidth),
      'compHeight': serializer.toJson<int>(compHeight),
      'compFrameRate': serializer.toJson<double>(compFrameRate),
      'compDurationUs': serializer.toJson<int>(compDurationUs),
      'compBackgroundColor': serializer.toJson<int>(compBackgroundColor),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'dateModified': serializer.toJson<DateTime>(dateModified),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? filePath,
    String? description,
    String? version,
    int? compWidth,
    int? compHeight,
    double? compFrameRate,
    int? compDurationUs,
    int? compBackgroundColor,
    DateTime? dateCreated,
    DateTime? dateModified,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    filePath: filePath ?? this.filePath,
    description: description ?? this.description,
    version: version ?? this.version,
    compWidth: compWidth ?? this.compWidth,
    compHeight: compHeight ?? this.compHeight,
    compFrameRate: compFrameRate ?? this.compFrameRate,
    compDurationUs: compDurationUs ?? this.compDurationUs,
    compBackgroundColor: compBackgroundColor ?? this.compBackgroundColor,
    dateCreated: dateCreated ?? this.dateCreated,
    dateModified: dateModified ?? this.dateModified,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      description: data.description.present
          ? data.description.value
          : this.description,
      version: data.version.present ? data.version.value : this.version,
      compWidth: data.compWidth.present ? data.compWidth.value : this.compWidth,
      compHeight: data.compHeight.present
          ? data.compHeight.value
          : this.compHeight,
      compFrameRate: data.compFrameRate.present
          ? data.compFrameRate.value
          : this.compFrameRate,
      compDurationUs: data.compDurationUs.present
          ? data.compDurationUs.value
          : this.compDurationUs,
      compBackgroundColor: data.compBackgroundColor.present
          ? data.compBackgroundColor.value
          : this.compBackgroundColor,
      dateCreated: data.dateCreated.present
          ? data.dateCreated.value
          : this.dateCreated,
      dateModified: data.dateModified.present
          ? data.dateModified.value
          : this.dateModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('filePath: $filePath, ')
          ..write('description: $description, ')
          ..write('version: $version, ')
          ..write('compWidth: $compWidth, ')
          ..write('compHeight: $compHeight, ')
          ..write('compFrameRate: $compFrameRate, ')
          ..write('compDurationUs: $compDurationUs, ')
          ..write('compBackgroundColor: $compBackgroundColor, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateModified: $dateModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    filePath,
    description,
    version,
    compWidth,
    compHeight,
    compFrameRate,
    compDurationUs,
    compBackgroundColor,
    dateCreated,
    dateModified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.filePath == this.filePath &&
          other.description == this.description &&
          other.version == this.version &&
          other.compWidth == this.compWidth &&
          other.compHeight == this.compHeight &&
          other.compFrameRate == this.compFrameRate &&
          other.compDurationUs == this.compDurationUs &&
          other.compBackgroundColor == this.compBackgroundColor &&
          other.dateCreated == this.dateCreated &&
          other.dateModified == this.dateModified);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> filePath;
  final Value<String> description;
  final Value<String> version;
  final Value<int> compWidth;
  final Value<int> compHeight;
  final Value<double> compFrameRate;
  final Value<int> compDurationUs;
  final Value<int> compBackgroundColor;
  final Value<DateTime> dateCreated;
  final Value<DateTime> dateModified;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.filePath = const Value.absent(),
    this.description = const Value.absent(),
    this.version = const Value.absent(),
    this.compWidth = const Value.absent(),
    this.compHeight = const Value.absent(),
    this.compFrameRate = const Value.absent(),
    this.compDurationUs = const Value.absent(),
    this.compBackgroundColor = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.dateModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    required String filePath,
    this.description = const Value.absent(),
    this.version = const Value.absent(),
    this.compWidth = const Value.absent(),
    this.compHeight = const Value.absent(),
    this.compFrameRate = const Value.absent(),
    this.compDurationUs = const Value.absent(),
    this.compBackgroundColor = const Value.absent(),
    required DateTime dateCreated,
    required DateTime dateModified,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       filePath = Value(filePath),
       dateCreated = Value(dateCreated),
       dateModified = Value(dateModified);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? filePath,
    Expression<String>? description,
    Expression<String>? version,
    Expression<int>? compWidth,
    Expression<int>? compHeight,
    Expression<double>? compFrameRate,
    Expression<int>? compDurationUs,
    Expression<int>? compBackgroundColor,
    Expression<DateTime>? dateCreated,
    Expression<DateTime>? dateModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (filePath != null) 'file_path': filePath,
      if (description != null) 'description': description,
      if (version != null) 'version': version,
      if (compWidth != null) 'comp_width': compWidth,
      if (compHeight != null) 'comp_height': compHeight,
      if (compFrameRate != null) 'comp_frame_rate': compFrameRate,
      if (compDurationUs != null) 'comp_duration_us': compDurationUs,
      if (compBackgroundColor != null)
        'comp_background_color': compBackgroundColor,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateModified != null) 'date_modified': dateModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? filePath,
    Value<String>? description,
    Value<String>? version,
    Value<int>? compWidth,
    Value<int>? compHeight,
    Value<double>? compFrameRate,
    Value<int>? compDurationUs,
    Value<int>? compBackgroundColor,
    Value<DateTime>? dateCreated,
    Value<DateTime>? dateModified,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      description: description ?? this.description,
      version: version ?? this.version,
      compWidth: compWidth ?? this.compWidth,
      compHeight: compHeight ?? this.compHeight,
      compFrameRate: compFrameRate ?? this.compFrameRate,
      compDurationUs: compDurationUs ?? this.compDurationUs,
      compBackgroundColor: compBackgroundColor ?? this.compBackgroundColor,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
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
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (compWidth.present) {
      map['comp_width'] = Variable<int>(compWidth.value);
    }
    if (compHeight.present) {
      map['comp_height'] = Variable<int>(compHeight.value);
    }
    if (compFrameRate.present) {
      map['comp_frame_rate'] = Variable<double>(compFrameRate.value);
    }
    if (compDurationUs.present) {
      map['comp_duration_us'] = Variable<int>(compDurationUs.value);
    }
    if (compBackgroundColor.present) {
      map['comp_background_color'] = Variable<int>(compBackgroundColor.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (dateModified.present) {
      map['date_modified'] = Variable<DateTime>(dateModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('filePath: $filePath, ')
          ..write('description: $description, ')
          ..write('version: $version, ')
          ..write('compWidth: $compWidth, ')
          ..write('compHeight: $compHeight, ')
          ..write('compFrameRate: $compFrameRate, ')
          ..write('compDurationUs: $compDurationUs, ')
          ..write('compBackgroundColor: $compBackgroundColor, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('dateModified: $dateModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaAssetsTable extends MediaAssets
    with TableInfo<$MediaAssetsTable, MediaAssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationUsMeta = const VerificationMeta(
    'durationUs',
  );
  @override
  late final GeneratedColumn<int> durationUs = GeneratedColumn<int>(
    'duration_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _frameRateMeta = const VerificationMeta(
    'frameRate',
  );
  @override
  late final GeneratedColumn<double> frameRate = GeneratedColumn<double>(
    'frame_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _sampleRateMeta = const VerificationMeta(
    'sampleRate',
  );
  @override
  late final GeneratedColumn<int> sampleRate = GeneratedColumn<int>(
    'sample_rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _channelsMeta = const VerificationMeta(
    'channels',
  );
  @override
  late final GeneratedColumn<int> channels = GeneratedColumn<int>(
    'channels',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _videoCodecMeta = const VerificationMeta(
    'videoCodec',
  );
  @override
  late final GeneratedColumn<String> videoCodec = GeneratedColumn<String>(
    'video_codec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _audioCodecMeta = const VerificationMeta(
    'audioCodec',
  );
  @override
  late final GeneratedColumn<String> audioCodec = GeneratedColumn<String>(
    'audio_codec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bitRateMeta = const VerificationMeta(
    'bitRate',
  );
  @override
  late final GeneratedColumn<int> bitRate = GeneratedColumn<int>(
    'bit_rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorSpaceMeta = const VerificationMeta(
    'colorSpace',
  );
  @override
  late final GeneratedColumn<String> colorSpace = GeneratedColumn<String>(
    'color_space',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _proxyPathMeta = const VerificationMeta(
    'proxyPath',
  );
  @override
  late final GeneratedColumn<String> proxyPath = GeneratedColumn<String>(
    'proxy_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _binIdMeta = const VerificationMeta('binId');
  @override
  late final GeneratedColumn<String> binId = GeneratedColumn<String>(
    'bin_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    filePath,
    name,
    type,
    durationUs,
    width,
    height,
    frameRate,
    sampleRate,
    channels,
    videoCodec,
    audioCodec,
    bitRate,
    fileSize,
    colorSpace,
    proxyPath,
    thumbnailPath,
    binId,
    dateAdded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaAssetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('duration_us')) {
      context.handle(
        _durationUsMeta,
        durationUs.isAcceptableOrUnknown(data['duration_us']!, _durationUsMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('frame_rate')) {
      context.handle(
        _frameRateMeta,
        frameRate.isAcceptableOrUnknown(data['frame_rate']!, _frameRateMeta),
      );
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
        _sampleRateMeta,
        sampleRate.isAcceptableOrUnknown(data['sample_rate']!, _sampleRateMeta),
      );
    }
    if (data.containsKey('channels')) {
      context.handle(
        _channelsMeta,
        channels.isAcceptableOrUnknown(data['channels']!, _channelsMeta),
      );
    }
    if (data.containsKey('video_codec')) {
      context.handle(
        _videoCodecMeta,
        videoCodec.isAcceptableOrUnknown(data['video_codec']!, _videoCodecMeta),
      );
    }
    if (data.containsKey('audio_codec')) {
      context.handle(
        _audioCodecMeta,
        audioCodec.isAcceptableOrUnknown(data['audio_codec']!, _audioCodecMeta),
      );
    }
    if (data.containsKey('bit_rate')) {
      context.handle(
        _bitRateMeta,
        bitRate.isAcceptableOrUnknown(data['bit_rate']!, _bitRateMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('color_space')) {
      context.handle(
        _colorSpaceMeta,
        colorSpace.isAcceptableOrUnknown(data['color_space']!, _colorSpaceMeta),
      );
    }
    if (data.containsKey('proxy_path')) {
      context.handle(
        _proxyPathMeta,
        proxyPath.isAcceptableOrUnknown(data['proxy_path']!, _proxyPathMeta),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('bin_id')) {
      context.handle(
        _binIdMeta,
        binId.isAcceptableOrUnknown(data['bin_id']!, _binIdMeta),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaAssetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAssetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      durationUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_us'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      frameRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frame_rate'],
      )!,
      sampleRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate'],
      )!,
      channels: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channels'],
      )!,
      videoCodec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_codec'],
      )!,
      audioCodec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_codec'],
      )!,
      bitRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bit_rate'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      colorSpace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_space'],
      )!,
      proxyPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proxy_path'],
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      binId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bin_id'],
      ),
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
    );
  }

  @override
  $MediaAssetsTable createAlias(String alias) {
    return $MediaAssetsTable(attachedDatabase, alias);
  }
}

class MediaAssetRow extends DataClass implements Insertable<MediaAssetRow> {
  final String id;
  final String projectId;
  final String filePath;
  final String name;
  final String type;
  final int durationUs;
  final int width;
  final int height;
  final double frameRate;
  final int sampleRate;
  final int channels;
  final String videoCodec;
  final String audioCodec;
  final int bitRate;
  final int fileSize;
  final String colorSpace;
  final String? proxyPath;
  final String? thumbnailPath;
  final String? binId;
  final DateTime dateAdded;
  const MediaAssetRow({
    required this.id,
    required this.projectId,
    required this.filePath,
    required this.name,
    required this.type,
    required this.durationUs,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.sampleRate,
    required this.channels,
    required this.videoCodec,
    required this.audioCodec,
    required this.bitRate,
    required this.fileSize,
    required this.colorSpace,
    this.proxyPath,
    this.thumbnailPath,
    this.binId,
    required this.dateAdded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['file_path'] = Variable<String>(filePath);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['duration_us'] = Variable<int>(durationUs);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['frame_rate'] = Variable<double>(frameRate);
    map['sample_rate'] = Variable<int>(sampleRate);
    map['channels'] = Variable<int>(channels);
    map['video_codec'] = Variable<String>(videoCodec);
    map['audio_codec'] = Variable<String>(audioCodec);
    map['bit_rate'] = Variable<int>(bitRate);
    map['file_size'] = Variable<int>(fileSize);
    map['color_space'] = Variable<String>(colorSpace);
    if (!nullToAbsent || proxyPath != null) {
      map['proxy_path'] = Variable<String>(proxyPath);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || binId != null) {
      map['bin_id'] = Variable<String>(binId);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    return map;
  }

  MediaAssetsCompanion toCompanion(bool nullToAbsent) {
    return MediaAssetsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      filePath: Value(filePath),
      name: Value(name),
      type: Value(type),
      durationUs: Value(durationUs),
      width: Value(width),
      height: Value(height),
      frameRate: Value(frameRate),
      sampleRate: Value(sampleRate),
      channels: Value(channels),
      videoCodec: Value(videoCodec),
      audioCodec: Value(audioCodec),
      bitRate: Value(bitRate),
      fileSize: Value(fileSize),
      colorSpace: Value(colorSpace),
      proxyPath: proxyPath == null && nullToAbsent
          ? const Value.absent()
          : Value(proxyPath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      binId: binId == null && nullToAbsent
          ? const Value.absent()
          : Value(binId),
      dateAdded: Value(dateAdded),
    );
  }

  factory MediaAssetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAssetRow(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      durationUs: serializer.fromJson<int>(json['durationUs']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      frameRate: serializer.fromJson<double>(json['frameRate']),
      sampleRate: serializer.fromJson<int>(json['sampleRate']),
      channels: serializer.fromJson<int>(json['channels']),
      videoCodec: serializer.fromJson<String>(json['videoCodec']),
      audioCodec: serializer.fromJson<String>(json['audioCodec']),
      bitRate: serializer.fromJson<int>(json['bitRate']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      colorSpace: serializer.fromJson<String>(json['colorSpace']),
      proxyPath: serializer.fromJson<String?>(json['proxyPath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      binId: serializer.fromJson<String?>(json['binId']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'filePath': serializer.toJson<String>(filePath),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'durationUs': serializer.toJson<int>(durationUs),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'frameRate': serializer.toJson<double>(frameRate),
      'sampleRate': serializer.toJson<int>(sampleRate),
      'channels': serializer.toJson<int>(channels),
      'videoCodec': serializer.toJson<String>(videoCodec),
      'audioCodec': serializer.toJson<String>(audioCodec),
      'bitRate': serializer.toJson<int>(bitRate),
      'fileSize': serializer.toJson<int>(fileSize),
      'colorSpace': serializer.toJson<String>(colorSpace),
      'proxyPath': serializer.toJson<String?>(proxyPath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'binId': serializer.toJson<String?>(binId),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
    };
  }

  MediaAssetRow copyWith({
    String? id,
    String? projectId,
    String? filePath,
    String? name,
    String? type,
    int? durationUs,
    int? width,
    int? height,
    double? frameRate,
    int? sampleRate,
    int? channels,
    String? videoCodec,
    String? audioCodec,
    int? bitRate,
    int? fileSize,
    String? colorSpace,
    Value<String?> proxyPath = const Value.absent(),
    Value<String?> thumbnailPath = const Value.absent(),
    Value<String?> binId = const Value.absent(),
    DateTime? dateAdded,
  }) => MediaAssetRow(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    filePath: filePath ?? this.filePath,
    name: name ?? this.name,
    type: type ?? this.type,
    durationUs: durationUs ?? this.durationUs,
    width: width ?? this.width,
    height: height ?? this.height,
    frameRate: frameRate ?? this.frameRate,
    sampleRate: sampleRate ?? this.sampleRate,
    channels: channels ?? this.channels,
    videoCodec: videoCodec ?? this.videoCodec,
    audioCodec: audioCodec ?? this.audioCodec,
    bitRate: bitRate ?? this.bitRate,
    fileSize: fileSize ?? this.fileSize,
    colorSpace: colorSpace ?? this.colorSpace,
    proxyPath: proxyPath.present ? proxyPath.value : this.proxyPath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    binId: binId.present ? binId.value : this.binId,
    dateAdded: dateAdded ?? this.dateAdded,
  );
  MediaAssetRow copyWithCompanion(MediaAssetsCompanion data) {
    return MediaAssetRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      durationUs: data.durationUs.present
          ? data.durationUs.value
          : this.durationUs,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      frameRate: data.frameRate.present ? data.frameRate.value : this.frameRate,
      sampleRate: data.sampleRate.present
          ? data.sampleRate.value
          : this.sampleRate,
      channels: data.channels.present ? data.channels.value : this.channels,
      videoCodec: data.videoCodec.present
          ? data.videoCodec.value
          : this.videoCodec,
      audioCodec: data.audioCodec.present
          ? data.audioCodec.value
          : this.audioCodec,
      bitRate: data.bitRate.present ? data.bitRate.value : this.bitRate,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      colorSpace: data.colorSpace.present
          ? data.colorSpace.value
          : this.colorSpace,
      proxyPath: data.proxyPath.present ? data.proxyPath.value : this.proxyPath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      binId: data.binId.present ? data.binId.value : this.binId,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('filePath: $filePath, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('durationUs: $durationUs, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('frameRate: $frameRate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('channels: $channels, ')
          ..write('videoCodec: $videoCodec, ')
          ..write('audioCodec: $audioCodec, ')
          ..write('bitRate: $bitRate, ')
          ..write('fileSize: $fileSize, ')
          ..write('colorSpace: $colorSpace, ')
          ..write('proxyPath: $proxyPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('binId: $binId, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    filePath,
    name,
    type,
    durationUs,
    width,
    height,
    frameRate,
    sampleRate,
    channels,
    videoCodec,
    audioCodec,
    bitRate,
    fileSize,
    colorSpace,
    proxyPath,
    thumbnailPath,
    binId,
    dateAdded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAssetRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.filePath == this.filePath &&
          other.name == this.name &&
          other.type == this.type &&
          other.durationUs == this.durationUs &&
          other.width == this.width &&
          other.height == this.height &&
          other.frameRate == this.frameRate &&
          other.sampleRate == this.sampleRate &&
          other.channels == this.channels &&
          other.videoCodec == this.videoCodec &&
          other.audioCodec == this.audioCodec &&
          other.bitRate == this.bitRate &&
          other.fileSize == this.fileSize &&
          other.colorSpace == this.colorSpace &&
          other.proxyPath == this.proxyPath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.binId == this.binId &&
          other.dateAdded == this.dateAdded);
}

class MediaAssetsCompanion extends UpdateCompanion<MediaAssetRow> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> filePath;
  final Value<String> name;
  final Value<String> type;
  final Value<int> durationUs;
  final Value<int> width;
  final Value<int> height;
  final Value<double> frameRate;
  final Value<int> sampleRate;
  final Value<int> channels;
  final Value<String> videoCodec;
  final Value<String> audioCodec;
  final Value<int> bitRate;
  final Value<int> fileSize;
  final Value<String> colorSpace;
  final Value<String?> proxyPath;
  final Value<String?> thumbnailPath;
  final Value<String?> binId;
  final Value<DateTime> dateAdded;
  final Value<int> rowid;
  const MediaAssetsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.durationUs = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.frameRate = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.channels = const Value.absent(),
    this.videoCodec = const Value.absent(),
    this.audioCodec = const Value.absent(),
    this.bitRate = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.colorSpace = const Value.absent(),
    this.proxyPath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.binId = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaAssetsCompanion.insert({
    required String id,
    required String projectId,
    required String filePath,
    required String name,
    required String type,
    this.durationUs = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.frameRate = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.channels = const Value.absent(),
    this.videoCodec = const Value.absent(),
    this.audioCodec = const Value.absent(),
    this.bitRate = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.colorSpace = const Value.absent(),
    this.proxyPath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.binId = const Value.absent(),
    required DateTime dateAdded,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       filePath = Value(filePath),
       name = Value(name),
       type = Value(type),
       dateAdded = Value(dateAdded);
  static Insertable<MediaAssetRow> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? filePath,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? durationUs,
    Expression<int>? width,
    Expression<int>? height,
    Expression<double>? frameRate,
    Expression<int>? sampleRate,
    Expression<int>? channels,
    Expression<String>? videoCodec,
    Expression<String>? audioCodec,
    Expression<int>? bitRate,
    Expression<int>? fileSize,
    Expression<String>? colorSpace,
    Expression<String>? proxyPath,
    Expression<String>? thumbnailPath,
    Expression<String>? binId,
    Expression<DateTime>? dateAdded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (filePath != null) 'file_path': filePath,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (durationUs != null) 'duration_us': durationUs,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (frameRate != null) 'frame_rate': frameRate,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (channels != null) 'channels': channels,
      if (videoCodec != null) 'video_codec': videoCodec,
      if (audioCodec != null) 'audio_codec': audioCodec,
      if (bitRate != null) 'bit_rate': bitRate,
      if (fileSize != null) 'file_size': fileSize,
      if (colorSpace != null) 'color_space': colorSpace,
      if (proxyPath != null) 'proxy_path': proxyPath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (binId != null) 'bin_id': binId,
      if (dateAdded != null) 'date_added': dateAdded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaAssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? filePath,
    Value<String>? name,
    Value<String>? type,
    Value<int>? durationUs,
    Value<int>? width,
    Value<int>? height,
    Value<double>? frameRate,
    Value<int>? sampleRate,
    Value<int>? channels,
    Value<String>? videoCodec,
    Value<String>? audioCodec,
    Value<int>? bitRate,
    Value<int>? fileSize,
    Value<String>? colorSpace,
    Value<String?>? proxyPath,
    Value<String?>? thumbnailPath,
    Value<String?>? binId,
    Value<DateTime>? dateAdded,
    Value<int>? rowid,
  }) {
    return MediaAssetsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      filePath: filePath ?? this.filePath,
      name: name ?? this.name,
      type: type ?? this.type,
      durationUs: durationUs ?? this.durationUs,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      bitRate: bitRate ?? this.bitRate,
      fileSize: fileSize ?? this.fileSize,
      colorSpace: colorSpace ?? this.colorSpace,
      proxyPath: proxyPath ?? this.proxyPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      binId: binId ?? this.binId,
      dateAdded: dateAdded ?? this.dateAdded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (durationUs.present) {
      map['duration_us'] = Variable<int>(durationUs.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (frameRate.present) {
      map['frame_rate'] = Variable<double>(frameRate.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = Variable<int>(sampleRate.value);
    }
    if (channels.present) {
      map['channels'] = Variable<int>(channels.value);
    }
    if (videoCodec.present) {
      map['video_codec'] = Variable<String>(videoCodec.value);
    }
    if (audioCodec.present) {
      map['audio_codec'] = Variable<String>(audioCodec.value);
    }
    if (bitRate.present) {
      map['bit_rate'] = Variable<int>(bitRate.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (colorSpace.present) {
      map['color_space'] = Variable<String>(colorSpace.value);
    }
    if (proxyPath.present) {
      map['proxy_path'] = Variable<String>(proxyPath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (binId.present) {
      map['bin_id'] = Variable<String>(binId.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('filePath: $filePath, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('durationUs: $durationUs, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('frameRate: $frameRate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('channels: $channels, ')
          ..write('videoCodec: $videoCodec, ')
          ..write('audioCodec: $audioCodec, ')
          ..write('bitRate: $bitRate, ')
          ..write('fileSize: $fileSize, ')
          ..write('colorSpace: $colorSpace, ')
          ..write('proxyPath: $proxyPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('binId: $binId, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIndexMeta = const VerificationMeta(
    'trackIndex',
  );
  @override
  late final GeneratedColumn<int> trackIndex = GeneratedColumn<int>(
    'track_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(56.0),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSoloedMeta = const VerificationMeta(
    'isSoloed',
  );
  @override
  late final GeneratedColumn<bool> isSoloed = GeneratedColumn<bool>(
    'is_soloed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_soloed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isVisibleMeta = const VerificationMeta(
    'isVisible',
  );
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
    'is_visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _panMeta = const VerificationMeta('pan');
  @override
  late final GeneratedColumn<double> pan = GeneratedColumn<double>(
    'pan',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    type,
    trackIndex,
    name,
    height,
    isMuted,
    isSoloed,
    isLocked,
    isVisible,
    volume,
    pan,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Track> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('track_index')) {
      context.handle(
        _trackIndexMeta,
        trackIndex.isAcceptableOrUnknown(data['track_index']!, _trackIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIndexMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    if (data.containsKey('is_soloed')) {
      context.handle(
        _isSoloedMeta,
        isSoloed.isAcceptableOrUnknown(data['is_soloed']!, _isSoloedMeta),
      );
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('is_visible')) {
      context.handle(
        _isVisibleMeta,
        isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta),
      );
    }
    if (data.containsKey('volume')) {
      context.handle(
        _volumeMeta,
        volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta),
      );
    }
    if (data.containsKey('pan')) {
      context.handle(
        _panMeta,
        pan.isAcceptableOrUnknown(data['pan']!, _panMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      trackIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_index'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_muted'],
      )!,
      isSoloed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_soloed'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      isVisible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_visible'],
      )!,
      volume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume'],
      )!,
      pan: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pan'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final String id;
  final String projectId;
  final String type;
  final int trackIndex;
  final String name;
  final double height;
  final bool isMuted;
  final bool isSoloed;
  final bool isLocked;
  final bool isVisible;
  final double volume;
  final double pan;
  const Track({
    required this.id,
    required this.projectId,
    required this.type,
    required this.trackIndex,
    required this.name,
    required this.height,
    required this.isMuted,
    required this.isSoloed,
    required this.isLocked,
    required this.isVisible,
    required this.volume,
    required this.pan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['type'] = Variable<String>(type);
    map['track_index'] = Variable<int>(trackIndex);
    map['name'] = Variable<String>(name);
    map['height'] = Variable<double>(height);
    map['is_muted'] = Variable<bool>(isMuted);
    map['is_soloed'] = Variable<bool>(isSoloed);
    map['is_locked'] = Variable<bool>(isLocked);
    map['is_visible'] = Variable<bool>(isVisible);
    map['volume'] = Variable<double>(volume);
    map['pan'] = Variable<double>(pan);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      projectId: Value(projectId),
      type: Value(type),
      trackIndex: Value(trackIndex),
      name: Value(name),
      height: Value(height),
      isMuted: Value(isMuted),
      isSoloed: Value(isSoloed),
      isLocked: Value(isLocked),
      isVisible: Value(isVisible),
      volume: Value(volume),
      pan: Value(pan),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      type: serializer.fromJson<String>(json['type']),
      trackIndex: serializer.fromJson<int>(json['trackIndex']),
      name: serializer.fromJson<String>(json['name']),
      height: serializer.fromJson<double>(json['height']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      isSoloed: serializer.fromJson<bool>(json['isSoloed']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
      volume: serializer.fromJson<double>(json['volume']),
      pan: serializer.fromJson<double>(json['pan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'type': serializer.toJson<String>(type),
      'trackIndex': serializer.toJson<int>(trackIndex),
      'name': serializer.toJson<String>(name),
      'height': serializer.toJson<double>(height),
      'isMuted': serializer.toJson<bool>(isMuted),
      'isSoloed': serializer.toJson<bool>(isSoloed),
      'isLocked': serializer.toJson<bool>(isLocked),
      'isVisible': serializer.toJson<bool>(isVisible),
      'volume': serializer.toJson<double>(volume),
      'pan': serializer.toJson<double>(pan),
    };
  }

  Track copyWith({
    String? id,
    String? projectId,
    String? type,
    int? trackIndex,
    String? name,
    double? height,
    bool? isMuted,
    bool? isSoloed,
    bool? isLocked,
    bool? isVisible,
    double? volume,
    double? pan,
  }) => Track(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    type: type ?? this.type,
    trackIndex: trackIndex ?? this.trackIndex,
    name: name ?? this.name,
    height: height ?? this.height,
    isMuted: isMuted ?? this.isMuted,
    isSoloed: isSoloed ?? this.isSoloed,
    isLocked: isLocked ?? this.isLocked,
    isVisible: isVisible ?? this.isVisible,
    volume: volume ?? this.volume,
    pan: pan ?? this.pan,
  );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      type: data.type.present ? data.type.value : this.type,
      trackIndex: data.trackIndex.present
          ? data.trackIndex.value
          : this.trackIndex,
      name: data.name.present ? data.name.value : this.name,
      height: data.height.present ? data.height.value : this.height,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      isSoloed: data.isSoloed.present ? data.isSoloed.value : this.isSoloed,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
      volume: data.volume.present ? data.volume.value : this.volume,
      pan: data.pan.present ? data.pan.value : this.pan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('type: $type, ')
          ..write('trackIndex: $trackIndex, ')
          ..write('name: $name, ')
          ..write('height: $height, ')
          ..write('isMuted: $isMuted, ')
          ..write('isSoloed: $isSoloed, ')
          ..write('isLocked: $isLocked, ')
          ..write('isVisible: $isVisible, ')
          ..write('volume: $volume, ')
          ..write('pan: $pan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    type,
    trackIndex,
    name,
    height,
    isMuted,
    isSoloed,
    isLocked,
    isVisible,
    volume,
    pan,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.type == this.type &&
          other.trackIndex == this.trackIndex &&
          other.name == this.name &&
          other.height == this.height &&
          other.isMuted == this.isMuted &&
          other.isSoloed == this.isSoloed &&
          other.isLocked == this.isLocked &&
          other.isVisible == this.isVisible &&
          other.volume == this.volume &&
          other.pan == this.pan);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> type;
  final Value<int> trackIndex;
  final Value<String> name;
  final Value<double> height;
  final Value<bool> isMuted;
  final Value<bool> isSoloed;
  final Value<bool> isLocked;
  final Value<bool> isVisible;
  final Value<double> volume;
  final Value<double> pan;
  final Value<int> rowid;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.type = const Value.absent(),
    this.trackIndex = const Value.absent(),
    this.name = const Value.absent(),
    this.height = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.isSoloed = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.volume = const Value.absent(),
    this.pan = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String id,
    required String projectId,
    required String type,
    required int trackIndex,
    this.name = const Value.absent(),
    this.height = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.isSoloed = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.volume = const Value.absent(),
    this.pan = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       type = Value(type),
       trackIndex = Value(trackIndex);
  static Insertable<Track> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? type,
    Expression<int>? trackIndex,
    Expression<String>? name,
    Expression<double>? height,
    Expression<bool>? isMuted,
    Expression<bool>? isSoloed,
    Expression<bool>? isLocked,
    Expression<bool>? isVisible,
    Expression<double>? volume,
    Expression<double>? pan,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (type != null) 'type': type,
      if (trackIndex != null) 'track_index': trackIndex,
      if (name != null) 'name': name,
      if (height != null) 'height': height,
      if (isMuted != null) 'is_muted': isMuted,
      if (isSoloed != null) 'is_soloed': isSoloed,
      if (isLocked != null) 'is_locked': isLocked,
      if (isVisible != null) 'is_visible': isVisible,
      if (volume != null) 'volume': volume,
      if (pan != null) 'pan': pan,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? type,
    Value<int>? trackIndex,
    Value<String>? name,
    Value<double>? height,
    Value<bool>? isMuted,
    Value<bool>? isSoloed,
    Value<bool>? isLocked,
    Value<bool>? isVisible,
    Value<double>? volume,
    Value<double>? pan,
    Value<int>? rowid,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      trackIndex: trackIndex ?? this.trackIndex,
      name: name ?? this.name,
      height: height ?? this.height,
      isMuted: isMuted ?? this.isMuted,
      isSoloed: isSoloed ?? this.isSoloed,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (trackIndex.present) {
      map['track_index'] = Variable<int>(trackIndex.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (isSoloed.present) {
      map['is_soloed'] = Variable<bool>(isSoloed.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (pan.present) {
      map['pan'] = Variable<double>(pan.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('type: $type, ')
          ..write('trackIndex: $trackIndex, ')
          ..write('name: $name, ')
          ..write('height: $height, ')
          ..write('isMuted: $isMuted, ')
          ..write('isSoloed: $isSoloed, ')
          ..write('isLocked: $isLocked, ')
          ..write('isVisible: $isVisible, ')
          ..write('volume: $volume, ')
          ..write('pan: $pan, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClipsTable extends Clips with TableInfo<$ClipsTable, Clip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_assets (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startOnTimelineUsMeta = const VerificationMeta(
    'startOnTimelineUs',
  );
  @override
  late final GeneratedColumn<int> startOnTimelineUs = GeneratedColumn<int>(
    'start_on_timeline_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endOnTimelineUsMeta = const VerificationMeta(
    'endOnTimelineUs',
  );
  @override
  late final GeneratedColumn<int> endOnTimelineUs = GeneratedColumn<int>(
    'end_on_timeline_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaInPointUsMeta = const VerificationMeta(
    'mediaInPointUs',
  );
  @override
  late final GeneratedColumn<int> mediaInPointUs = GeneratedColumn<int>(
    'media_in_point_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaOutPointUsMeta = const VerificationMeta(
    'mediaOutPointUs',
  );
  @override
  late final GeneratedColumn<int> mediaOutPointUs = GeneratedColumn<int>(
    'media_out_point_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _opacityMeta = const VerificationMeta(
    'opacity',
  );
  @override
  late final GeneratedColumn<double> opacity = GeneratedColumn<double>(
    'opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _blendModeMeta = const VerificationMeta(
    'blendMode',
  );
  @override
  late final GeneratedColumn<String> blendMode = GeneratedColumn<String>(
    'blend_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _labelColorIndexMeta = const VerificationMeta(
    'labelColorIndex',
  );
  @override
  late final GeneratedColumn<int> labelColorIndex = GeneratedColumn<int>(
    'label_color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isVideoLinkedMeta = const VerificationMeta(
    'isVideoLinked',
  );
  @override
  late final GeneratedColumn<bool> isVideoLinked = GeneratedColumn<bool>(
    'is_video_linked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_video_linked" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isAudioLinkedMeta = const VerificationMeta(
    'isAudioLinked',
  );
  @override
  late final GeneratedColumn<bool> isAudioLinked = GeneratedColumn<bool>(
    'is_audio_linked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_audio_linked" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _transitionInIdMeta = const VerificationMeta(
    'transitionInId',
  );
  @override
  late final GeneratedColumn<String> transitionInId = GeneratedColumn<String>(
    'transition_in_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transitionOutIdMeta = const VerificationMeta(
    'transitionOutId',
  );
  @override
  late final GeneratedColumn<String> transitionOutId = GeneratedColumn<String>(
    'transition_out_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transitionInDurationUsMeta =
      const VerificationMeta('transitionInDurationUs');
  @override
  late final GeneratedColumn<int> transitionInDurationUs = GeneratedColumn<int>(
    'transition_in_duration_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transitionOutDurationUsMeta =
      const VerificationMeta('transitionOutDurationUs');
  @override
  late final GeneratedColumn<int> transitionOutDurationUs =
      GeneratedColumn<int>(
        'transition_out_duration_us',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    mediaId,
    type,
    startOnTimelineUs,
    endOnTimelineUs,
    mediaInPointUs,
    mediaOutPointUs,
    speed,
    opacity,
    blendMode,
    labelColorIndex,
    isVideoLinked,
    isAudioLinked,
    isMuted,
    isLocked,
    name,
    transitionInId,
    transitionOutId,
    transitionInDurationUs,
    transitionOutDurationUs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Clip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('start_on_timeline_us')) {
      context.handle(
        _startOnTimelineUsMeta,
        startOnTimelineUs.isAcceptableOrUnknown(
          data['start_on_timeline_us']!,
          _startOnTimelineUsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startOnTimelineUsMeta);
    }
    if (data.containsKey('end_on_timeline_us')) {
      context.handle(
        _endOnTimelineUsMeta,
        endOnTimelineUs.isAcceptableOrUnknown(
          data['end_on_timeline_us']!,
          _endOnTimelineUsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endOnTimelineUsMeta);
    }
    if (data.containsKey('media_in_point_us')) {
      context.handle(
        _mediaInPointUsMeta,
        mediaInPointUs.isAcceptableOrUnknown(
          data['media_in_point_us']!,
          _mediaInPointUsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaInPointUsMeta);
    }
    if (data.containsKey('media_out_point_us')) {
      context.handle(
        _mediaOutPointUsMeta,
        mediaOutPointUs.isAcceptableOrUnknown(
          data['media_out_point_us']!,
          _mediaOutPointUsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaOutPointUsMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('opacity')) {
      context.handle(
        _opacityMeta,
        opacity.isAcceptableOrUnknown(data['opacity']!, _opacityMeta),
      );
    }
    if (data.containsKey('blend_mode')) {
      context.handle(
        _blendModeMeta,
        blendMode.isAcceptableOrUnknown(data['blend_mode']!, _blendModeMeta),
      );
    }
    if (data.containsKey('label_color_index')) {
      context.handle(
        _labelColorIndexMeta,
        labelColorIndex.isAcceptableOrUnknown(
          data['label_color_index']!,
          _labelColorIndexMeta,
        ),
      );
    }
    if (data.containsKey('is_video_linked')) {
      context.handle(
        _isVideoLinkedMeta,
        isVideoLinked.isAcceptableOrUnknown(
          data['is_video_linked']!,
          _isVideoLinkedMeta,
        ),
      );
    }
    if (data.containsKey('is_audio_linked')) {
      context.handle(
        _isAudioLinkedMeta,
        isAudioLinked.isAcceptableOrUnknown(
          data['is_audio_linked']!,
          _isAudioLinkedMeta,
        ),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('transition_in_id')) {
      context.handle(
        _transitionInIdMeta,
        transitionInId.isAcceptableOrUnknown(
          data['transition_in_id']!,
          _transitionInIdMeta,
        ),
      );
    }
    if (data.containsKey('transition_out_id')) {
      context.handle(
        _transitionOutIdMeta,
        transitionOutId.isAcceptableOrUnknown(
          data['transition_out_id']!,
          _transitionOutIdMeta,
        ),
      );
    }
    if (data.containsKey('transition_in_duration_us')) {
      context.handle(
        _transitionInDurationUsMeta,
        transitionInDurationUs.isAcceptableOrUnknown(
          data['transition_in_duration_us']!,
          _transitionInDurationUsMeta,
        ),
      );
    }
    if (data.containsKey('transition_out_duration_us')) {
      context.handle(
        _transitionOutDurationUsMeta,
        transitionOutDurationUs.isAcceptableOrUnknown(
          data['transition_out_duration_us']!,
          _transitionOutDurationUsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Clip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Clip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      startOnTimelineUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_on_timeline_us'],
      )!,
      endOnTimelineUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_on_timeline_us'],
      )!,
      mediaInPointUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_in_point_us'],
      )!,
      mediaOutPointUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_out_point_us'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
      opacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opacity'],
      )!,
      blendMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blend_mode'],
      )!,
      labelColorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}label_color_index'],
      )!,
      isVideoLinked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_video_linked'],
      )!,
      isAudioLinked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_audio_linked'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_muted'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      transitionInId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transition_in_id'],
      ),
      transitionOutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transition_out_id'],
      ),
      transitionInDurationUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transition_in_duration_us'],
      )!,
      transitionOutDurationUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transition_out_duration_us'],
      )!,
    );
  }

  @override
  $ClipsTable createAlias(String alias) {
    return $ClipsTable(attachedDatabase, alias);
  }
}

class Clip extends DataClass implements Insertable<Clip> {
  final String id;
  final String trackId;
  final String mediaId;
  final String type;
  final int startOnTimelineUs;
  final int endOnTimelineUs;
  final int mediaInPointUs;
  final int mediaOutPointUs;
  final double speed;
  final double opacity;
  final String blendMode;
  final int labelColorIndex;
  final bool isVideoLinked;
  final bool isAudioLinked;
  final bool isMuted;
  final bool isLocked;
  final String name;
  final String? transitionInId;
  final String? transitionOutId;
  final int transitionInDurationUs;
  final int transitionOutDurationUs;
  const Clip({
    required this.id,
    required this.trackId,
    required this.mediaId,
    required this.type,
    required this.startOnTimelineUs,
    required this.endOnTimelineUs,
    required this.mediaInPointUs,
    required this.mediaOutPointUs,
    required this.speed,
    required this.opacity,
    required this.blendMode,
    required this.labelColorIndex,
    required this.isVideoLinked,
    required this.isAudioLinked,
    required this.isMuted,
    required this.isLocked,
    required this.name,
    this.transitionInId,
    this.transitionOutId,
    required this.transitionInDurationUs,
    required this.transitionOutDurationUs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['track_id'] = Variable<String>(trackId);
    map['media_id'] = Variable<String>(mediaId);
    map['type'] = Variable<String>(type);
    map['start_on_timeline_us'] = Variable<int>(startOnTimelineUs);
    map['end_on_timeline_us'] = Variable<int>(endOnTimelineUs);
    map['media_in_point_us'] = Variable<int>(mediaInPointUs);
    map['media_out_point_us'] = Variable<int>(mediaOutPointUs);
    map['speed'] = Variable<double>(speed);
    map['opacity'] = Variable<double>(opacity);
    map['blend_mode'] = Variable<String>(blendMode);
    map['label_color_index'] = Variable<int>(labelColorIndex);
    map['is_video_linked'] = Variable<bool>(isVideoLinked);
    map['is_audio_linked'] = Variable<bool>(isAudioLinked);
    map['is_muted'] = Variable<bool>(isMuted);
    map['is_locked'] = Variable<bool>(isLocked);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || transitionInId != null) {
      map['transition_in_id'] = Variable<String>(transitionInId);
    }
    if (!nullToAbsent || transitionOutId != null) {
      map['transition_out_id'] = Variable<String>(transitionOutId);
    }
    map['transition_in_duration_us'] = Variable<int>(transitionInDurationUs);
    map['transition_out_duration_us'] = Variable<int>(transitionOutDurationUs);
    return map;
  }

  ClipsCompanion toCompanion(bool nullToAbsent) {
    return ClipsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      mediaId: Value(mediaId),
      type: Value(type),
      startOnTimelineUs: Value(startOnTimelineUs),
      endOnTimelineUs: Value(endOnTimelineUs),
      mediaInPointUs: Value(mediaInPointUs),
      mediaOutPointUs: Value(mediaOutPointUs),
      speed: Value(speed),
      opacity: Value(opacity),
      blendMode: Value(blendMode),
      labelColorIndex: Value(labelColorIndex),
      isVideoLinked: Value(isVideoLinked),
      isAudioLinked: Value(isAudioLinked),
      isMuted: Value(isMuted),
      isLocked: Value(isLocked),
      name: Value(name),
      transitionInId: transitionInId == null && nullToAbsent
          ? const Value.absent()
          : Value(transitionInId),
      transitionOutId: transitionOutId == null && nullToAbsent
          ? const Value.absent()
          : Value(transitionOutId),
      transitionInDurationUs: Value(transitionInDurationUs),
      transitionOutDurationUs: Value(transitionOutDurationUs),
    );
  }

  factory Clip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Clip(
      id: serializer.fromJson<String>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      type: serializer.fromJson<String>(json['type']),
      startOnTimelineUs: serializer.fromJson<int>(json['startOnTimelineUs']),
      endOnTimelineUs: serializer.fromJson<int>(json['endOnTimelineUs']),
      mediaInPointUs: serializer.fromJson<int>(json['mediaInPointUs']),
      mediaOutPointUs: serializer.fromJson<int>(json['mediaOutPointUs']),
      speed: serializer.fromJson<double>(json['speed']),
      opacity: serializer.fromJson<double>(json['opacity']),
      blendMode: serializer.fromJson<String>(json['blendMode']),
      labelColorIndex: serializer.fromJson<int>(json['labelColorIndex']),
      isVideoLinked: serializer.fromJson<bool>(json['isVideoLinked']),
      isAudioLinked: serializer.fromJson<bool>(json['isAudioLinked']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      name: serializer.fromJson<String>(json['name']),
      transitionInId: serializer.fromJson<String?>(json['transitionInId']),
      transitionOutId: serializer.fromJson<String?>(json['transitionOutId']),
      transitionInDurationUs: serializer.fromJson<int>(
        json['transitionInDurationUs'],
      ),
      transitionOutDurationUs: serializer.fromJson<int>(
        json['transitionOutDurationUs'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trackId': serializer.toJson<String>(trackId),
      'mediaId': serializer.toJson<String>(mediaId),
      'type': serializer.toJson<String>(type),
      'startOnTimelineUs': serializer.toJson<int>(startOnTimelineUs),
      'endOnTimelineUs': serializer.toJson<int>(endOnTimelineUs),
      'mediaInPointUs': serializer.toJson<int>(mediaInPointUs),
      'mediaOutPointUs': serializer.toJson<int>(mediaOutPointUs),
      'speed': serializer.toJson<double>(speed),
      'opacity': serializer.toJson<double>(opacity),
      'blendMode': serializer.toJson<String>(blendMode),
      'labelColorIndex': serializer.toJson<int>(labelColorIndex),
      'isVideoLinked': serializer.toJson<bool>(isVideoLinked),
      'isAudioLinked': serializer.toJson<bool>(isAudioLinked),
      'isMuted': serializer.toJson<bool>(isMuted),
      'isLocked': serializer.toJson<bool>(isLocked),
      'name': serializer.toJson<String>(name),
      'transitionInId': serializer.toJson<String?>(transitionInId),
      'transitionOutId': serializer.toJson<String?>(transitionOutId),
      'transitionInDurationUs': serializer.toJson<int>(transitionInDurationUs),
      'transitionOutDurationUs': serializer.toJson<int>(
        transitionOutDurationUs,
      ),
    };
  }

  Clip copyWith({
    String? id,
    String? trackId,
    String? mediaId,
    String? type,
    int? startOnTimelineUs,
    int? endOnTimelineUs,
    int? mediaInPointUs,
    int? mediaOutPointUs,
    double? speed,
    double? opacity,
    String? blendMode,
    int? labelColorIndex,
    bool? isVideoLinked,
    bool? isAudioLinked,
    bool? isMuted,
    bool? isLocked,
    String? name,
    Value<String?> transitionInId = const Value.absent(),
    Value<String?> transitionOutId = const Value.absent(),
    int? transitionInDurationUs,
    int? transitionOutDurationUs,
  }) => Clip(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    mediaId: mediaId ?? this.mediaId,
    type: type ?? this.type,
    startOnTimelineUs: startOnTimelineUs ?? this.startOnTimelineUs,
    endOnTimelineUs: endOnTimelineUs ?? this.endOnTimelineUs,
    mediaInPointUs: mediaInPointUs ?? this.mediaInPointUs,
    mediaOutPointUs: mediaOutPointUs ?? this.mediaOutPointUs,
    speed: speed ?? this.speed,
    opacity: opacity ?? this.opacity,
    blendMode: blendMode ?? this.blendMode,
    labelColorIndex: labelColorIndex ?? this.labelColorIndex,
    isVideoLinked: isVideoLinked ?? this.isVideoLinked,
    isAudioLinked: isAudioLinked ?? this.isAudioLinked,
    isMuted: isMuted ?? this.isMuted,
    isLocked: isLocked ?? this.isLocked,
    name: name ?? this.name,
    transitionInId: transitionInId.present
        ? transitionInId.value
        : this.transitionInId,
    transitionOutId: transitionOutId.present
        ? transitionOutId.value
        : this.transitionOutId,
    transitionInDurationUs:
        transitionInDurationUs ?? this.transitionInDurationUs,
    transitionOutDurationUs:
        transitionOutDurationUs ?? this.transitionOutDurationUs,
  );
  Clip copyWithCompanion(ClipsCompanion data) {
    return Clip(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      type: data.type.present ? data.type.value : this.type,
      startOnTimelineUs: data.startOnTimelineUs.present
          ? data.startOnTimelineUs.value
          : this.startOnTimelineUs,
      endOnTimelineUs: data.endOnTimelineUs.present
          ? data.endOnTimelineUs.value
          : this.endOnTimelineUs,
      mediaInPointUs: data.mediaInPointUs.present
          ? data.mediaInPointUs.value
          : this.mediaInPointUs,
      mediaOutPointUs: data.mediaOutPointUs.present
          ? data.mediaOutPointUs.value
          : this.mediaOutPointUs,
      speed: data.speed.present ? data.speed.value : this.speed,
      opacity: data.opacity.present ? data.opacity.value : this.opacity,
      blendMode: data.blendMode.present ? data.blendMode.value : this.blendMode,
      labelColorIndex: data.labelColorIndex.present
          ? data.labelColorIndex.value
          : this.labelColorIndex,
      isVideoLinked: data.isVideoLinked.present
          ? data.isVideoLinked.value
          : this.isVideoLinked,
      isAudioLinked: data.isAudioLinked.present
          ? data.isAudioLinked.value
          : this.isAudioLinked,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      name: data.name.present ? data.name.value : this.name,
      transitionInId: data.transitionInId.present
          ? data.transitionInId.value
          : this.transitionInId,
      transitionOutId: data.transitionOutId.present
          ? data.transitionOutId.value
          : this.transitionOutId,
      transitionInDurationUs: data.transitionInDurationUs.present
          ? data.transitionInDurationUs.value
          : this.transitionInDurationUs,
      transitionOutDurationUs: data.transitionOutDurationUs.present
          ? data.transitionOutDurationUs.value
          : this.transitionOutDurationUs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Clip(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('mediaId: $mediaId, ')
          ..write('type: $type, ')
          ..write('startOnTimelineUs: $startOnTimelineUs, ')
          ..write('endOnTimelineUs: $endOnTimelineUs, ')
          ..write('mediaInPointUs: $mediaInPointUs, ')
          ..write('mediaOutPointUs: $mediaOutPointUs, ')
          ..write('speed: $speed, ')
          ..write('opacity: $opacity, ')
          ..write('blendMode: $blendMode, ')
          ..write('labelColorIndex: $labelColorIndex, ')
          ..write('isVideoLinked: $isVideoLinked, ')
          ..write('isAudioLinked: $isAudioLinked, ')
          ..write('isMuted: $isMuted, ')
          ..write('isLocked: $isLocked, ')
          ..write('name: $name, ')
          ..write('transitionInId: $transitionInId, ')
          ..write('transitionOutId: $transitionOutId, ')
          ..write('transitionInDurationUs: $transitionInDurationUs, ')
          ..write('transitionOutDurationUs: $transitionOutDurationUs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    trackId,
    mediaId,
    type,
    startOnTimelineUs,
    endOnTimelineUs,
    mediaInPointUs,
    mediaOutPointUs,
    speed,
    opacity,
    blendMode,
    labelColorIndex,
    isVideoLinked,
    isAudioLinked,
    isMuted,
    isLocked,
    name,
    transitionInId,
    transitionOutId,
    transitionInDurationUs,
    transitionOutDurationUs,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Clip &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.mediaId == this.mediaId &&
          other.type == this.type &&
          other.startOnTimelineUs == this.startOnTimelineUs &&
          other.endOnTimelineUs == this.endOnTimelineUs &&
          other.mediaInPointUs == this.mediaInPointUs &&
          other.mediaOutPointUs == this.mediaOutPointUs &&
          other.speed == this.speed &&
          other.opacity == this.opacity &&
          other.blendMode == this.blendMode &&
          other.labelColorIndex == this.labelColorIndex &&
          other.isVideoLinked == this.isVideoLinked &&
          other.isAudioLinked == this.isAudioLinked &&
          other.isMuted == this.isMuted &&
          other.isLocked == this.isLocked &&
          other.name == this.name &&
          other.transitionInId == this.transitionInId &&
          other.transitionOutId == this.transitionOutId &&
          other.transitionInDurationUs == this.transitionInDurationUs &&
          other.transitionOutDurationUs == this.transitionOutDurationUs);
}

class ClipsCompanion extends UpdateCompanion<Clip> {
  final Value<String> id;
  final Value<String> trackId;
  final Value<String> mediaId;
  final Value<String> type;
  final Value<int> startOnTimelineUs;
  final Value<int> endOnTimelineUs;
  final Value<int> mediaInPointUs;
  final Value<int> mediaOutPointUs;
  final Value<double> speed;
  final Value<double> opacity;
  final Value<String> blendMode;
  final Value<int> labelColorIndex;
  final Value<bool> isVideoLinked;
  final Value<bool> isAudioLinked;
  final Value<bool> isMuted;
  final Value<bool> isLocked;
  final Value<String> name;
  final Value<String?> transitionInId;
  final Value<String?> transitionOutId;
  final Value<int> transitionInDurationUs;
  final Value<int> transitionOutDurationUs;
  final Value<int> rowid;
  const ClipsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.type = const Value.absent(),
    this.startOnTimelineUs = const Value.absent(),
    this.endOnTimelineUs = const Value.absent(),
    this.mediaInPointUs = const Value.absent(),
    this.mediaOutPointUs = const Value.absent(),
    this.speed = const Value.absent(),
    this.opacity = const Value.absent(),
    this.blendMode = const Value.absent(),
    this.labelColorIndex = const Value.absent(),
    this.isVideoLinked = const Value.absent(),
    this.isAudioLinked = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.name = const Value.absent(),
    this.transitionInId = const Value.absent(),
    this.transitionOutId = const Value.absent(),
    this.transitionInDurationUs = const Value.absent(),
    this.transitionOutDurationUs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClipsCompanion.insert({
    required String id,
    required String trackId,
    required String mediaId,
    required String type,
    required int startOnTimelineUs,
    required int endOnTimelineUs,
    required int mediaInPointUs,
    required int mediaOutPointUs,
    this.speed = const Value.absent(),
    this.opacity = const Value.absent(),
    this.blendMode = const Value.absent(),
    this.labelColorIndex = const Value.absent(),
    this.isVideoLinked = const Value.absent(),
    this.isAudioLinked = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.name = const Value.absent(),
    this.transitionInId = const Value.absent(),
    this.transitionOutId = const Value.absent(),
    this.transitionInDurationUs = const Value.absent(),
    this.transitionOutDurationUs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       trackId = Value(trackId),
       mediaId = Value(mediaId),
       type = Value(type),
       startOnTimelineUs = Value(startOnTimelineUs),
       endOnTimelineUs = Value(endOnTimelineUs),
       mediaInPointUs = Value(mediaInPointUs),
       mediaOutPointUs = Value(mediaOutPointUs);
  static Insertable<Clip> custom({
    Expression<String>? id,
    Expression<String>? trackId,
    Expression<String>? mediaId,
    Expression<String>? type,
    Expression<int>? startOnTimelineUs,
    Expression<int>? endOnTimelineUs,
    Expression<int>? mediaInPointUs,
    Expression<int>? mediaOutPointUs,
    Expression<double>? speed,
    Expression<double>? opacity,
    Expression<String>? blendMode,
    Expression<int>? labelColorIndex,
    Expression<bool>? isVideoLinked,
    Expression<bool>? isAudioLinked,
    Expression<bool>? isMuted,
    Expression<bool>? isLocked,
    Expression<String>? name,
    Expression<String>? transitionInId,
    Expression<String>? transitionOutId,
    Expression<int>? transitionInDurationUs,
    Expression<int>? transitionOutDurationUs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (mediaId != null) 'media_id': mediaId,
      if (type != null) 'type': type,
      if (startOnTimelineUs != null) 'start_on_timeline_us': startOnTimelineUs,
      if (endOnTimelineUs != null) 'end_on_timeline_us': endOnTimelineUs,
      if (mediaInPointUs != null) 'media_in_point_us': mediaInPointUs,
      if (mediaOutPointUs != null) 'media_out_point_us': mediaOutPointUs,
      if (speed != null) 'speed': speed,
      if (opacity != null) 'opacity': opacity,
      if (blendMode != null) 'blend_mode': blendMode,
      if (labelColorIndex != null) 'label_color_index': labelColorIndex,
      if (isVideoLinked != null) 'is_video_linked': isVideoLinked,
      if (isAudioLinked != null) 'is_audio_linked': isAudioLinked,
      if (isMuted != null) 'is_muted': isMuted,
      if (isLocked != null) 'is_locked': isLocked,
      if (name != null) 'name': name,
      if (transitionInId != null) 'transition_in_id': transitionInId,
      if (transitionOutId != null) 'transition_out_id': transitionOutId,
      if (transitionInDurationUs != null)
        'transition_in_duration_us': transitionInDurationUs,
      if (transitionOutDurationUs != null)
        'transition_out_duration_us': transitionOutDurationUs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClipsCompanion copyWith({
    Value<String>? id,
    Value<String>? trackId,
    Value<String>? mediaId,
    Value<String>? type,
    Value<int>? startOnTimelineUs,
    Value<int>? endOnTimelineUs,
    Value<int>? mediaInPointUs,
    Value<int>? mediaOutPointUs,
    Value<double>? speed,
    Value<double>? opacity,
    Value<String>? blendMode,
    Value<int>? labelColorIndex,
    Value<bool>? isVideoLinked,
    Value<bool>? isAudioLinked,
    Value<bool>? isMuted,
    Value<bool>? isLocked,
    Value<String>? name,
    Value<String?>? transitionInId,
    Value<String?>? transitionOutId,
    Value<int>? transitionInDurationUs,
    Value<int>? transitionOutDurationUs,
    Value<int>? rowid,
  }) {
    return ClipsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      mediaId: mediaId ?? this.mediaId,
      type: type ?? this.type,
      startOnTimelineUs: startOnTimelineUs ?? this.startOnTimelineUs,
      endOnTimelineUs: endOnTimelineUs ?? this.endOnTimelineUs,
      mediaInPointUs: mediaInPointUs ?? this.mediaInPointUs,
      mediaOutPointUs: mediaOutPointUs ?? this.mediaOutPointUs,
      speed: speed ?? this.speed,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      labelColorIndex: labelColorIndex ?? this.labelColorIndex,
      isVideoLinked: isVideoLinked ?? this.isVideoLinked,
      isAudioLinked: isAudioLinked ?? this.isAudioLinked,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      name: name ?? this.name,
      transitionInId: transitionInId ?? this.transitionInId,
      transitionOutId: transitionOutId ?? this.transitionOutId,
      transitionInDurationUs:
          transitionInDurationUs ?? this.transitionInDurationUs,
      transitionOutDurationUs:
          transitionOutDurationUs ?? this.transitionOutDurationUs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startOnTimelineUs.present) {
      map['start_on_timeline_us'] = Variable<int>(startOnTimelineUs.value);
    }
    if (endOnTimelineUs.present) {
      map['end_on_timeline_us'] = Variable<int>(endOnTimelineUs.value);
    }
    if (mediaInPointUs.present) {
      map['media_in_point_us'] = Variable<int>(mediaInPointUs.value);
    }
    if (mediaOutPointUs.present) {
      map['media_out_point_us'] = Variable<int>(mediaOutPointUs.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (opacity.present) {
      map['opacity'] = Variable<double>(opacity.value);
    }
    if (blendMode.present) {
      map['blend_mode'] = Variable<String>(blendMode.value);
    }
    if (labelColorIndex.present) {
      map['label_color_index'] = Variable<int>(labelColorIndex.value);
    }
    if (isVideoLinked.present) {
      map['is_video_linked'] = Variable<bool>(isVideoLinked.value);
    }
    if (isAudioLinked.present) {
      map['is_audio_linked'] = Variable<bool>(isAudioLinked.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (transitionInId.present) {
      map['transition_in_id'] = Variable<String>(transitionInId.value);
    }
    if (transitionOutId.present) {
      map['transition_out_id'] = Variable<String>(transitionOutId.value);
    }
    if (transitionInDurationUs.present) {
      map['transition_in_duration_us'] = Variable<int>(
        transitionInDurationUs.value,
      );
    }
    if (transitionOutDurationUs.present) {
      map['transition_out_duration_us'] = Variable<int>(
        transitionOutDurationUs.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClipsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('mediaId: $mediaId, ')
          ..write('type: $type, ')
          ..write('startOnTimelineUs: $startOnTimelineUs, ')
          ..write('endOnTimelineUs: $endOnTimelineUs, ')
          ..write('mediaInPointUs: $mediaInPointUs, ')
          ..write('mediaOutPointUs: $mediaOutPointUs, ')
          ..write('speed: $speed, ')
          ..write('opacity: $opacity, ')
          ..write('blendMode: $blendMode, ')
          ..write('labelColorIndex: $labelColorIndex, ')
          ..write('isVideoLinked: $isVideoLinked, ')
          ..write('isAudioLinked: $isAudioLinked, ')
          ..write('isMuted: $isMuted, ')
          ..write('isLocked: $isLocked, ')
          ..write('name: $name, ')
          ..write('transitionInId: $transitionInId, ')
          ..write('transitionOutId: $transitionOutId, ')
          ..write('transitionInDurationUs: $transitionInDurationUs, ')
          ..write('transitionOutDurationUs: $transitionOutDurationUs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyframesTable extends Keyframes
    with TableInfo<$KeyframesTable, Keyframe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyframesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clipIdMeta = const VerificationMeta('clipId');
  @override
  late final GeneratedColumn<String> clipId = GeneratedColumn<String>(
    'clip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _parameterIdMeta = const VerificationMeta(
    'parameterId',
  );
  @override
  late final GeneratedColumn<String> parameterId = GeneratedColumn<String>(
    'parameter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeUsMeta = const VerificationMeta('timeUs');
  @override
  late final GeneratedColumn<int> timeUs = GeneratedColumn<int>(
    'time_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interpolationMeta = const VerificationMeta(
    'interpolation',
  );
  @override
  late final GeneratedColumn<String> interpolation = GeneratedColumn<String>(
    'interpolation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('linear'),
  );
  static const VerificationMeta _inTangentXMeta = const VerificationMeta(
    'inTangentX',
  );
  @override
  late final GeneratedColumn<double> inTangentX = GeneratedColumn<double>(
    'in_tangent_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _inTangentYMeta = const VerificationMeta(
    'inTangentY',
  );
  @override
  late final GeneratedColumn<double> inTangentY = GeneratedColumn<double>(
    'in_tangent_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _outTangentXMeta = const VerificationMeta(
    'outTangentX',
  );
  @override
  late final GeneratedColumn<double> outTangentX = GeneratedColumn<double>(
    'out_tangent_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _outTangentYMeta = const VerificationMeta(
    'outTangentY',
  );
  @override
  late final GeneratedColumn<double> outTangentY = GeneratedColumn<double>(
    'out_tangent_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clipId,
    parameterId,
    timeUs,
    value,
    interpolation,
    inTangentX,
    inTangentY,
    outTangentX,
    outTangentY,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'keyframes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Keyframe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('clip_id')) {
      context.handle(
        _clipIdMeta,
        clipId.isAcceptableOrUnknown(data['clip_id']!, _clipIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clipIdMeta);
    }
    if (data.containsKey('parameter_id')) {
      context.handle(
        _parameterIdMeta,
        parameterId.isAcceptableOrUnknown(
          data['parameter_id']!,
          _parameterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parameterIdMeta);
    }
    if (data.containsKey('time_us')) {
      context.handle(
        _timeUsMeta,
        timeUs.isAcceptableOrUnknown(data['time_us']!, _timeUsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeUsMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('interpolation')) {
      context.handle(
        _interpolationMeta,
        interpolation.isAcceptableOrUnknown(
          data['interpolation']!,
          _interpolationMeta,
        ),
      );
    }
    if (data.containsKey('in_tangent_x')) {
      context.handle(
        _inTangentXMeta,
        inTangentX.isAcceptableOrUnknown(
          data['in_tangent_x']!,
          _inTangentXMeta,
        ),
      );
    }
    if (data.containsKey('in_tangent_y')) {
      context.handle(
        _inTangentYMeta,
        inTangentY.isAcceptableOrUnknown(
          data['in_tangent_y']!,
          _inTangentYMeta,
        ),
      );
    }
    if (data.containsKey('out_tangent_x')) {
      context.handle(
        _outTangentXMeta,
        outTangentX.isAcceptableOrUnknown(
          data['out_tangent_x']!,
          _outTangentXMeta,
        ),
      );
    }
    if (data.containsKey('out_tangent_y')) {
      context.handle(
        _outTangentYMeta,
        outTangentY.isAcceptableOrUnknown(
          data['out_tangent_y']!,
          _outTangentYMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Keyframe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Keyframe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clip_id'],
      )!,
      parameterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parameter_id'],
      )!,
      timeUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_us'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      interpolation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interpolation'],
      )!,
      inTangentX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}in_tangent_x'],
      )!,
      inTangentY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}in_tangent_y'],
      )!,
      outTangentX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}out_tangent_x'],
      )!,
      outTangentY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}out_tangent_y'],
      )!,
    );
  }

  @override
  $KeyframesTable createAlias(String alias) {
    return $KeyframesTable(attachedDatabase, alias);
  }
}

class Keyframe extends DataClass implements Insertable<Keyframe> {
  final String id;
  final String clipId;
  final String parameterId;
  final int timeUs;
  final double value;
  final String interpolation;
  final double inTangentX;
  final double inTangentY;
  final double outTangentX;
  final double outTangentY;
  const Keyframe({
    required this.id,
    required this.clipId,
    required this.parameterId,
    required this.timeUs,
    required this.value,
    required this.interpolation,
    required this.inTangentX,
    required this.inTangentY,
    required this.outTangentX,
    required this.outTangentY,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['clip_id'] = Variable<String>(clipId);
    map['parameter_id'] = Variable<String>(parameterId);
    map['time_us'] = Variable<int>(timeUs);
    map['value'] = Variable<double>(value);
    map['interpolation'] = Variable<String>(interpolation);
    map['in_tangent_x'] = Variable<double>(inTangentX);
    map['in_tangent_y'] = Variable<double>(inTangentY);
    map['out_tangent_x'] = Variable<double>(outTangentX);
    map['out_tangent_y'] = Variable<double>(outTangentY);
    return map;
  }

  KeyframesCompanion toCompanion(bool nullToAbsent) {
    return KeyframesCompanion(
      id: Value(id),
      clipId: Value(clipId),
      parameterId: Value(parameterId),
      timeUs: Value(timeUs),
      value: Value(value),
      interpolation: Value(interpolation),
      inTangentX: Value(inTangentX),
      inTangentY: Value(inTangentY),
      outTangentX: Value(outTangentX),
      outTangentY: Value(outTangentY),
    );
  }

  factory Keyframe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Keyframe(
      id: serializer.fromJson<String>(json['id']),
      clipId: serializer.fromJson<String>(json['clipId']),
      parameterId: serializer.fromJson<String>(json['parameterId']),
      timeUs: serializer.fromJson<int>(json['timeUs']),
      value: serializer.fromJson<double>(json['value']),
      interpolation: serializer.fromJson<String>(json['interpolation']),
      inTangentX: serializer.fromJson<double>(json['inTangentX']),
      inTangentY: serializer.fromJson<double>(json['inTangentY']),
      outTangentX: serializer.fromJson<double>(json['outTangentX']),
      outTangentY: serializer.fromJson<double>(json['outTangentY']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clipId': serializer.toJson<String>(clipId),
      'parameterId': serializer.toJson<String>(parameterId),
      'timeUs': serializer.toJson<int>(timeUs),
      'value': serializer.toJson<double>(value),
      'interpolation': serializer.toJson<String>(interpolation),
      'inTangentX': serializer.toJson<double>(inTangentX),
      'inTangentY': serializer.toJson<double>(inTangentY),
      'outTangentX': serializer.toJson<double>(outTangentX),
      'outTangentY': serializer.toJson<double>(outTangentY),
    };
  }

  Keyframe copyWith({
    String? id,
    String? clipId,
    String? parameterId,
    int? timeUs,
    double? value,
    String? interpolation,
    double? inTangentX,
    double? inTangentY,
    double? outTangentX,
    double? outTangentY,
  }) => Keyframe(
    id: id ?? this.id,
    clipId: clipId ?? this.clipId,
    parameterId: parameterId ?? this.parameterId,
    timeUs: timeUs ?? this.timeUs,
    value: value ?? this.value,
    interpolation: interpolation ?? this.interpolation,
    inTangentX: inTangentX ?? this.inTangentX,
    inTangentY: inTangentY ?? this.inTangentY,
    outTangentX: outTangentX ?? this.outTangentX,
    outTangentY: outTangentY ?? this.outTangentY,
  );
  Keyframe copyWithCompanion(KeyframesCompanion data) {
    return Keyframe(
      id: data.id.present ? data.id.value : this.id,
      clipId: data.clipId.present ? data.clipId.value : this.clipId,
      parameterId: data.parameterId.present
          ? data.parameterId.value
          : this.parameterId,
      timeUs: data.timeUs.present ? data.timeUs.value : this.timeUs,
      value: data.value.present ? data.value.value : this.value,
      interpolation: data.interpolation.present
          ? data.interpolation.value
          : this.interpolation,
      inTangentX: data.inTangentX.present
          ? data.inTangentX.value
          : this.inTangentX,
      inTangentY: data.inTangentY.present
          ? data.inTangentY.value
          : this.inTangentY,
      outTangentX: data.outTangentX.present
          ? data.outTangentX.value
          : this.outTangentX,
      outTangentY: data.outTangentY.present
          ? data.outTangentY.value
          : this.outTangentY,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Keyframe(')
          ..write('id: $id, ')
          ..write('clipId: $clipId, ')
          ..write('parameterId: $parameterId, ')
          ..write('timeUs: $timeUs, ')
          ..write('value: $value, ')
          ..write('interpolation: $interpolation, ')
          ..write('inTangentX: $inTangentX, ')
          ..write('inTangentY: $inTangentY, ')
          ..write('outTangentX: $outTangentX, ')
          ..write('outTangentY: $outTangentY')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clipId,
    parameterId,
    timeUs,
    value,
    interpolation,
    inTangentX,
    inTangentY,
    outTangentX,
    outTangentY,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Keyframe &&
          other.id == this.id &&
          other.clipId == this.clipId &&
          other.parameterId == this.parameterId &&
          other.timeUs == this.timeUs &&
          other.value == this.value &&
          other.interpolation == this.interpolation &&
          other.inTangentX == this.inTangentX &&
          other.inTangentY == this.inTangentY &&
          other.outTangentX == this.outTangentX &&
          other.outTangentY == this.outTangentY);
}

class KeyframesCompanion extends UpdateCompanion<Keyframe> {
  final Value<String> id;
  final Value<String> clipId;
  final Value<String> parameterId;
  final Value<int> timeUs;
  final Value<double> value;
  final Value<String> interpolation;
  final Value<double> inTangentX;
  final Value<double> inTangentY;
  final Value<double> outTangentX;
  final Value<double> outTangentY;
  final Value<int> rowid;
  const KeyframesCompanion({
    this.id = const Value.absent(),
    this.clipId = const Value.absent(),
    this.parameterId = const Value.absent(),
    this.timeUs = const Value.absent(),
    this.value = const Value.absent(),
    this.interpolation = const Value.absent(),
    this.inTangentX = const Value.absent(),
    this.inTangentY = const Value.absent(),
    this.outTangentX = const Value.absent(),
    this.outTangentY = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyframesCompanion.insert({
    required String id,
    required String clipId,
    required String parameterId,
    required int timeUs,
    required double value,
    this.interpolation = const Value.absent(),
    this.inTangentX = const Value.absent(),
    this.inTangentY = const Value.absent(),
    this.outTangentX = const Value.absent(),
    this.outTangentY = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clipId = Value(clipId),
       parameterId = Value(parameterId),
       timeUs = Value(timeUs),
       value = Value(value);
  static Insertable<Keyframe> custom({
    Expression<String>? id,
    Expression<String>? clipId,
    Expression<String>? parameterId,
    Expression<int>? timeUs,
    Expression<double>? value,
    Expression<String>? interpolation,
    Expression<double>? inTangentX,
    Expression<double>? inTangentY,
    Expression<double>? outTangentX,
    Expression<double>? outTangentY,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clipId != null) 'clip_id': clipId,
      if (parameterId != null) 'parameter_id': parameterId,
      if (timeUs != null) 'time_us': timeUs,
      if (value != null) 'value': value,
      if (interpolation != null) 'interpolation': interpolation,
      if (inTangentX != null) 'in_tangent_x': inTangentX,
      if (inTangentY != null) 'in_tangent_y': inTangentY,
      if (outTangentX != null) 'out_tangent_x': outTangentX,
      if (outTangentY != null) 'out_tangent_y': outTangentY,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyframesCompanion copyWith({
    Value<String>? id,
    Value<String>? clipId,
    Value<String>? parameterId,
    Value<int>? timeUs,
    Value<double>? value,
    Value<String>? interpolation,
    Value<double>? inTangentX,
    Value<double>? inTangentY,
    Value<double>? outTangentX,
    Value<double>? outTangentY,
    Value<int>? rowid,
  }) {
    return KeyframesCompanion(
      id: id ?? this.id,
      clipId: clipId ?? this.clipId,
      parameterId: parameterId ?? this.parameterId,
      timeUs: timeUs ?? this.timeUs,
      value: value ?? this.value,
      interpolation: interpolation ?? this.interpolation,
      inTangentX: inTangentX ?? this.inTangentX,
      inTangentY: inTangentY ?? this.inTangentY,
      outTangentX: outTangentX ?? this.outTangentX,
      outTangentY: outTangentY ?? this.outTangentY,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clipId.present) {
      map['clip_id'] = Variable<String>(clipId.value);
    }
    if (parameterId.present) {
      map['parameter_id'] = Variable<String>(parameterId.value);
    }
    if (timeUs.present) {
      map['time_us'] = Variable<int>(timeUs.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (interpolation.present) {
      map['interpolation'] = Variable<String>(interpolation.value);
    }
    if (inTangentX.present) {
      map['in_tangent_x'] = Variable<double>(inTangentX.value);
    }
    if (inTangentY.present) {
      map['in_tangent_y'] = Variable<double>(inTangentY.value);
    }
    if (outTangentX.present) {
      map['out_tangent_x'] = Variable<double>(outTangentX.value);
    }
    if (outTangentY.present) {
      map['out_tangent_y'] = Variable<double>(outTangentY.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyframesCompanion(')
          ..write('id: $id, ')
          ..write('clipId: $clipId, ')
          ..write('parameterId: $parameterId, ')
          ..write('timeUs: $timeUs, ')
          ..write('value: $value, ')
          ..write('interpolation: $interpolation, ')
          ..write('inTangentX: $inTangentX, ')
          ..write('inTangentY: $inTangentY, ')
          ..write('outTangentX: $outTangentX, ')
          ..write('outTangentY: $outTangentY, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EffectInstancesTable extends EffectInstances
    with TableInfo<$EffectInstancesTable, EffectInstanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EffectInstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clipIdMeta = const VerificationMeta('clipId');
  @override
  late final GeneratedColumn<String> clipId = GeneratedColumn<String>(
    'clip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _effectTypeMeta = const VerificationMeta(
    'effectType',
  );
  @override
  late final GeneratedColumn<String> effectType = GeneratedColumn<String>(
    'effect_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stackIndexMeta = const VerificationMeta(
    'stackIndex',
  );
  @override
  late final GeneratedColumn<int> stackIndex = GeneratedColumn<int>(
    'stack_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _parametersJsonMeta = const VerificationMeta(
    'parametersJson',
  );
  @override
  late final GeneratedColumn<String> parametersJson = GeneratedColumn<String>(
    'parameters_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clipId,
    effectType,
    stackIndex,
    isEnabled,
    parametersJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'effect_instances';
  @override
  VerificationContext validateIntegrity(
    Insertable<EffectInstanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('clip_id')) {
      context.handle(
        _clipIdMeta,
        clipId.isAcceptableOrUnknown(data['clip_id']!, _clipIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clipIdMeta);
    }
    if (data.containsKey('effect_type')) {
      context.handle(
        _effectTypeMeta,
        effectType.isAcceptableOrUnknown(data['effect_type']!, _effectTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_effectTypeMeta);
    }
    if (data.containsKey('stack_index')) {
      context.handle(
        _stackIndexMeta,
        stackIndex.isAcceptableOrUnknown(data['stack_index']!, _stackIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_stackIndexMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('parameters_json')) {
      context.handle(
        _parametersJsonMeta,
        parametersJson.isAcceptableOrUnknown(
          data['parameters_json']!,
          _parametersJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EffectInstanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EffectInstanceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clip_id'],
      )!,
      effectType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effect_type'],
      )!,
      stackIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stack_index'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      parametersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parameters_json'],
      )!,
    );
  }

  @override
  $EffectInstancesTable createAlias(String alias) {
    return $EffectInstancesTable(attachedDatabase, alias);
  }
}

class EffectInstanceRow extends DataClass
    implements Insertable<EffectInstanceRow> {
  final String id;
  final String clipId;
  final String effectType;
  final int stackIndex;
  final bool isEnabled;
  final String parametersJson;
  const EffectInstanceRow({
    required this.id,
    required this.clipId,
    required this.effectType,
    required this.stackIndex,
    required this.isEnabled,
    required this.parametersJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['clip_id'] = Variable<String>(clipId);
    map['effect_type'] = Variable<String>(effectType);
    map['stack_index'] = Variable<int>(stackIndex);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['parameters_json'] = Variable<String>(parametersJson);
    return map;
  }

  EffectInstancesCompanion toCompanion(bool nullToAbsent) {
    return EffectInstancesCompanion(
      id: Value(id),
      clipId: Value(clipId),
      effectType: Value(effectType),
      stackIndex: Value(stackIndex),
      isEnabled: Value(isEnabled),
      parametersJson: Value(parametersJson),
    );
  }

  factory EffectInstanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EffectInstanceRow(
      id: serializer.fromJson<String>(json['id']),
      clipId: serializer.fromJson<String>(json['clipId']),
      effectType: serializer.fromJson<String>(json['effectType']),
      stackIndex: serializer.fromJson<int>(json['stackIndex']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      parametersJson: serializer.fromJson<String>(json['parametersJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clipId': serializer.toJson<String>(clipId),
      'effectType': serializer.toJson<String>(effectType),
      'stackIndex': serializer.toJson<int>(stackIndex),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'parametersJson': serializer.toJson<String>(parametersJson),
    };
  }

  EffectInstanceRow copyWith({
    String? id,
    String? clipId,
    String? effectType,
    int? stackIndex,
    bool? isEnabled,
    String? parametersJson,
  }) => EffectInstanceRow(
    id: id ?? this.id,
    clipId: clipId ?? this.clipId,
    effectType: effectType ?? this.effectType,
    stackIndex: stackIndex ?? this.stackIndex,
    isEnabled: isEnabled ?? this.isEnabled,
    parametersJson: parametersJson ?? this.parametersJson,
  );
  EffectInstanceRow copyWithCompanion(EffectInstancesCompanion data) {
    return EffectInstanceRow(
      id: data.id.present ? data.id.value : this.id,
      clipId: data.clipId.present ? data.clipId.value : this.clipId,
      effectType: data.effectType.present
          ? data.effectType.value
          : this.effectType,
      stackIndex: data.stackIndex.present
          ? data.stackIndex.value
          : this.stackIndex,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      parametersJson: data.parametersJson.present
          ? data.parametersJson.value
          : this.parametersJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EffectInstanceRow(')
          ..write('id: $id, ')
          ..write('clipId: $clipId, ')
          ..write('effectType: $effectType, ')
          ..write('stackIndex: $stackIndex, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('parametersJson: $parametersJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clipId,
    effectType,
    stackIndex,
    isEnabled,
    parametersJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EffectInstanceRow &&
          other.id == this.id &&
          other.clipId == this.clipId &&
          other.effectType == this.effectType &&
          other.stackIndex == this.stackIndex &&
          other.isEnabled == this.isEnabled &&
          other.parametersJson == this.parametersJson);
}

class EffectInstancesCompanion extends UpdateCompanion<EffectInstanceRow> {
  final Value<String> id;
  final Value<String> clipId;
  final Value<String> effectType;
  final Value<int> stackIndex;
  final Value<bool> isEnabled;
  final Value<String> parametersJson;
  final Value<int> rowid;
  const EffectInstancesCompanion({
    this.id = const Value.absent(),
    this.clipId = const Value.absent(),
    this.effectType = const Value.absent(),
    this.stackIndex = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.parametersJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EffectInstancesCompanion.insert({
    required String id,
    required String clipId,
    required String effectType,
    required int stackIndex,
    this.isEnabled = const Value.absent(),
    this.parametersJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clipId = Value(clipId),
       effectType = Value(effectType),
       stackIndex = Value(stackIndex);
  static Insertable<EffectInstanceRow> custom({
    Expression<String>? id,
    Expression<String>? clipId,
    Expression<String>? effectType,
    Expression<int>? stackIndex,
    Expression<bool>? isEnabled,
    Expression<String>? parametersJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clipId != null) 'clip_id': clipId,
      if (effectType != null) 'effect_type': effectType,
      if (stackIndex != null) 'stack_index': stackIndex,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (parametersJson != null) 'parameters_json': parametersJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EffectInstancesCompanion copyWith({
    Value<String>? id,
    Value<String>? clipId,
    Value<String>? effectType,
    Value<int>? stackIndex,
    Value<bool>? isEnabled,
    Value<String>? parametersJson,
    Value<int>? rowid,
  }) {
    return EffectInstancesCompanion(
      id: id ?? this.id,
      clipId: clipId ?? this.clipId,
      effectType: effectType ?? this.effectType,
      stackIndex: stackIndex ?? this.stackIndex,
      isEnabled: isEnabled ?? this.isEnabled,
      parametersJson: parametersJson ?? this.parametersJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clipId.present) {
      map['clip_id'] = Variable<String>(clipId.value);
    }
    if (effectType.present) {
      map['effect_type'] = Variable<String>(effectType.value);
    }
    if (stackIndex.present) {
      map['stack_index'] = Variable<int>(stackIndex.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (parametersJson.present) {
      map['parameters_json'] = Variable<String>(parametersJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EffectInstancesCompanion(')
          ..write('id: $id, ')
          ..write('clipId: $clipId, ')
          ..write('effectType: $effectType, ')
          ..write('stackIndex: $stackIndex, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('parametersJson: $parametersJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectSettingsTable extends ProjectSettings
    with TableInfo<$ProjectSettingsTable, ProjectSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
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
  List<GeneratedColumn> get $columns => [projectId, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
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
  Set<GeneratedColumn> get $primaryKey => {projectId, key};
  @override
  ProjectSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectSetting(
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ProjectSettingsTable createAlias(String alias) {
    return $ProjectSettingsTable(attachedDatabase, alias);
  }
}

class ProjectSetting extends DataClass implements Insertable<ProjectSetting> {
  final String projectId;
  final String key;
  final String value;
  const ProjectSetting({
    required this.projectId,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<String>(projectId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ProjectSettingsCompanion toCompanion(bool nullToAbsent) {
    return ProjectSettingsCompanion(
      projectId: Value(projectId),
      key: Value(key),
      value: Value(value),
    );
  }

  factory ProjectSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectSetting(
      projectId: serializer.fromJson<String>(json['projectId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'projectId': serializer.toJson<String>(projectId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  ProjectSetting copyWith({String? projectId, String? key, String? value}) =>
      ProjectSetting(
        projectId: projectId ?? this.projectId,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  ProjectSetting copyWithCompanion(ProjectSettingsCompanion data) {
    return ProjectSetting(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectSetting(')
          ..write('projectId: $projectId, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(projectId, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectSetting &&
          other.projectId == this.projectId &&
          other.key == this.key &&
          other.value == this.value);
}

class ProjectSettingsCompanion extends UpdateCompanion<ProjectSetting> {
  final Value<String> projectId;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ProjectSettingsCompanion({
    this.projectId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectSettingsCompanion.insert({
    required String projectId,
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       key = Value(key),
       value = Value(value);
  static Insertable<ProjectSetting> custom({
    Expression<String>? projectId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectSettingsCompanion copyWith({
    Value<String>? projectId,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ProjectSettingsCompanion(
      projectId: projectId ?? this.projectId,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
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
    return (StringBuffer('ProjectSettingsCompanion(')
          ..write('projectId: $projectId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $MediaAssetsTable mediaAssets = $MediaAssetsTable(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $ClipsTable clips = $ClipsTable(this);
  late final $KeyframesTable keyframes = $KeyframesTable(this);
  late final $EffectInstancesTable effectInstances = $EffectInstancesTable(
    this,
  );
  late final $ProjectSettingsTable projectSettings = $ProjectSettingsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    mediaAssets,
    tracks,
    clips,
    keyframes,
    effectInstances,
    projectSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_assets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tracks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('clips', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'clips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('keyframes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'clips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('effect_instances', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('project_settings', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      required String name,
      required String filePath,
      Value<String> description,
      Value<String> version,
      Value<int> compWidth,
      Value<int> compHeight,
      Value<double> compFrameRate,
      Value<int> compDurationUs,
      Value<int> compBackgroundColor,
      required DateTime dateCreated,
      required DateTime dateModified,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> filePath,
      Value<String> description,
      Value<String> version,
      Value<int> compWidth,
      Value<int> compHeight,
      Value<double> compFrameRate,
      Value<int> compDurationUs,
      Value<int> compBackgroundColor,
      Value<DateTime> dateCreated,
      Value<DateTime> dateModified,
      Value<int> rowid,
    });

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaAssetsTable, List<MediaAssetRow>>
  _mediaAssetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaAssets,
    aliasName: $_aliasNameGenerator(db.projects.id, db.mediaAssets.projectId),
  );

  $$MediaAssetsTableProcessedTableManager get mediaAssetsRefs {
    final manager = $$MediaAssetsTableTableManager(
      $_db,
      $_db.mediaAssets,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TracksTable, List<Track>> _tracksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tracks,
    aliasName: $_aliasNameGenerator(db.projects.id, db.tracks.projectId),
  );

  $$TracksTableProcessedTableManager get tracksRefs {
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProjectSettingsTable, List<ProjectSetting>>
  _projectSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.projectSettings,
    aliasName: $_aliasNameGenerator(
      db.projects.id,
      db.projectSettings.projectId,
    ),
  );

  $$ProjectSettingsTableProcessedTableManager get projectSettingsRefs {
    final manager = $$ProjectSettingsTableTableManager(
      $_db,
      $_db.projectSettings,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _projectSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get compWidth => $composableBuilder(
    column: $table.compWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get compHeight => $composableBuilder(
    column: $table.compHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get compFrameRate => $composableBuilder(
    column: $table.compFrameRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get compDurationUs => $composableBuilder(
    column: $table.compDurationUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get compBackgroundColor => $composableBuilder(
    column: $table.compBackgroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaAssetsRefs(
    Expression<bool> Function($$MediaAssetsTableFilterComposer f) f,
  ) {
    final $$MediaAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableFilterComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tracksRefs(
    Expression<bool> Function($$TracksTableFilterComposer f) f,
  ) {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> projectSettingsRefs(
    Expression<bool> Function($$ProjectSettingsTableFilterComposer f) f,
  ) {
    final $$ProjectSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectSettings,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectSettingsTableFilterComposer(
            $db: $db,
            $table: $db.projectSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get compWidth => $composableBuilder(
    column: $table.compWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get compHeight => $composableBuilder(
    column: $table.compHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get compFrameRate => $composableBuilder(
    column: $table.compFrameRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get compDurationUs => $composableBuilder(
    column: $table.compDurationUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get compBackgroundColor => $composableBuilder(
    column: $table.compBackgroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
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

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get compWidth =>
      $composableBuilder(column: $table.compWidth, builder: (column) => column);

  GeneratedColumn<int> get compHeight => $composableBuilder(
    column: $table.compHeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get compFrameRate => $composableBuilder(
    column: $table.compFrameRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get compDurationUs => $composableBuilder(
    column: $table.compDurationUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get compBackgroundColor => $composableBuilder(
    column: $table.compBackgroundColor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateCreated => $composableBuilder(
    column: $table.dateCreated,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => column,
  );

  Expression<T> mediaAssetsRefs<T extends Object>(
    Expression<T> Function($$MediaAssetsTableAnnotationComposer a) f,
  ) {
    final $$MediaAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tracksRefs<T extends Object>(
    Expression<T> Function($$TracksTableAnnotationComposer a) f,
  ) {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> projectSettingsRefs<T extends Object>(
    Expression<T> Function($$ProjectSettingsTableAnnotationComposer a) f,
  ) {
    final $$ProjectSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectSettings,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.projectSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({
            bool mediaAssetsRefs,
            bool tracksRefs,
            bool projectSettingsRefs,
          })
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<int> compWidth = const Value.absent(),
                Value<int> compHeight = const Value.absent(),
                Value<double> compFrameRate = const Value.absent(),
                Value<int> compDurationUs = const Value.absent(),
                Value<int> compBackgroundColor = const Value.absent(),
                Value<DateTime> dateCreated = const Value.absent(),
                Value<DateTime> dateModified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                filePath: filePath,
                description: description,
                version: version,
                compWidth: compWidth,
                compHeight: compHeight,
                compFrameRate: compFrameRate,
                compDurationUs: compDurationUs,
                compBackgroundColor: compBackgroundColor,
                dateCreated: dateCreated,
                dateModified: dateModified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String filePath,
                Value<String> description = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<int> compWidth = const Value.absent(),
                Value<int> compHeight = const Value.absent(),
                Value<double> compFrameRate = const Value.absent(),
                Value<int> compDurationUs = const Value.absent(),
                Value<int> compBackgroundColor = const Value.absent(),
                required DateTime dateCreated,
                required DateTime dateModified,
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                filePath: filePath,
                description: description,
                version: version,
                compWidth: compWidth,
                compHeight: compHeight,
                compFrameRate: compFrameRate,
                compDurationUs: compDurationUs,
                compBackgroundColor: compBackgroundColor,
                dateCreated: dateCreated,
                dateModified: dateModified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                mediaAssetsRefs = false,
                tracksRefs = false,
                projectSettingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaAssetsRefs) db.mediaAssets,
                    if (tracksRefs) db.tracks,
                    if (projectSettingsRefs) db.projectSettings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaAssetsRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          MediaAssetRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._mediaAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tracksRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          Track
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._tracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).tracksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (projectSettingsRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          ProjectSetting
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._projectSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).projectSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({
        bool mediaAssetsRefs,
        bool tracksRefs,
        bool projectSettingsRefs,
      })
    >;
typedef $$MediaAssetsTableCreateCompanionBuilder =
    MediaAssetsCompanion Function({
      required String id,
      required String projectId,
      required String filePath,
      required String name,
      required String type,
      Value<int> durationUs,
      Value<int> width,
      Value<int> height,
      Value<double> frameRate,
      Value<int> sampleRate,
      Value<int> channels,
      Value<String> videoCodec,
      Value<String> audioCodec,
      Value<int> bitRate,
      Value<int> fileSize,
      Value<String> colorSpace,
      Value<String?> proxyPath,
      Value<String?> thumbnailPath,
      Value<String?> binId,
      required DateTime dateAdded,
      Value<int> rowid,
    });
typedef $$MediaAssetsTableUpdateCompanionBuilder =
    MediaAssetsCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> filePath,
      Value<String> name,
      Value<String> type,
      Value<int> durationUs,
      Value<int> width,
      Value<int> height,
      Value<double> frameRate,
      Value<int> sampleRate,
      Value<int> channels,
      Value<String> videoCodec,
      Value<String> audioCodec,
      Value<int> bitRate,
      Value<int> fileSize,
      Value<String> colorSpace,
      Value<String?> proxyPath,
      Value<String?> thumbnailPath,
      Value<String?> binId,
      Value<DateTime> dateAdded,
      Value<int> rowid,
    });

final class $$MediaAssetsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaAssetsTable, MediaAssetRow> {
  $$MediaAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
        $_aliasNameGenerator(db.mediaAssets.projectId, db.projects.id),
      );

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ClipsTable, List<Clip>> _clipsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.clips,
    aliasName: $_aliasNameGenerator(db.mediaAssets.id, db.clips.mediaId),
  );

  $$ClipsTableProcessedTableManager get clipsRefs {
    final manager = $$ClipsTableTableManager(
      $_db,
      $_db.clips,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_clipsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationUs => $composableBuilder(
    column: $table.durationUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frameRate => $composableBuilder(
    column: $table.frameRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoCodec => $composableBuilder(
    column: $table.videoCodec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioCodec => $composableBuilder(
    column: $table.audioCodec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitRate => $composableBuilder(
    column: $table.bitRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorSpace => $composableBuilder(
    column: $table.colorSpace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proxyPath => $composableBuilder(
    column: $table.proxyPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get binId => $composableBuilder(
    column: $table.binId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> clipsRefs(
    Expression<bool> Function($$ClipsTableFilterComposer f) f,
  ) {
    final $$ClipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableFilterComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
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

  ColumnOrderings<int> get durationUs => $composableBuilder(
    column: $table.durationUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frameRate => $composableBuilder(
    column: $table.frameRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoCodec => $composableBuilder(
    column: $table.videoCodec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioCodec => $composableBuilder(
    column: $table.audioCodec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitRate => $composableBuilder(
    column: $table.bitRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorSpace => $composableBuilder(
    column: $table.colorSpace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proxyPath => $composableBuilder(
    column: $table.proxyPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get binId => $composableBuilder(
    column: $table.binId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get durationUs => $composableBuilder(
    column: $table.durationUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get frameRate =>
      $composableBuilder(column: $table.frameRate, builder: (column) => column);

  GeneratedColumn<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channels =>
      $composableBuilder(column: $table.channels, builder: (column) => column);

  GeneratedColumn<String> get videoCodec => $composableBuilder(
    column: $table.videoCodec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioCodec => $composableBuilder(
    column: $table.audioCodec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bitRate =>
      $composableBuilder(column: $table.bitRate, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get colorSpace => $composableBuilder(
    column: $table.colorSpace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get proxyPath =>
      $composableBuilder(column: $table.proxyPath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get binId =>
      $composableBuilder(column: $table.binId, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> clipsRefs<T extends Object>(
    Expression<T> Function($$ClipsTableAnnotationComposer a) f,
  ) {
    final $$ClipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableAnnotationComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaAssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaAssetsTable,
          MediaAssetRow,
          $$MediaAssetsTableFilterComposer,
          $$MediaAssetsTableOrderingComposer,
          $$MediaAssetsTableAnnotationComposer,
          $$MediaAssetsTableCreateCompanionBuilder,
          $$MediaAssetsTableUpdateCompanionBuilder,
          (MediaAssetRow, $$MediaAssetsTableReferences),
          MediaAssetRow,
          PrefetchHooks Function({bool projectId, bool clipsRefs})
        > {
  $$MediaAssetsTableTableManager(_$AppDatabase db, $MediaAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> durationUs = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<double> frameRate = const Value.absent(),
                Value<int> sampleRate = const Value.absent(),
                Value<int> channels = const Value.absent(),
                Value<String> videoCodec = const Value.absent(),
                Value<String> audioCodec = const Value.absent(),
                Value<int> bitRate = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> colorSpace = const Value.absent(),
                Value<String?> proxyPath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> binId = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaAssetsCompanion(
                id: id,
                projectId: projectId,
                filePath: filePath,
                name: name,
                type: type,
                durationUs: durationUs,
                width: width,
                height: height,
                frameRate: frameRate,
                sampleRate: sampleRate,
                channels: channels,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                bitRate: bitRate,
                fileSize: fileSize,
                colorSpace: colorSpace,
                proxyPath: proxyPath,
                thumbnailPath: thumbnailPath,
                binId: binId,
                dateAdded: dateAdded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String filePath,
                required String name,
                required String type,
                Value<int> durationUs = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<double> frameRate = const Value.absent(),
                Value<int> sampleRate = const Value.absent(),
                Value<int> channels = const Value.absent(),
                Value<String> videoCodec = const Value.absent(),
                Value<String> audioCodec = const Value.absent(),
                Value<int> bitRate = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> colorSpace = const Value.absent(),
                Value<String?> proxyPath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> binId = const Value.absent(),
                required DateTime dateAdded,
                Value<int> rowid = const Value.absent(),
              }) => MediaAssetsCompanion.insert(
                id: id,
                projectId: projectId,
                filePath: filePath,
                name: name,
                type: type,
                durationUs: durationUs,
                width: width,
                height: height,
                frameRate: frameRate,
                sampleRate: sampleRate,
                channels: channels,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                bitRate: bitRate,
                fileSize: fileSize,
                colorSpace: colorSpace,
                proxyPath: proxyPath,
                thumbnailPath: thumbnailPath,
                binId: binId,
                dateAdded: dateAdded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, clipsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (clipsRefs) db.clips],
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
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable: $$MediaAssetsTableReferences
                                    ._projectIdTable(db),
                                referencedColumn: $$MediaAssetsTableReferences
                                    ._projectIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (clipsRefs)
                    await $_getPrefetchedData<
                      MediaAssetRow,
                      $MediaAssetsTable,
                      Clip
                    >(
                      currentTable: table,
                      referencedTable: $$MediaAssetsTableReferences
                          ._clipsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MediaAssetsTableReferences(db, table, p0).clipsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.mediaId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MediaAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaAssetsTable,
      MediaAssetRow,
      $$MediaAssetsTableFilterComposer,
      $$MediaAssetsTableOrderingComposer,
      $$MediaAssetsTableAnnotationComposer,
      $$MediaAssetsTableCreateCompanionBuilder,
      $$MediaAssetsTableUpdateCompanionBuilder,
      (MediaAssetRow, $$MediaAssetsTableReferences),
      MediaAssetRow,
      PrefetchHooks Function({bool projectId, bool clipsRefs})
    >;
typedef $$TracksTableCreateCompanionBuilder =
    TracksCompanion Function({
      required String id,
      required String projectId,
      required String type,
      required int trackIndex,
      Value<String> name,
      Value<double> height,
      Value<bool> isMuted,
      Value<bool> isSoloed,
      Value<bool> isLocked,
      Value<bool> isVisible,
      Value<double> volume,
      Value<double> pan,
      Value<int> rowid,
    });
typedef $$TracksTableUpdateCompanionBuilder =
    TracksCompanion Function({
      Value<String> id,
      Value<String> projectId,
      Value<String> type,
      Value<int> trackIndex,
      Value<String> name,
      Value<double> height,
      Value<bool> isMuted,
      Value<bool> isSoloed,
      Value<bool> isLocked,
      Value<bool> isVisible,
      Value<double> volume,
      Value<double> pan,
      Value<int> rowid,
    });

final class $$TracksTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTable, Track> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) => db.projects
      .createAlias($_aliasNameGenerator(db.tracks.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ClipsTable, List<Clip>> _clipsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.clips,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.clips.trackId),
  );

  $$ClipsTableProcessedTableManager get clipsRefs {
    final manager = $$ClipsTableTableManager(
      $_db,
      $_db.clips,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_clipsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSoloed => $composableBuilder(
    column: $table.isSoloed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pan => $composableBuilder(
    column: $table.pan,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> clipsRefs(
    Expression<bool> Function($$ClipsTableFilterComposer f) f,
  ) {
    final $$ClipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableFilterComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
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

  ColumnOrderings<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSoloed => $composableBuilder(
    column: $table.isSoloed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pan => $composableBuilder(
    column: $table.pan,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get trackIndex => $composableBuilder(
    column: $table.trackIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<bool> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);

  GeneratedColumn<bool> get isSoloed =>
      $composableBuilder(column: $table.isSoloed, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<double> get pan =>
      $composableBuilder(column: $table.pan, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> clipsRefs<T extends Object>(
    Expression<T> Function($$ClipsTableAnnotationComposer a) f,
  ) {
    final $$ClipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableAnnotationComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          Track,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (Track, $$TracksTableReferences),
          Track,
          PrefetchHooks Function({bool projectId, bool clipsRefs})
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> trackIndex = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> isSoloed = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<double> pan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                projectId: projectId,
                type: type,
                trackIndex: trackIndex,
                name: name,
                height: height,
                isMuted: isMuted,
                isSoloed: isSoloed,
                isLocked: isLocked,
                isVisible: isVisible,
                volume: volume,
                pan: pan,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String type,
                required int trackIndex,
                Value<String> name = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> isSoloed = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<double> pan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                projectId: projectId,
                type: type,
                trackIndex: trackIndex,
                name: name,
                height: height,
                isMuted: isMuted,
                isSoloed: isSoloed,
                isLocked: isLocked,
                isVisible: isVisible,
                volume: volume,
                pan: pan,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TracksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, clipsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (clipsRefs) db.clips],
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
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable: $$TracksTableReferences
                                    ._projectIdTable(db),
                                referencedColumn: $$TracksTableReferences
                                    ._projectIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (clipsRefs)
                    await $_getPrefetchedData<Track, $TracksTable, Clip>(
                      currentTable: table,
                      referencedTable: $$TracksTableReferences._clipsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TracksTableReferences(db, table, p0).clipsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.trackId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      Track,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (Track, $$TracksTableReferences),
      Track,
      PrefetchHooks Function({bool projectId, bool clipsRefs})
    >;
typedef $$ClipsTableCreateCompanionBuilder =
    ClipsCompanion Function({
      required String id,
      required String trackId,
      required String mediaId,
      required String type,
      required int startOnTimelineUs,
      required int endOnTimelineUs,
      required int mediaInPointUs,
      required int mediaOutPointUs,
      Value<double> speed,
      Value<double> opacity,
      Value<String> blendMode,
      Value<int> labelColorIndex,
      Value<bool> isVideoLinked,
      Value<bool> isAudioLinked,
      Value<bool> isMuted,
      Value<bool> isLocked,
      Value<String> name,
      Value<String?> transitionInId,
      Value<String?> transitionOutId,
      Value<int> transitionInDurationUs,
      Value<int> transitionOutDurationUs,
      Value<int> rowid,
    });
typedef $$ClipsTableUpdateCompanionBuilder =
    ClipsCompanion Function({
      Value<String> id,
      Value<String> trackId,
      Value<String> mediaId,
      Value<String> type,
      Value<int> startOnTimelineUs,
      Value<int> endOnTimelineUs,
      Value<int> mediaInPointUs,
      Value<int> mediaOutPointUs,
      Value<double> speed,
      Value<double> opacity,
      Value<String> blendMode,
      Value<int> labelColorIndex,
      Value<bool> isVideoLinked,
      Value<bool> isAudioLinked,
      Value<bool> isMuted,
      Value<bool> isLocked,
      Value<String> name,
      Value<String?> transitionInId,
      Value<String?> transitionOutId,
      Value<int> transitionInDurationUs,
      Value<int> transitionOutDurationUs,
      Value<int> rowid,
    });

final class $$ClipsTableReferences
    extends BaseReferences<_$AppDatabase, $ClipsTable, Clip> {
  $$ClipsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.clips.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<String>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MediaAssetsTable _mediaIdTable(_$AppDatabase db) => db.mediaAssets
      .createAlias($_aliasNameGenerator(db.clips.mediaId, db.mediaAssets.id));

  $$MediaAssetsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaAssetsTableTableManager(
      $_db,
      $_db.mediaAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$KeyframesTable, List<Keyframe>>
  _keyframesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.keyframes,
    aliasName: $_aliasNameGenerator(db.clips.id, db.keyframes.clipId),
  );

  $$KeyframesTableProcessedTableManager get keyframesRefs {
    final manager = $$KeyframesTableTableManager(
      $_db,
      $_db.keyframes,
    ).filter((f) => f.clipId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_keyframesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EffectInstancesTable, List<EffectInstanceRow>>
  _effectInstancesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.effectInstances,
    aliasName: $_aliasNameGenerator(db.clips.id, db.effectInstances.clipId),
  );

  $$EffectInstancesTableProcessedTableManager get effectInstancesRefs {
    final manager = $$EffectInstancesTableTableManager(
      $_db,
      $_db.effectInstances,
    ).filter((f) => f.clipId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _effectInstancesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClipsTableFilterComposer extends Composer<_$AppDatabase, $ClipsTable> {
  $$ClipsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startOnTimelineUs => $composableBuilder(
    column: $table.startOnTimelineUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endOnTimelineUs => $composableBuilder(
    column: $table.endOnTimelineUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaInPointUs => $composableBuilder(
    column: $table.mediaInPointUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaOutPointUs => $composableBuilder(
    column: $table.mediaOutPointUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blendMode => $composableBuilder(
    column: $table.blendMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get labelColorIndex => $composableBuilder(
    column: $table.labelColorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVideoLinked => $composableBuilder(
    column: $table.isVideoLinked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAudioLinked => $composableBuilder(
    column: $table.isAudioLinked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transitionInId => $composableBuilder(
    column: $table.transitionInId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transitionOutId => $composableBuilder(
    column: $table.transitionOutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transitionInDurationUs => $composableBuilder(
    column: $table.transitionInDurationUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transitionOutDurationUs => $composableBuilder(
    column: $table.transitionOutDurationUs,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaAssetsTableFilterComposer get mediaId {
    final $$MediaAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableFilterComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> keyframesRefs(
    Expression<bool> Function($$KeyframesTableFilterComposer f) f,
  ) {
    final $$KeyframesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.keyframes,
      getReferencedColumn: (t) => t.clipId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeyframesTableFilterComposer(
            $db: $db,
            $table: $db.keyframes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> effectInstancesRefs(
    Expression<bool> Function($$EffectInstancesTableFilterComposer f) f,
  ) {
    final $$EffectInstancesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.effectInstances,
      getReferencedColumn: (t) => t.clipId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EffectInstancesTableFilterComposer(
            $db: $db,
            $table: $db.effectInstances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClipsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClipsTable> {
  $$ClipsTableOrderingComposer({
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

  ColumnOrderings<int> get startOnTimelineUs => $composableBuilder(
    column: $table.startOnTimelineUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endOnTimelineUs => $composableBuilder(
    column: $table.endOnTimelineUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaInPointUs => $composableBuilder(
    column: $table.mediaInPointUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaOutPointUs => $composableBuilder(
    column: $table.mediaOutPointUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blendMode => $composableBuilder(
    column: $table.blendMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get labelColorIndex => $composableBuilder(
    column: $table.labelColorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVideoLinked => $composableBuilder(
    column: $table.isVideoLinked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAudioLinked => $composableBuilder(
    column: $table.isAudioLinked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transitionInId => $composableBuilder(
    column: $table.transitionInId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transitionOutId => $composableBuilder(
    column: $table.transitionOutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transitionInDurationUs => $composableBuilder(
    column: $table.transitionInDurationUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transitionOutDurationUs => $composableBuilder(
    column: $table.transitionOutDurationUs,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaAssetsTableOrderingComposer get mediaId {
    final $$MediaAssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClipsTable> {
  $$ClipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get startOnTimelineUs => $composableBuilder(
    column: $table.startOnTimelineUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endOnTimelineUs => $composableBuilder(
    column: $table.endOnTimelineUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaInPointUs => $composableBuilder(
    column: $table.mediaInPointUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaOutPointUs => $composableBuilder(
    column: $table.mediaOutPointUs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get opacity =>
      $composableBuilder(column: $table.opacity, builder: (column) => column);

  GeneratedColumn<String> get blendMode =>
      $composableBuilder(column: $table.blendMode, builder: (column) => column);

  GeneratedColumn<int> get labelColorIndex => $composableBuilder(
    column: $table.labelColorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVideoLinked => $composableBuilder(
    column: $table.isVideoLinked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAudioLinked => $composableBuilder(
    column: $table.isAudioLinked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get transitionInId => $composableBuilder(
    column: $table.transitionInId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transitionOutId => $composableBuilder(
    column: $table.transitionOutId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transitionInDurationUs => $composableBuilder(
    column: $table.transitionInDurationUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transitionOutDurationUs => $composableBuilder(
    column: $table.transitionOutDurationUs,
    builder: (column) => column,
  );

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaAssetsTableAnnotationComposer get mediaId {
    final $$MediaAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> keyframesRefs<T extends Object>(
    Expression<T> Function($$KeyframesTableAnnotationComposer a) f,
  ) {
    final $$KeyframesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.keyframes,
      getReferencedColumn: (t) => t.clipId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KeyframesTableAnnotationComposer(
            $db: $db,
            $table: $db.keyframes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> effectInstancesRefs<T extends Object>(
    Expression<T> Function($$EffectInstancesTableAnnotationComposer a) f,
  ) {
    final $$EffectInstancesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.effectInstances,
      getReferencedColumn: (t) => t.clipId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EffectInstancesTableAnnotationComposer(
            $db: $db,
            $table: $db.effectInstances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClipsTable,
          Clip,
          $$ClipsTableFilterComposer,
          $$ClipsTableOrderingComposer,
          $$ClipsTableAnnotationComposer,
          $$ClipsTableCreateCompanionBuilder,
          $$ClipsTableUpdateCompanionBuilder,
          (Clip, $$ClipsTableReferences),
          Clip,
          PrefetchHooks Function({
            bool trackId,
            bool mediaId,
            bool keyframesRefs,
            bool effectInstancesRefs,
          })
        > {
  $$ClipsTableTableManager(_$AppDatabase db, $ClipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> startOnTimelineUs = const Value.absent(),
                Value<int> endOnTimelineUs = const Value.absent(),
                Value<int> mediaInPointUs = const Value.absent(),
                Value<int> mediaOutPointUs = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                Value<String> blendMode = const Value.absent(),
                Value<int> labelColorIndex = const Value.absent(),
                Value<bool> isVideoLinked = const Value.absent(),
                Value<bool> isAudioLinked = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> transitionInId = const Value.absent(),
                Value<String?> transitionOutId = const Value.absent(),
                Value<int> transitionInDurationUs = const Value.absent(),
                Value<int> transitionOutDurationUs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClipsCompanion(
                id: id,
                trackId: trackId,
                mediaId: mediaId,
                type: type,
                startOnTimelineUs: startOnTimelineUs,
                endOnTimelineUs: endOnTimelineUs,
                mediaInPointUs: mediaInPointUs,
                mediaOutPointUs: mediaOutPointUs,
                speed: speed,
                opacity: opacity,
                blendMode: blendMode,
                labelColorIndex: labelColorIndex,
                isVideoLinked: isVideoLinked,
                isAudioLinked: isAudioLinked,
                isMuted: isMuted,
                isLocked: isLocked,
                name: name,
                transitionInId: transitionInId,
                transitionOutId: transitionOutId,
                transitionInDurationUs: transitionInDurationUs,
                transitionOutDurationUs: transitionOutDurationUs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String trackId,
                required String mediaId,
                required String type,
                required int startOnTimelineUs,
                required int endOnTimelineUs,
                required int mediaInPointUs,
                required int mediaOutPointUs,
                Value<double> speed = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                Value<String> blendMode = const Value.absent(),
                Value<int> labelColorIndex = const Value.absent(),
                Value<bool> isVideoLinked = const Value.absent(),
                Value<bool> isAudioLinked = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> transitionInId = const Value.absent(),
                Value<String?> transitionOutId = const Value.absent(),
                Value<int> transitionInDurationUs = const Value.absent(),
                Value<int> transitionOutDurationUs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClipsCompanion.insert(
                id: id,
                trackId: trackId,
                mediaId: mediaId,
                type: type,
                startOnTimelineUs: startOnTimelineUs,
                endOnTimelineUs: endOnTimelineUs,
                mediaInPointUs: mediaInPointUs,
                mediaOutPointUs: mediaOutPointUs,
                speed: speed,
                opacity: opacity,
                blendMode: blendMode,
                labelColorIndex: labelColorIndex,
                isVideoLinked: isVideoLinked,
                isAudioLinked: isAudioLinked,
                isMuted: isMuted,
                isLocked: isLocked,
                name: name,
                transitionInId: transitionInId,
                transitionOutId: transitionOutId,
                transitionInDurationUs: transitionInDurationUs,
                transitionOutDurationUs: transitionOutDurationUs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ClipsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                trackId = false,
                mediaId = false,
                keyframesRefs = false,
                effectInstancesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (keyframesRefs) db.keyframes,
                    if (effectInstancesRefs) db.effectInstances,
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
                        if (trackId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.trackId,
                                    referencedTable: $$ClipsTableReferences
                                        ._trackIdTable(db),
                                    referencedColumn: $$ClipsTableReferences
                                        ._trackIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (mediaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.mediaId,
                                    referencedTable: $$ClipsTableReferences
                                        ._mediaIdTable(db),
                                    referencedColumn: $$ClipsTableReferences
                                        ._mediaIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (keyframesRefs)
                        await $_getPrefetchedData<Clip, $ClipsTable, Keyframe>(
                          currentTable: table,
                          referencedTable: $$ClipsTableReferences
                              ._keyframesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClipsTableReferences(
                                db,
                                table,
                                p0,
                              ).keyframesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.clipId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (effectInstancesRefs)
                        await $_getPrefetchedData<
                          Clip,
                          $ClipsTable,
                          EffectInstanceRow
                        >(
                          currentTable: table,
                          referencedTable: $$ClipsTableReferences
                              ._effectInstancesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClipsTableReferences(
                                db,
                                table,
                                p0,
                              ).effectInstancesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.clipId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ClipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClipsTable,
      Clip,
      $$ClipsTableFilterComposer,
      $$ClipsTableOrderingComposer,
      $$ClipsTableAnnotationComposer,
      $$ClipsTableCreateCompanionBuilder,
      $$ClipsTableUpdateCompanionBuilder,
      (Clip, $$ClipsTableReferences),
      Clip,
      PrefetchHooks Function({
        bool trackId,
        bool mediaId,
        bool keyframesRefs,
        bool effectInstancesRefs,
      })
    >;
typedef $$KeyframesTableCreateCompanionBuilder =
    KeyframesCompanion Function({
      required String id,
      required String clipId,
      required String parameterId,
      required int timeUs,
      required double value,
      Value<String> interpolation,
      Value<double> inTangentX,
      Value<double> inTangentY,
      Value<double> outTangentX,
      Value<double> outTangentY,
      Value<int> rowid,
    });
typedef $$KeyframesTableUpdateCompanionBuilder =
    KeyframesCompanion Function({
      Value<String> id,
      Value<String> clipId,
      Value<String> parameterId,
      Value<int> timeUs,
      Value<double> value,
      Value<String> interpolation,
      Value<double> inTangentX,
      Value<double> inTangentY,
      Value<double> outTangentX,
      Value<double> outTangentY,
      Value<int> rowid,
    });

final class $$KeyframesTableReferences
    extends BaseReferences<_$AppDatabase, $KeyframesTable, Keyframe> {
  $$KeyframesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClipsTable _clipIdTable(_$AppDatabase db) => db.clips.createAlias(
    $_aliasNameGenerator(db.keyframes.clipId, db.clips.id),
  );

  $$ClipsTableProcessedTableManager get clipId {
    final $_column = $_itemColumn<String>('clip_id')!;

    final manager = $$ClipsTableTableManager(
      $_db,
      $_db.clips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clipIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KeyframesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyframesTable> {
  $$KeyframesTableFilterComposer({
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

  ColumnFilters<String> get parameterId => $composableBuilder(
    column: $table.parameterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeUs => $composableBuilder(
    column: $table.timeUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interpolation => $composableBuilder(
    column: $table.interpolation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get inTangentX => $composableBuilder(
    column: $table.inTangentX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get inTangentY => $composableBuilder(
    column: $table.inTangentY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get outTangentX => $composableBuilder(
    column: $table.outTangentX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get outTangentY => $composableBuilder(
    column: $table.outTangentY,
    builder: (column) => ColumnFilters(column),
  );

  $$ClipsTableFilterComposer get clipId {
    final $$ClipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clipId,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableFilterComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeyframesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyframesTable> {
  $$KeyframesTableOrderingComposer({
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

  ColumnOrderings<String> get parameterId => $composableBuilder(
    column: $table.parameterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeUs => $composableBuilder(
    column: $table.timeUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interpolation => $composableBuilder(
    column: $table.interpolation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get inTangentX => $composableBuilder(
    column: $table.inTangentX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get inTangentY => $composableBuilder(
    column: $table.inTangentY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get outTangentX => $composableBuilder(
    column: $table.outTangentX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get outTangentY => $composableBuilder(
    column: $table.outTangentY,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClipsTableOrderingComposer get clipId {
    final $$ClipsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clipId,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableOrderingComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeyframesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyframesTable> {
  $$KeyframesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parameterId => $composableBuilder(
    column: $table.parameterId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeUs =>
      $composableBuilder(column: $table.timeUs, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get interpolation => $composableBuilder(
    column: $table.interpolation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get inTangentX => $composableBuilder(
    column: $table.inTangentX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get inTangentY => $composableBuilder(
    column: $table.inTangentY,
    builder: (column) => column,
  );

  GeneratedColumn<double> get outTangentX => $composableBuilder(
    column: $table.outTangentX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get outTangentY => $composableBuilder(
    column: $table.outTangentY,
    builder: (column) => column,
  );

  $$ClipsTableAnnotationComposer get clipId {
    final $$ClipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clipId,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableAnnotationComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KeyframesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyframesTable,
          Keyframe,
          $$KeyframesTableFilterComposer,
          $$KeyframesTableOrderingComposer,
          $$KeyframesTableAnnotationComposer,
          $$KeyframesTableCreateCompanionBuilder,
          $$KeyframesTableUpdateCompanionBuilder,
          (Keyframe, $$KeyframesTableReferences),
          Keyframe,
          PrefetchHooks Function({bool clipId})
        > {
  $$KeyframesTableTableManager(_$AppDatabase db, $KeyframesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyframesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyframesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyframesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clipId = const Value.absent(),
                Value<String> parameterId = const Value.absent(),
                Value<int> timeUs = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> interpolation = const Value.absent(),
                Value<double> inTangentX = const Value.absent(),
                Value<double> inTangentY = const Value.absent(),
                Value<double> outTangentX = const Value.absent(),
                Value<double> outTangentY = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyframesCompanion(
                id: id,
                clipId: clipId,
                parameterId: parameterId,
                timeUs: timeUs,
                value: value,
                interpolation: interpolation,
                inTangentX: inTangentX,
                inTangentY: inTangentY,
                outTangentX: outTangentX,
                outTangentY: outTangentY,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clipId,
                required String parameterId,
                required int timeUs,
                required double value,
                Value<String> interpolation = const Value.absent(),
                Value<double> inTangentX = const Value.absent(),
                Value<double> inTangentY = const Value.absent(),
                Value<double> outTangentX = const Value.absent(),
                Value<double> outTangentY = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyframesCompanion.insert(
                id: id,
                clipId: clipId,
                parameterId: parameterId,
                timeUs: timeUs,
                value: value,
                interpolation: interpolation,
                inTangentX: inTangentX,
                inTangentY: inTangentY,
                outTangentX: outTangentX,
                outTangentY: outTangentY,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KeyframesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({clipId = false}) {
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
                    if (clipId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.clipId,
                                referencedTable: $$KeyframesTableReferences
                                    ._clipIdTable(db),
                                referencedColumn: $$KeyframesTableReferences
                                    ._clipIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$KeyframesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyframesTable,
      Keyframe,
      $$KeyframesTableFilterComposer,
      $$KeyframesTableOrderingComposer,
      $$KeyframesTableAnnotationComposer,
      $$KeyframesTableCreateCompanionBuilder,
      $$KeyframesTableUpdateCompanionBuilder,
      (Keyframe, $$KeyframesTableReferences),
      Keyframe,
      PrefetchHooks Function({bool clipId})
    >;
typedef $$EffectInstancesTableCreateCompanionBuilder =
    EffectInstancesCompanion Function({
      required String id,
      required String clipId,
      required String effectType,
      required int stackIndex,
      Value<bool> isEnabled,
      Value<String> parametersJson,
      Value<int> rowid,
    });
typedef $$EffectInstancesTableUpdateCompanionBuilder =
    EffectInstancesCompanion Function({
      Value<String> id,
      Value<String> clipId,
      Value<String> effectType,
      Value<int> stackIndex,
      Value<bool> isEnabled,
      Value<String> parametersJson,
      Value<int> rowid,
    });

final class $$EffectInstancesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EffectInstancesTable,
          EffectInstanceRow
        > {
  $$EffectInstancesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClipsTable _clipIdTable(_$AppDatabase db) => db.clips.createAlias(
    $_aliasNameGenerator(db.effectInstances.clipId, db.clips.id),
  );

  $$ClipsTableProcessedTableManager get clipId {
    final $_column = $_itemColumn<String>('clip_id')!;

    final manager = $$ClipsTableTableManager(
      $_db,
      $_db.clips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clipIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EffectInstancesTableFilterComposer
    extends Composer<_$AppDatabase, $EffectInstancesTable> {
  $$EffectInstancesTableFilterComposer({
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

  ColumnFilters<String> get effectType => $composableBuilder(
    column: $table.effectType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stackIndex => $composableBuilder(
    column: $table.stackIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parametersJson => $composableBuilder(
    column: $table.parametersJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ClipsTableFilterComposer get clipId {
    final $$ClipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clipId,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableFilterComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EffectInstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $EffectInstancesTable> {
  $$EffectInstancesTableOrderingComposer({
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

  ColumnOrderings<String> get effectType => $composableBuilder(
    column: $table.effectType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stackIndex => $composableBuilder(
    column: $table.stackIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parametersJson => $composableBuilder(
    column: $table.parametersJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClipsTableOrderingComposer get clipId {
    final $$ClipsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clipId,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableOrderingComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EffectInstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EffectInstancesTable> {
  $$EffectInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get effectType => $composableBuilder(
    column: $table.effectType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stackIndex => $composableBuilder(
    column: $table.stackIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get parametersJson => $composableBuilder(
    column: $table.parametersJson,
    builder: (column) => column,
  );

  $$ClipsTableAnnotationComposer get clipId {
    final $$ClipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clipId,
      referencedTable: $db.clips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClipsTableAnnotationComposer(
            $db: $db,
            $table: $db.clips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EffectInstancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EffectInstancesTable,
          EffectInstanceRow,
          $$EffectInstancesTableFilterComposer,
          $$EffectInstancesTableOrderingComposer,
          $$EffectInstancesTableAnnotationComposer,
          $$EffectInstancesTableCreateCompanionBuilder,
          $$EffectInstancesTableUpdateCompanionBuilder,
          (EffectInstanceRow, $$EffectInstancesTableReferences),
          EffectInstanceRow,
          PrefetchHooks Function({bool clipId})
        > {
  $$EffectInstancesTableTableManager(
    _$AppDatabase db,
    $EffectInstancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EffectInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EffectInstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EffectInstancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clipId = const Value.absent(),
                Value<String> effectType = const Value.absent(),
                Value<int> stackIndex = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String> parametersJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EffectInstancesCompanion(
                id: id,
                clipId: clipId,
                effectType: effectType,
                stackIndex: stackIndex,
                isEnabled: isEnabled,
                parametersJson: parametersJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clipId,
                required String effectType,
                required int stackIndex,
                Value<bool> isEnabled = const Value.absent(),
                Value<String> parametersJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EffectInstancesCompanion.insert(
                id: id,
                clipId: clipId,
                effectType: effectType,
                stackIndex: stackIndex,
                isEnabled: isEnabled,
                parametersJson: parametersJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EffectInstancesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({clipId = false}) {
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
                    if (clipId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.clipId,
                                referencedTable:
                                    $$EffectInstancesTableReferences
                                        ._clipIdTable(db),
                                referencedColumn:
                                    $$EffectInstancesTableReferences
                                        ._clipIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$EffectInstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EffectInstancesTable,
      EffectInstanceRow,
      $$EffectInstancesTableFilterComposer,
      $$EffectInstancesTableOrderingComposer,
      $$EffectInstancesTableAnnotationComposer,
      $$EffectInstancesTableCreateCompanionBuilder,
      $$EffectInstancesTableUpdateCompanionBuilder,
      (EffectInstanceRow, $$EffectInstancesTableReferences),
      EffectInstanceRow,
      PrefetchHooks Function({bool clipId})
    >;
typedef $$ProjectSettingsTableCreateCompanionBuilder =
    ProjectSettingsCompanion Function({
      required String projectId,
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$ProjectSettingsTableUpdateCompanionBuilder =
    ProjectSettingsCompanion Function({
      Value<String> projectId,
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

final class $$ProjectSettingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ProjectSettingsTable, ProjectSetting> {
  $$ProjectSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
        $_aliasNameGenerator(db.projectSettings.projectId, db.projects.id),
      );

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProjectSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectSettingsTable> {
  $$ProjectSettingsTableFilterComposer({
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

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectSettingsTable> {
  $$ProjectSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectSettingsTable> {
  $$ProjectSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectSettingsTable,
          ProjectSetting,
          $$ProjectSettingsTableFilterComposer,
          $$ProjectSettingsTableOrderingComposer,
          $$ProjectSettingsTableAnnotationComposer,
          $$ProjectSettingsTableCreateCompanionBuilder,
          $$ProjectSettingsTableUpdateCompanionBuilder,
          (ProjectSetting, $$ProjectSettingsTableReferences),
          ProjectSetting,
          PrefetchHooks Function({bool projectId})
        > {
  $$ProjectSettingsTableTableManager(
    _$AppDatabase db,
    $ProjectSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectSettingsCompanion(
                projectId: projectId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectId,
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => ProjectSettingsCompanion.insert(
                projectId: projectId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProjectSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
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
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable:
                                    $$ProjectSettingsTableReferences
                                        ._projectIdTable(db),
                                referencedColumn:
                                    $$ProjectSettingsTableReferences
                                        ._projectIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$ProjectSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectSettingsTable,
      ProjectSetting,
      $$ProjectSettingsTableFilterComposer,
      $$ProjectSettingsTableOrderingComposer,
      $$ProjectSettingsTableAnnotationComposer,
      $$ProjectSettingsTableCreateCompanionBuilder,
      $$ProjectSettingsTableUpdateCompanionBuilder,
      (ProjectSetting, $$ProjectSettingsTableReferences),
      ProjectSetting,
      PrefetchHooks Function({bool projectId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db, _db.mediaAssets);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$ClipsTableTableManager get clips =>
      $$ClipsTableTableManager(_db, _db.clips);
  $$KeyframesTableTableManager get keyframes =>
      $$KeyframesTableTableManager(_db, _db.keyframes);
  $$EffectInstancesTableTableManager get effectInstances =>
      $$EffectInstancesTableTableManager(_db, _db.effectInstances);
  $$ProjectSettingsTableTableManager get projectSettings =>
      $$ProjectSettingsTableTableManager(_db, _db.projectSettings);
}
