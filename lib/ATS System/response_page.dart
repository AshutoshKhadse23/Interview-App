import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:interview_app/Interview/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class ResponsePage extends StatelessWidget {
  final String responseText;
  final String title;
  final String candidateName;
  final int percentageMatch;
  final String jobDescription;

  ResponsePage({
    required this.responseText,
    required this.title,
    required this.candidateName,
    required this.percentageMatch,
    required this.jobDescription,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user = AuthService().getCurrentUser();

  Future<void> addData(int data) async {
    try {
      String email = user?.email ?? 'No email available';
      await _firestore.collection(email).doc('ats_score').set({
        'percentage': data,
      });
      print('Data added successfully!');
    } catch (e) {
      print('Error adding data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the color of the progress bar based on the percentage match
    Color progressColor = percentageMatch >= 75 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Candidate's Name
            Text(
              'Candidate: $candidateName',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Display Percentage Match
            Row(
              children: [
                Text(
                  'Percentage Match: ',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '$percentageMatch%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Progress Bar
            LinearProgressIndicator(
              value: percentageMatch / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 10,
            ),
            SizedBox(height: 20),
            // Display the Response Text
            Expanded(
              child: Markdown(
                data: responseText,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 16),
                ),
              ),
            ),
            // Conditionally display the "Proceed" button
            if (percentageMatch >= 75)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20), // Add vertical padding
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to ProceedPage when pressed
                      addData(percentageMatch);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            jobDescription: jobDescription,
                            candidateName: candidateName,
                          ),
                        ),
                      );
                    },
                    child: Text("Proceed"),
                    style: ElevatedButton.styleFrom(
                      // Button color
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      // primary: Colors.green, // Set the button color
                      // onPrimary: Colors.white, // Set the text color
                      elevation: 5, // Shadow
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15), // Rounded edges
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
