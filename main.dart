import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Screens/welcome_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const TahaleliReaderApp());
}

class TahaleliReaderApp extends StatelessWidget {
  const TahaleliReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
    );
  }
}


