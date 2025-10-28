import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hanja/incorrect_hanja_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanja/ranking_quiz_page.dart';
import 'package:hanja/ranking_board_page.dart';
import 'package:hanja/eum_quiz_page.dart';
import 'package:hanja/gosa_list_screen.dart'; // Import the new GosaListScreen
import 'package:hanja/gallery_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:hanja/hanja.dart';
import 'package:hanja/home_page.dart'; // Import HomePage
import 'package:hanja/quiz_page.dart'; // Import QuizPage
import 'package:hanja/hanja_detail_dialog.dart'; // Import HanjaDetailDialog
import 'package:hanja/hanja_list_page.dart'; // Import HanjaListPage
import 'package:hanja/hanja_search_page.dart'; // Import HanjaSearchPage
import 'package:hanja/preparation_dialog.dart'; // Import PreparationDialog

void main() async {
  print('main started');
  WidgetsFlutterBinding.ensureInitialized();
  print('WidgetsFlutterBinding ensured');
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Firebase initialized');
  print('Calling runApp');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('MyApp build method called');
    return MaterialApp(
      title: '한자 학습',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: Colors.cyan,
        ).copyWith(secondary: Colors.cyanAccent),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontStyle: FontStyle.italic),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.cyanAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
