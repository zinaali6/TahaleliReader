class PatientRes {
  PatientInfo? patientinfo;
  List<TestResult>? testresults;

  PatientRes({this.patientinfo, this.testresults});

  PatientRes.fromJson(Map<String, dynamic> json) {
    patientinfo:
    json['patient_info'] != null
        ? PatientInfo?.fromJson(json['patient_info'])
        : null;
    if (json['test_results'] != null) {
      testresults = <TestResult>[];
      json['test_results'].forEach((v) {
        testresults!.add(TestResult.fromJson(v));
      });
    }
  }
}

class PatientInfo {
  String? age;
  String? name;
  String? sex;

  PatientInfo({this.age, this.name, this.sex});

  PatientInfo.fromJson(Map<String, dynamic> json) {
    age:
    json['age'];
    name:
    json['name'];
    sex:
    json['sex'];
  }
}

class TestResult {
  final String? displaymessage;
  final String? maxrefvalue;
  final String? minrefvalue;
  final String? referencerange;
  final String? testName;
  final String? unit;
  final String? value;

  TestResult({
    required this.displaymessage,
    required this.maxrefvalue,
    required this.minrefvalue,
    required this.referencerange,
    required this.testName,
    required this.unit,
    required this.value,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      displaymessage: json['display_message'].toString(),
      maxrefvalue: json['max_ref_value'].toString(),
      minrefvalue: json['min_ref_value'].toString(),
      referencerange: json['reference_range'].toString(),
      testName: json['test_name'].toString(),
      unit: json['unit'].toString(),
      value: json['value'].toString(),
    );
  }
}
