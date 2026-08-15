/// Anything the API said no to, in a shape a screen can act on.
///
/// [errors] is Laravel's 422 payload — `{"email": ["The email field is
/// required."]}` — which is why [errorFor] exists: a form field asks for its
/// own message and shows it under itself, rather than every screen dumping one
/// combined error at the top and leaving the reader to work out which box is
/// wrong.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  /// The first message for one field, or null if that field was fine.
  String? errorFor(String field) => errors?[field]?.first;

  bool get isValidation => statusCode == 422;

  bool get isNotFound => statusCode == 404;

  /// Too many requests. Worth naming, because the write endpoints are throttled
  /// per IP and users behind a carrier NAT can hit it without doing anything
  /// wrong.
  bool get isThrottled => statusCode == 429;

  @override
  String toString() => message;
}
