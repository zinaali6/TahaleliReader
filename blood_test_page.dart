import 'package:flutter/material.dart';

class BloodTestPage extends StatelessWidget {
  final Map<String, dynamic> testResults;

  const BloodTestPage({Key? key, required this.testResults}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Test Results'),
      ),
      body: ListView.builder(
        itemCount: testResults['test_results'].length,
        itemBuilder: (context, index) {
          final result = testResults['test_results'][index];
          return ListTile(
            title: Text(result['test_name']),
            subtitle: Text(
              "Value: ${result['value']} ${result['unit']}\nReference Range: ${result['reference_range'] ?? 'N/A'}",
            ),
          );
        },
      ),
    );
  }
}
