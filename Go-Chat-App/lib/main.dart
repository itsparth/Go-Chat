import 'package:flutter/material.dart';
import 'start.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Chat',
      theme: _chatTheme(),
      home: StartPage(),
    );
  }
}

ThemeData _chatTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    primaryColor: Colors.green,
  );
}
