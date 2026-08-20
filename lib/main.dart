import 'package:crack/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MundoDelPernoApp());

class MundoDelPernoApp extends StatelessWidget {
  const MundoDelPernoApp({super.key});
  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF45B0B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'El Mundo del Perno Admin',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.light,
          primary: orange,
          secondary: const Color(0xFFFFA726),
          surface: const Color(0xFFF6F4F1),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F1EF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF171717),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: orange, width: 1.6),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
