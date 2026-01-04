import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add HapticFeedback
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';
import '../models/meaning_card.dart';
import '../models/meaning_spectrum.dart';

class MeaningBoxScreen extends StatelessWidget {
  const MeaningBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取所有意义卡 (包括主对话和好友对话)
    final allCards = context.watch<ChatProvider>().allMeaningCards;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getText('意义盒子', 'Meaning Box'), style: const TextStyle(color: Colors.brown)),
        backgroundColor: Colors.amber[100],
        iconTheme: const IconThemeData(color: Colors.brown),
        elevation: 0,
      ),
      backgroundColor: Colors.amber[50],
      body: allCards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.amber[200]),
                  const SizedBox(height: 16),
                  Text(
                    languageProvider.getText(
                      '还没有收集到意义卡片\n多聊聊，让意义自然浮现...',
                      'No meaning cards collected yet\nChat more to let meaning emerge...',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.brown[300]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              // 反序显示，最新的在最上面
              itemCount: allCards.length,
              itemBuilder: (context, index) {
                final card = allCards[allCards.length - 1 - index];
                return _buildMeaningCardItem(context, card);
              },
            ),
    );
  }

  Widget _buildMeaningCardItem(BuildContext context, MeaningCard card) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick(); // Add haptic feedback
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 20, color: Colors.amber[800]),
                  const SizedBox(width: 8),
                  Text(
                    card.spectrum.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                  const Spacer(),
                  // 如果需要显示时间，MeaningCard 目前没有时间字段，暂时忽略
                ],
              ),
              const Divider(height: 24),
              Text(
                card.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 12),
              // 进度条展示分数
              Row(
                children: [
                  Text(
                    "${context.read<LanguageProvider>().getText('深度', 'Depth')}: ${(card.score * 100).toStringAsFixed(0)}%",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: card.score,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[300]!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
