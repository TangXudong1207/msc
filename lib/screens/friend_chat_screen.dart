import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend.dart';
import '../models/message.dart';
import '../models/meaning_spectrum.dart'; // Import for extension methods
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';

class FriendChatScreen extends StatefulWidget {
  final Friend friend;

  const FriendChatScreen({super.key, required this.friend});

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    
    // 1. Send message via provider
    chatProvider.sendFriendMessage(widget.friend.id, text);
    _controller.clear();
    _scrollToBottom();

    // 2. Analyze meaning (Async)
    // Get updated friend object
    final updatedFriend = chatProvider.friends.firstWhere((f) => f.id == widget.friend.id);
    final contextHistory = updatedFriend.messages
        .reversed
        .take(5)
        .map((m) => "${m.isUser ? '用户' : '好友'}: ${m.content}")
        .toList();

    final isChinese = context.read<LanguageProvider>().isChinese;
    final meaningCard = await chatProvider.analyzeFriendMessage(widget.friend.id, text, contextHistory, isChinese: isChinese);

    if (meaningCard != null && mounted) {
      _scrollToBottom();
    }

    // 3. Mock reply
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        chatProvider.receiveFriendMessage(widget.friend.id, 'This is a mock reply from ${widget.friend.name}.');
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Style Constants
    final paperColorLight = const Color(0xFFFDFBF7);
    final terracotta = const Color(0xFFBC5D48);
    final inkBlack = const Color(0xFF2C2C2C);
    final languageProvider = context.watch<LanguageProvider>();

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Find the friend in the provider to get the latest state
        Friend? currentFriend;
        try {
          currentFriend = chatProvider.friends.firstWhere((f) => f.id == widget.friend.id);
        } catch (e) {
          currentFriend = widget.friend;
        }

        return Scaffold(
          backgroundColor: paperColorLight,
          appBar: AppBar(
            backgroundColor: paperColorLight,
            elevation: 0,
            iconTheme: IconThemeData(color: terracotta),
            title: Text(
              currentFriend.name,
              style: TextStyle(
                color: inkBlack,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: terracotta.withValues(alpha: 0.1),
                height: 1.0,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: currentFriend.messages.length,
                  itemBuilder: (context, index) {
                    final message = currentFriend!.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: paperColorLight,
                  border: Border(top: BorderSide(color: terracotta.withValues(alpha: 0.1))),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(fontFamily: 'Georgia'),
                            decoration: InputDecoration(
                              hintText: languageProvider.getText('输入消息...', 'Type a message...'),
                              hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Georgia'),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.send_outlined),
                        color: terracotta,
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    final ivyGreen = const Color(0xFF6B8E23);
    final terracotta = const Color(0xFFBC5D48);

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            decoration: !isUser
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: ivyGreen, width: 3),
                    ),
                  )
                : null,
            padding: !isUser ? const EdgeInsets.only(left: 12) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? terracotta.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Color(0xFF2C2C2C),
                  fontFamily: 'Georgia',
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
        if (message.meaningCard != null)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF7),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: terracotta.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: message.meaningCard!.spectrum.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${context.read<LanguageProvider>().getText('意义', 'MEANING')}: ${message.meaningCard!.spectrum.displayName.split('\n')[0]}",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: terracotta,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.expand_more,
                    size: 16,
                    color: terracotta,
                  ),
                  children: [
                    Text(
                      message.meaningCard!.content,
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.grey[800],
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
