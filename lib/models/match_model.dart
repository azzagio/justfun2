// lib/models/match_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class MatchModel {
  final String id;
  final UserModel user;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final bool lastMessageRead;

  MatchModel({
    required this.id,
    required this.user,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.lastMessageRead,
  });

  factory MatchModel.fromMap(Map<String, dynamic> data, String id, UserModel user) {
    return MatchModel(
      id: id,
      user: user,
      lastMessage: data['lastMessage'],
      lastMessageTimestamp: data['lastMessageTimestamp'] != null
          ? (data['lastMessageTimestamp'] as Timestamp).toDate()
          : null,
      lastMessageRead: data['lastMessageRead'] ?? true,
    );
  }
}