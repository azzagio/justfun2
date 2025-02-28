import 'package:simple_dating_app/models/user_model.dart';

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
}
