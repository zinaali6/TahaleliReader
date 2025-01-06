class PatientFileReq {
  final String? base64string;

  PatientFileReq({required this.base64string});

  Map<String, dynamic> toJson() {
    return {
      'base64_string': base64string,
    };
  }
}
