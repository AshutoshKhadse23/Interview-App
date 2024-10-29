import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:interview_app/constants.dart';
import 'package:interview_app/components/components.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static String id = 'signup_screen';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _email;
  String? _password;
  String? _confirmPass;
  bool _saving = false;

  Future<void> _signUp() async {
    // Unfocus the keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    // Check if passwords match
    if (_password != _confirmPass) {
      _showAlert(
        context: context,
        title: 'WRONG PASSWORD',
        desc: 'Make sure that you write the same password twice',
      );
      return;
    }

    // Start loading overlay
    setState(() {
      _saving = true;
    });

    try {
      // Create user with email and password
      await _auth.createUserWithEmailAndPassword(
        email: _email!,
        password: _password!,
      );

      // Successful sign-up, show success alert
      if (context.mounted) {
        _showSuccessAlert(context);
      }
    } on FirebaseAuthException catch (e) {
      _showAlert(
        context: context,
        title: 'ERROR',
        desc: e.message ?? 'Something went wrong. Please try again.',
      );
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  void _showAlert({
    required BuildContext context,
    required String title,
    required String desc,
  }) {
    showAlert(
      context: context,
      title: title,
      desc: desc,
      onPressed: () {
        Navigator.pop(context);
      },
    ).show();
  }

  void _showSuccessAlert(BuildContext context) {
    signUpAlert(
      context: context,
      title: 'GOOD JOB',
      desc: 'Go login now',
      btnText: 'Login Now',
      onPressed: () {
        Navigator.popAndPushNamed(context, LoginScreen.id);
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popAndPushNamed(context, HomeScreen.id);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LoadingOverlay(
          isLoading: _saving,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TopScreenImage(screenImageName: 'signup.png'),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ScreenTitle(title: 'Sign Up'),
                          CustomTextField(
                            textField: TextField(
                              onChanged: (value) {
                                _email = value;
                              },
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 20),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Email',
                              ),
                            ),
                          ),
                          CustomTextField(
                            textField: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                _password = value;
                              },
                              style: const TextStyle(fontSize: 20),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Password',
                              ),
                            ),
                          ),
                          CustomTextField(
                            textField: TextField(
                              obscureText: true,
                              onChanged: (value) {
                                _confirmPass = value;
                              },
                              style: const TextStyle(fontSize: 20),
                              decoration: kTextInputDecoration.copyWith(
                                hintText: 'Confirm Password',
                              ),
                            ),
                          ),
                          CustomBottomScreen(
                            textButton: 'Sign Up',
                            heroTag: 'signup_btn',
                            question: 'Have an account?',
                            buttonPressed: _signUp,
                            questionPressed: () async {
                              Navigator.pushNamed(context, LoginScreen.id);
                            },
                          ),
                        ],
                      ),
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
