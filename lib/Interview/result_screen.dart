import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import flutter_markdown for formatting
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:interview_app/Dashboard/dashboard.dart';

class AuthService {
  // Get a reference to the FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to get the current user
  User? getCurrentUser() {
    try {
      // Returns the current logged-in user, or null if no user is logged in
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}

class ResultsScreen extends StatelessWidget {
  final int totalMarks;
  final String feedback;

  ResultsScreen({
    super.key,
    required this.totalMarks,
    required this.feedback,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user = AuthService().getCurrentUser();

  Future<void> addData(int data, String feedback) async {
    try {
      String email = user?.email ?? 'No email available';

      await _firestore
          .collection(email)
          .doc('interview')
          .set({'score': data, 'feedback': feedback});
      print('Data added successfully!');
    } catch (e) {
      print('Error adding data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Results'),
      ),
      body: SingleChildScrollView(
        // Make the screen scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Score',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Progress Bar representing the marks
            LinearProgressIndicator(
              value: totalMarks / 100, // Value should be between 0.0 and 1.0
              backgroundColor:
                  Colors.grey[300], // Background color of the progress bar
              color: totalMarks >= 50
                  ? Colors.green
                  : Colors.red, // Green if pass, Red if fail
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Score: $totalMarks/100',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Detailed Feedback:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            MarkdownBody(
              // Use MarkdownBody to format feedback text
              data: feedback,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  addData(totalMarks, feedback);
                  try {
                    String email = user?.email ?? 'No email available';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(
                          userId: email,
                        ),
                      ),
                    );
                  } catch (e) {
                    print('Error adding data: $e');
                  }
                },
                child: Text("Proceed"),
                style: ElevatedButton.styleFrom(
                  // Button color
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  // primary: Colors.green, // Set the button color
                  // onPrimary: Colors.white, // Set the text color
                  elevation: 5, // Shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Rounded edges
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
