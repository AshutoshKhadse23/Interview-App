import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import the flutter_markdown package
import 'firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  DashboardScreen({required this.userId});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late FirestoreService _firestoreService;
  double? aptitudeScore, atsScore, interviewScore;
  String? interviewFeedback;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Fetch scores and feedback
    double? aptitude = await _firestoreService.getAptitudeScore(widget.userId);
    double? ats = await _firestoreService.getAtsScore(widget.userId);
    Map<String, dynamic>? interview =
        await _firestoreService.getInterviewData(widget.userId);

    setState(() {
      aptitudeScore = aptitude;
      atsScore = ats;
      interviewScore = interview?['score']?.toDouble();
      interviewFeedback = interview?['feedback'];
    });
  }

  void _navigateTo(BuildContext context, String route) {
    // Use Navigator to navigate to different screens
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              _navigateTo(context, '/aptitude_test');
            },
            itemBuilder: (BuildContext context) {
              return {'Aptitude Test', 'Resume', 'Interview'}
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: aptitudeScore == null ||
                atsScore == null ||
                interviewScore == null ||
                interviewFeedback == null
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                // Wrap the Column with SingleChildScrollView
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aptitude Score and Progress Meter
                    Text(
                        'Aptitude Score: ${aptitudeScore?.toStringAsFixed(2) ?? "Loading..."}',
                        style: TextStyle(fontSize: 20)),
                    LinearProgressIndicator(
                      value: aptitudeScore! / 100, // Assuming max score is 100
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),

                    // ATS Score and Progress Meter
                    Text(
                        'ATS Score: ${atsScore?.toStringAsFixed(2) ?? "Loading..."}',
                        style: TextStyle(fontSize: 20)),
                    LinearProgressIndicator(
                      value: atsScore! / 100, // Assuming max score is 100
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 16),

                    // Interview Score and Progress Meter
                    Text(
                        'Interview Score: ${interviewScore?.toStringAsFixed(2) ?? "Loading..."}',
                        style: TextStyle(fontSize: 20)),
                    LinearProgressIndicator(
                      value: interviewScore! / 100, // Assuming max score is 100
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    SizedBox(height: 16),

                    // Interview Feedback
                    Text(
                      'Interview Feedback:',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: MarkdownBody(
                        data: interviewFeedback ?? "Loading...",
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(fontSize: 18), // Paragraph text style
                          strong: TextStyle(
                              fontWeight: FontWeight.bold), // Bold text style
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
