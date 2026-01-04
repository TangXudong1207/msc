import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add HapticFeedback
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';
import 'friend_chat_screen.dart';
import 'add_friend_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadFriends();
    });
  }

  String _formatTime(DateTime time, bool isChinese) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) {
      return isChinese ? '${diff.inDays}天前' : '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return isChinese ? '${diff.inHours}小时前' : '${diff.inHours}h ago';
    } else {
      return isChinese ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, String friendId, String friendName) {
    final languageProvider = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('删除好友', 'Delete Friend')),
        content: Text(languageProvider.getText(
          '确定要删除 $friendName 吗？此操作无法撤销。',
          'Are you sure you want to delete $friendName? This cannot be undone.'
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.getText('取消', 'Cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await context.read<ChatProvider>().deleteFriend(friendId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(languageProvider.getText('已删除', 'Deleted'))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(languageProvider.getText('删除', 'Delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Style Constants
    final paperColor = const Color(0xFFF4ECD8); 
    final terracotta = const Color(0xFFBC5D48);
    final inkBlack = const Color(0xFF2C2C2C);
    final languageProvider = context.watch<LanguageProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: paperColor,
        appBar: AppBar(
          backgroundColor: paperColor,
          elevation: 0,
          iconTheme: IconThemeData(color: terracotta),
          title: Text(
            languageProvider.getText('好友列表', 'FRIENDS'),
            style: TextStyle(
              color: inkBlack,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          bottom: TabBar(
            labelColor: terracotta,
            unselectedLabelColor: Colors.grey,
            indicatorColor: terracotta,
            labelStyle: const TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            tabs: [
              Tab(text: languageProvider.getText('消息', 'MESSAGES')),
              Tab(text: languageProvider.getText('联系人', 'CONTACTS')),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddFriendScreen()),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildRecentChats(context),
            _buildContacts(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChats(BuildContext context) {
    final terracotta = const Color(0xFFBC5D48);
    final inkBlack = const Color(0xFF2C2C2C);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final friends = chatProvider.friends;
        return ListView.separated(
          padding: const EdgeInsets.only(top: 16),
          itemCount: friends.length,
          separatorBuilder: (context, index) => Divider(
            height: 1, 
            indent: 72, 
            endIndent: 24, 
            color: terracotta.withValues(alpha: 0.1)
          ),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return ListTile(
              onLongPress: () {
                HapticFeedback.heavyImpact(); // Add haptic feedback
                _showDeleteConfirmDialog(context, friend.id, friend.name);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: terracotta.withValues(alpha: 0.1),
                child: Text(
                  friend.avatarUrl,
                  style: TextStyle(
                    color: terracotta,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              title: Text(
                friend.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                  color: inkBlack,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  friend.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Georgia',
                    fontSize: 13,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(friend.lastMessageTime, context.read<LanguageProvider>().isChinese),
                    style: TextStyle(
                      fontSize: 11, 
                      color: Colors.grey[500],
                      fontFamily: 'Georgia',
                    ),
                  ),
                  if (friend.unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: terracotta,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${friend.unreadCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendChatScreen(friend: friend),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContacts(BuildContext context) {
    final terracotta = const Color(0xFFBC5D48);
    final inkBlack = const Color(0xFF2C2C2C);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final contacts = chatProvider.contacts;
        return ListView.separated(
          padding: const EdgeInsets.only(top: 16),
          itemCount: contacts.length,
          separatorBuilder: (context, index) => Divider(
            height: 1, 
            indent: 72, 
            endIndent: 24, 
            color: terracotta.withValues(alpha: 0.1)
          ),
          itemBuilder: (context, index) {
            final friend = contacts[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                child: Text(
                  friend.avatarUrl,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              title: Text(
                friend.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                  color: inkBlack,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendChatScreen(friend: friend),
                  ),
                );
              },
              onLongPress: () => _showDeleteConfirmDialog(context, friend.id, friend.name),
            );
          },
        );
      },
    );
  }
}
