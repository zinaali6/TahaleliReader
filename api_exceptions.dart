class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.errorMSG,
    this.methodName,
  });

  final String statusCode;
  final String errorMSG;
  final String? methodName;
}

class BadRequestException extends ApiException {
  BadRequestException({
    super.statusCode = "400",
    required super.errorMSG,
  });
}
