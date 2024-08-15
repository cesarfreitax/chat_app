import 'package:chat_app/widgets/message_bubble_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessagesWidget extends StatelessWidget {
  const MessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final currentActiveUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (ctx, snapshots) {
        if (snapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshots.hasData || snapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found.'),
          );
        }

        if (snapshots.hasError) {
          return const Center(
            child: Text('Something went wrong...'),
          );
        }

        final messages = snapshots.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(left: 13, right: 13, bottom: 40),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (ctx, index) {
            final message = messages[index].data();
            final hasNextMessage = index + 1 < messages.length;
            final nextMessage =
                hasNextMessage ? messages[index + 1].data() : null;

            final currentUserId = message['userId'];
            final nextUserId = nextMessage?['userId'];
            final nextUserIsTheSame = currentUserId == nextUserId;

            if (nextUserIsTheSame) {
              return MessageBubble.next(
                  message: message['message'],
                  isMe: currentActiveUserId == currentUserId);
            } else {
              return MessageBubble.first(
                userImage: message['user_image_url'],
                username: message['username'],
                message: message['message'],
                isMe: currentActiveUserId == currentUserId,
              );
            }
          },
        );
      },
    );
  }
}
