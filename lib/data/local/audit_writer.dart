import 'dart:convert';

import '../../core/clock.dart';
import '../../database/app_database.dart';
import 'mappers.dart';

/// Writes an audit trail for every change to financial data. Called inside
/// the same transaction as the change it records.
class AuditWriter {
  AuditWriter(this.db, this.clock, this.ids);

  final AppDatabase db;
  final Clock clock;
  final IdGenerator ids;

  Future<void> log({
    required String entityType,
    required String entityId,
    required String action,
    required String summary,
    String? accountId,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  }) =>
      db.into(db.auditLog).insert(AuditRow(
            id: ids.newId(),
            accountId: accountId,
            entityType: entityType,
            entityId: entityId,
            action: action,
            summary: summary,
            beforeJson: before == null ? null : jsonEncode(before),
            afterJson: after == null ? null : jsonEncode(after),
            at: ts(clock.now()),
          ));
}
