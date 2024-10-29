import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch Aptitude Test Score
  Future<double?> getAptitudeScore(String userId) async {
    // Adjusted to use userId as the collection
    var doc = await _db.collection(userId).doc('aptitude_test').get();
    return doc.data()?['score']?.toDouble();
  }

  // Fetch ATS Score
  Future<double?> getAtsScore(String userId) async {
    // Adjusted to use userId as the collection
    var doc = await _db.collection(userId).doc('ats_score').get();
    return doc.data()?['percentage']?.toDouble();
  }

  // Fetch Interview Feedback and Score
  Future<Map<String, dynamic>?> getInterviewData(String userId) async {
    // Adjusted to use userId as the collection
    var doc = await _db.collection(userId).doc('interview').get();
    return doc.data();
  }

  // Display Aptitude Test Score
  void displayAptitudeScore(String userId) {
    final docRef = _db.collection(userId).doc('aptitude_test');

    docRef.get().then(
      (DocumentSnapshot doc) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final score = data['score']?.toDouble();
          if (score != null) {
            print("Aptitude Test Score: $score");
          } else {
            print("Score not found in aptitude_test document.");
          }
        } else {
          print("Document aptitude_test not found for user $userId.");
        }
      },
      onError: (e) => print("Error getting document: $e"),
    );
  }
}
