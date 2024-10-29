import 'dart:math';
import 'package:flutter/material.dart';
import 'questions.dart'; // Assuming you have a list of questions in this file.
import 'package:interview_app/ATS System/ats_homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AptitudeTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QuizScreen(),
    );
  }
}

//auth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _totalScore = 0;
  bool _isQuizCompleted = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = AuthService().getCurrentUser();

  List<Map<String, dynamic>> _shuffledQuestions = [];

  @override
  void initState() {
    super.initState();
    _shuffleQuestionsAndOptions();
  }

  void _shuffleQuestionsAndOptions() {
    // Make a copy of the original questions list
    _shuffledQuestions = List.from(questions);

    // Shuffle the questions
    _shuffledQuestions.shuffle();

    // Shuffle the options for each question
    for (var question in _shuffledQuestions) {
      (question['options'] as List).shuffle();
    }
  }

  Future<void> addData(int data) async {
    try {
      String email = user?.email ?? 'No email available';
      await _firestore.collection(email).doc('aptitude_test').set({
        'score': data,
      });
      print('Data added successfully!');
    } catch (e) {
      print('Error adding data: $e');
    }
  }

  void _checkAnswer(String selectedOption) {
    if (!_isQuizCompleted) {
      final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
      if (selectedOption == currentQuestion['correctAnswer']) {
        _totalScore += (currentQuestion['marks'] as int);
      }
      setState(() {
        if (_currentQuestionIndex < _shuffledQuestions.length - 1) {
          _currentQuestionIndex++;
        } else {
          _isQuizCompleted = true;
          addData(_totalScore);
        }
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _totalScore = 0;
      _isQuizCompleted = false;
      _shuffleQuestionsAndOptions(); // Reshuffle the questions and options
    });
  }

  void _proceed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeApp(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz App',
          style: TextStyle(fontSize: 24),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: _isQuizCompleted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quiz Completed! Your Score: $_totalScore',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  if (_totalScore > 75)
                    ElevatedButton(
                      onPressed: _proceed,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                      ),
                      child: Text(
                        'Proceed',
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _resetQuiz,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                    child: Text(
                      'Restart Quiz',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${_shuffledQuestions.length}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    _shuffledQuestions[_currentQuestionIndex]['question'],
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 30),
                  ..._shuffledQuestions[_currentQuestionIndex]['options']
                      .map<Widget>((option) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7.5),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _checkAnswer(option),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15.0),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                          child: Text(option),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 30),
                  Text(
                    'Score: $_totalScore',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
