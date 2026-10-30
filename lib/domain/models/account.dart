import 'package:collection/collection.dart';

/// Categorises an account. Purely descriptive — every type has the same
/// features.
enum AccountType {
  personal,
  family,
  friends,
  business,
  freelance,
  custom;

  String get label => switch (this) {
        personal => 'Personal',
        family => 'Family',
        friends => 'Friends',
        business => 'Business',
        freelance => 'Freelance',
        custom => 'Custom',
      };

  String get defaultEmoji => switch (this) {
        personal => '🙂',
        family => '👨‍👩‍👧',
        friends => '🤝',
        business => '🏢',
        freelance => '💻',
        custom => '✨',
      };
}

/// An individual financial account: one person's (or one business's)
/// independent income sources, payments, history and settings.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.avatarEmoji,
    this.colorIndex = 0,
    this.avatarImage,
    this.description,
    this.locale,
    this.monthlyTargetMinor,
    this.requiresPin = false,
    this.isArchived = false,
    this.sortOrder = 0,
  });

  /// Maximum number of individual accounts (combined accounts don't count).
  static const maxAccounts = 10;

  final String id;
  final String name;
  final AccountType type;
  final String? avatarEmoji;
  final int colorIndex;

  /// Base64 PNG profile photo, if the user chose one.
  final String? avatarImage;
  final String? description;
  final String currencyCode;

  /// Number formatting override; null uses the profile locale.
  final String? locale;
  final int? monthlyTargetMinor;

  /// Opening this account requires its own PIN.
  final bool requiresPin;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get emoji => avatarEmoji ?? type.defaultEmoji;

  Account copyWith({
    String? name,
    AccountType? type,
    String? avatarEmoji,
    int? colorIndex,
    String? avatarImage,
    bool clearAvatarImage = false,
    String? description,
    bool clearDescription = false,
    String? currencyCode,
    String? locale,
    bool clearLocale = false,
    int? monthlyTargetMinor,
    bool clearMonthlyTarget = false,
    bool? requiresPin,
    bool? isArchived,
    int? sortOrder,
    DateTime? updatedAt,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        colorIndex: colorIndex ?? this.colorIndex,
        avatarImage: clearAvatarImage ? null : (avatarImage ?? this.avatarImage),
        description: clearDescription ? null : (description ?? this.description),
        currencyCode: currencyCode ?? this.currencyCode,
        locale: clearLocale ? null : (locale ?? this.locale),
        monthlyTargetMinor: clearMonthlyTarget ? null : (monthlyTargetMinor ?? this.monthlyTargetMinor),
        requiresPin: requiresPin ?? this.requiresPin,
        isArchived: isArchived ?? this.isArchived,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// A combined view over two or more individual accounts. It stores no
/// financial records: every figure is calculated from the members' own
/// records, so it always reflects their latest data and can never change it.
class CombinedAccount {
  const CombinedAccount({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
    this.avatarEmoji,
    this.colorIndex = 0,
    this.avatarImage,
    this.description,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? avatarEmoji;
  final int colorIndex;
  final String? avatarImage;
  final String? description;

  /// Display currency. Member sources in other currencies are shown
  /// separately — EarnLens never converts or mixes currencies.
  final String currencyCode;

  /// Member individual account ids, sorted.
  final List<String> memberIds;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get emoji => avatarEmoji ?? '👥';

  CombinedAccount copyWith({
    String? name,
    String? avatarEmoji,
    int? colorIndex,
    String? avatarImage,
    bool clearAvatarImage = false,
    String? description,
    bool clearDescription = false,
    String? currencyCode,
    List<String>? memberIds,
    int? sortOrder,
    DateTime? updatedAt,
  }) =>
      CombinedAccount(
        id: id,
        name: name ?? this.name,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        colorIndex: colorIndex ?? this.colorIndex,
        avatarImage: clearAvatarImage ? null : (avatarImage ?? this.avatarImage),
        description: clearDescription ? null : (description ?? this.description),
        currencyCode: currencyCode ?? this.currencyCode,
        memberIds: memberIds ?? this.memberIds,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Canonical identity of a member set: sorted, de-duplicated ids. Two
  /// selections in any order produce the same key.
  static String memberKeyOf(Iterable<String> ids) => (ids.toSet().toList()..sort()).join(',');

  String get memberKey => memberKeyOf(memberIds);

  @override
  bool operator ==(Object other) =>
      other is CombinedAccount &&
      other.id == id &&
      other.name == name &&
      other.avatarEmoji == avatarEmoji &&
      other.colorIndex == colorIndex &&
      other.avatarImage == avatarImage &&
      other.description == description &&
      other.currencyCode == currencyCode &&
      const ListEquality<String>().equals(other.memberIds, memberIds) &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, name, currencyCode, memberKey, updatedAt);
}

/// What the app is currently showing: one individual account, or a combined
/// account. Everything account-dependent (dashboard, income, calendar,
/// insights, rates) is derived from the active view.
sealed class AccountView {
  const AccountView();

  String get id;

  /// Key for per-view presentation settings (dashboard layout).
  String get settingsKey;

  bool get isCombined => this is CombinedView;

  Map<String, dynamic> toJson();

  static AccountView? fromJson(Map<String, dynamic>? json) {
    final id = json?['id'];
    if (id is! String || id.isEmpty) return null;
    return switch (json?['kind']) {
      'account' => IndividualView(id),
      'combined' => CombinedView(id),
      _ => null,
    };
  }
}

class IndividualView extends AccountView {
  const IndividualView(this.id);

  @override
  final String id;

  @override
  String get settingsKey => id;

  @override
  Map<String, dynamic> toJson() => {'kind': 'account', 'id': id};

  @override
  bool operator ==(Object other) => other is IndividualView && other.id == id;

  @override
  int get hashCode => Object.hash('account', id);

  @override
  String toString() => 'IndividualView($id)';
}

class CombinedView extends AccountView {
  const CombinedView(this.id);

  @override
  final String id;

  @override
  String get settingsKey => 'combined:$id';

  @override
  Map<String, dynamic> toJson() => {'kind': 'combined', 'id': id};

  @override
  bool operator ==(Object other) => other is CombinedView && other.id == id;

  @override
  int get hashCode => Object.hash('combined', id);

  @override
  String toString() => 'CombinedView($id)';
}

/// Which accounts a repository or snapshot may see and write.
class AccountScope {
  const AccountScope({required this.visibleAccountIds, this.writableAccountId});

  /// One individual account: visible and writable.
  AccountScope.single(String accountId)
      : visibleAccountIds = {accountId},
        writableAccountId = accountId;

  /// A combined account: members visible, nothing writable.
  AccountScope.readOnly(Set<String> accountIds)
      : visibleAccountIds = accountIds,
        writableAccountId = null;

  /// Before any account exists (first launch).
  static const none = AccountScope(visibleAccountIds: {});

  final Set<String> visibleAccountIds;

  /// The only account writes may target; null in combined views.
  final String? writableAccountId;

  bool get isReadOnly => writableAccountId == null;

  @override
  bool operator ==(Object other) =>
      other is AccountScope &&
      other.writableAccountId == writableAccountId &&
      other.visibleAccountIds.length == visibleAccountIds.length &&
      other.visibleAccountIds.containsAll(visibleAccountIds);

  @override
  int get hashCode => Object.hash(writableAccountId, Object.hashAllUnordered(visibleAccountIds));
}

/// What deleting an individual account would remove, shown before the user
/// confirms and returned after the deletion.
class AccountDeletionImpact {
  const AccountDeletionImpact({
    required this.account,
    required this.sourceCount,
    required this.recordCount,
    required this.removedCombined,
    required this.updatedCombined,
  });

  final Account account;
  final int sourceCount;

  /// Rate changes, payments, bonuses, monthly records, holidays and events.
  final int recordCount;

  /// Combined accounts left with fewer than two members (or matching another
  /// combined account) — only their configuration is removed.
  final List<CombinedAccount> removedCombined;

  /// Combined accounts that keep working without this member.
  final List<CombinedAccount> updatedCombined;
}
