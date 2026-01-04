import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'settings_screen.dart'; // Add import

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final userProfile = context.read<AuthProvider>().userProfile;
    _nicknameController = TextEditingController(text: userProfile?.nickname ?? '');
    _bioController = TextEditingController(text: userProfile?.bio ?? '');
    _avatarUrlController = TextEditingController(text: userProfile?.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final languageProvider = context.read<LanguageProvider>();
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<AuthProvider>().updateProfile(
          nickname: _nicknameController.text,
          bio: _bioController.text,
          avatarUrl: _avatarUrlController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(languageProvider.getText('个人资料更新成功', 'Profile updated successfully'))),
          );
          setState(() {
            _isEditing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(languageProvider.getText('更新失败: $e', 'Failed to update profile: $e'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<AuthProvider>().userProfile;
    final languageProvider = context.watch<LanguageProvider>();
    final paperColor = const Color(0xFFF4ECD8);
    final terracotta = const Color(0xFFBC5D48);
    final ivyGreen = const Color(0xFF6B8E23);

    return Scaffold(
      backgroundColor: paperColor,
      appBar: AppBar(
        backgroundColor: paperColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: terracotta),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () {
            // Secret door to admin panel (Triple tap)
            // We use a simple counter reset by time
          },
          onDoubleTap: () {}, // Consume double tap
          onLongPress: () {
             Navigator.pushNamed(context, '/admin');
          },
          child: Text(
            languageProvider.getText('个人资料', 'USER PROFILE'),
            style: TextStyle(
              color: terracotta,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: ivyGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: ivyGreen),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: _isEditing ? () {
                  // Optional: Implement image picker
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: terracotta, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: terracotta.withValues(alpha: 0.1),
                    backgroundImage: (userProfile?.avatarUrl != null && userProfile!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(userProfile.avatarUrl!)
                        : null,
                    child: (userProfile?.avatarUrl == null || userProfile!.avatarUrl!.isEmpty)
                        ? Text(
                            (userProfile?.email.isNotEmpty == true)
                                ? userProfile!.email[0].toUpperCase()
                                : "U",
                            style: TextStyle(
                              fontSize: 40.0,
                              color: terracotta,
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Email (Read-only)
              _buildTextField(
                label: 'EMAIL',
                initialValue: userProfile?.email,
                readOnly: true,
                terracotta: terracotta,
              ),
              const SizedBox(height: 24),

              // Nickname
              _buildTextField(
                label: 'NICKNAME',
                controller: _nicknameController,
                readOnly: !_isEditing,
                terracotta: terracotta,
              ),
              const SizedBox(height: 24),

              // Bio
              _buildTextField(
                label: 'BIO',
                controller: _bioController,
                readOnly: !_isEditing,
                terracotta: terracotta,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Avatar URL (Editable)
              if (_isEditing)
                _buildTextField(
                  label: 'AVATAR URL',
                  controller: _avatarUrlController,
                  readOnly: false,
                  terracotta: terracotta,
                  hintText: 'https://example.com/avatar.png',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    TextEditingController? controller,
    required bool readOnly,
    required Color terracotta,
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: terracotta,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 16,
            color: Color(0xFF2C2C2C),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: readOnly ? Colors.transparent : Colors.white.withValues(alpha: 0.5),
            border: readOnly
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: terracotta.withValues(alpha: 0.3)),
                  ),
            enabledBorder: readOnly
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: terracotta.withValues(alpha: 0.3)),
                  ),
            focusedBorder: readOnly
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: terracotta),
                  ),
            contentPadding: readOnly
                ? const EdgeInsets.symmetric(vertical: 8)
                : const EdgeInsets.all(16),
          ),
        ),
        if (readOnly)
          Divider(color: terracotta.withValues(alpha: 0.2)),
      ],
    );
  }
}
