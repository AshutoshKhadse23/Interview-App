import 'package:flutter/material.dart';
import 'package:interview_app/components/components.dart';
import 'package:interview_app/constants.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:interview_app/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:interview_app/Apltitude Test/aptitude_test.dart';
import 'package:interview_app/Dashboard/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static String id = 'login_screen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  late String _email;
  late String _password;
  bool _saving = false;
  bool hasDocuments = false;

  Future<bool> checkCollectionContent(String collectionName) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference collectionRef = firestore.collection(collectionName);

    bool hasDocuments = false; // Initialize the boolean variable

    try {
      // Fetch documents from the collection
      QuerySnapshot querySnapshot = await collectionRef.get();

      // Debug: Print the number of documents fetched
      print('Number of documents fetched: ${querySnapshot.docs.length}');

      // Check if the collection is empty
      if (querySnapshot.docs.isEmpty) {
        hasDocuments = false; // Set to false if the collection is empty
      } else {
        hasDocuments = true; // Set to true if the collection has documents
      }
    } catch (e) {
      print('Error fetching documents: $e');
      hasDocuments = false; // Set to false in case of an error
    }

    return hasDocuments; // Return the boolean value
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomeScreen.id);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _saving,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const TopScreenImage(screenImageName: 'welcome.png'),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const ScreenTitle(title: 'Login'),
                        CustomTextField(
                          textField: TextField(
                              onChanged: (value) {
                                _email = value;
                              },
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                              decoration: kTextInputDecoration.copyWith(
                                  hintText: 'Email')),
                        ),
                        CustomTextField(
                          textField: TextField(
                            obscureText: true,
                            onChanged: (value) {
                              _password = value;
                            },
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                            decoration: kTextInputDecoration.copyWith(
                                hintText: 'Password'),
                          ),
                        ),
                        CustomBottomScreen(
                          textButton: 'Login',
                          heroTag: 'login_btn',
                          question: 'Forgot password?',
                          buttonPressed: () async {
                            hasDocuments = await checkCollectionContent(_email);
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() {
                              _saving = true;
                            });
                            try {
                              await _auth.signInWithEmailAndPassword(
                                  email: _email, password: _password);

                              if (context.mounted) {
                                setState(() {
                                  _saving = false;
                                  Navigator.popAndPushNamed(
                                      context, LoginScreen.id);
                                });

                                if (!hasDocuments) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AptitudeTestApp(),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DashboardScreen(
                                        userId: _email,
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              signUpAlert(
                                context: context,
                                onPressed: () {
                                  setState(() {
                                    _saving = false;
                                  });
                                  Navigator.popAndPushNamed(
                                      context, LoginScreen.id);
                                },
                                title: 'WRONG PASSWORD OR EMAIL',
                                desc:
                                    'Confirm your email and password and try again',
                                btnText: 'Try Now',
                              ).show();
                            }
                          },
                          questionPressed: () {
                            signUpAlert(
                              onPressed: () async {
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(email: _email);
                              },
                              title: 'RESET YOUR PASSWORD',
                              desc:
                                  'Click on the button to reset your password',
                              btnText: 'Reset Now',
                              context: context,
                            ).show();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
