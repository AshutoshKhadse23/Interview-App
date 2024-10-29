import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import flutter_markdown
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'message.dart';
import 'package:speech_to_text/speech_to_text.dart'
    as stt; // For speech recognition
import 'package:flutter_tts/flutter_tts.dart'; // For text-to-speech
import 'result_screen.dart';

class ChatScreen extends StatefulWidget {
  final String jobDescription;
  final String candidateName;
  ChatScreen({required this.jobDescription, required this.candidateName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _userInput = TextEditingController();
  final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey:
          'API KEY');

  final List<Message> _messages = [];
  List<String> _questions = [];
  int _interviewStep = 0;
  bool _isInterviewComplete = false;
  late stt.SpeechToText _speech; // Speech recognition variable
  late FlutterTts _flutterTts; // Text-to-speech variable
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _prepareQuestions(widget.candidateName,
        widget.jobDescription); // Call this with the actual candidate's name
    _speech = stt.SpeechToText(); // Initialize speech recognition
    _flutterTts = FlutterTts(); // Initialize text-to-speech
  }

  // Fetch questions using the generative AI
  Future<void> _prepareQuestions(
      String candidateName, String jobDescription) async {
    final prompt = """
    You are acting as an interviewer. Greet the candidate by name in a friendly and natural manner, briefly explaining that you’re conducting an interview based on the following job description. Immediately generate 5 interview questions for the candidate without waiting for a response or including any headings.
    Interviewer name : JobQuest
    Candidate Name: $candidateName
    Job Description: $jobDescription

    """;

    final response = await model.generateContent([Content.text(prompt)]);

    setState(() {
      // Add the initial introduction from Gemini
      final introduction = response.text?.split("\n").firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => "Welcome! Let's start."); // More natural greeting

      _messages.add(Message(
        isUser: false,
        message:
            introduction ?? "Welcome! Let's start.", // Handle nullable case
        date: DateTime.now(),
      ));

      // Read the introduction aloud
      _speak(introduction ?? "Welcome! Let's start()"); // Handle nullable case

      // Extract questions and start asking the first question directly
      _questions = _extractQuestions(response.text ?? "");
      _startInterview();
    });
  }

  // Utility to extract questions and format them
  List<String> _extractQuestions(String text) {
    final lines =
        text.split("\n").skip(1); // Skip the first line (introduction)

    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((question) =>
            '**${question.trim()}**') // Apply ** for bold formatting
        .toList();
  }

  // Start the interview by sending the first question directly after the introduction
  void _startInterview() {
    if (_questions.isNotEmpty) {
      final firstQuestion = _questions[0];
      _messages.add(
        Message(isUser: false, message: firstQuestion, date: DateTime.now()),
      );
      _speak(firstQuestion); // Read the first question aloud
    }
  }

  // Send user message and fetch bot's response
  Future<void> _sendMessage() async {
    final message = _userInput.text;

    if (message.isEmpty && _text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'You Ask Nothing!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      setState(() {
        _messages.add(
          Message(
              isUser: true,
              message: _text.isEmpty ? message : _text,
              date: DateTime.now()),
        );
        _interviewStep++;
      });

      if (_interviewStep < _questions.length) {
        final nextQuestion = _questions[_interviewStep];
        _messages.add(Message(
            isUser: false, message: nextQuestion, date: DateTime.now()));
        _speak(nextQuestion); // Read the next question aloud
      } else if (_interviewStep == _questions.length) {
        final evaluation = await _evaluateCandidate();
        _navigateToResultsScreen(evaluation);
        _isInterviewComplete = true;
      }

      _userInput.clear();
      _text = ''; // Clear the speech text
    }
  }

  // Speech recognition functionality
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (error) => print('Error: $error'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
            _userInput.text =
                _text; // Update the TextField with recognized words
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Function to evaluate the candidate based on answers
// Function to evaluate the candidate based on answers and provide detailed feedback
  Future<Map<String, dynamic>> _evaluateCandidate() async {
    final responses =
        _messages.where((msg) => msg.isUser).map((msg) => msg.message).toList();

    final interviewText = _questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      final answer = responses.length > index ? responses[index] : "";
      return "Question: $question\nAnswer: $answer\n";
    }).join("\n");

    final prompt = """
    Evaluate the candidate based on their answers to the following interview questions:

    $interviewText

    Provide a score out of 10 for each answer. Also, give detailed feedback on areas where the candidate performed well and areas where they need improvement. Provide constructive criticism on their weaknesses and actionable steps for improvement.
  """;

    final response = await model.generateContent([Content.text(prompt)]);
    return _extractEvaluation(response.text ?? "0/10");
  }

// Function to extract scores and feedback from the AI's response
  Map<String, dynamic> _extractEvaluation(String responseText) {
    final regex = RegExp(r'(\d+)\s*/\s*10'); // Find scores out of 10
    final matches = regex.allMatches(responseText);
    int totalMarks = 0;
    int numQuestions = _questions.length;
    List<int> scores = [];

    for (var match in matches) {
      final score = int.parse(match.group(1) ?? '0');
      scores.add(score);
      totalMarks += score;
    }

    // Extract feedback on strengths and weaknesses
    final feedbackStart = responseText.indexOf("Feedback:");
    final feedback = feedbackStart != -1
        ? responseText.substring(feedbackStart)
        : "No feedback provided.";

    double totalScoreOutOf100 = (totalMarks / (numQuestions * 10)) * 100;

    return {
      "totalScore": totalScoreOutOf100.round(),
      "individualScores": scores,
      "feedback": feedback
    };
  }

  // Extract marks out of 100
  int _extractMarks(String responseText) {
    final regex = RegExp(r'(\d+)\s*/\s*10');
    final matches = regex.allMatches(responseText);
    int totalMarks = 0;
    for (var match in matches) {
      totalMarks += int.parse(match.group(1) ?? '0');
    }
    double totalScoreOutOf100 = (totalMarks / (_questions.length * 10)) * 100;
    return totalScoreOutOf100.round();
  }

  // Navigate to results screen
  void _navigateToResultsScreen(Map<String, dynamic> evaluation) {
    int totalMarks =
        evaluation['totalScore']; // Extract total marks from evaluation map
    String feedback =
        evaluation['feedback']; // Extract feedback from evaluation map

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          totalMarks: totalMarks,
          feedback: feedback,
        ),
      ),
    );
  }

  // Function to speak text
  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview ChatBot'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Row(
                  mainAxisAlignment: message.isUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8),
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Colors.grey[300]
                            : Colors.blue[100],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: message.isUser
                          ? Text(
                              message.message,
                              style: const TextStyle(fontSize: 16),
                            )
                          : MarkdownBody(
                              data: message.message,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.deepPurple : null,
                  ),
                  onPressed: _listen,
                ),
                Expanded(
                  child: TextField(
                    controller: _userInput,
                    decoration: const InputDecoration(
                      labelText: 'Type your answer or use the mic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _userInput.clear(); // Clear the input field
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
