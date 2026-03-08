// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ClientsTable extends Clients with TableInfo<$ClientsTable, Client> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _whatsappMeta =
      const VerificationMeta('whatsapp');
  @override
  late final GeneratedColumn<String> whatsapp = GeneratedColumn<String>(
      'whatsapp', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, whatsapp, email, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients';
  @override
  VerificationContext validateIntegrity(Insertable<Client> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('whatsapp')) {
      context.handle(_whatsappMeta,
          whatsapp.isAcceptableOrUnknown(data['whatsapp']!, _whatsappMeta));
    } else if (isInserting) {
      context.missing(_whatsappMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Client map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Client(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      whatsapp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}whatsapp'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ClientsTable createAlias(String alias) {
    return $ClientsTable(attachedDatabase, alias);
  }
}

class Client extends DataClass implements Insertable<Client> {
  final String id;
  final String name;
  final String whatsapp;
  final String? email;
  final DateTime createdAt;
  const Client(
      {required this.id,
      required this.name,
      required this.whatsapp,
      this.email,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['whatsapp'] = Variable<String>(whatsapp);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ClientsCompanion toCompanion(bool nullToAbsent) {
    return ClientsCompanion(
      id: Value(id),
      name: Value(name),
      whatsapp: Value(whatsapp),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      createdAt: Value(createdAt),
    );
  }

  factory Client.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Client(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      whatsapp: serializer.fromJson<String>(json['whatsapp']),
      email: serializer.fromJson<String?>(json['email']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'whatsapp': serializer.toJson<String>(whatsapp),
      'email': serializer.toJson<String?>(email),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Client copyWith(
          {String? id,
          String? name,
          String? whatsapp,
          Value<String?> email = const Value.absent(),
          DateTime? createdAt}) =>
      Client(
        id: id ?? this.id,
        name: name ?? this.name,
        whatsapp: whatsapp ?? this.whatsapp,
        email: email.present ? email.value : this.email,
        createdAt: createdAt ?? this.createdAt,
      );
  Client copyWithCompanion(ClientsCompanion data) {
    return Client(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      whatsapp: data.whatsapp.present ? data.whatsapp.value : this.whatsapp,
      email: data.email.present ? data.email.value : this.email,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Client(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, whatsapp, email, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Client &&
          other.id == this.id &&
          other.name == this.name &&
          other.whatsapp == this.whatsapp &&
          other.email == this.email &&
          other.createdAt == this.createdAt);
}

class ClientsCompanion extends UpdateCompanion<Client> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> whatsapp;
  final Value<String?> email;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ClientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.email = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsCompanion.insert({
    required String id,
    required String name,
    required String whatsapp,
    this.email = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        whatsapp = Value(whatsapp);
  static Insertable<Client> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? whatsapp,
    Expression<String>? email,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? whatsapp,
      Value<String?>? email,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ClientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
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
    if (whatsapp.present) {
      map['whatsapp'] = Variable<String>(whatsapp.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
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
    return (StringBuffer('ClientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotoAssetsTable extends PhotoAssets
    with TableInfo<$PhotoAssetsTable, PhotoAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailKeyMeta =
      const VerificationMeta('thumbnailKey');
  @override
  late final GeneratedColumn<String> thumbnailKey = GeneratedColumn<String>(
      'thumbnail_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _capturedAtMeta =
      const VerificationMeta('capturedAt');
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
      'captured_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _uploadStatusMeta =
      const VerificationMeta('uploadStatus');
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
      'upload_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _storagePathMeta =
      const VerificationMeta('storagePath');
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
      'storage_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        localPath,
        thumbnailKey,
        capturedAt,
        checksum,
        uploadStatus,
        storagePath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_assets';
  @override
  VerificationContext validateIntegrity(Insertable<PhotoAsset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('thumbnail_key')) {
      context.handle(
          _thumbnailKeyMeta,
          thumbnailKey.isAcceptableOrUnknown(
              data['thumbnail_key']!, _thumbnailKeyMeta));
    } else if (isInserting) {
      context.missing(_thumbnailKeyMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
          _capturedAtMeta,
          capturedAt.isAcceptableOrUnknown(
              data['captured_at']!, _capturedAtMeta));
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('upload_status')) {
      context.handle(
          _uploadStatusMeta,
          uploadStatus.isAcceptableOrUnknown(
              data['upload_status']!, _uploadStatusMeta));
    } else if (isInserting) {
      context.missing(_uploadStatusMeta);
    }
    if (data.containsKey('storage_path')) {
      context.handle(
          _storagePathMeta,
          storagePath.isAcceptableOrUnknown(
              data['storage_path']!, _storagePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoAsset(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      thumbnailKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_key'])!,
      capturedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}captured_at'])!,
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum'])!,
      uploadStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}upload_status'])!,
      storagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storage_path']),
    );
  }

  @override
  $PhotoAssetsTable createAlias(String alias) {
    return $PhotoAssetsTable(attachedDatabase, alias);
  }
}

class PhotoAsset extends DataClass implements Insertable<PhotoAsset> {
  final String id;
  final String localPath;
  final String thumbnailKey;
  final DateTime capturedAt;
  final String checksum;
  final String uploadStatus;
  final String? storagePath;
  const PhotoAsset(
      {required this.id,
      required this.localPath,
      required this.thumbnailKey,
      required this.capturedAt,
      required this.checksum,
      required this.uploadStatus,
      this.storagePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_path'] = Variable<String>(localPath);
    map['thumbnail_key'] = Variable<String>(thumbnailKey);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['checksum'] = Variable<String>(checksum);
    map['upload_status'] = Variable<String>(uploadStatus);
    if (!nullToAbsent || storagePath != null) {
      map['storage_path'] = Variable<String>(storagePath);
    }
    return map;
  }

  PhotoAssetsCompanion toCompanion(bool nullToAbsent) {
    return PhotoAssetsCompanion(
      id: Value(id),
      localPath: Value(localPath),
      thumbnailKey: Value(thumbnailKey),
      capturedAt: Value(capturedAt),
      checksum: Value(checksum),
      uploadStatus: Value(uploadStatus),
      storagePath: storagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(storagePath),
    );
  }

  factory PhotoAsset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoAsset(
      id: serializer.fromJson<String>(json['id']),
      localPath: serializer.fromJson<String>(json['localPath']),
      thumbnailKey: serializer.fromJson<String>(json['thumbnailKey']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      checksum: serializer.fromJson<String>(json['checksum']),
      uploadStatus: serializer.fromJson<String>(json['uploadStatus']),
      storagePath: serializer.fromJson<String?>(json['storagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localPath': serializer.toJson<String>(localPath),
      'thumbnailKey': serializer.toJson<String>(thumbnailKey),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'checksum': serializer.toJson<String>(checksum),
      'uploadStatus': serializer.toJson<String>(uploadStatus),
      'storagePath': serializer.toJson<String?>(storagePath),
    };
  }

  PhotoAsset copyWith(
          {String? id,
          String? localPath,
          String? thumbnailKey,
          DateTime? capturedAt,
          String? checksum,
          String? uploadStatus,
          Value<String?> storagePath = const Value.absent()}) =>
      PhotoAsset(
        id: id ?? this.id,
        localPath: localPath ?? this.localPath,
        thumbnailKey: thumbnailKey ?? this.thumbnailKey,
        capturedAt: capturedAt ?? this.capturedAt,
        checksum: checksum ?? this.checksum,
        uploadStatus: uploadStatus ?? this.uploadStatus,
        storagePath: storagePath.present ? storagePath.value : this.storagePath,
      );
  PhotoAsset copyWithCompanion(PhotoAssetsCompanion data) {
    return PhotoAsset(
      id: data.id.present ? data.id.value : this.id,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      thumbnailKey: data.thumbnailKey.present
          ? data.thumbnailKey.value
          : this.thumbnailKey,
      capturedAt:
          data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      storagePath:
          data.storagePath.present ? data.storagePath.value : this.storagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoAsset(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('thumbnailKey: $thumbnailKey, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('checksum: $checksum, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('storagePath: $storagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, localPath, thumbnailKey, capturedAt,
      checksum, uploadStatus, storagePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoAsset &&
          other.id == this.id &&
          other.localPath == this.localPath &&
          other.thumbnailKey == this.thumbnailKey &&
          other.capturedAt == this.capturedAt &&
          other.checksum == this.checksum &&
          other.uploadStatus == this.uploadStatus &&
          other.storagePath == this.storagePath);
}

class PhotoAssetsCompanion extends UpdateCompanion<PhotoAsset> {
  final Value<String> id;
  final Value<String> localPath;
  final Value<String> thumbnailKey;
  final Value<DateTime> capturedAt;
  final Value<String> checksum;
  final Value<String> uploadStatus;
  final Value<String?> storagePath;
  final Value<int> rowid;
  const PhotoAssetsCompanion({
    this.id = const Value.absent(),
    this.localPath = const Value.absent(),
    this.thumbnailKey = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoAssetsCompanion.insert({
    required String id,
    required String localPath,
    required String thumbnailKey,
    required DateTime capturedAt,
    required String checksum,
    required String uploadStatus,
    this.storagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        localPath = Value(localPath),
        thumbnailKey = Value(thumbnailKey),
        capturedAt = Value(capturedAt),
        checksum = Value(checksum),
        uploadStatus = Value(uploadStatus);
  static Insertable<PhotoAsset> custom({
    Expression<String>? id,
    Expression<String>? localPath,
    Expression<String>? thumbnailKey,
    Expression<DateTime>? capturedAt,
    Expression<String>? checksum,
    Expression<String>? uploadStatus,
    Expression<String>? storagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localPath != null) 'local_path': localPath,
      if (thumbnailKey != null) 'thumbnail_key': thumbnailKey,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (checksum != null) 'checksum': checksum,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (storagePath != null) 'storage_path': storagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoAssetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? localPath,
      Value<String>? thumbnailKey,
      Value<DateTime>? capturedAt,
      Value<String>? checksum,
      Value<String>? uploadStatus,
      Value<String?>? storagePath,
      Value<int>? rowid}) {
    return PhotoAssetsCompanion(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      thumbnailKey: thumbnailKey ?? this.thumbnailKey,
      capturedAt: capturedAt ?? this.capturedAt,
      checksum: checksum ?? this.checksum,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      storagePath: storagePath ?? this.storagePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (thumbnailKey.present) {
      map['thumbnail_key'] = Variable<String>(thumbnailKey.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoAssetsCompanion(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('thumbnailKey: $thumbnailKey, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('checksum: $checksum, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('storagePath: $storagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
      'client_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountCentsMeta =
      const VerificationMeta('totalAmountCents');
  @override
  late final GeneratedColumn<int> totalAmountCents = GeneratedColumn<int>(
      'total_amount_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('BRL'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _externalReferenceMeta =
      const VerificationMeta('externalReference');
  @override
  late final GeneratedColumn<String> externalReference =
      GeneratedColumn<String>('external_reference', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _providerDataJsonMeta =
      const VerificationMeta('providerDataJson');
  @override
  late final GeneratedColumn<String> providerDataJson = GeneratedColumn<String>(
      'provider_data_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        clientId,
        totalAmountCents,
        currency,
        status,
        paymentMethod,
        externalReference,
        providerDataJson,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(Insertable<Order> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('total_amount_cents')) {
      context.handle(
          _totalAmountCentsMeta,
          totalAmountCents.isAcceptableOrUnknown(
              data['total_amount_cents']!, _totalAmountCentsMeta));
    } else if (isInserting) {
      context.missing(_totalAmountCentsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('external_reference')) {
      context.handle(
          _externalReferenceMeta,
          externalReference.isAcceptableOrUnknown(
              data['external_reference']!, _externalReferenceMeta));
    } else if (isInserting) {
      context.missing(_externalReferenceMeta);
    }
    if (data.containsKey('provider_data_json')) {
      context.handle(
          _providerDataJsonMeta,
          providerDataJson.isAcceptableOrUnknown(
              data['provider_data_json']!, _providerDataJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_id'])!,
      totalAmountCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_amount_cents'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      externalReference: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}external_reference'])!,
      providerDataJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}provider_data_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final String clientId;
  final int totalAmountCents;
  final String currency;
  final String status;
  final String paymentMethod;
  final String externalReference;
  final String? providerDataJson;
  final DateTime createdAt;
  const Order(
      {required this.id,
      required this.clientId,
      required this.totalAmountCents,
      required this.currency,
      required this.status,
      required this.paymentMethod,
      required this.externalReference,
      this.providerDataJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    map['total_amount_cents'] = Variable<int>(totalAmountCents);
    map['currency'] = Variable<String>(currency);
    map['status'] = Variable<String>(status);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['external_reference'] = Variable<String>(externalReference);
    if (!nullToAbsent || providerDataJson != null) {
      map['provider_data_json'] = Variable<String>(providerDataJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      clientId: Value(clientId),
      totalAmountCents: Value(totalAmountCents),
      currency: Value(currency),
      status: Value(status),
      paymentMethod: Value(paymentMethod),
      externalReference: Value(externalReference),
      providerDataJson: providerDataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(providerDataJson),
      createdAt: Value(createdAt),
    );
  }

  factory Order.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      totalAmountCents: serializer.fromJson<int>(json['totalAmountCents']),
      currency: serializer.fromJson<String>(json['currency']),
      status: serializer.fromJson<String>(json['status']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      externalReference: serializer.fromJson<String>(json['externalReference']),
      providerDataJson: serializer.fromJson<String?>(json['providerDataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'totalAmountCents': serializer.toJson<int>(totalAmountCents),
      'currency': serializer.toJson<String>(currency),
      'status': serializer.toJson<String>(status),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'externalReference': serializer.toJson<String>(externalReference),
      'providerDataJson': serializer.toJson<String?>(providerDataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Order copyWith(
          {String? id,
          String? clientId,
          int? totalAmountCents,
          String? currency,
          String? status,
          String? paymentMethod,
          String? externalReference,
          Value<String?> providerDataJson = const Value.absent(),
          DateTime? createdAt}) =>
      Order(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        totalAmountCents: totalAmountCents ?? this.totalAmountCents,
        currency: currency ?? this.currency,
        status: status ?? this.status,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        externalReference: externalReference ?? this.externalReference,
        providerDataJson: providerDataJson.present
            ? providerDataJson.value
            : this.providerDataJson,
        createdAt: createdAt ?? this.createdAt,
      );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      totalAmountCents: data.totalAmountCents.present
          ? data.totalAmountCents.value
          : this.totalAmountCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      status: data.status.present ? data.status.value : this.status,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      externalReference: data.externalReference.present
          ? data.externalReference.value
          : this.externalReference,
      providerDataJson: data.providerDataJson.present
          ? data.providerDataJson.value
          : this.providerDataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('totalAmountCents: $totalAmountCents, ')
          ..write('currency: $currency, ')
          ..write('status: $status, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('externalReference: $externalReference, ')
          ..write('providerDataJson: $providerDataJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clientId, totalAmountCents, currency,
      status, paymentMethod, externalReference, providerDataJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.totalAmountCents == this.totalAmountCents &&
          other.currency == this.currency &&
          other.status == this.status &&
          other.paymentMethod == this.paymentMethod &&
          other.externalReference == this.externalReference &&
          other.providerDataJson == this.providerDataJson &&
          other.createdAt == this.createdAt);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<int> totalAmountCents;
  final Value<String> currency;
  final Value<String> status;
  final Value<String> paymentMethod;
  final Value<String> externalReference;
  final Value<String?> providerDataJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.totalAmountCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.externalReference = const Value.absent(),
    this.providerDataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String clientId,
    required int totalAmountCents,
    this.currency = const Value.absent(),
    required String status,
    required String paymentMethod,
    required String externalReference,
    this.providerDataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        clientId = Value(clientId),
        totalAmountCents = Value(totalAmountCents),
        status = Value(status),
        paymentMethod = Value(paymentMethod),
        externalReference = Value(externalReference);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<int>? totalAmountCents,
    Expression<String>? currency,
    Expression<String>? status,
    Expression<String>? paymentMethod,
    Expression<String>? externalReference,
    Expression<String>? providerDataJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (totalAmountCents != null) 'total_amount_cents': totalAmountCents,
      if (currency != null) 'currency': currency,
      if (status != null) 'status': status,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (externalReference != null) 'external_reference': externalReference,
      if (providerDataJson != null) 'provider_data_json': providerDataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith(
      {Value<String>? id,
      Value<String>? clientId,
      Value<int>? totalAmountCents,
      Value<String>? currency,
      Value<String>? status,
      Value<String>? paymentMethod,
      Value<String>? externalReference,
      Value<String?>? providerDataJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return OrdersCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      externalReference: externalReference ?? this.externalReference,
      providerDataJson: providerDataJson ?? this.providerDataJson,
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
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (totalAmountCents.present) {
      map['total_amount_cents'] = Variable<int>(totalAmountCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (externalReference.present) {
      map['external_reference'] = Variable<String>(externalReference.value);
    }
    if (providerDataJson.present) {
      map['provider_data_json'] = Variable<String>(providerDataJson.value);
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
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('totalAmountCents: $totalAmountCents, ')
          ..write('currency: $currency, ')
          ..write('status: $status, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('externalReference: $externalReference, ')
          ..write('providerDataJson: $providerDataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _photoAssetIdMeta =
      const VerificationMeta('photoAssetId');
  @override
  late final GeneratedColumn<String> photoAssetId = GeneratedColumn<String>(
      'photo_asset_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES photo_assets (id)'));
  static const VerificationMeta _unitPriceCentsMeta =
      const VerificationMeta('unitPriceCents');
  @override
  late final GeneratedColumn<int> unitPriceCents = GeneratedColumn<int>(
      'unit_price_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, orderId, photoAssetId, unitPriceCents, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(Insertable<OrderItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('photo_asset_id')) {
      context.handle(
          _photoAssetIdMeta,
          photoAssetId.isAcceptableOrUnknown(
              data['photo_asset_id']!, _photoAssetIdMeta));
    } else if (isInserting) {
      context.missing(_photoAssetIdMeta);
    }
    if (data.containsKey('unit_price_cents')) {
      context.handle(
          _unitPriceCentsMeta,
          unitPriceCents.isAcceptableOrUnknown(
              data['unit_price_cents']!, _unitPriceCentsMeta));
    } else if (isInserting) {
      context.missing(_unitPriceCentsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      photoAssetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_asset_id'])!,
      unitPriceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_price_cents'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItem extends DataClass implements Insertable<OrderItem> {
  final String id;
  final String orderId;
  final String photoAssetId;
  final int unitPriceCents;
  final DateTime createdAt;
  const OrderItem(
      {required this.id,
      required this.orderId,
      required this.photoAssetId,
      required this.unitPriceCents,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['photo_asset_id'] = Variable<String>(photoAssetId);
    map['unit_price_cents'] = Variable<int>(unitPriceCents);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      photoAssetId: Value(photoAssetId),
      unitPriceCents: Value(unitPriceCents),
      createdAt: Value(createdAt),
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItem(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      photoAssetId: serializer.fromJson<String>(json['photoAssetId']),
      unitPriceCents: serializer.fromJson<int>(json['unitPriceCents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'photoAssetId': serializer.toJson<String>(photoAssetId),
      'unitPriceCents': serializer.toJson<int>(unitPriceCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OrderItem copyWith(
          {String? id,
          String? orderId,
          String? photoAssetId,
          int? unitPriceCents,
          DateTime? createdAt}) =>
      OrderItem(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        photoAssetId: photoAssetId ?? this.photoAssetId,
        unitPriceCents: unitPriceCents ?? this.unitPriceCents,
        createdAt: createdAt ?? this.createdAt,
      );
  OrderItem copyWithCompanion(OrderItemsCompanion data) {
    return OrderItem(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      photoAssetId: data.photoAssetId.present
          ? data.photoAssetId.value
          : this.photoAssetId,
      unitPriceCents: data.unitPriceCents.present
          ? data.unitPriceCents.value
          : this.unitPriceCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItem(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('photoAssetId: $photoAssetId, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, orderId, photoAssetId, unitPriceCents, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.photoAssetId == this.photoAssetId &&
          other.unitPriceCents == this.unitPriceCents &&
          other.createdAt == this.createdAt);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItem> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> photoAssetId;
  final Value<int> unitPriceCents;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.photoAssetId = const Value.absent(),
    this.unitPriceCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    required String id,
    required String orderId,
    required String photoAssetId,
    required int unitPriceCents,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        photoAssetId = Value(photoAssetId),
        unitPriceCents = Value(unitPriceCents);
  static Insertable<OrderItem> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? photoAssetId,
    Expression<int>? unitPriceCents,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (photoAssetId != null) 'photo_asset_id': photoAssetId,
      if (unitPriceCents != null) 'unit_price_cents': unitPriceCents,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<String>? photoAssetId,
      Value<int>? unitPriceCents,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      photoAssetId: photoAssetId ?? this.photoAssetId,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
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
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (photoAssetId.present) {
      map['photo_asset_id'] = Variable<String>(photoAssetId.value);
    }
    if (unitPriceCents.present) {
      map['unit_price_cents'] = Variable<int>(unitPriceCents.value);
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
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('photoAssetId: $photoAssetId, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pt-BR'));
  static const VerificationMeta _wifiOnlyMeta =
      const VerificationMeta('wifiOnly');
  @override
  late final GeneratedColumn<bool> wifiOnly = GeneratedColumn<bool>(
      'wifi_only', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("wifi_only" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _accessCodeValidityDaysMeta =
      const VerificationMeta('accessCodeValidityDays');
  @override
  late final GeneratedColumn<int> accessCodeValidityDays = GeneratedColumn<int>(
      'access_code_validity_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(7));
  static const VerificationMeta _watermarkConfigJsonMeta =
      const VerificationMeta('watermarkConfigJson');
  @override
  late final GeneratedColumn<String> watermarkConfigJson =
      GeneratedColumn<String>('watermark_config_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('{}'));
  static const VerificationMeta _highContrastEnabledMeta =
      const VerificationMeta('highContrastEnabled');
  @override
  late final GeneratedColumn<bool> highContrastEnabled = GeneratedColumn<bool>(
      'high_contrast_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("high_contrast_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _solarLargeFontEnabledMeta =
      const VerificationMeta('solarLargeFontEnabled');
  @override
  late final GeneratedColumn<bool> solarLargeFontEnabled =
      GeneratedColumn<bool>('solar_large_font_enabled', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("solar_large_font_enabled" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _adminUsernameMeta =
      const VerificationMeta('adminUsername');
  @override
  late final GeneratedColumn<String> adminUsername = GeneratedColumn<String>(
      'admin_username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('admin'));
  static const VerificationMeta _adminPasswordHashMeta =
      const VerificationMeta('adminPasswordHash');
  @override
  late final GeneratedColumn<String> adminPasswordHash = GeneratedColumn<
          String>('admin_password_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(
          '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9'));
  static const VerificationMeta _photographerNameMeta =
      const VerificationMeta('photographerName');
  @override
  late final GeneratedColumn<String> photographerName = GeneratedColumn<String>(
      'photographer_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Fotografo'));
  static const VerificationMeta _photographerWhatsappMeta =
      const VerificationMeta('photographerWhatsapp');
  @override
  late final GeneratedColumn<String> photographerWhatsapp =
      GeneratedColumn<String>('photographer_whatsapp', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _photographerEmailMeta =
      const VerificationMeta('photographerEmail');
  @override
  late final GeneratedColumn<String> photographerEmail =
      GeneratedColumn<String>('photographer_email', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _photographerPixKeyMeta =
      const VerificationMeta('photographerPixKey');
  @override
  late final GeneratedColumn<String> photographerPixKey =
      GeneratedColumn<String>('photographer_pix_key', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _deliveryHistoryJsonMeta =
      const VerificationMeta('deliveryHistoryJson');
  @override
  late final GeneratedColumn<String> deliveryHistoryJson =
      GeneratedColumn<String>('delivery_history_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _preferredInputFolderMeta =
      const VerificationMeta('preferredInputFolder');
  @override
  late final GeneratedColumn<String> preferredInputFolder =
      GeneratedColumn<String>('preferred_input_folder', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        language,
        wifiOnly,
        accessCodeValidityDays,
        watermarkConfigJson,
        highContrastEnabled,
        solarLargeFontEnabled,
        themeMode,
        adminUsername,
        adminPasswordHash,
        photographerName,
        photographerWhatsapp,
        photographerEmail,
        photographerPixKey,
        deliveryHistoryJson,
        preferredInputFolder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('wifi_only')) {
      context.handle(_wifiOnlyMeta,
          wifiOnly.isAcceptableOrUnknown(data['wifi_only']!, _wifiOnlyMeta));
    }
    if (data.containsKey('access_code_validity_days')) {
      context.handle(
          _accessCodeValidityDaysMeta,
          accessCodeValidityDays.isAcceptableOrUnknown(
              data['access_code_validity_days']!, _accessCodeValidityDaysMeta));
    }
    if (data.containsKey('watermark_config_json')) {
      context.handle(
          _watermarkConfigJsonMeta,
          watermarkConfigJson.isAcceptableOrUnknown(
              data['watermark_config_json']!, _watermarkConfigJsonMeta));
    }
    if (data.containsKey('high_contrast_enabled')) {
      context.handle(
          _highContrastEnabledMeta,
          highContrastEnabled.isAcceptableOrUnknown(
              data['high_contrast_enabled']!, _highContrastEnabledMeta));
    }
    if (data.containsKey('solar_large_font_enabled')) {
      context.handle(
          _solarLargeFontEnabledMeta,
          solarLargeFontEnabled.isAcceptableOrUnknown(
              data['solar_large_font_enabled']!, _solarLargeFontEnabledMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('admin_username')) {
      context.handle(
          _adminUsernameMeta,
          adminUsername.isAcceptableOrUnknown(
              data['admin_username']!, _adminUsernameMeta));
    }
    if (data.containsKey('admin_password_hash')) {
      context.handle(
          _adminPasswordHashMeta,
          adminPasswordHash.isAcceptableOrUnknown(
              data['admin_password_hash']!, _adminPasswordHashMeta));
    }
    if (data.containsKey('photographer_name')) {
      context.handle(
          _photographerNameMeta,
          photographerName.isAcceptableOrUnknown(
              data['photographer_name']!, _photographerNameMeta));
    }
    if (data.containsKey('photographer_whatsapp')) {
      context.handle(
          _photographerWhatsappMeta,
          photographerWhatsapp.isAcceptableOrUnknown(
              data['photographer_whatsapp']!, _photographerWhatsappMeta));
    }
    if (data.containsKey('photographer_email')) {
      context.handle(
          _photographerEmailMeta,
          photographerEmail.isAcceptableOrUnknown(
              data['photographer_email']!, _photographerEmailMeta));
    }
    if (data.containsKey('photographer_pix_key')) {
      context.handle(
          _photographerPixKeyMeta,
          photographerPixKey.isAcceptableOrUnknown(
              data['photographer_pix_key']!, _photographerPixKeyMeta));
    }
    if (data.containsKey('delivery_history_json')) {
      context.handle(
          _deliveryHistoryJsonMeta,
          deliveryHistoryJson.isAcceptableOrUnknown(
              data['delivery_history_json']!, _deliveryHistoryJsonMeta));
    }
    if (data.containsKey('preferred_input_folder')) {
      context.handle(
          _preferredInputFolderMeta,
          preferredInputFolder.isAcceptableOrUnknown(
              data['preferred_input_folder']!, _preferredInputFolderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      wifiOnly: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}wifi_only'])!,
      accessCodeValidityDays: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}access_code_validity_days'])!,
      watermarkConfigJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}watermark_config_json'])!,
      highContrastEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}high_contrast_enabled'])!,
      solarLargeFontEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}solar_large_font_enabled'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      adminUsername: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}admin_username'])!,
      adminPasswordHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}admin_password_hash'])!,
      photographerName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photographer_name'])!,
      photographerWhatsapp: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}photographer_whatsapp'])!,
      photographerEmail: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photographer_email'])!,
      photographerPixKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photographer_pix_key'])!,
      deliveryHistoryJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}delivery_history_json'])!,
      preferredInputFolder: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}preferred_input_folder'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String language;
  final bool wifiOnly;
  final int accessCodeValidityDays;
  final String watermarkConfigJson;
  final bool highContrastEnabled;
  final bool solarLargeFontEnabled;
  final String themeMode;
  final String adminUsername;
  final String adminPasswordHash;
  final String photographerName;
  final String photographerWhatsapp;
  final String photographerEmail;
  final String photographerPixKey;
  final String deliveryHistoryJson;
  final String preferredInputFolder;
  const AppSetting(
      {required this.id,
      required this.language,
      required this.wifiOnly,
      required this.accessCodeValidityDays,
      required this.watermarkConfigJson,
      required this.highContrastEnabled,
      required this.solarLargeFontEnabled,
      required this.themeMode,
      required this.adminUsername,
      required this.adminPasswordHash,
      required this.photographerName,
      required this.photographerWhatsapp,
      required this.photographerEmail,
      required this.photographerPixKey,
      required this.deliveryHistoryJson,
      required this.preferredInputFolder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['language'] = Variable<String>(language);
    map['wifi_only'] = Variable<bool>(wifiOnly);
    map['access_code_validity_days'] = Variable<int>(accessCodeValidityDays);
    map['watermark_config_json'] = Variable<String>(watermarkConfigJson);
    map['high_contrast_enabled'] = Variable<bool>(highContrastEnabled);
    map['solar_large_font_enabled'] = Variable<bool>(solarLargeFontEnabled);
    map['theme_mode'] = Variable<String>(themeMode);
    map['admin_username'] = Variable<String>(adminUsername);
    map['admin_password_hash'] = Variable<String>(adminPasswordHash);
    map['photographer_name'] = Variable<String>(photographerName);
    map['photographer_whatsapp'] = Variable<String>(photographerWhatsapp);
    map['photographer_email'] = Variable<String>(photographerEmail);
    map['photographer_pix_key'] = Variable<String>(photographerPixKey);
    map['delivery_history_json'] = Variable<String>(deliveryHistoryJson);
    map['preferred_input_folder'] = Variable<String>(preferredInputFolder);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      language: Value(language),
      wifiOnly: Value(wifiOnly),
      accessCodeValidityDays: Value(accessCodeValidityDays),
      watermarkConfigJson: Value(watermarkConfigJson),
      highContrastEnabled: Value(highContrastEnabled),
      solarLargeFontEnabled: Value(solarLargeFontEnabled),
      themeMode: Value(themeMode),
      adminUsername: Value(adminUsername),
      adminPasswordHash: Value(adminPasswordHash),
      photographerName: Value(photographerName),
      photographerWhatsapp: Value(photographerWhatsapp),
      photographerEmail: Value(photographerEmail),
      photographerPixKey: Value(photographerPixKey),
      deliveryHistoryJson: Value(deliveryHistoryJson),
      preferredInputFolder: Value(preferredInputFolder),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      language: serializer.fromJson<String>(json['language']),
      wifiOnly: serializer.fromJson<bool>(json['wifiOnly']),
      accessCodeValidityDays:
          serializer.fromJson<int>(json['accessCodeValidityDays']),
      watermarkConfigJson:
          serializer.fromJson<String>(json['watermarkConfigJson']),
      highContrastEnabled:
          serializer.fromJson<bool>(json['highContrastEnabled']),
      solarLargeFontEnabled:
          serializer.fromJson<bool>(json['solarLargeFontEnabled']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      adminUsername: serializer.fromJson<String>(json['adminUsername']),
      adminPasswordHash: serializer.fromJson<String>(json['adminPasswordHash']),
      photographerName: serializer.fromJson<String>(json['photographerName']),
      photographerWhatsapp:
          serializer.fromJson<String>(json['photographerWhatsapp']),
      photographerEmail: serializer.fromJson<String>(json['photographerEmail']),
      photographerPixKey:
          serializer.fromJson<String>(json['photographerPixKey']),
      deliveryHistoryJson:
          serializer.fromJson<String>(json['deliveryHistoryJson']),
      preferredInputFolder:
          serializer.fromJson<String>(json['preferredInputFolder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'language': serializer.toJson<String>(language),
      'wifiOnly': serializer.toJson<bool>(wifiOnly),
      'accessCodeValidityDays': serializer.toJson<int>(accessCodeValidityDays),
      'watermarkConfigJson': serializer.toJson<String>(watermarkConfigJson),
      'highContrastEnabled': serializer.toJson<bool>(highContrastEnabled),
      'solarLargeFontEnabled': serializer.toJson<bool>(solarLargeFontEnabled),
      'themeMode': serializer.toJson<String>(themeMode),
      'adminUsername': serializer.toJson<String>(adminUsername),
      'adminPasswordHash': serializer.toJson<String>(adminPasswordHash),
      'photographerName': serializer.toJson<String>(photographerName),
      'photographerWhatsapp': serializer.toJson<String>(photographerWhatsapp),
      'photographerEmail': serializer.toJson<String>(photographerEmail),
      'photographerPixKey': serializer.toJson<String>(photographerPixKey),
      'deliveryHistoryJson': serializer.toJson<String>(deliveryHistoryJson),
      'preferredInputFolder': serializer.toJson<String>(preferredInputFolder),
    };
  }

  AppSetting copyWith(
          {int? id,
          String? language,
          bool? wifiOnly,
          int? accessCodeValidityDays,
          String? watermarkConfigJson,
          bool? highContrastEnabled,
          bool? solarLargeFontEnabled,
          String? themeMode,
          String? adminUsername,
          String? adminPasswordHash,
          String? photographerName,
          String? photographerWhatsapp,
          String? photographerEmail,
          String? photographerPixKey,
          String? deliveryHistoryJson,
          String? preferredInputFolder}) =>
      AppSetting(
        id: id ?? this.id,
        language: language ?? this.language,
        wifiOnly: wifiOnly ?? this.wifiOnly,
        accessCodeValidityDays:
            accessCodeValidityDays ?? this.accessCodeValidityDays,
        watermarkConfigJson: watermarkConfigJson ?? this.watermarkConfigJson,
        highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
        solarLargeFontEnabled:
            solarLargeFontEnabled ?? this.solarLargeFontEnabled,
        themeMode: themeMode ?? this.themeMode,
        adminUsername: adminUsername ?? this.adminUsername,
        adminPasswordHash: adminPasswordHash ?? this.adminPasswordHash,
        photographerName: photographerName ?? this.photographerName,
        photographerWhatsapp: photographerWhatsapp ?? this.photographerWhatsapp,
        photographerEmail: photographerEmail ?? this.photographerEmail,
        photographerPixKey: photographerPixKey ?? this.photographerPixKey,
        deliveryHistoryJson: deliveryHistoryJson ?? this.deliveryHistoryJson,
        preferredInputFolder: preferredInputFolder ?? this.preferredInputFolder,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      language: data.language.present ? data.language.value : this.language,
      wifiOnly: data.wifiOnly.present ? data.wifiOnly.value : this.wifiOnly,
      accessCodeValidityDays: data.accessCodeValidityDays.present
          ? data.accessCodeValidityDays.value
          : this.accessCodeValidityDays,
      watermarkConfigJson: data.watermarkConfigJson.present
          ? data.watermarkConfigJson.value
          : this.watermarkConfigJson,
      highContrastEnabled: data.highContrastEnabled.present
          ? data.highContrastEnabled.value
          : this.highContrastEnabled,
      solarLargeFontEnabled: data.solarLargeFontEnabled.present
          ? data.solarLargeFontEnabled.value
          : this.solarLargeFontEnabled,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      adminUsername: data.adminUsername.present
          ? data.adminUsername.value
          : this.adminUsername,
      adminPasswordHash: data.adminPasswordHash.present
          ? data.adminPasswordHash.value
          : this.adminPasswordHash,
      photographerName: data.photographerName.present
          ? data.photographerName.value
          : this.photographerName,
      photographerWhatsapp: data.photographerWhatsapp.present
          ? data.photographerWhatsapp.value
          : this.photographerWhatsapp,
      photographerEmail: data.photographerEmail.present
          ? data.photographerEmail.value
          : this.photographerEmail,
      photographerPixKey: data.photographerPixKey.present
          ? data.photographerPixKey.value
          : this.photographerPixKey,
      deliveryHistoryJson: data.deliveryHistoryJson.present
          ? data.deliveryHistoryJson.value
          : this.deliveryHistoryJson,
      preferredInputFolder: data.preferredInputFolder.present
          ? data.preferredInputFolder.value
          : this.preferredInputFolder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('accessCodeValidityDays: $accessCodeValidityDays, ')
          ..write('watermarkConfigJson: $watermarkConfigJson, ')
          ..write('highContrastEnabled: $highContrastEnabled, ')
          ..write('solarLargeFontEnabled: $solarLargeFontEnabled, ')
          ..write('themeMode: $themeMode, ')
          ..write('adminUsername: $adminUsername, ')
          ..write('adminPasswordHash: $adminPasswordHash, ')
          ..write('photographerName: $photographerName, ')
          ..write('photographerWhatsapp: $photographerWhatsapp, ')
          ..write('photographerEmail: $photographerEmail, ')
          ..write('photographerPixKey: $photographerPixKey, ')
          ..write('deliveryHistoryJson: $deliveryHistoryJson, ')
          ..write('preferredInputFolder: $preferredInputFolder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      language,
      wifiOnly,
      accessCodeValidityDays,
      watermarkConfigJson,
      highContrastEnabled,
      solarLargeFontEnabled,
      themeMode,
      adminUsername,
      adminPasswordHash,
      photographerName,
      photographerWhatsapp,
      photographerEmail,
      photographerPixKey,
      deliveryHistoryJson,
      preferredInputFolder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.language == this.language &&
          other.wifiOnly == this.wifiOnly &&
          other.accessCodeValidityDays == this.accessCodeValidityDays &&
          other.watermarkConfigJson == this.watermarkConfigJson &&
          other.highContrastEnabled == this.highContrastEnabled &&
          other.solarLargeFontEnabled == this.solarLargeFontEnabled &&
          other.themeMode == this.themeMode &&
          other.adminUsername == this.adminUsername &&
          other.adminPasswordHash == this.adminPasswordHash &&
          other.photographerName == this.photographerName &&
          other.photographerWhatsapp == this.photographerWhatsapp &&
          other.photographerEmail == this.photographerEmail &&
          other.photographerPixKey == this.photographerPixKey &&
          other.deliveryHistoryJson == this.deliveryHistoryJson &&
          other.preferredInputFolder == this.preferredInputFolder);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> language;
  final Value<bool> wifiOnly;
  final Value<int> accessCodeValidityDays;
  final Value<String> watermarkConfigJson;
  final Value<bool> highContrastEnabled;
  final Value<bool> solarLargeFontEnabled;
  final Value<String> themeMode;
  final Value<String> adminUsername;
  final Value<String> adminPasswordHash;
  final Value<String> photographerName;
  final Value<String> photographerWhatsapp;
  final Value<String> photographerEmail;
  final Value<String> photographerPixKey;
  final Value<String> deliveryHistoryJson;
  final Value<String> preferredInputFolder;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.accessCodeValidityDays = const Value.absent(),
    this.watermarkConfigJson = const Value.absent(),
    this.highContrastEnabled = const Value.absent(),
    this.solarLargeFontEnabled = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.adminUsername = const Value.absent(),
    this.adminPasswordHash = const Value.absent(),
    this.photographerName = const Value.absent(),
    this.photographerWhatsapp = const Value.absent(),
    this.photographerEmail = const Value.absent(),
    this.photographerPixKey = const Value.absent(),
    this.deliveryHistoryJson = const Value.absent(),
    this.preferredInputFolder = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.language = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.accessCodeValidityDays = const Value.absent(),
    this.watermarkConfigJson = const Value.absent(),
    this.highContrastEnabled = const Value.absent(),
    this.solarLargeFontEnabled = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.adminUsername = const Value.absent(),
    this.adminPasswordHash = const Value.absent(),
    this.photographerName = const Value.absent(),
    this.photographerWhatsapp = const Value.absent(),
    this.photographerEmail = const Value.absent(),
    this.photographerPixKey = const Value.absent(),
    this.deliveryHistoryJson = const Value.absent(),
    this.preferredInputFolder = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? language,
    Expression<bool>? wifiOnly,
    Expression<int>? accessCodeValidityDays,
    Expression<String>? watermarkConfigJson,
    Expression<bool>? highContrastEnabled,
    Expression<bool>? solarLargeFontEnabled,
    Expression<String>? themeMode,
    Expression<String>? adminUsername,
    Expression<String>? adminPasswordHash,
    Expression<String>? photographerName,
    Expression<String>? photographerWhatsapp,
    Expression<String>? photographerEmail,
    Expression<String>? photographerPixKey,
    Expression<String>? deliveryHistoryJson,
    Expression<String>? preferredInputFolder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (language != null) 'language': language,
      if (wifiOnly != null) 'wifi_only': wifiOnly,
      if (accessCodeValidityDays != null)
        'access_code_validity_days': accessCodeValidityDays,
      if (watermarkConfigJson != null)
        'watermark_config_json': watermarkConfigJson,
      if (highContrastEnabled != null)
        'high_contrast_enabled': highContrastEnabled,
      if (solarLargeFontEnabled != null)
        'solar_large_font_enabled': solarLargeFontEnabled,
      if (themeMode != null) 'theme_mode': themeMode,
      if (adminUsername != null) 'admin_username': adminUsername,
      if (adminPasswordHash != null) 'admin_password_hash': adminPasswordHash,
      if (photographerName != null) 'photographer_name': photographerName,
      if (photographerWhatsapp != null)
        'photographer_whatsapp': photographerWhatsapp,
      if (photographerEmail != null) 'photographer_email': photographerEmail,
      if (photographerPixKey != null)
        'photographer_pix_key': photographerPixKey,
      if (deliveryHistoryJson != null)
        'delivery_history_json': deliveryHistoryJson,
      if (preferredInputFolder != null)
        'preferred_input_folder': preferredInputFolder,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? language,
      Value<bool>? wifiOnly,
      Value<int>? accessCodeValidityDays,
      Value<String>? watermarkConfigJson,
      Value<bool>? highContrastEnabled,
      Value<bool>? solarLargeFontEnabled,
      Value<String>? themeMode,
      Value<String>? adminUsername,
      Value<String>? adminPasswordHash,
      Value<String>? photographerName,
      Value<String>? photographerWhatsapp,
      Value<String>? photographerEmail,
      Value<String>? photographerPixKey,
      Value<String>? deliveryHistoryJson,
      Value<String>? preferredInputFolder}) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      language: language ?? this.language,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      accessCodeValidityDays:
          accessCodeValidityDays ?? this.accessCodeValidityDays,
      watermarkConfigJson: watermarkConfigJson ?? this.watermarkConfigJson,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      solarLargeFontEnabled:
          solarLargeFontEnabled ?? this.solarLargeFontEnabled,
      themeMode: themeMode ?? this.themeMode,
      adminUsername: adminUsername ?? this.adminUsername,
      adminPasswordHash: adminPasswordHash ?? this.adminPasswordHash,
      photographerName: photographerName ?? this.photographerName,
      photographerWhatsapp: photographerWhatsapp ?? this.photographerWhatsapp,
      photographerEmail: photographerEmail ?? this.photographerEmail,
      photographerPixKey: photographerPixKey ?? this.photographerPixKey,
      deliveryHistoryJson: deliveryHistoryJson ?? this.deliveryHistoryJson,
      preferredInputFolder: preferredInputFolder ?? this.preferredInputFolder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (wifiOnly.present) {
      map['wifi_only'] = Variable<bool>(wifiOnly.value);
    }
    if (accessCodeValidityDays.present) {
      map['access_code_validity_days'] =
          Variable<int>(accessCodeValidityDays.value);
    }
    if (watermarkConfigJson.present) {
      map['watermark_config_json'] =
          Variable<String>(watermarkConfigJson.value);
    }
    if (highContrastEnabled.present) {
      map['high_contrast_enabled'] = Variable<bool>(highContrastEnabled.value);
    }
    if (solarLargeFontEnabled.present) {
      map['solar_large_font_enabled'] =
          Variable<bool>(solarLargeFontEnabled.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (adminUsername.present) {
      map['admin_username'] = Variable<String>(adminUsername.value);
    }
    if (adminPasswordHash.present) {
      map['admin_password_hash'] = Variable<String>(adminPasswordHash.value);
    }
    if (photographerName.present) {
      map['photographer_name'] = Variable<String>(photographerName.value);
    }
    if (photographerWhatsapp.present) {
      map['photographer_whatsapp'] =
          Variable<String>(photographerWhatsapp.value);
    }
    if (photographerEmail.present) {
      map['photographer_email'] = Variable<String>(photographerEmail.value);
    }
    if (photographerPixKey.present) {
      map['photographer_pix_key'] = Variable<String>(photographerPixKey.value);
    }
    if (deliveryHistoryJson.present) {
      map['delivery_history_json'] =
          Variable<String>(deliveryHistoryJson.value);
    }
    if (preferredInputFolder.present) {
      map['preferred_input_folder'] =
          Variable<String>(preferredInputFolder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('language: $language, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('accessCodeValidityDays: $accessCodeValidityDays, ')
          ..write('watermarkConfigJson: $watermarkConfigJson, ')
          ..write('highContrastEnabled: $highContrastEnabled, ')
          ..write('solarLargeFontEnabled: $solarLargeFontEnabled, ')
          ..write('themeMode: $themeMode, ')
          ..write('adminUsername: $adminUsername, ')
          ..write('adminPasswordHash: $adminPasswordHash, ')
          ..write('photographerName: $photographerName, ')
          ..write('photographerWhatsapp: $photographerWhatsapp, ')
          ..write('photographerEmail: $photographerEmail, ')
          ..write('photographerPixKey: $photographerPixKey, ')
          ..write('deliveryHistoryJson: $deliveryHistoryJson, ')
          ..write('preferredInputFolder: $preferredInputFolder')
          ..write(')'))
        .toString();
  }
}

class $UploadTasksTable extends UploadTasks
    with TableInfo<$UploadTasksTable, UploadTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
      'order_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, orderId, status, retryCount, nextAttemptAt, lastError, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<UploadTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UploadTasksTable createAlias(String alias) {
    return $UploadTasksTable(attachedDatabase, alias);
  }
}

class UploadTask extends DataClass implements Insertable<UploadTask> {
  final String id;
  final String orderId;
  final String status;
  final int retryCount;
  final DateTime nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  const UploadTask(
      {required this.id,
      required this.orderId,
      required this.status,
      required this.retryCount,
      required this.nextAttemptAt,
      this.lastError,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UploadTasksCompanion toCompanion(bool nullToAbsent) {
    return UploadTasksCompanion(
      id: Value(id),
      orderId: Value(orderId),
      status: Value(status),
      retryCount: Value(retryCount),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory UploadTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadTask(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UploadTask copyWith(
          {String? id,
          String? orderId,
          String? status,
          int? retryCount,
          DateTime? nextAttemptAt,
          Value<String?> lastError = const Value.absent(),
          DateTime? createdAt}) =>
      UploadTask(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError.present ? lastError.value : this.lastError,
        createdAt: createdAt ?? this.createdAt,
      );
  UploadTask copyWithCompanion(UploadTasksCompanion data) {
    return UploadTask(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadTask(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, orderId, status, retryCount, nextAttemptAt, lastError, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadTask &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class UploadTasksCompanion extends UpdateCompanion<UploadTask> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UploadTasksCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UploadTasksCompanion.insert({
    required String id,
    required String orderId,
    required String status,
    this.retryCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        orderId = Value(orderId),
        status = Value(status);
  static Insertable<UploadTask> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UploadTasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? orderId,
      Value<String>? status,
      Value<int>? retryCount,
      Value<DateTime>? nextAttemptAt,
      Value<String?>? lastError,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return UploadTasksCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
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
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
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
    return (StringBuffer('UploadTasksCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClientsTable clients = $ClientsTable(this);
  late final $PhotoAssetsTable photoAssets = $PhotoAssetsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $UploadTasksTable uploadTasks = $UploadTasksTable(this);
  late final Index photoAssetsCapturedAtIdx = Index(
      'photo_assets_captured_at_idx',
      'CREATE INDEX photo_assets_captured_at_idx ON photo_assets (captured_at)');
  late final Index ordersStatusCreatedAtIdx = Index(
      'orders_status_created_at_idx',
      'CREATE INDEX orders_status_created_at_idx ON orders (status, created_at)');
  late final Index uploadTasksStatusNextAttemptIdx = Index(
      'upload_tasks_status_next_attempt_idx',
      'CREATE INDEX upload_tasks_status_next_attempt_idx ON upload_tasks (status, next_attempt_at)');
  late final Index uploadTasksOrderIdIdx = Index('upload_tasks_order_id_idx',
      'CREATE INDEX upload_tasks_order_id_idx ON upload_tasks (order_id)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        clients,
        photoAssets,
        orders,
        orderItems,
        appSettings,
        uploadTasks,
        photoAssetsCapturedAtIdx,
        ordersStatusCreatedAtIdx,
        uploadTasksStatusNextAttemptIdx,
        uploadTasksOrderIdIdx
      ];
}

typedef $$ClientsTableCreateCompanionBuilder = ClientsCompanion Function({
  required String id,
  required String name,
  required String whatsapp,
  Value<String?> email,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ClientsTableUpdateCompanionBuilder = ClientsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> whatsapp,
  Value<String?> email,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ClientsTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get whatsapp => $composableBuilder(
      column: $table.whatsapp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ClientsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get whatsapp => $composableBuilder(
      column: $table.whatsapp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ClientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTable> {
  $$ClientsTableAnnotationComposer({
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

  GeneratedColumn<String> get whatsapp =>
      $composableBuilder(column: $table.whatsapp, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ClientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClientsTable,
    Client,
    $$ClientsTableFilterComposer,
    $$ClientsTableOrderingComposer,
    $$ClientsTableAnnotationComposer,
    $$ClientsTableCreateCompanionBuilder,
    $$ClientsTableUpdateCompanionBuilder,
    (Client, BaseReferences<_$AppDatabase, $ClientsTable, Client>),
    Client,
    PrefetchHooks Function()> {
  $$ClientsTableTableManager(_$AppDatabase db, $ClientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> whatsapp = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClientsCompanion(
            id: id,
            name: name,
            whatsapp: whatsapp,
            email: email,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String whatsapp,
            Value<String?> email = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClientsCompanion.insert(
            id: id,
            name: name,
            whatsapp: whatsapp,
            email: email,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ClientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClientsTable,
    Client,
    $$ClientsTableFilterComposer,
    $$ClientsTableOrderingComposer,
    $$ClientsTableAnnotationComposer,
    $$ClientsTableCreateCompanionBuilder,
    $$ClientsTableUpdateCompanionBuilder,
    (Client, BaseReferences<_$AppDatabase, $ClientsTable, Client>),
    Client,
    PrefetchHooks Function()>;
typedef $$PhotoAssetsTableCreateCompanionBuilder = PhotoAssetsCompanion
    Function({
  required String id,
  required String localPath,
  required String thumbnailKey,
  required DateTime capturedAt,
  required String checksum,
  required String uploadStatus,
  Value<String?> storagePath,
  Value<int> rowid,
});
typedef $$PhotoAssetsTableUpdateCompanionBuilder = PhotoAssetsCompanion
    Function({
  Value<String> id,
  Value<String> localPath,
  Value<String> thumbnailKey,
  Value<DateTime> capturedAt,
  Value<String> checksum,
  Value<String> uploadStatus,
  Value<String?> storagePath,
  Value<int> rowid,
});

final class $$PhotoAssetsTableReferences
    extends BaseReferences<_$AppDatabase, $PhotoAssetsTable, PhotoAsset> {
  $$PhotoAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItem>>
      _orderItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.orderItems,
              aliasName: $_aliasNameGenerator(
                  db.photoAssets.id, db.orderItems.photoAssetId));

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager($_db, $_db.orderItems).filter(
        (f) => f.photoAssetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PhotoAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $PhotoAssetsTable> {
  $$PhotoAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailKey => $composableBuilder(
      column: $table.thumbnailKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checksum => $composableBuilder(
      column: $table.checksum, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnFilters(column));

  Expression<bool> orderItemsRefs(
      Expression<bool> Function($$OrderItemsTableFilterComposer f) f) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.photoAssetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableFilterComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PhotoAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotoAssetsTable> {
  $$PhotoAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailKey => $composableBuilder(
      column: $table.thumbnailKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checksum => $composableBuilder(
      column: $table.checksum, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => ColumnOrderings(column));
}

class $$PhotoAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotoAssetsTable> {
  $$PhotoAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailKey => $composableBuilder(
      column: $table.thumbnailKey, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get uploadStatus => $composableBuilder(
      column: $table.uploadStatus, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
      column: $table.storagePath, builder: (column) => column);

  Expression<T> orderItemsRefs<T extends Object>(
      Expression<T> Function($$OrderItemsTableAnnotationComposer a) f) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.photoAssetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PhotoAssetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PhotoAssetsTable,
    PhotoAsset,
    $$PhotoAssetsTableFilterComposer,
    $$PhotoAssetsTableOrderingComposer,
    $$PhotoAssetsTableAnnotationComposer,
    $$PhotoAssetsTableCreateCompanionBuilder,
    $$PhotoAssetsTableUpdateCompanionBuilder,
    (PhotoAsset, $$PhotoAssetsTableReferences),
    PhotoAsset,
    PrefetchHooks Function({bool orderItemsRefs})> {
  $$PhotoAssetsTableTableManager(_$AppDatabase db, $PhotoAssetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String> thumbnailKey = const Value.absent(),
            Value<DateTime> capturedAt = const Value.absent(),
            Value<String> checksum = const Value.absent(),
            Value<String> uploadStatus = const Value.absent(),
            Value<String?> storagePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotoAssetsCompanion(
            id: id,
            localPath: localPath,
            thumbnailKey: thumbnailKey,
            capturedAt: capturedAt,
            checksum: checksum,
            uploadStatus: uploadStatus,
            storagePath: storagePath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String localPath,
            required String thumbnailKey,
            required DateTime capturedAt,
            required String checksum,
            required String uploadStatus,
            Value<String?> storagePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotoAssetsCompanion.insert(
            id: id,
            localPath: localPath,
            thumbnailKey: thumbnailKey,
            capturedAt: capturedAt,
            checksum: checksum,
            uploadStatus: uploadStatus,
            storagePath: storagePath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PhotoAssetsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({orderItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (orderItemsRefs) db.orderItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderItemsRefs)
                    await $_getPrefetchedData<PhotoAsset, $PhotoAssetsTable,
                            OrderItem>(
                        currentTable: table,
                        referencedTable: $$PhotoAssetsTableReferences
                            ._orderItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PhotoAssetsTableReferences(db, table, p0)
                                .orderItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.photoAssetId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PhotoAssetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PhotoAssetsTable,
    PhotoAsset,
    $$PhotoAssetsTableFilterComposer,
    $$PhotoAssetsTableOrderingComposer,
    $$PhotoAssetsTableAnnotationComposer,
    $$PhotoAssetsTableCreateCompanionBuilder,
    $$PhotoAssetsTableUpdateCompanionBuilder,
    (PhotoAsset, $$PhotoAssetsTableReferences),
    PhotoAsset,
    PrefetchHooks Function({bool orderItemsRefs})>;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  required String id,
  required String clientId,
  required int totalAmountCents,
  Value<String> currency,
  required String status,
  required String paymentMethod,
  required String externalReference,
  Value<String?> providerDataJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<String> id,
  Value<String> clientId,
  Value<int> totalAmountCents,
  Value<String> currency,
  Value<String> status,
  Value<String> paymentMethod,
  Value<String> externalReference,
  Value<String?> providerDataJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, Order> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItem>>
      _orderItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.orderItems,
          aliasName: $_aliasNameGenerator(db.orders.id, db.orderItems.orderId));

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager($_db, $_db.orderItems)
        .filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UploadTasksTable, List<UploadTask>>
      _uploadTasksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.uploadTasks,
              aliasName:
                  $_aliasNameGenerator(db.orders.id, db.uploadTasks.orderId));

  $$UploadTasksTableProcessedTableManager get uploadTasksRefs {
    final manager = $$UploadTasksTableTableManager($_db, $_db.uploadTasks)
        .filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_uploadTasksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalReference => $composableBuilder(
      column: $table.externalReference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerDataJson => $composableBuilder(
      column: $table.providerDataJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> orderItemsRefs(
      Expression<bool> Function($$OrderItemsTableFilterComposer f) f) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableFilterComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> uploadTasksRefs(
      Expression<bool> Function($$UploadTasksTableFilterComposer f) f) {
    final $$UploadTasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.uploadTasks,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UploadTasksTableFilterComposer(
              $db: $db,
              $table: $db.uploadTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientId => $composableBuilder(
      column: $table.clientId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalReference => $composableBuilder(
      column: $table.externalReference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerDataJson => $composableBuilder(
      column: $table.providerDataJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get totalAmountCents => $composableBuilder(
      column: $table.totalAmountCents, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get externalReference => $composableBuilder(
      column: $table.externalReference, builder: (column) => column);

  GeneratedColumn<String> get providerDataJson => $composableBuilder(
      column: $table.providerDataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> orderItemsRefs<T extends Object>(
      Expression<T> Function($$OrderItemsTableAnnotationComposer a) f) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> uploadTasksRefs<T extends Object>(
      Expression<T> Function($$UploadTasksTableAnnotationComposer a) f) {
    final $$UploadTasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.uploadTasks,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UploadTasksTableAnnotationComposer(
              $db: $db,
              $table: $db.uploadTasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, $$OrdersTableReferences),
    Order,
    PrefetchHooks Function({bool orderItemsRefs, bool uploadTasksRefs})> {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> clientId = const Value.absent(),
            Value<int> totalAmountCents = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<String> externalReference = const Value.absent(),
            Value<String?> providerDataJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion(
            id: id,
            clientId: clientId,
            totalAmountCents: totalAmountCents,
            currency: currency,
            status: status,
            paymentMethod: paymentMethod,
            externalReference: externalReference,
            providerDataJson: providerDataJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String clientId,
            required int totalAmountCents,
            Value<String> currency = const Value.absent(),
            required String status,
            required String paymentMethod,
            required String externalReference,
            Value<String?> providerDataJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrdersCompanion.insert(
            id: id,
            clientId: clientId,
            totalAmountCents: totalAmountCents,
            currency: currency,
            status: status,
            paymentMethod: paymentMethod,
            externalReference: externalReference,
            providerDataJson: providerDataJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$OrdersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {orderItemsRefs = false, uploadTasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (orderItemsRefs) db.orderItems,
                if (uploadTasksRefs) db.uploadTasks
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderItemsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, OrderItem>(
                        currentTable: table,
                        referencedTable:
                            $$OrdersTableReferences._orderItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0)
                                .orderItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items),
                  if (uploadTasksRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, UploadTask>(
                        currentTable: table,
                        referencedTable:
                            $$OrdersTableReferences._uploadTasksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0)
                                .uploadTasksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, $$OrdersTableReferences),
    Order,
    PrefetchHooks Function({bool orderItemsRefs, bool uploadTasksRefs})>;
typedef $$OrderItemsTableCreateCompanionBuilder = OrderItemsCompanion Function({
  required String id,
  required String orderId,
  required String photoAssetId,
  required int unitPriceCents,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$OrderItemsTableUpdateCompanionBuilder = OrderItemsCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> photoAssetId,
  Value<int> unitPriceCents,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$OrderItemsTableReferences
    extends BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItem> {
  $$OrderItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders
      .createAlias($_aliasNameGenerator(db.orderItems.orderId, db.orders.id));

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PhotoAssetsTable _photoAssetIdTable(_$AppDatabase db) =>
      db.photoAssets.createAlias(
          $_aliasNameGenerator(db.orderItems.photoAssetId, db.photoAssets.id));

  $$PhotoAssetsTableProcessedTableManager get photoAssetId {
    final $_column = $_itemColumn<String>('photo_asset_id')!;

    final manager = $$PhotoAssetsTableTableManager($_db, $_db.photoAssets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_photoAssetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OrderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotoAssetsTableFilterComposer get photoAssetId {
    final $$PhotoAssetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.photoAssetId,
        referencedTable: $db.photoAssets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotoAssetsTableFilterComposer(
              $db: $db,
              $table: $db.photoAssets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotoAssetsTableOrderingComposer get photoAssetId {
    final $$PhotoAssetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.photoAssetId,
        referencedTable: $db.photoAssets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotoAssetsTableOrderingComposer(
              $db: $db,
              $table: $db.photoAssets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get unitPriceCents => $composableBuilder(
      column: $table.unitPriceCents, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotoAssetsTableAnnotationComposer get photoAssetId {
    final $$PhotoAssetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.photoAssetId,
        referencedTable: $db.photoAssets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotoAssetsTableAnnotationComposer(
              $db: $db,
              $table: $db.photoAssets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrderItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrderItemsTable,
    OrderItem,
    $$OrderItemsTableFilterComposer,
    $$OrderItemsTableOrderingComposer,
    $$OrderItemsTableAnnotationComposer,
    $$OrderItemsTableCreateCompanionBuilder,
    $$OrderItemsTableUpdateCompanionBuilder,
    (OrderItem, $$OrderItemsTableReferences),
    OrderItem,
    PrefetchHooks Function({bool orderId, bool photoAssetId})> {
  $$OrderItemsTableTableManager(_$AppDatabase db, $OrderItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> photoAssetId = const Value.absent(),
            Value<int> unitPriceCents = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrderItemsCompanion(
            id: id,
            orderId: orderId,
            photoAssetId: photoAssetId,
            unitPriceCents: unitPriceCents,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            required String photoAssetId,
            required int unitPriceCents,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OrderItemsCompanion.insert(
            id: id,
            orderId: orderId,
            photoAssetId: photoAssetId,
            unitPriceCents: unitPriceCents,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OrderItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({orderId = false, photoAssetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$OrderItemsTableReferences._orderIdTable(db),
                    referencedColumn:
                        $$OrderItemsTableReferences._orderIdTable(db).id,
                  ) as T;
                }
                if (photoAssetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.photoAssetId,
                    referencedTable:
                        $$OrderItemsTableReferences._photoAssetIdTable(db),
                    referencedColumn:
                        $$OrderItemsTableReferences._photoAssetIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$OrderItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrderItemsTable,
    OrderItem,
    $$OrderItemsTableFilterComposer,
    $$OrderItemsTableOrderingComposer,
    $$OrderItemsTableAnnotationComposer,
    $$OrderItemsTableCreateCompanionBuilder,
    $$OrderItemsTableUpdateCompanionBuilder,
    (OrderItem, $$OrderItemsTableReferences),
    OrderItem,
    PrefetchHooks Function({bool orderId, bool photoAssetId})>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<String> language,
  Value<bool> wifiOnly,
  Value<int> accessCodeValidityDays,
  Value<String> watermarkConfigJson,
  Value<bool> highContrastEnabled,
  Value<bool> solarLargeFontEnabled,
  Value<String> themeMode,
  Value<String> adminUsername,
  Value<String> adminPasswordHash,
  Value<String> photographerName,
  Value<String> photographerWhatsapp,
  Value<String> photographerEmail,
  Value<String> photographerPixKey,
  Value<String> deliveryHistoryJson,
  Value<String> preferredInputFolder,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<String> language,
  Value<bool> wifiOnly,
  Value<int> accessCodeValidityDays,
  Value<String> watermarkConfigJson,
  Value<bool> highContrastEnabled,
  Value<bool> solarLargeFontEnabled,
  Value<String> themeMode,
  Value<String> adminUsername,
  Value<String> adminPasswordHash,
  Value<String> photographerName,
  Value<String> photographerWhatsapp,
  Value<String> photographerEmail,
  Value<String> photographerPixKey,
  Value<String> deliveryHistoryJson,
  Value<String> preferredInputFolder,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wifiOnly => $composableBuilder(
      column: $table.wifiOnly, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accessCodeValidityDays => $composableBuilder(
      column: $table.accessCodeValidityDays,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get watermarkConfigJson => $composableBuilder(
      column: $table.watermarkConfigJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get highContrastEnabled => $composableBuilder(
      column: $table.highContrastEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get solarLargeFontEnabled => $composableBuilder(
      column: $table.solarLargeFontEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get adminUsername => $composableBuilder(
      column: $table.adminUsername, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get adminPasswordHash => $composableBuilder(
      column: $table.adminPasswordHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photographerName => $composableBuilder(
      column: $table.photographerName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photographerWhatsapp => $composableBuilder(
      column: $table.photographerWhatsapp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photographerEmail => $composableBuilder(
      column: $table.photographerEmail,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photographerPixKey => $composableBuilder(
      column: $table.photographerPixKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveryHistoryJson => $composableBuilder(
      column: $table.deliveryHistoryJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get preferredInputFolder => $composableBuilder(
      column: $table.preferredInputFolder,
      builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wifiOnly => $composableBuilder(
      column: $table.wifiOnly, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accessCodeValidityDays => $composableBuilder(
      column: $table.accessCodeValidityDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get watermarkConfigJson => $composableBuilder(
      column: $table.watermarkConfigJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get highContrastEnabled => $composableBuilder(
      column: $table.highContrastEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get solarLargeFontEnabled => $composableBuilder(
      column: $table.solarLargeFontEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get adminUsername => $composableBuilder(
      column: $table.adminUsername,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get adminPasswordHash => $composableBuilder(
      column: $table.adminPasswordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photographerName => $composableBuilder(
      column: $table.photographerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photographerWhatsapp => $composableBuilder(
      column: $table.photographerWhatsapp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photographerEmail => $composableBuilder(
      column: $table.photographerEmail,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photographerPixKey => $composableBuilder(
      column: $table.photographerPixKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveryHistoryJson => $composableBuilder(
      column: $table.deliveryHistoryJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get preferredInputFolder => $composableBuilder(
      column: $table.preferredInputFolder,
      builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<bool> get wifiOnly =>
      $composableBuilder(column: $table.wifiOnly, builder: (column) => column);

  GeneratedColumn<int> get accessCodeValidityDays => $composableBuilder(
      column: $table.accessCodeValidityDays, builder: (column) => column);

  GeneratedColumn<String> get watermarkConfigJson => $composableBuilder(
      column: $table.watermarkConfigJson, builder: (column) => column);

  GeneratedColumn<bool> get highContrastEnabled => $composableBuilder(
      column: $table.highContrastEnabled, builder: (column) => column);

  GeneratedColumn<bool> get solarLargeFontEnabled => $composableBuilder(
      column: $table.solarLargeFontEnabled, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get adminUsername => $composableBuilder(
      column: $table.adminUsername, builder: (column) => column);

  GeneratedColumn<String> get adminPasswordHash => $composableBuilder(
      column: $table.adminPasswordHash, builder: (column) => column);

  GeneratedColumn<String> get photographerName => $composableBuilder(
      column: $table.photographerName, builder: (column) => column);

  GeneratedColumn<String> get photographerWhatsapp => $composableBuilder(
      column: $table.photographerWhatsapp, builder: (column) => column);

  GeneratedColumn<String> get photographerEmail => $composableBuilder(
      column: $table.photographerEmail, builder: (column) => column);

  GeneratedColumn<String> get photographerPixKey => $composableBuilder(
      column: $table.photographerPixKey, builder: (column) => column);

  GeneratedColumn<String> get deliveryHistoryJson => $composableBuilder(
      column: $table.deliveryHistoryJson, builder: (column) => column);

  GeneratedColumn<String> get preferredInputFolder => $composableBuilder(
      column: $table.preferredInputFolder, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<bool> wifiOnly = const Value.absent(),
            Value<int> accessCodeValidityDays = const Value.absent(),
            Value<String> watermarkConfigJson = const Value.absent(),
            Value<bool> highContrastEnabled = const Value.absent(),
            Value<bool> solarLargeFontEnabled = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> adminUsername = const Value.absent(),
            Value<String> adminPasswordHash = const Value.absent(),
            Value<String> photographerName = const Value.absent(),
            Value<String> photographerWhatsapp = const Value.absent(),
            Value<String> photographerEmail = const Value.absent(),
            Value<String> photographerPixKey = const Value.absent(),
            Value<String> deliveryHistoryJson = const Value.absent(),
            Value<String> preferredInputFolder = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            id: id,
            language: language,
            wifiOnly: wifiOnly,
            accessCodeValidityDays: accessCodeValidityDays,
            watermarkConfigJson: watermarkConfigJson,
            highContrastEnabled: highContrastEnabled,
            solarLargeFontEnabled: solarLargeFontEnabled,
            themeMode: themeMode,
            adminUsername: adminUsername,
            adminPasswordHash: adminPasswordHash,
            photographerName: photographerName,
            photographerWhatsapp: photographerWhatsapp,
            photographerEmail: photographerEmail,
            photographerPixKey: photographerPixKey,
            deliveryHistoryJson: deliveryHistoryJson,
            preferredInputFolder: preferredInputFolder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<bool> wifiOnly = const Value.absent(),
            Value<int> accessCodeValidityDays = const Value.absent(),
            Value<String> watermarkConfigJson = const Value.absent(),
            Value<bool> highContrastEnabled = const Value.absent(),
            Value<bool> solarLargeFontEnabled = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> adminUsername = const Value.absent(),
            Value<String> adminPasswordHash = const Value.absent(),
            Value<String> photographerName = const Value.absent(),
            Value<String> photographerWhatsapp = const Value.absent(),
            Value<String> photographerEmail = const Value.absent(),
            Value<String> photographerPixKey = const Value.absent(),
            Value<String> deliveryHistoryJson = const Value.absent(),
            Value<String> preferredInputFolder = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            id: id,
            language: language,
            wifiOnly: wifiOnly,
            accessCodeValidityDays: accessCodeValidityDays,
            watermarkConfigJson: watermarkConfigJson,
            highContrastEnabled: highContrastEnabled,
            solarLargeFontEnabled: solarLargeFontEnabled,
            themeMode: themeMode,
            adminUsername: adminUsername,
            adminPasswordHash: adminPasswordHash,
            photographerName: photographerName,
            photographerWhatsapp: photographerWhatsapp,
            photographerEmail: photographerEmail,
            photographerPixKey: photographerPixKey,
            deliveryHistoryJson: deliveryHistoryJson,
            preferredInputFolder: preferredInputFolder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$UploadTasksTableCreateCompanionBuilder = UploadTasksCompanion
    Function({
  required String id,
  required String orderId,
  required String status,
  Value<int> retryCount,
  Value<DateTime> nextAttemptAt,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$UploadTasksTableUpdateCompanionBuilder = UploadTasksCompanion
    Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> status,
  Value<int> retryCount,
  Value<DateTime> nextAttemptAt,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$UploadTasksTableReferences
    extends BaseReferences<_$AppDatabase, $UploadTasksTable, UploadTask> {
  $$UploadTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders
      .createAlias($_aliasNameGenerator(db.uploadTasks.orderId, db.orders.id));

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UploadTasksTableFilterComposer
    extends Composer<_$AppDatabase, $UploadTasksTable> {
  $$UploadTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UploadTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadTasksTable> {
  $$UploadTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UploadTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadTasksTable> {
  $$UploadTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UploadTasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UploadTasksTable,
    UploadTask,
    $$UploadTasksTableFilterComposer,
    $$UploadTasksTableOrderingComposer,
    $$UploadTasksTableAnnotationComposer,
    $$UploadTasksTableCreateCompanionBuilder,
    $$UploadTasksTableUpdateCompanionBuilder,
    (UploadTask, $$UploadTasksTableReferences),
    UploadTask,
    PrefetchHooks Function({bool orderId})> {
  $$UploadTasksTableTableManager(_$AppDatabase db, $UploadTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> orderId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UploadTasksCompanion(
            id: id,
            orderId: orderId,
            status: status,
            retryCount: retryCount,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String orderId,
            required String status,
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> nextAttemptAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UploadTasksCompanion.insert(
            id: id,
            orderId: orderId,
            status: status,
            retryCount: retryCount,
            nextAttemptAt: nextAttemptAt,
            lastError: lastError,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UploadTasksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$UploadTasksTableReferences._orderIdTable(db),
                    referencedColumn:
                        $$UploadTasksTableReferences._orderIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UploadTasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UploadTasksTable,
    UploadTask,
    $$UploadTasksTableFilterComposer,
    $$UploadTasksTableOrderingComposer,
    $$UploadTasksTableAnnotationComposer,
    $$UploadTasksTableCreateCompanionBuilder,
    $$UploadTasksTableUpdateCompanionBuilder,
    (UploadTask, $$UploadTasksTableReferences),
    UploadTask,
    PrefetchHooks Function({bool orderId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClientsTableTableManager get clients =>
      $$ClientsTableTableManager(_db, _db.clients);
  $$PhotoAssetsTableTableManager get photoAssets =>
      $$PhotoAssetsTableTableManager(_db, _db.photoAssets);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$UploadTasksTableTableManager get uploadTasks =>
      $$UploadTasksTableTableManager(_db, _db.uploadTasks);
}
