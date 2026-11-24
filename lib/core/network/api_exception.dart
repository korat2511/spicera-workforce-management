class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiValidationException extends ApiException {
  ApiValidationException(super.message, this.errors) : super(statusCode: 422);

  final Map<String, List<String>> errors;

  String get firstMessage {
    for (final messages in errors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return message;
  }
}
