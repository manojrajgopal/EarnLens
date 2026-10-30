/// Base class for expected, user-presentable failures.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.field});
  final String? field;
}

/// Raised when an identical financial entry already exists.
class DuplicateEntryException extends AppException {
  const DuplicateEntryException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// The operation would destroy financial history.
class ProtectedHistoryException extends AppException {
  const ProtectedHistoryException(super.message);
}

class BackupException extends AppException {
  const BackupException(super.message);
}

class SecurityException extends AppException {
  const SecurityException(super.message);
}

/// A write was attempted while a combined account is open. Combined accounts
/// are read-only views; changes are made in the member's own account.
class ReadOnlyViewException extends AppException {
  const ReadOnlyViewException([
    super.message = 'Combined accounts are read-only. Open the member\'s own account to make changes.',
  ]);
}

/// The record belongs to a different account than the one being edited.
class AccountOwnershipException extends AppException {
  const AccountOwnershipException([super.message = 'That record belongs to another account.']);
}

/// The 10 individual account limit was reached.
class AccountLimitException extends AppException {
  const AccountLimitException([
    super.message = 'You already have the maximum of 10 accounts. Delete one you no longer need to add another.',
  ]);
}

/// The same set of accounts is already combined (in any order).
class DuplicateCombinationException extends AppException {
  const DuplicateCombinationException(this.existingId, this.existingName)
      : super('These accounts are already combined as "$existingName".');

  final String existingId;
  final String existingName;
}
