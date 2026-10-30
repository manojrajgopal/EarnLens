import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/errors/app_exception.dart';
import '../../database/app_database.dart';
import '../../domain/models/account.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/validators.dart';
import '../local/audit_writer.dart';
import '../local/mappers.dart';

/// Settings key of a per-account (or per-combined-account) settings section,
/// e.g. `dashboard@<accountId>` or `dashboard@combined:<id>`.
String accountSettingsKey(String section, String viewKey) => '$section@$viewKey';

class LocalAccountRepository implements AccountRepository {
  LocalAccountRepository(this.db, this.clock, this.ids) : audit = AuditWriter(db, clock, ids);

  final AppDatabase db;
  final Clock clock;
  final IdGenerator ids;
  final AuditWriter audit;

  @override
  Stream<List<Account>> watchAccounts() => (db.select(db.accounts)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<List<Account>> accounts() async => (await (db.select(db.accounts)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]))
          .get())
      .map((r) => r.toDomain())
      .toList();

  @override
  Future<Account?> account(String id) async =>
      (await (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull())?.toDomain();

  Future<AccountRow> _row(String id) async {
    final row = await (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundException('Account not found');
    return row;
  }

  Future<int> _count() async =>
      await (db.selectOnly(db.accounts)..addColumns([countAll()])).map((r) => r.read(countAll())).getSingle() ?? 0;

  @override
  Future<void> createAccount(Account account) async {
    Validators.account(account);
    try {
      await db.transaction(() async {
        if (await _count() >= Account.maxAccounts) throw const AccountLimitException();
        final maxOrder = await (db.selectOnly(db.accounts)..addColumns([db.accounts.sortOrder.max()]))
            .map((r) => r.read(db.accounts.sortOrder.max()))
            .getSingleOrNull();
        final row = accountToRow(account.copyWith(name: account.name.trim(), sortOrder: (maxOrder ?? -1) + 1));
        await db.into(db.accounts).insert(row);
        await audit.log(
          accountId: account.id,
          entityType: 'account',
          entityId: account.id,
          action: 'create',
          summary: 'Created account "${row.name}"',
        );
      });
    } on AppException {
      rethrow;
    } on Object catch (e) {
      // The database trigger is the last line of defence against a race.
      if ('$e'.contains('EARNLENS_ACCOUNT_LIMIT')) throw const AccountLimitException();
      rethrow;
    }
  }

  @override
  Future<void> updateAccount(Account account) async {
    Validators.account(account);
    await db.transaction(() async {
      final before = await _row(account.id);
      final row = accountToRow(account.copyWith(name: account.name.trim(), updatedAt: clock.now()))
          .copyWith(createdAt: before.createdAt, sortOrder: before.sortOrder);
      await db.update(db.accounts).replace(row);
      await audit.log(
        accountId: account.id,
        entityType: 'account',
        entityId: account.id,
        action: 'update',
        summary: 'Edited account "${row.name}"',
      );
    });
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) => db.transaction(() async {
        final row = await _row(id);
        if (archived) {
          final active = await (db.select(db.accounts)..where((t) => t.isArchived.equals(false))).get();
          if (active.length <= 1 && !row.isArchived) {
            throw const ValidationException('Keep at least one active account.');
          }
        }
        await (db.update(db.accounts)..where((t) => t.id.equals(id)))
            .write(AccountsCompanion(isArchived: Value(archived), updatedAt: Value(ts(clock.now()))));
        await audit.log(
          accountId: id,
          entityType: 'account',
          entityId: id,
          action: archived ? 'archive' : 'restore',
          summary: '${archived ? 'Archived' : 'Restored'} account "${row.name}"',
        );
      });

  @override
  Future<void> reorder(List<String> ids) => db.transaction(() async {
        for (var i = 0; i < ids.length; i++) {
          await (db.update(db.accounts)..where((t) => t.id.equals(ids[i])))
              .write(AccountsCompanion(sortOrder: Value(i)));
        }
      });

  // ---- Deletion -------------------------------------------------------------

  /// Financial tables that carry `account_id`, children before parents.
  List<TableInfo> get _ownedTables => [
        db.ledgerEntries,
        db.compensationItems,
        db.monthlyRecords,
        db.calendarEvents,
        db.rateRevisions,
        db.sourcePauses,
        db.dayOverrides,
        db.incomeSources,
      ];

  Future<int> _countOwned(TableInfo table, String accountId) async {
    final column = table.columnsByName['account_id']! as GeneratedColumn<String>;
    final q = db.selectOnly(table)
      ..addColumns([countAll()])
      ..where(column.equals(accountId));
    return await q.map((r) => r.read(countAll())).getSingle() ?? 0;
  }

  Future<AccountDeletionImpact> _impact(String id) async {
    final row = await _row(id);
    final total = await db.select(db.accounts).get();
    if (total.length <= 1) {
      throw const ValidationException('This is your only account. Create another one before deleting it.');
    }
    var records = 0;
    var sources = 0;
    for (final t in _ownedTables) {
      final n = await _countOwned(t, id);
      if (t == db.incomeSources) {
        sources = n;
      } else {
        records += n;
      }
    }
    final combined = await LocalCombinedAccountRepository(db, clock, ids).combined();
    final removed = <CombinedAccount>[];
    final updated = <CombinedAccount>[];
    // Keys that will exist after this deletion, to detect two combined
    // accounts collapsing onto the same member set.
    final keys = {for (final c in combined) if (!c.memberIds.contains(id)) c.memberKey};
    for (final c in combined.where((c) => c.memberIds.contains(id))) {
      final remaining = c.memberIds.where((m) => m != id).toList();
      final key = CombinedAccount.memberKeyOf(remaining);
      if (remaining.length < 2 || keys.contains(key)) {
        removed.add(c);
      } else {
        keys.add(key);
        updated.add(c.copyWith(memberIds: remaining));
      }
    }
    return AccountDeletionImpact(
      account: row.toDomain(),
      sourceCount: sources,
      recordCount: records,
      removedCombined: removed,
      updatedCombined: updated,
    );
  }

  @override
  Future<AccountDeletionImpact> previewDelete(String id) => _impact(id);

  @override
  Future<AccountDeletionImpact> deleteAccount(String id) => db.transaction(() async {
        final impact = await _impact(id);
        final now = ts(clock.now());
        for (final c in impact.removedCombined) {
          await (db.delete(db.combinedAccountMembers)..where((t) => t.combinedAccountId.equals(c.id))).go();
          await (db.delete(db.combinedAccounts)..where((t) => t.id.equals(c.id))).go();
          await (db.delete(db.settings)..where((t) => t.key.like('%@${CombinedView(c.id).settingsKey}'))).go();
        }
        for (final c in impact.updatedCombined) {
          await (db.delete(db.combinedAccountMembers)
                ..where((t) => t.combinedAccountId.equals(c.id) & t.accountId.equals(id)))
              .go();
          await (db.update(db.combinedAccounts)..where((t) => t.id.equals(c.id)))
              .write(CombinedAccountsCompanion(memberKey: Value(c.memberKey), updatedAt: Value(now)));
        }
        // Only rows owned by this account: every query filters on account_id.
        for (final t in _ownedTables) {
          final column = t.columnsByName['account_id']! as GeneratedColumn<String>;
          await (db.delete(t)..where((_) => column.equals(id))).go();
        }
        await (db.delete(db.auditLog)..where((t) => t.accountId.equals(id))).go();
        await (db.delete(db.settings)..where((t) => t.key.like('%@$id'))).go();
        await (db.delete(db.accounts)..where((t) => t.id.equals(id))).go();
        await audit.log(
          entityType: 'account',
          entityId: id,
          action: 'delete',
          summary: 'Deleted account "${impact.account.name}" (${impact.sourceCount} sources, '
              '${impact.recordCount} records)',
        );
        return impact;
      });
}

class LocalCombinedAccountRepository implements CombinedAccountRepository {
  LocalCombinedAccountRepository(this.db, this.clock, this.ids) : audit = AuditWriter(db, clock, ids);

  final AppDatabase db;
  final Clock clock;
  final IdGenerator ids;
  final AuditWriter audit;

  JoinedSelectStatement<HasResultSet, dynamic> _query() => db.select(db.combinedAccounts).join([
        leftOuterJoin(
          db.combinedAccountMembers,
          db.combinedAccountMembers.combinedAccountId.equalsExp(db.combinedAccounts.id),
        ),
      ])
        ..orderBy([OrderingTerm.asc(db.combinedAccounts.sortOrder), OrderingTerm.asc(db.combinedAccounts.createdAt)]);

  List<CombinedAccount> _group(List<TypedResult> rows) {
    final heads = <String, CombinedAccountRow>{};
    final members = <String, List<String>>{};
    for (final r in rows) {
      final head = r.readTable(db.combinedAccounts);
      heads[head.id] = head;
      final list = members.putIfAbsent(head.id, () => []);
      final m = r.readTableOrNull(db.combinedAccountMembers);
      if (m != null) list.add(m.accountId);
    }
    return [for (final h in heads.values) h.toDomain(members[h.id]!)];
  }

  @override
  Stream<List<CombinedAccount>> watchCombined() => _query().watch().map(_group);

  @override
  Future<List<CombinedAccount>> combined() async => _group(await _query().get());

  @override
  Future<CombinedAccount?> byId(String id) async {
    final q = _query()..where(db.combinedAccounts.id.equals(id));
    final list = _group(await q.get());
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<CombinedAccount?> findByMembers(Iterable<String> accountIds) async {
    final key = CombinedAccount.memberKeyOf(accountIds);
    final head =
        await (db.select(db.combinedAccounts)..where((t) => t.memberKey.equals(key))).getSingleOrNull();
    return head == null ? null : byId(head.id);
  }

  Future<Set<String>> _individualIds() async =>
      (await db.select(db.accounts).get()).map((a) => a.id).toSet();

  /// Throws when another combined account (not [exceptId]) has the same set.
  Future<void> _checkDuplicate(List<String> memberIds, {String? exceptId}) async {
    final existing = await findByMembers(memberIds);
    if (existing != null && existing.id != exceptId) {
      throw DuplicateCombinationException(existing.id, existing.name);
    }
  }

  Future<void> _insertMembers(String combinedId, Iterable<String> accountIds) async {
    for (final a in accountIds) {
      await db.into(db.combinedAccountMembers).insert(CombinedMemberRow(
            id: ids.newId(),
            combinedAccountId: combinedId,
            accountId: a,
            createdAt: ts(clock.now()),
          ));
    }
  }

  @override
  Future<void> create(CombinedAccount combined) => db.transaction(() async {
        final c = combined.copyWith(name: combined.name.trim());
        // Validate the raw selection, so a repeated id is reported rather
        // than silently de-duplicated.
        Validators.combined(c, await _individualIds());
        await _checkDuplicate(c.memberIds);
        final maxOrder = await (db.selectOnly(db.combinedAccounts)..addColumns([db.combinedAccounts.sortOrder.max()]))
            .map((r) => r.read(db.combinedAccounts.sortOrder.max()))
            .getSingleOrNull();
        final sorted = [...c.memberIds]..sort();
        await db
            .into(db.combinedAccounts)
            .insert(combinedToRow(c.copyWith(memberIds: sorted, sortOrder: (maxOrder ?? -1) + 1)));
        await _insertMembers(c.id, sorted);
        await audit.log(
          entityType: 'combined',
          entityId: c.id,
          action: 'create',
          summary: 'Created combined account "${c.name}" with ${sorted.length} accounts',
        );
      });

  @override
  Future<void> update(CombinedAccount combined) => db.transaction(() async {
        final before = await byId(combined.id);
        if (before == null) throw const NotFoundException('Combined account not found');
        // Members are managed through setMembers only.
        final c = combined.copyWith(name: combined.name.trim(), memberIds: before.memberIds, updatedAt: clock.now());
        Validators.combined(c, await _individualIds());
        await db.update(db.combinedAccounts).replace(
            combinedToRow(c.copyWith(sortOrder: before.sortOrder)).copyWith(createdAt: ts(before.createdAt)));
        await audit.log(
          entityType: 'combined',
          entityId: c.id,
          action: 'update',
          summary: 'Edited combined account "${c.name}"',
        );
      });

  @override
  Future<void> setMembers(String id, List<String> accountIds) => db.transaction(() async {
        final before = await byId(id);
        if (before == null) throw const NotFoundException('Combined account not found');
        Validators.members(id, accountIds, await _individualIds());
        await _checkDuplicate(accountIds, exceptId: id);
        final next = accountIds.toSet();
        final previous = before.memberIds.toSet();
        await (db.delete(db.combinedAccountMembers)
              ..where((t) => t.combinedAccountId.equals(id) & t.accountId.isIn(previous.difference(next))))
            .go();
        await _insertMembers(id, next.difference(previous));
        await (db.update(db.combinedAccounts)..where((t) => t.id.equals(id))).write(CombinedAccountsCompanion(
          memberKey: Value(CombinedAccount.memberKeyOf(next)),
          updatedAt: Value(ts(clock.now())),
        ));
        await audit.log(
          entityType: 'combined',
          entityId: id,
          action: 'members',
          summary: 'Changed members of "${before.name}" to ${next.length} accounts',
        );
      });

  @override
  Future<void> delete(String id) => db.transaction(() async {
        final before = await byId(id);
        if (before == null) return;
        await (db.delete(db.combinedAccountMembers)..where((t) => t.combinedAccountId.equals(id))).go();
        await (db.delete(db.combinedAccounts)..where((t) => t.id.equals(id))).go();
        await (db.delete(db.settings)..where((t) => t.key.like('%@${CombinedView(id).settingsKey}'))).go();
        await audit.log(
          entityType: 'combined',
          entityId: id,
          action: 'delete',
          summary: 'Deleted combined account "${before.name}" (member records kept)',
        );
      });
}
