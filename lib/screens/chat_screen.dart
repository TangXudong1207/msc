import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add HapticFeedback
import 'dart:math';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Added
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../models/message.dart';
import '../models/meaning_spectrum.dart';
import '../widgets/app_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late String _randomHintText;

  final List<String> _hintTexts = [
    "今天有没有哪一刻，你突然停了一下......",
    "不用想清楚，说到哪算哪......",
    "不需要说的对......",
    "不成熟也没关系，慢慢说......",
    "这里不是考试，也没人逼你说......",
    "不用不好意思，说出来更重要......",
    "映射此刻的情绪.......",
  ];

  @override
  void initState() {
    super.initState();
    _randomHintText = _hintTexts[Random().nextInt(_hintTexts.length)];
    // 页面加载时获取历史消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages();
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (mounted) {
          context.read<ChatProvider>().sendImage(image);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // 强制使用动画，确保用户能感知到下滑动作
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _scrollToMessage(String messageId) {
    final messages = context.read<ChatProvider>().messages;
    final index = messages.indexWhere((m) => m.id == messageId);
    
    if (index != -1 && _scrollController.hasClients) {
      // 估算滚动位置 (假设平均高度 150)
      // 注意：这是一个粗略的估算，因为 ListView item 高度不固定
      // 如果列表很长，可能不准确。
      // 更好的做法是使用 scroll_to_index 库，但为了不引入新依赖，我们先用估算。
      final double estimatedOffset = index * 150.0; 
      
      // 确保不超过最大滚动范围
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double targetOffset = estimatedOffset > maxScroll ? maxScroll : estimatedOffset;

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LanguageProvider>().getText('已跳转到相关对话', 'Jumped to related message')), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, String?>((p) => p.currentUser);
    final languageProvider = context.watch<LanguageProvider>();
    
    // Style Constants
    final paperColorLight = const Color(0xFFFDFBF7);
    final terracotta = const Color(0xFFBC5D48);
    final inkBlack = const Color(0xFF2C2C2C);

    // 监听跳转请求
    final jumpId = context.select<ChatProvider, String?>((p) => p.jumpToMessageId);
    if (jumpId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMessage(jumpId);
        context.read<ChatProvider>().clearJumpToMessage();
      });
    }

    // 监听意义卡引导请求
    final shouldShowIntro = context.select<ChatProvider, bool>((p) => p.shouldShowMeaningCardIntro);
    if (shouldShowIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMeaningCardIntroDialog(context);
      });
    }

    return Scaffold(
      backgroundColor: paperColorLight,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: paperColorLight,
        elevation: 0,
        iconTheme: IconThemeData(color: terracotta),
        title: Text(
          user != null ? 'Hi, $user' : languageProvider.getText('AI 对话', 'AI Chat'),
          style: TextStyle(
            color: inkBlack,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: languageProvider.getText('清空对话', 'Clear Chat'),
            onPressed: () {
              context.read<ChatProvider>().clearMessages();
            },
          ),
          // Removed Logout button as requested
        ],
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
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // 自动滚动到底部 (仅当没有跳转请求时)
                if (chatProvider.jumpToMessageId == null) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Text(
                      languageProvider.getText('开始对话...', 'Start a conversation...'),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: 'Georgia',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount:
                      chatProvider.messages.length +
                      (chatProvider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatProvider.messages.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(color: terracotta)),
                      );
                    }

                    final message = chatProvider.messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    final ivyGreen = const Color(0xFF6B8E23);
    final terracotta = const Color(0xFFBC5D48);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
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
              child: message.type == MessageType.image
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        message.content,
                        width: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                        },
                      ),
                    )
                  : (isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Color(0xFF2C2C2C),
                            fontFamily: 'Georgia',
                            fontSize: 15,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: Color(0xFF2C2C2C),
                              fontFamily: 'Georgia',
                              fontSize: 15,
                              height: 1.4,
                            ),
                            strong: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )),
            ),
          ),
          
          // 意义卡显示区域
          if (isUser && message.meaningCard != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16, right: 4, top: 4),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF7), // Paper
                border: Border.all(color: terracotta.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                        context.read<LanguageProvider>().getText('意义分析', 'MEANING ANALYSIS'),
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
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${context.read<LanguageProvider>().getText('深度', 'DEPTH')}: ${(message.meaningCard!.score * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final paperColorLight = const Color(0xFFFDFBF7);
    final terracotta = const Color(0xFFBC5D48);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: paperColorLight,
        border: Border(top: BorderSide(color: terracotta.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              color: Colors.grey[600],
              onPressed: _pickImage,
            ),
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
                    hintText: context.read<LanguageProvider>().getText(_randomHintText, 'Type a message...'),
                    hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Georgia'),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
    );
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact(); // Add haptic feedback
      final isChinese = context.read<LanguageProvider>().isChinese;
      context.read<ChatProvider>().sendMessage(text, isChinese: isChinese);
      _controller.clear();
    }
  }

  void _showMeaningCardIntroDialog(BuildContext context) {
    // 标记为已读，防止重复弹窗
    context.read<ChatProvider>().markMeaningCardIntroSeen();

    // 滚动到底部以确保用户看到最新的意义卡
    _scrollToBottom();

    showDialog(
      context: context,
      barrierDismissible: false, // 强制用户点击按钮关闭
      builder: (context) {
        final languageProvider = context.watch<LanguageProvider>();
        final isChinese = languageProvider.isChinese;
        
        return Stack(
          children: [
            // 1. 引导内容
            Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4ECD8), // Paper color
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBC5D48), width: 2), // Terracotta
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 48, color: Color(0xFFBC5D48)),
                    const SizedBox(height: 24),
                    Text(
                      isChinese 
                        ? "刚刚那句话，被我们留下来了。" 
                        : "That sentence just now, we kept it.",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                        color: Color(0xFF2C2C2C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isChinese
                        ? "在这里，它被称为一张「意义卡」。\n\n意义卡不是观点，也不是结论，而是你真正认真思考过的痕迹。\n\n解锁更多的意义卡，你会看到更多与世界互动的方式。不是被推送，而是从你自己出发。"
                        : "Here, it is called a 'Meaning Card'.\n\nA Meaning Card is not an opinion, nor a conclusion, but a trace of your serious thinking.\n\nUnlock more Meaning Cards, and you will see more ways to interact with the world. Not pushed to you, but starting from yourself.",
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        fontFamily: 'Georgia',
                        color: Color(0xFF4A4A4A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBC5D48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        isChinese ? "我知道了" : "Got it",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 2. 指向左上角菜单的箭头 (示意意义盒子)
            Positioned(
              top: 60,
              left: 60,
              child: Transform.rotate(
                angle: -0.5,
                child: const Icon(Icons.arrow_upward, color: Colors.white, size: 60),
              ),
            ),
            Positioned(
              top: 120,
              left: 80,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  isChinese ? "意义盒子在这里" : "Meaning Box here",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ),

            // 3. 指向底部的箭头 (示意刚刚生成的卡片)
            Positioned(
              bottom: 100,
              right: 60,
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 60),
            ),
             Positioned(
              bottom: 160,
              right: 80,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  isChinese ? "你的意义卡在这里" : "Your Meaning Card here",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

