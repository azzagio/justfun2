import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({Key? key, required this.message, required this.isMe}) : super(key: key);

  Widget _buildTimeStamp() {
    final DateTime messageTime = message.timestamp;
    final now = DateTime.now();
    String formattedTime = (messageTime.year == now.year && messageTime.month == now.month && messageTime.day == now.day)
        ? DateFormat('HH:mm').format(messageTime)
        : DateFormat('dd/MM HH:mm').format(messageTime);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        formattedTime,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isMe) _buildTimeStamp(),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
            ),
          ),
          if (!isMe) _buildTimeStamp(),
        ],
      ),
    );
  }
}
