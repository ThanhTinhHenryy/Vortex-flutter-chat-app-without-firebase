import 'package:chat_app_flutter/Screens/HomeScreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: "OpenSans",
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF075E54),
          secondary: Color(0xFF128C7E), // thay accentColor bằng secondary
        ),
      ),
      home: HomeScreen(),
    );
  }
}
