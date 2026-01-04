import 'message.dart';

class Friend {
  final String id;
  final String name;
  final String avatarUrl; // Or asset path
  String lastMessage;
  DateTime lastMessageTime;
  int unreadCount;
  final List<Message> messages; // Chat history

  Friend({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    List<Message>? messages,
  }) : messages = messages ?? [];
}

// Mock Data
final List<Friend> mockFriends = [
  Friend(
    id: '1',
    name: 'Alice',
    avatarUrl: 'A',
    lastMessage: 'Hey, how are you doing?',
    lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
    unreadCount: 2,
    messages: [
      Message(content: 'Hey, how are you doing?', isUser: false, timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    ],
  ),
  Friend(
    id: '2',
    name: 'Bob',
    avatarUrl: 'B',
    lastMessage: 'Did you see the new update?',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
    unreadCount: 0,
    messages: [
      Message(content: 'Did you see the new update?', isUser: false, timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    ],
  ),
  Friend(
    id: '3',
    name: 'Charlie',
    avatarUrl: 'C',
    lastMessage: 'Let\'s meet up tomorrow.',
    lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
    unreadCount: 0,
    messages: [
      Message(content: 'Let\'s meet up tomorrow.', isUser: false, timestamp: DateTime.now().subtract(const Duration(days: 1))),
    ],
  ),
  Friend(
    id: '4',
    name: 'Diana',
    avatarUrl: 'D',
    lastMessage: 'Thanks for the help!',
    lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
    unreadCount: 0,
    messages: [
      Message(content: 'Thanks for the help!', isUser: false, timestamp: DateTime.now().subtract(const Duration(days: 2))),
    ],
  ),
];
