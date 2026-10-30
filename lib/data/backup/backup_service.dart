import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/errors/app_exception.dart';
import '../../database/app_database.dart';

enum RestoreMode {
  /// Delete everything on this device, then load the backup.
  replace,

  /// Keep current data and add records from the backup whose ids are new.
  merge;

  String get label => switch (this) {
        replace => 'Replace all data on this device',
        merge => 'Merge — add records that are missing',
      };
}

/// A validated, decrypted backup ready to restore.
class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.schemaVersion,
    required this.appVersion,
    required this.counts,
    required this.tables,
    required this.encrypted,
  });

  final DateTime createdAt;
  final int schemaVersion;
  final String appVersion;
  final Map<String, int> counts;
  final bool encrypted;
  final Map<String, List<Map<String, dynamic>>> tables;

  int get sourceCount => counts['income_sources'] ?? 0;
  int get ledgerCount => counts['ledger_entries'] ?? 0;
  int get accountCount => counts['accounts'] ?? 0;
  int get combinedCount => counts['combined_accounts'] ?? 0;
}

class RestoreResult {
  const RestoreResult({required this.inserted, required this.skipped});
  final int inserted;

  /// Records already present (merge mode) — never duplicated.
  final int skipped;
}

/// Versioned, integrity-checked and optionally encrypted backups.
///
/// File layout (JSON):
/// ```
/// { "format": "earnlens-backup", "formatVersion": 1, "schemaVersion": 2,
///   "appVersion": "...", "createdAt": "...", "counts": {...},
///   "sha256": "<hex of payload JSON>",
///   "payload": {...}                      // unencrypted backups
///   "cipher": { "alg": "AES-256-GCM", "kdf": "PBKDF2-HMAC-SHA256",
///               "iterations": n, "salt": b64, "nonce": b64,
///               "ciphertext": b64, "mac": b64 } }   // encrypted backups
/// ```
/// The PIN and other secure-store secrets are never included. Accounts,
/// combined accounts and their memberships are included; account PINs are
/// not, so restored accounts start without one.
///
/// Schema 1 backups (before accounts existed) are upgraded on import: all of
/// their records go into one "Personal" account whose id is derived from the
/// backup, so restoring the same file twice never creates two accounts.
class BackupService {
  BackupService(this.db, this.clock, {this.kdfIterations = 210000, this.appVersion = '2.0.1'});

  static const format = 'earnlens-backup';
  static const formatVersion = 1;

  final AppDatabase db;
  final Clock clock;
  final int kdfIterations;
  final String appVersion;

  /// Row (de)serialisers for every table, in foreign-key insert order.
  late final List<_TableCodec> _codecs = [
    _TableCodec(db.profiles, ProfileRow.fromJson),
    _TableCodec(db.settings, SettingRow.fromJson),
    _TableCodec(db.accounts, AccountRow.fromJson),
    _TableCodec(db.combinedAccounts, CombinedAccountRow.fromJson),
    _TableCodec(db.combinedAccountMembers, CombinedMemberRow.fromJson),
    _TableCodec(db.incomeSources, IncomeSourceRow.fromJson),
    _TableCodec(db.rateRevisions, RateRevisionRow.fromJson),
    _TableCodec(db.sourcePauses, SourcePauseRow.fromJson),
    _TableCodec(db.dayOverrides, DayOverrideRow.fromJson),
    _TableCodec(db.compensationItems, CompensationItemRow.fromJson),
    _TableCodec(db.monthlyRecords, MonthlyRecordRow.fromJson),
    _TableCodec(db.ledgerEntries, LedgerEntryRow.fromJson),
    _TableCodec(db.calendarEvents, CalendarEventRow.fromJson),
    _TableCodec(db.auditLog, AuditRow.fromJson),
  ];

