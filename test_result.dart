class CompareTestResult {
  final String? description;
  final String? normalRangeMax;
  final String? normalRangeMin;
  final String? testName;
  final String? units;

  CompareTestResult({
    required this.description,
    required this.normalRangeMax,
    required this.normalRangeMin,
    required this.testName,
    required this.units,
  });

  factory CompareTestResult.fromJson(Map<String, dynamic> json) {
    return CompareTestResult(
      description: json['description'].toString(),
      normalRangeMax: json['normalRangeMax'].toString(),
      normalRangeMin: json['normalRangeMin'].toString(),
      testName: json['testName'].toString(),
      units: json['units'].toString(),
    );
  }
}
