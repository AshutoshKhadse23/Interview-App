import 'package:flutter/material.dart';
import 'package:interview_app/screens/home_screen.dart';
import 'package:interview_app/screens/login_screen.dart';
import 'package:interview_app/screens/signup_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:interview_app/screens/welcome.dart';
import 'Apltitude Test/aptitude_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontFamily: 'Ubuntu',
        ),
      )),
      initialRoute: HomeScreen.id,
      routes: {
        '/aptitude_test': (context) => AptitudeTestApp(),
        HomeScreen.id: (context) => HomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        SignUpScreen.id: (context) => SignUpScreen(),
        WelcomeScreen.id: (context) => WelcomeScreen(),
      },
    );
  }
}
