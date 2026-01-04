import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add HapticFeedback
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';
import '../models/user_profile.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/soul_orb.dart';
import '../utils/soul_calculator.dart';
import '../screens/meaning_box_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/friends_list_screen.dart';
import '../screens/world_screen.dart';
import '../screens/chat_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = context.select<AuthProvider, UserProfile?>((p) => p.userProfile);
    final userEmail = userProfile?.email ?? context.select<AuthProvider, String?>((p) => p.currentUser);
    final displayName = (userProfile?.nickname?.isNotEmpty ?? false) 
        ? userProfile!.nickname! 
        : (userEmail ?? "Guest");
    final avatarUrl = userProfile?.avatarUrl;
    final languageProvider = context.watch<LanguageProvider>();
    
    // Style Constants
    final paperColor = const Color(0xFFF4ECD8); 
    final ivyGreen = const Color(0xFF6B8E23); 
    final terracotta = const Color(0xFFBC5D48);
    final inkBlack = const Color(0xFF2C2C2C);

    return Drawer(
      backgroundColor: paperColor,
      child: Stack(
        children: [
          // 1. Background Decoration (Ivy)
          Positioned(
            top: -30,
            right: -30,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.eco, size: 200, color: ivyGreen),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -20,
            child: Transform.rotate(
              angle: 0.3,
              child: Opacity(
                opacity: 0.08,
                child: Icon(Icons.local_florist, size: 150, color: ivyGreen),
              ),
            ),
          ),

          // 2. Content
          Column(
            children: [
              // Custom Header
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: ivyGreen.withValues(alpha: 0.15))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: terracotta, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: terracotta.withValues(alpha: 0.1),
                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? Text(
                                  (userEmail != null && userEmail.isNotEmpty)
                                      ? userEmail[0].toUpperCase()
                                      : "U",
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    color: terracotta,
                                    fontFamily: 'Georgia',
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageProvider.getText("当前用户", "CURRENT USER"),
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: ivyGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.bold,
                                color: inkBlack,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (userProfile?.nickname != null && userProfile!.nickname!.isNotEmpty)
                              Text(
                                userEmail ?? "",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: inkBlack.withValues(alpha: 0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit, size: 16, color: ivyGreen.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // 1. Meaning Box
                      _buildMenuItem(
                        context,
                        icon: Icons.inbox_outlined, // Linear style
                        title: languageProvider.getText('意义盒子', 'MEANING BOX'),
                        subtitle: languageProvider.getText('收集的意义卡片', 'Collected Meaning Cards'),
                        color: terracotta,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MeaningBoxScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // 2. Soul Form
                      Consumer<ChatProvider>(
                        builder: (context, chatProvider, child) {
                          final dimensionScores = SoulCalculator.calculateScores(chatProvider.allMeaningCards);

                          double maxValue = 0.0;
                          dimensionScores.forEach((key, value) {
                            if (value > maxValue) maxValue = value;
                          });
                          if (maxValue < 0.5) maxValue = 0.5;

                          return Column(
                            children: [
                              Text(
                                languageProvider.getText("灵魂形态", "SOUL FORM"),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ivyGreen,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A), 
                                  borderRadius: BorderRadius.circular(1000), 
                                  border: Border.all(color: terracotta.withValues(alpha: 0.3), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: terracotta.withValues(alpha: 0.15),
                                      blurRadius: 25,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1000),
                                  child: Center(
                                    child: SoulOrbWidget(
                                      data: dimensionScores,
                                      maxValue: maxValue,
                                      width: 220,
                                      height: 220,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // 3. Dimension Analysis
                      _buildMenuItem(
                        context,
                        icon: Icons.radar_outlined,
                        title: languageProvider.getText('维度分析', 'DIMENSIONS'),
                        subtitle: languageProvider.getText('灵魂维度雷达图', 'Soul Dimension Radar'),
                        color: terracotta,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AnalysisScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // 4. Compact Group
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: ivyGreen.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: ivyGreen.withValues(alpha: 0.05),
                        ),
                        child: Column(
                          children: [
                            _buildCompactMenuItem(
                              context,
                              icon: Icons.chat_bubble_outline,
                              title: languageProvider.getText('AI 对话', 'AI CHAT'),
                              color: terracotta,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                                );
                              },
                            ),
                            Divider(height: 1, color: ivyGreen.withValues(alpha: 0.15)),
                            _buildCompactMenuItem(
                              context,
                              icon: Icons.people_outline,
                              title: languageProvider.getText('好友列表', 'FRIENDS'),
                              color: terracotta,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const FriendsListScreen()),
                                );
                              },
                            ),
                            Divider(height: 1, color: ivyGreen.withValues(alpha: 0.15)),
                            _buildCompactMenuItem(
                              context,
                              icon: Icons.public_outlined,
                              title: languageProvider.getText('世界地图', 'WORLD MAP'),
                              color: terracotta,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const WorldScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.only(bottom: 32, left: 16, top: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.logout_outlined, color: terracotta, size: 20),
                      title: Text(
                        languageProvider.getText('断开连接', 'DISCONNECT'), 
                        style: TextStyle(
                          color: terracotta, 
                          fontSize: 12, 
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        )
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<AuthProvider>().logout();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.language, color: terracotta, size: 20),
                      title: Text(
                        languageProvider.getText('语言 / LANGUAGE', 'LANGUAGE / 语言'),
                        style: TextStyle(
                          color: terracotta, 
                          fontSize: 12, 
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Georgia',
                        )
                      ),
                      onTap: () {
                        languageProvider.toggleLanguage();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: color, size: 24), // Terracotta linear icons
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Color(0xFF2C2C2C),
          fontFamily: 'Georgia',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
          fontFamily: 'Georgia',
        ),
      ),
      onTap: () {
        HapticFeedback.selectionClick(); // Add haptic feedback
        onTap();
      },
    );
  }

  Widget _buildCompactMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Color(0xFF2C2C2C),
          fontFamily: 'Georgia',
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 16, color: color.withValues(alpha: 0.5)),
      onTap: () {
        HapticFeedback.selectionClick(); // Add haptic feedback
        onTap();
      },
    );
  }
}
