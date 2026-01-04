import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_globe.dart';
import '../services/world_service.dart';
import '../models/world_meaning.dart';
import '../providers/language_provider.dart';
import '../providers/chat_provider.dart';

class WorldScreen extends StatefulWidget {
  static const routeName = '/world';

  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  final WorldService _worldService = WorldService();
  List<WorldMeaning> _meanings = [];
  bool _isLoading = true;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    final chatProvider = context.read<ChatProvider>();
    
    // 1. Check Unlock Condition (5 cards)
    if (chatProvider.allMeaningCards.length < 5) {
      setState(() {
        _isLocked = true;
        _isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLockDialog();
      });
      return;
    }

    // 2. Load Data
    _loadData();
  }

  void _showLockDialog() {
    final languageProvider = context.read<LanguageProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(languageProvider.getText('未解锁', 'LOCKED'), style: const TextStyle(color: Colors.cyan)),
        content: Text(
          languageProvider.getText(
            '你需要先探索自己的内心（解锁 5 张意义卡），才能看到世界的全貌。',
            'You need to explore your own heart first (Unlock 5 Meaning Cards) to see the whole world.'
          ),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: Text(languageProvider.getText('返回', 'BACK'), style: const TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final data = await _worldService.fetchWorldMeanings();
      if (mounted) {
        setState(() {
          _meanings = data;
          _isLoading = false;
        });
        
        // Show Privacy Toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LanguageProvider>().getText(
              '位置已模糊处理至城市级别以保护隐私',
              'Locations are blurred to city level for privacy'
            )),
            backgroundColor: Colors.black54,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading world data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    
    if (_isLocked) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The Globe
          if (!_isLoading)
            Positioned.fill(
              child: CustomGlobe(meanings: _meanings),
            ),
            
          // Loading Indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.cyan)),

          // UI Overlay
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.cyan),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          Positioned(
            top: 40,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  languageProvider.getText('世界意义地图', 'WORLD MEANING MAP'),
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(color: Colors.cyan, blurRadius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Overlay
          Positioned(
            bottom: 40,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${languageProvider.getText('活跃卫星', 'ACTIVE SATELLITES')}: ${_meanings.where((m) => m.isSatellite).length}",
                  style: const TextStyle(color: Colors.white70, fontFamily: 'Courier', fontSize: 12),
                ),
                Text(
                  "${languageProvider.getText('地表节点', 'SURFACE NODES')}: ${_meanings.where((m) => m.isSurface).length}",
                  style: const TextStyle(color: Colors.white70, fontFamily: 'Courier', fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
