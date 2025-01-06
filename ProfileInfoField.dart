import 'package:flutter/material.dart';

class ProfileInfoField extends StatelessWidget {
  final String label;

  ProfileInfoField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: Colors.grey[400]),
        ),
      ),
    );
  }
}
