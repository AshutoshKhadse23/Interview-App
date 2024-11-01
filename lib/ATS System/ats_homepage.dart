import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf_text/pdf_text.dart';
import 'response_page.dart';

class ResumeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATS Resume Expert',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ResumeHomePage(),
    );
  }
}

class ResumeHomePage extends StatefulWidget {
  @override
  _ResumeHomePageState createState() => _ResumeHomePageState();
}

class _ResumeHomePageState extends State<ResumeHomePage> {
  File? uploadedFile;
  String jobDescription = '';
  String apiKey = 'AIzaSyAt6YBVTCCcDKBMclzg7tHZST-uIIEggEY';

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        uploadedFile = File(result.files.single.path!);
      });
    }
  }

  void _viewPDF() {
    if (uploadedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFView(
            filePath: uploadedFile!.path,
          ),
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getGeminiResponse(
      String inputText, String prompt) async {
    if (uploadedFile == null) {
      return {"error": "Error: No resume uploaded."};
    }

    String resumeContent = await _readPdfContent(uploadedFile!);

    // Extract the name from the first few lines of the resume
    String name = _extractNameFromResume(resumeContent);

    Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': inputText + '\n\n' + prompt + '\n\n' + resumeContent}
          ]
        }
      ]
    };

    Dio dio = Dio();

    try {
      Response response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey',
        data: jsonEncode(requestBody),
      );

      if (response.data != null && response.data['candidates'] != null) {
        var candidate = response.data['candidates'][0];
        var textContent = candidate['content']['parts'][0]['text'];
        // Extract percentage match from response
        int percentageMatch = _extractPercentageMatch(textContent);
        return {
          "name": name,
          "responseText": textContent,
          "percentageMatch": percentageMatch
        };
      }

      return {"error": "No proper response from the API."};
    } catch (e) {
      print('Error: $e');
      if (e is DioError) {
        print(
            'Dio error details: ${e.response?.statusCode} - ${e.response?.data}');
        return {"error": "Error: ${e.response?.data['error']['message']}"};
      }
      return {"error": "An unexpected error occurred."};
    }
  }

  // Function to read PDF content
  Future<String> _readPdfContent(File file) async {
    try {
      PDFDoc doc = await PDFDoc.fromFile(file);
      String text = await doc.text;
      return text;
    } catch (e) {
      print("Error reading PDF content: $e");
      return "Error reading PDF content.";
    }
  }

  // Extract name from resume
  String _extractNameFromResume(String resumeContent) {
    // Assuming the name is in the first few lines
    List<String> lines = resumeContent.split('\n');
    for (String line in lines) {
      if (_isValidName(line.trim())) {
        return line.trim();
      }
    }
    return "Unknown Candidate";
  }

  // Basic check for a valid name (can be extended based on regex or other rules)
  bool _isValidName(String line) {
    // Assume a valid name contains two words (First and Last)
    return line.split(' ').length >= 2;
  }

  // Mock function to extract percentage match from response (can be refined based on API response structure)
  int _extractPercentageMatch(String responseText) {
    // Assuming the API returns the match percentage in plain text
    RegExp regExp = RegExp(r'(\d+)%');
    Match? match = regExp.firstMatch(responseText);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0; // Default if no percentage found
  }

  Future<void> _handleTellMeAboutResume() async {
    String prompt = """
You are an experienced Technical Human Resource Manager, your task is to review the provided resume against the job description.
Please share your professional evaluation on whether the candidate's profile aligns with the role. Highlight the strengths and weaknesses of the applicant in relation to the specified job requirements.
""";

    var response = await _getGeminiResponse(jobDescription, prompt);

    if (response.containsKey("error")) {
      // Handle error
      print(response["error"]);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResponsePage(
          responseText: response['responseText'],
          title: "Resume Evaluation",
          candidateName: response['name'],
          percentageMatch: response['percentageMatch'],
          jobDescription: jobDescription,
        ),
      ),
    );
  }

  Future<void> _handlePercentageMatch() async {
    String prompt = """
You are a skilled ATS (Applicant Tracking System) scanner with a deep understanding of data science and ATS functionality.
Your task is to evaluate the resume against the provided job description. Give me the percentage match, missing keywords, and final thoughts.
""";

    var response = await _getGeminiResponse(jobDescription, prompt);

    if (response.containsKey("error")) {
      // Handle error
      print(response["error"]);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResponsePage(
          responseText: response['responseText'],
          title: "Percentage Match",
          candidateName: response['name'],
          percentageMatch: response['percentageMatch'],
          jobDescription: jobDescription,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ATS Resume Expert"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center elements horizontally
              mainAxisAlignment:
                  MainAxisAlignment.start, // Start elements from the top
              children: [
                // Job Description TextField
                TextField(
                  maxLines: 5,
                  onChanged: (value) {
                    setState(() {
                      jobDescription = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Job Description",
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 20),

                // Upload Resume Button
                SizedBox(
                  width: double.infinity, // Full width button
                  child: ElevatedButton(
                    onPressed: _pickFile,
                    child: Text(
                      uploadedFile == null
                          ? "Upload Resume (PDF)"
                          : "Resume Uploaded!",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),

          // Conditionally display the PDF if it's uploaded
          if (uploadedFile != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: PDFView(
                  filePath: uploadedFile!.path,
                  autoSpacing: false,
                  swipeHorizontal:
                      true, // Enable horizontal scrolling for better viewing
                  fitPolicy: FitPolicy.BOTH, // Scale the PDF to fit the screen
                  onRender: (pages) {
                    setState(() {
                      // To force a rebuild after the PDF has been rendered
                    });
                  },
                  onError: (error) {
                    print(error.toString());
                  },
                ),
              ),
            ),

          SizedBox(height: 20),

          // Percentage Match Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity, // Full width button
              child: ElevatedButton(
                onPressed: _handlePercentageMatch,
                child: Text(
                  "Percentage Match",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }
}
