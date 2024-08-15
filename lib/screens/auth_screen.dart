import 'dart:io';

import 'package:chat_app/widgets/image_picker_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

final _firebaseAuthInstance = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = false;
  final formKey = GlobalKey<FormState>();
  var email = "";
  var pwd = "";
  File? userImageFile;
  var username = "";
  var isAuthenticating = false;

  void toggleLogin() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void submit() async {
    final formInvalid = !formKey.currentState!.validate() ||
        (!isLogin && userImageFile == null);

    if (formInvalid) {
      return;
    }

    formKey.currentState!.save();
    try {
      setState(() {
        isAuthenticating = true;
      });
      if (isLogin) {
        await _firebaseAuthInstance.signInWithEmailAndPassword(
            email: email, password: pwd);
      } else {
        final userCredential =
            await _firebaseAuthInstance.createUserWithEmailAndPassword(
          email: email,
          password: pwd,
        );

        final imageStorageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredential.user!.uid}.jpg');

        await imageStorageRef.putFile(userImageFile!);
        final imageUrl = await imageStorageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': username,
          'user_email': email,
          'user_image_url': imageUrl
        });
      }
    } on FirebaseAuthException catch (error) {
      // Note that this could be treated by error type
      // if (error.code == 'email-already-in-us') {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message ?? 'Authentication failed'),
      ));
      setState(() {
        isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(isLogin ? 'Sign-in' : 'Sign-up'),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  child: Image.asset('assets/images/chat.png'),
                ),
                const SizedBox(
                  height: 16,
                ),
                Card(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            if (!isLogin)
                              ImagePickerWidget(
                                  onPickImage: (image) =>
                                      userImageFile = image),
                            if (!isLogin)
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Username'
                                  ),
                                  enableSuggestions: false,
                                  validator: (value) {
                                    if (value == null || value.isEmpty || value.trim().length < 4) {
                                      return 'Please insert a valid username.';
                                    }
                                  },
                                  onSaved: (value) => username = value!,
                                ),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Email Address'),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@') ||
                                    !value.contains('.')) {
                                  return 'Please insert a valid email.';
                                }
                              },
                              onSaved: (value) => email = value!,
                            ),
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Password'),
                              obscureText: true,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    value.trim().length < 6) {
                                  return 'A valid password should contains at least 6 characters';
                                }
                              },
                              onSaved: (value) => pwd = value!,
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            isAuthenticating
                                ? const CircularProgressIndicator()
                                : Column(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer),
                                        onPressed: submit,
                                        child: Text(
                                            isLogin ? 'Login' : 'Register'),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          formKey.currentState!.reset();
                                          toggleLogin();
                                        },
                                        child: Text(isLogin
                                            ? 'Create an account'
                                            : 'I already have an account'),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
