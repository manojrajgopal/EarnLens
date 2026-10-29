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
