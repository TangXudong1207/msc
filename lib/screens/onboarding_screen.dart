import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Colors
  final paperColor = const Color(0xFFF4ECD8);
  final ivyGreen = const Color(0xFF6B8E23);
  final terracotta = const Color(0xFFBC5D48);
  final inkBlack = const Color(0xFF2C2C2C);

  final List<Map<String, dynamic>> _pages = [
    {
      "zh_title": "这里是",
      "zh_lines": [
        "深夜还亮着灯的",
        "图书馆一角",
        "",
        "不吵闹",
        "但有人低声交谈的酒吧",
        "",
        "一个人可以说话的空间"
      ],
      "en_title": "THIS IS",
      "en_lines": [
        "A corner of the library",
        "where lights stay on late",
        "",
        "A bar not noisy",
        "but with quiet whispers",
        "",
        "A space to speak alone"
      ],
      "zh_btn": "进入",
      "en_btn": "ENTER",
    },
    {
      "zh_title": "这里的人",
      "zh_lines": [
        "不成熟的思想司空见惯",
        "对的表达凤毛麟角",
        "没想清楚的问题比比皆是",
        "",
        "你不用急着成为前者",
        "也不用害怕自己属于后者"
      ],
      "en_title": "PEOPLE HERE",
      "en_lines": [
        "Immature thoughts are common",
        "Correct expressions are rare",
        "Unclear questions abound",
        "",
        "No rush to be the former",
        "No fear to be the latter"
      ],
      "zh_btn": "明白了",
      "en_btn": "UNDERSTOOD",
    },
    {
      "zh_title": "这里你会",
      "zh_lines": [
        "慢慢看到世界",
        "",
        "慢慢拥有思想上的",
        "真挚朋友",
        "或一生宿敌"
      ],
      "en_title": "HERE YOU WILL",
      "en_lines": [
        "Slowly see the world",
        "",
        "Slowly find intellectual",
        "sincere friends",
        "or lifelong rivals"
      ],
      "zh_btn": "开始旅程",
      "en_btn": "START JOURNEY",
    },
  ];


  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (mounted) {
      // Update AuthProvider state if necessary, or just navigate
      // Since AuthWrapper might be watching a value, we might need to update provider
      // But for now, let's just pushReplacement to ChatScreen
      // Ideally, we should update a state in AuthProvider so AuthWrapper rebuilds correctly
      // But direct navigation works too if we are already authenticated.
      
      // However, if we use AuthWrapper, we should update the provider.
      context.read<AuthProvider>().completeOnboarding();
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isChinese = languageProvider.isChinese;

    return Scaffold(
      backgroundColor: paperColor,
      body: Stack(
        children: [
          // Background Decoration
          Positioned(
            top: -50,
            right: -50,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.auto_stories, size: 300, color: ivyGreen),
            ),
          ),
          
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              final title = isChinese ? page["zh_title"] : page["en_title"];
              final lines = isChinese ? page["zh_lines"] as List<String> : page["en_lines"] as List<String>;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (Same style as body)
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: terracotta,
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24), // Spacing between title and lines
                    
                    // Lines
                    ...lines.map((line) {
                      if (line.isEmpty) {
                        return const SizedBox(height: 24);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.6,
                            color: terracotta,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page Indicators (Minimalist dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 6,
                      width: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? terracotta : Colors.transparent,
                        border: Border.all(color: terracotta, width: 1),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 48),
                
                // Action Button (Minimalist text button)
                TextButton(
                  onPressed: _nextPage,
                  style: TextButton.styleFrom(
                    foregroundColor: terracotta,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isChinese 
                            ? _pages[_currentPage]["zh_btn"] 
                            : _pages[_currentPage]["en_btn"],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Language Switcher (Optional, but good for onboarding)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.language, color: terracotta.withValues(alpha: 0.6)),
              onPressed: () {
                languageProvider.toggleLanguage();
              },
            ),
          ),
        ],
      ),
    );
  }
}
