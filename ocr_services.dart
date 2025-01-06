// import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/api_exceptions.dart';

class OCRService {
  /*
    Run Api Local:
    - in CMD Open Python API Directory
    - Run Api Project (Python in CMD)
    - in CMD run (ipconfig) take (IPv4 Address in Wireless LAN adapter Wi-Fi)
    - url = "http://<IPv4 Address>:<Port>/process_base64"
   */
  // final String url = "http://tahaleli.com:81/process_base64";
  final String url = "http://192.168.1.25:5000/process_base64";

  OCRService();

  Future<Map<String, dynamic>> uploadFile(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse(url);

      http.Response response = await http.post(
        uri,
        body: jsonEncode(data),
        headers: {"Content-Type": "application/json"},
      );
      print("$url");
      print("${response.statusCode}");
      print("${response.body}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw BadRequestException(errorMSG: 'Failed to process OCR');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// void main() async {
//   final ocrService = OCRService(baseUrl: 'http://192.168.1.34:5000');
//   final file = File(
//       '"C:\Users\LENOVO\Downloads\احمد عبد سعيد ابو رمضان1.pdf"'); // Replace with your file path
//   final response = await ocrService.uploadFile(file);
//   print('OCR Response: $response');
// }
