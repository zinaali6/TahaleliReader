import 'dart:convert';
import 'dart:io';

String convertIntoBase64(File file) {
  List<int> imageBytes = file.readAsBytesSync();
  String base64File = base64Encode(imageBytes);
  return base64File;
}
