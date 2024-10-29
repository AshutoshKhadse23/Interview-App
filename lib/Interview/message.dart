import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class Message {
  final bool isUser; // true if it's a user message, false if it's a bot message
  final String message; // the text of the message
  final DateTime date; // timestamp of the message

  Message({
    required this.isUser,
    required this.message,
    required this.date,
  });
}

class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;

  const Messages({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.lightBlueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(1, 1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: message,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 14, color: Colors.black87),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                em: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(
                height: 4), // Reduced spacing for a more compact look
            Text(
              date,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
