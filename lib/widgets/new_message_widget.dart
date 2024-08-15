import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class NewMessageWidget extends StatefulWidget {
  const NewMessageWidget({super.key});

  @override
  State<NewMessageWidget> createState() {
    return _NewMessageWidgetState();
  }
}

class _NewMessageWidgetState extends State<NewMessageWidget> {

  final inputController = TextEditingController();

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (inputController.text.trim().isEmpty) {
      return;
    }

    // Close keyboard
    FocusScope.of(context).unfocus();
    final enteredMessage = inputController.text;
    inputController.clear();

    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    // Send to firebase
    FirebaseFirestore.instance
        .collection('chat')
        .add({
      'message': enteredMessage,
      'date': Timestamp.now(),
      'userId': user.uid,
      'username': userData['username'],
      'user_image_url': userData['user_image_url']
    });

  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: inputController,
              decoration: const InputDecoration(labelText: 'Send a message...'),
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
    );
  }
}
