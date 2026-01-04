import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // 切换登录/注册模式
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final rawUsername = _usernameController.text.trim();
    // 自动补充后缀，伪装成邮箱，实现"用户名"登录体验
    final email = rawUsername.contains('@')
        ? rawUsername
        : '$rawUsername@msc.app';
    final password = _passwordController.text;

    try {
      if (_isLogin) {
        await authProvider.login(email, password);
      } else {
        await authProvider.register(email, password);
      }
    } catch (e) {
      if (mounted) {
        // 提取更友好的错误信息
        String msg = e.toString();
        if (msg.contains('Invalid login credentials')) {
          msg = '用户名或密码错误';
        } else if (msg.contains('User already registered')) {
          msg = '该用户名已被注册';
        } else if (msg.contains('rate_limit')) {
          msg = '操作太频繁，请稍后再试';
        } else if (msg.contains('AuthException')) {
          // 尝试提取 message 字段
          final match = RegExp(r'message: (.*?),').firstMatch(msg);
          if (match != null) {
            msg = match.group(1) ?? msg;
          }
        }
        setState(() => _errorMessage = msg);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    // Antique Paper Color
    final paperColor = const Color(0xFFF4ECD8); 
    // Ancient Watercolor Green
    final ivyGreen = const Color(0xFF6B8E23); 
    // Terracotta
    final terracotta = const Color(0xFFBC5D48);
    
    final inputFillColor = const Color(0xFFE8E0D5).withValues(alpha: 0.5); 

    return Scaffold(
      backgroundColor: paperColor,
      body: Stack(
        children: [
          // 1. Background Texture & Ivy Decoration (Simulated)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: paperColor,
                // If you have the actual image, uncomment below:
                // image: const DecorationImage(
                //   image: AssetImage('assets/images/login_bg.jpg'), 
                //   fit: BoxFit.cover,
                //   opacity: 0.8, 
                // ),
              ),
            ),
          ),
          // Simulated Ivy Decor (Top Left)
          Positioned(
            top: -20,
            left: -20,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(Icons.eco, size: 150, color: ivyGreen.withValues(alpha: 0.2)),
            ),
          ),
          // Simulated Ivy Decor (Bottom Right)
          Positioned(
            bottom: -20,
            right: -20,
            child: Transform.rotate(
              angle: -0.5,
              child: Icon(Icons.local_florist, size: 180, color: ivyGreen.withValues(alpha: 0.15)),
            ),
          ),
          
          // 2. Content Layer
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title Section
                  const Text(
                    'MSC',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6.0,
                      color: Color(0xFF2C2C2C), // Ink Black
                      fontFamily: 'Georgia', 
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    languageProvider.getText('意义 · 结构 · 关怀', 'MEANING · STRUCTURE · CARE'),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 3.0,
                      fontWeight: FontWeight.w600,
                      color: ivyGreen, // Use Ivy Green for subtitle
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Login Card
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7).withValues(alpha: 0.9), // Lighter paper
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: ivyGreen.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3E2723).withValues(alpha: 0.08), // Brownish shadow
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tabs (Login / Sign Up)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTabButton(languageProvider.getText('登录', 'LOGIN'), _isLogin, terracotta),
                                const SizedBox(width: 24),
                                _buildTabButton(languageProvider.getText('注册', 'SIGN UP'), !_isLogin, terracotta),
                              ],
                            ),
                            const SizedBox(height: 36),

                            // Username Input
                            _buildInput(
                              controller: _usernameController,
                              hint: languageProvider.getText('用户名', 'Username'),
                              fillColor: inputFillColor,
                              activeColor: terracotta,
                            ),
                            const SizedBox(height: 20),

                            // Password Input
                            _buildInput(
                              controller: _passwordController,
                              hint: languageProvider.getText('密码', 'Password'),
                              isPassword: true,
                              fillColor: inputFillColor,
                              activeColor: terracotta,
                            ),

                            // Error Message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Georgia'),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: 36),

                            // Action Button
                            if (_isLoading)
                              CircularProgressIndicator(color: terracotta)
                            else
                              TextButton(
                                onPressed: _submit,
                                style: TextButton.styleFrom(
                                  foregroundColor: terracotta,
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                                child: Text(languageProvider.getText('连接上行链路', 'CONNECT UPLINK')),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Language Selector
                  GestureDetector(
                    onTap: () => languageProvider.toggleLanguage(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: ivyGreen.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '中文',
                            style: TextStyle(
                              color: languageProvider.isChinese ? terracotta : Colors.grey[600],
                              fontWeight: languageProvider.isChinese ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'Georgia',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'English',
                            style: TextStyle(
                              color: !languageProvider.isChinese ? terracotta : Colors.grey[600],
                              fontWeight: !languageProvider.isChinese ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ],
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

  Widget _buildTabButton(String text, bool isActive, Color activeColor) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          setState(() {
            _isLogin = !_isLogin;
            _errorMessage = null;
            _formKey.currentState?.reset();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: isActive 
            ? Border(bottom: BorderSide(color: activeColor, width: 2))
            : null,
        ),
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeColor : Colors.grey[500],
            letterSpacing: 1.2,
            fontFamily: 'Georgia',
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    required Color fillColor,
    required Color activeColor,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(fontSize: 14, fontFamily: 'Georgia', color: Color(0xFF4A4A4A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14, fontFamily: 'Georgia'),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activeColor.withValues(alpha: 0.5), width: 1),
        ),
        suffixIcon: isPassword
            ? Icon(Icons.visibility_outlined, size: 18, color: Colors.grey[500])
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '';
        if (isPassword && value.length < 6) return 'Too short';
        return null;
      },
    );
  }
}
