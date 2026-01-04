import 'package:uuid/uuid.dart';
import 'meaning_card.dart';

enum MessageType { text, image }

class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  MeaningCard? meaningCard;

  Message({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.type = MessageType.text,
    this.meaningCard,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();
}
