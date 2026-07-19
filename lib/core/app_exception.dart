class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException${code != null ? "($code)" : ""}: $message';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class SessionException extends AppException {
  const SessionException(super.message, {super.code});
}

class TransferException extends AppException {
  const TransferException(super.message, {super.code});
}