  Future<Uint8List> createBackup({String? password}) async {
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final c in _codecs) {
      final rows = await db.select(c.table).get();
      tables[c.table.actualTableName] = [for (final r in rows) (r as DataClass).toJson()];
    }
    final payloadJson = jsonEncode({'tables': tables});
    final digest = await Sha256().hash(utf8.encode(payloadJson));
    final envelope = <String, dynamic>{
      'format': format,
      'formatVersion': formatVersion,
      'schemaVersion': db.schemaVersion,
      'appVersion': appVersion,
      'createdAt': clock.now().toIso8601String(),
      'counts': {for (final e in tables.entries) e.key: e.value.length},
      'sha256': _hex(digest.bytes),
    };
    if (password == null || password.isEmpty) {
      envelope['payload'] = jsonDecode(payloadJson);
    } else {
      envelope['cipher'] = await _encrypt(utf8.encode(payloadJson), password);
    }
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  /// Returns true when the file is an encrypted backup (needs a password).
  static bool isEncrypted(Uint8List bytes) {
    try {
      final env = jsonDecode(utf8.decode(bytes)) as Map;
      return env['cipher'] != null;
    } on Object {
      return false;
    }
  }

  /// Parses, decrypts and validates a backup without touching the database.
  Future<BackupPreview> inspect(Uint8List bytes, {String? password}) async {
    final Map<String, dynamic> env;
    try {
      env = (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
    } on Object {
      throw const BackupException('This file is not an EarnLens backup.');
    }
    if (env['format'] != format) throw const BackupException('This file is not an EarnLens backup.');
    final fv = env['formatVersion'];
    if (fv is! int || fv > formatVersion) {
      throw const BackupException('This backup was made by a newer version of EarnLens. Update the app first.');
    }
    final schema = env['schemaVersion'];
    if (schema is! int || schema > db.schemaVersion) {
      throw const BackupException('This backup uses a newer database version. Update the app first.');
    }

    final String payloadJson;
    final encrypted = env['cipher'] != null;
    if (encrypted) {
      if (password == null || password.isEmpty) throw const BackupException('This backup is password protected.');
      payloadJson = utf8.decode(await _decrypt((env['cipher'] as Map).cast(), password));
    } else {
      payloadJson = jsonEncode(env['payload']);
    }

    final digest = _hex((await Sha256().hash(utf8.encode(payloadJson))).bytes);
    if (digest != env['sha256']) {
      throw const BackupException('Integrity check failed — the backup is damaged or was modified.');
    }

    final payload = (jsonDecode(payloadJson) as Map).cast<String, dynamic>();
    final rawTables = (payload['tables'] as Map?)?.cast<String, dynamic>() ?? {};
    if (schema < 2) _addV1Account(rawTables, 'restored-${digest.substring(0, 20)}');
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final c in _codecs) {
      final list = (rawTables[c.table.actualTableName] as List?) ?? const [];
      final rows = <Map<String, dynamic>>[];
      for (final (i, raw) in list.indexed) {
        final m = _migrateRow(c.table.actualTableName, (raw as Map).cast<String, dynamic>(), schema);
        try {
          c.fromJson(m); // validates types and required fields
        } on Object {
          throw BackupException('Record ${i + 1} in ${c.table.actualTableName} is invalid.');
        }
        rows.add(m);
      }
      tables[c.table.actualTableName] = rows;
    }
    _checkReferences(tables);

    return BackupPreview(
      createdAt: DateTime.tryParse(env['createdAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      schemaVersion: schema,
      appVersion: env['appVersion'] as String? ?? '?',
      counts: {for (final e in tables.entries) e.key: e.value.length},
      tables: tables,
      encrypted: encrypted,
    );
  }

  /// Restores inside a single transaction: on any failure nothing changes.
  Future<RestoreResult> restore(BackupPreview preview, RestoreMode mode) => db.transaction(() async {
        var inserted = 0;
        var skipped = 0;
        if (mode == RestoreMode.replace) {
          for (final c in _codecs.reversed) {
            await db.delete(c.table).go();
          }
        } else {
          final existing = {for (final a in await db.select(db.accounts).get()) a.id};
          final incoming = {for (final a in preview.tables['accounts'] ?? const <Map<String, dynamic>>[]) a['id']};
          if ({...existing, ...incoming}.length > maxAccounts) {
            throw const BackupException(
                'Merging would go over the limit of 10 accounts. Delete an account first, or replace instead.');
          }
        }
        final existingKeys = mode == RestoreMode.merge
            ? {for (final c in await db.select(db.combinedAccounts).get()) c.memberKey}
            : const <String>{};
        for (final c in _codecs) {
          var rows = preview.tables[c.table.actualTableName] ?? const <Map<String, dynamic>>[];
          if (mode == RestoreMode.merge && c.table == db.profiles) {
            // Keep this device's profile when merging.
            if ((await db.select(c.table).get()).isNotEmpty) {
              skipped += rows.length;
              continue;
            }
          }
          if (mode == RestoreMode.merge && c.table == db.settings) {
            // Keep this device's preferences; add only the settings of
            // accounts that arrive with the backup (`section@accountId`).
            rows = [for (final r in rows) if ('${r['key']}'.contains('@')) r];
          }
          if (c.table == db.accounts) {
            // Account PINs live in this device's secure storage, not in backups.
            rows = [for (final r in rows) {...r, 'requiresPin': false}];
          }
          if (c.table == db.combinedAccounts) {
            // The same member set already combined here: keep the existing one.
            rows = [for (final r in rows) if (!existingKeys.contains(r['memberKey'])) r];
          }
          if (c.table == db.combinedAccountMembers) {
            final present = {for (final h in await db.select(db.combinedAccounts).get()) h.id};
            rows = [for (final r in rows) if (present.contains(r['combinedAccountId'])) r];
          }
          // insertOrIgnore skips rows whose id (or ledger duplicate key) already
          // exists; the row-count difference tells us how many were new.
          final before = await _count(c.table);
          for (final json in rows) {
            await db.into(c.table).insert(c.fromJson(json) as Insertable, mode: InsertMode.insertOrIgnore);
          }
          final added = await _count(c.table) - before;
          inserted += added;
          final total = preview.tables[c.table.actualTableName]?.length ?? 0;
          skipped += total - added;
        }
        return RestoreResult(inserted: inserted, skipped: skipped);
      });

  static const maxAccounts = 10;

  Future<int> _count(TableInfo table) async {
    final q = db.selectOnly(table)..addColumns([countAll()]);
    return await q.map((r) => r.read(countAll())).getSingle() ?? 0;
  }

  static const _ownedTables = {
    'income_sources',
    'rate_revisions',
    'source_pauses',
    'day_overrides',
    'compensation_items',
    'monthly_records',
    'ledger_entries',
    'calendar_events',
    'audit_log',
  };

  /// Adds the account a schema 1 backup's records will belong to, and moves
  /// its dashboard, reminder and calculation settings onto that account.
  void _addV1Account(Map<String, dynamic> raw, String accountId) {
    final profiles = (raw['profiles'] as List?) ?? const [];
    final currency = profiles.isEmpty ? 'INR' : ((profiles.first as Map)['currencyCode'] as String? ?? 'INR');
    final now = clock.now().microsecondsSinceEpoch;
    raw['accounts'] = [
      {
        'id': accountId,
        'name': 'Personal',
        'type': 'personal',
        'avatarEmoji': null,
        'colorIndex': 0,
        'avatarImage': null,
        'description': null,
        'currencyCode': currency,
        'locale': null,
        'monthlyTargetMinor': null,
        'requiresPin': false,
        'isArchived': false,
        'sortOrder': 0,
        'createdAt': now,
        'updatedAt': now,
      },
    ];
    _v1AccountId = accountId;
  }

  String? _v1AccountId;

  /// Upgrades a row from an older schema version.
  Map<String, dynamic> _migrateRow(String table, Map<String, dynamic> row, int fromSchema) {
    if (fromSchema >= 2) return row;
    final accountId = _v1AccountId!;
    if (_ownedTables.contains(table)) return {...row, 'accountId': accountId};
    if (table == 'settings' && AppDatabase.perAccountSettingKeys.contains(row['key'])) {
      return {...row, 'key': '${row['key']}@$accountId'};
    }
    return row;
  }

  void _checkReferences(Map<String, List<Map<String, dynamic>>> t) {
    final accountIds = {for (final a in t['accounts'] ?? const []) a['id']};
    final combinedIds = {for (final c in t['combined_accounts'] ?? const []) c['id']};
    final sourceIds = {for (final s in t['income_sources'] ?? const []) s['id']};
    final itemIds = {for (final s in t['compensation_items'] ?? const []) s['id']};
    void check(String table, String field, Set<Object?> ids, {bool nullable = false}) {
      for (final r in t[table] ?? const <Map<String, dynamic>>[]) {
        final v = r[field];
        if (v == null && nullable) continue;
        if (!ids.contains(v)) {
          throw BackupException('Backup is inconsistent: a $table record points to a missing record.');
        }
      }
    }

    if (accountIds.length > maxAccounts) throw const BackupException('This backup has more than 10 accounts.');
    for (final table in _ownedTables) {
      check(table, 'accountId', accountIds, nullable: table == 'audit_log');
    }
    check('combined_account_members', 'combinedAccountId', combinedIds);
    check('combined_account_members', 'accountId', accountIds);

    // A record must belong to the same account as its income source.
    final owner = {for (final s in t['income_sources'] ?? const <Map<String, dynamic>>[]) s['id']: s['accountId']};
    for (final table in _ownedTables.difference({'income_sources', 'audit_log'})) {
      for (final r in t[table] ?? const <Map<String, dynamic>>[]) {
        final source = r['sourceId'];
        if (source != null && owner[source] != r['accountId']) {
          throw BackupException('Backup is inconsistent: a $table record belongs to another account.');
        }
      }
    }

    check('rate_revisions', 'sourceId', sourceIds);
    check('source_pauses', 'sourceId', sourceIds);
    check('day_overrides', 'sourceId', sourceIds, nullable: true);
    check('compensation_items', 'sourceId', sourceIds, nullable: true);
    check('monthly_records', 'sourceId', sourceIds);
    check('ledger_entries', 'sourceId', sourceIds);
    check('ledger_entries', 'itemId', itemIds, nullable: true);
    check('calendar_events', 'sourceId', sourceIds, nullable: true);
  }

  Future<Map<String, dynamic>> _encrypt(List<int> plain, String password) async {
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final key = await _deriveKey(password, salt, kdfIterations);
    final algorithm = AesGcm.with256bits();
    final box = await algorithm.encrypt(plain, secretKey: key);
    return {
      'alg': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': kdfIterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  Future<List<int>> _decrypt(Map<String, dynamic> c, String password) async {
    if (c['alg'] != 'AES-256-GCM' || c['kdf'] != 'PBKDF2-HMAC-SHA256') {
      throw const BackupException('Unsupported backup encryption.');
    }
    final key = await _deriveKey(password, base64Decode(c['salt'] as String), c['iterations'] as int);
    try {
      return await AesGcm.with256bits().decrypt(
        SecretBox(
          base64Decode(c['ciphertext'] as String),
          nonce: base64Decode(c['nonce'] as String),
          mac: Mac(base64Decode(c['mac'] as String)),
        ),
        secretKey: key,
      );
    } on SecretBoxAuthenticationError {
      throw const BackupException('Wrong password, or the backup was modified.');
    }
  }

  static Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) =>
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256)
          .deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

  static String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class _TableCodec {
  _TableCodec(this.table, this.fromJson);
  final TableInfo table;
  final Object Function(Map<String, dynamic> json, {ValueSerializer? serializer}) fromJson;
}
