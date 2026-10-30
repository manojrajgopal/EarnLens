import '../../core/date_time/local_date.dart';
import '../calculation/earnings_snapshot.dart';
import '../models/account.dart';
import '../models/enums.dart';
import '../models/income_source.dart';
import '../models/profile.dart';
import '../models/records.dart';

/// Repository interfaces. The app ships with local (Drift) implementations;
/// a future remote/sync implementation plugs in behind the same contracts
/// (see docs/FUTURE_BACKEND.md).

abstract interface class ProfileRepository {
  Future<UserProfile?> get();
  Stream<UserProfile?> watch();
  Future<void> save(UserProfile profile);
}

abstract interface class SettingsRepository {
  Future<Map<String, dynamic>?> read(String key);
  Stream<Map<String, dynamic>?> watch(String key);
  Future<void> write(String key, Map<String, dynamic> value);
}

/// Individual accounts. Each owns its own income sources, records and
/// settings; at most [Account.maxAccounts] can exist.
abstract interface class AccountRepository {
  Stream<List<Account>> watchAccounts();
  Future<List<Account>> accounts();
  Future<Account?> account(String id);

  /// Throws [AccountLimitException] when the limit is reached.
  Future<void> createAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> setArchived(String id, {required bool archived});

  /// Persists the switcher order of [ids].
  Future<void> reorder(List<String> ids);

  /// What [deleteAccount] would remove, without changing anything.
  Future<AccountDeletionImpact> previewDelete(String id);

  /// Deletes the account with all of its own records and settings, removes it
  /// from combined accounts (dropping those left with fewer than two
  /// members) and never touches another account's records.
  Future<AccountDeletionImpact> deleteAccount(String id);
}

/// Combined accounts: saved selections of individual accounts whose figures
/// are aggregated on the fly. They hold no financial records.
abstract interface class CombinedAccountRepository {
  Stream<List<CombinedAccount>> watchCombined();
  Future<List<CombinedAccount>> combined();
  Future<CombinedAccount?> byId(String id);

  /// The combined account with exactly these members, in any order.
  Future<CombinedAccount?> findByMembers(Iterable<String> accountIds);

  /// Throws [DuplicateCombinationException] when the same member set exists.
  Future<void> create(CombinedAccount combined);

  /// Name, avatar, description and display currency; members are unchanged.
  Future<void> update(CombinedAccount combined);
  Future<void> setMembers(String id, List<String> accountIds);

  /// Removes the configuration only; member records are untouched.
  Future<void> delete(String id);
}

abstract interface class IncomeSourceRepository {
  Stream<List<IncomeSource>> watchSources();
  Future<List<IncomeSource>> sources();
  Future<IncomeSource?> source(String id);

  /// Creates a source together with its starting rate in one transaction.
  Future<void> createSource(IncomeSource source, {RateRevision? initialRate});
  Future<void> updateSource(IncomeSource source);

  /// Sets an end date (if missing) and archives; history is kept.
  Future<void> archiveSource(String id, LocalDate endDate);
  Future<void> restoreSource(String id);

  /// Opens a pause from [from]; nothing accrues until resumed.
  Future<void> pauseSource(String id, LocalDate from);
  Future<void> resumeSource(String id, LocalDate on);

  /// Deletes a source only when it has no financial history.
  Future<void> deleteSourceIfUnused(String id);

  Stream<List<RateRevision>> watchRevisions(String sourceId);
  Future<void> addRevision(RateRevision revision);
  Future<void> updateRevision(RateRevision revision);
  Future<void> deleteRevision(String id);

  Stream<List<DayOverride>> watchOverrides();
  Future<void> addOverride(DayOverride o);
  Future<void> deleteOverride(String id);

  Stream<List<SourcePause>> watchPauses(String sourceId);
}

abstract interface class RecordsRepository {
  Future<void> saveItem(CompensationItem item);
  Future<void> cancelItem(String id);

  Future<void> saveMonthlyRecord(MonthlyRecord record);
  Future<void> finalizeMonth(String sourceId, YearMonth month, int actualMinor);
  Future<void> reopenMonth(String sourceId, YearMonth month, String reason);

  /// Adds a ledger entry. Throws DuplicateEntryException when an identical
  /// entry exists unless [allowDuplicate] is true.
  Future<void> addLedgerEntry(LedgerEntry entry, {bool allowDuplicate = false});
  Future<void> updateLedgerEntry(LedgerEntry entry);
  Future<void> setLedgerStatus(String id, LedgerStatus status);

  Stream<List<CalendarEvent>> watchEvents();
  Future<void> saveEvent(CalendarEvent event);
  Future<void> cancelEvent(String id);

  Stream<List<AuditEntry>> watchAudit({String? entityId, int limit = 200});
}

/// Read model consumed by the calculation engine.
abstract interface class EarningsDataSource {
  Future<EarningsSnapshot> loadSnapshot();
  Stream<EarningsSnapshot> watchSnapshot();
}
