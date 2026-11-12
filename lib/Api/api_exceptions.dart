class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message, [int? statusCode]) : super(message, statusCode);
}

class NotFoundException extends ApiException {
  NotFoundException(String message, [int? statusCode]) : super(message, statusCode);
}

class BadRequestException extends ApiException {
  BadRequestException(String message, [int? statusCode]) : super(message, statusCode);
}

class ServerErrorException extends ApiException {
  ServerErrorException(String message, [int? statusCode]) : super(message, statusCode);
}
