import 'user_profile.dart';

class FriendRequest {
  final String id; // friendship record id
  final UserProfile sender;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.sender,
    required this.createdAt,
  });
}
