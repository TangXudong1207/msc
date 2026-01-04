import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // Colors
    final paperColor = const Color(0xFFF4ECD8);
    final terracotta = const Color(0xFFBC5D48);

    return Scaffold(
      backgroundColor: paperColor,
      appBar: AppBar(
        backgroundColor: paperColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: terracotta),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          languageProvider.getText('设置', 'SETTINGS'),
          style: TextStyle(
            color: terracotta,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 1. About & Legal
          _buildSectionHeader(languageProvider.getText('关于', 'ABOUT')),
          _buildListTile(
            title: languageProvider.getText('版本', 'Version'),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          _buildListTile(
            title: languageProvider.getText('隐私政策', 'Privacy Policy'),
            onTap: () {
              // TODO: Open Privacy Policy URL
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy placeholder')),
              );
            },
          ),
          _buildListTile(
            title: languageProvider.getText('服务条款', 'Terms of Service'),
            onTap: () {
              // TODO: Open ToS URL
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of Service placeholder')),
              );
            },
          ),

          const SizedBox(height: 40),

          // 2. Danger Zone
          _buildSectionHeader(languageProvider.getText('危险区域', 'DANGER ZONE'), color: Colors.red),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(
                languageProvider.getText('注销账号', 'Delete Account'),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                languageProvider.getText(
                  '此操作不可撤销，所有数据将被永久删除。',
                  'This action cannot be undone. All data will be permanently deleted.',
                ),
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
              onTap: () => _showDeleteConfirmation(context, authProvider, languageProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: color ?? const Color(0xFF6B8E23), // Ivy Green default
        ),
      ),
    );
  }

  Widget _buildListTile({required String title, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Georgia',
            color: Color(0xFF2C2C2C),
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AuthProvider authProvider, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF4ECD8),
        title: Text(languageProvider.getText('确认注销?', 'Delete Account?')),
        content: Text(languageProvider.getText(
          '您的所有聊天记录、意义卡片和好友关系将被永久删除。',
          'All your chat history, meaning cards, and friendships will be permanently deleted.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.getText('取消', 'Cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await authProvider.deleteAccount();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst); // Go to login
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(languageProvider.getText('确认删除', 'Delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
