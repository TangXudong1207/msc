import 'package:supabase_flutter/supabase_flutter.dart'; // Added Supabase
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';
import '../utils/soul_calculator.dart';
import '../models/meaning_spectrum.dart';
import '../services/friend_match_service.dart';
import '../widgets/radar_chart.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController(); // Added
  bool _isSearching = false; // Added
  
  // Radar Scan State
  bool _isScanning = false;
  List<MatchedProfile> _similarMatches = [];
  List<MatchedProfile> _complementaryMatches = [];
  
  // Animation for radar scan
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Load friend requests on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadFriendRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scanController.dispose();
    _searchController.dispose(); // Added
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    final languageProvider = context.read<LanguageProvider>();
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    try {
      // Search by ID or Email (exact match for privacy)
      // Note: Searching by email requires RLS policy to allow reading other profiles
      // Assuming 'profiles' table is public read or we use a specific RPC function.
      // For now, we'll try to find by ID first.
      
      Map<String, dynamic>? userData;
      
      // 1. Try ID
      final resId = await supabase
          .from('profiles')
          .select()
          .eq('id', query)
          .maybeSingle();
      
      if (resId != null) {
        userData = resId;
      } else {
        // 2. Try Email (if your profiles table has email column and it's queryable)
        // If email is not in profiles, we can't search by it easily without an Edge Function.
        // Let's assume we only search by ID for now to be safe, or nickname?
        // Let's try nickname as a fallback.
        final resName = await supabase
            .from('profiles')
            .select()
            .eq('nickname', query)
            .limit(1)
            .maybeSingle();
            
        if (resName != null) userData = resName;
      }

      if (!mounted) return;
      setState(() => _isSearching = false);

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.getText('未找到用户', 'User not found'))),
        );
        return;
      }

      if (userData['id'] == currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.getText('不能添加自己', 'Cannot add yourself'))),
        );
        return;
      }

      // Show User Found Dialog
      _showUserFoundDialog(userData);

    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showUserFoundDialog(Map<String, dynamic> user) {
    final languageProvider = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('找到用户', 'User Found')),
        content: ListTile(
          leading: CircleAvatar(
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null ? Text(user['nickname']?[0] ?? '?') : null,
          ),
          title: Text(user['nickname'] ?? 'Unknown'),
          subtitle: Text('ID: ${user['id']}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.getText('取消', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<ChatProvider>().sendFriendRequest(user['id']);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(languageProvider.getText('已发送请求', 'Request Sent'))),
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
            child: Text(languageProvider.getText('添加好友', 'Add Friend')),
          ),
        ],
      ),
    );
  }

  void _startScan() async {
    final chatProvider = context.read<ChatProvider>();
    final languageProvider = context.read<LanguageProvider>();
    
    // 1. 检查解锁条件 (10张意义卡)
    if (chatProvider.allMeaningCards.length < 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getText(
            '灵魂共鸣需要更多数据。请先解锁 10 张意义卡 (当前: ${chatProvider.allMeaningCards.length})',
            'Soul resonance requires more data. Unlock 10 Meaning Cards first (Current: ${chatProvider.allMeaningCards.length})'
          )),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _similarMatches = [];
      _complementaryMatches = [];
    });

    // Simulate network delay (TODO: Replace with real DB query)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Get current user profile
    final myScores = SoulCalculator.calculateScores(chatProvider.allMeaningCards);
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) return;

    try {
      // 2. Fetch real profiles from DB
      final response = await supabase
          .from('profiles')
          .select()
          .neq('id', currentUserId) // Exclude self
          .limit(50); // Limit for performance

      final List<MatchedProfile> candidates = [];

      for (var row in response) {
        // Parse scores from DB columns
        final Map<MeaningDimension, double> scores = {};
        scores[MeaningDimension.agency] = (row['score_agency'] ?? 0).toDouble();
        scores[MeaningDimension.coherence] = (row['score_coherence'] ?? 0).toDouble();
        scores[MeaningDimension.curiosity] = (row['score_curiosity'] ?? 0).toDouble();
        scores[MeaningDimension.transcendence] = (row['score_transcendence'] ?? 0).toDouble();
        scores[MeaningDimension.care] = (row['score_care'] ?? 0).toDouble();
        scores[MeaningDimension.reflection] = (row['score_reflection'] ?? 0).toDouble();
        scores[MeaningDimension.aesthetic] = (row['score_aesthetic'] ?? 0).toDouble();

        // Calculate similarity
        final similarity = FriendMatchService.calculateSimilarity(myScores, scores);

        candidates.add(MatchedProfile(
          id: row['id'],
          name: row['nickname'] ?? 'Unknown Soul',
          avatarUrl: row['avatar_url'] ?? '',
          scores: scores,
          similarity: similarity,
        ));
      }

      // Sort by similarity
      candidates.sort((a, b) => b.similarity.compareTo(a.similarity));

      setState(() {
        _isScanning = false;
        // Top 5 similar
        _similarMatches = candidates.take(5).toList();
        // Top 5 complementary (lowest similarity, i.e., closest to -1)
        // We reverse the list to get the smallest similarity values
        _complementaryMatches = candidates.reversed.take(5).toList();
      });
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getText('添加好友', 'Add Friend')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: languageProvider.getText('ID 查找', 'Find by ID')),
            Tab(text: languageProvider.getText('灵魂雷达', 'Soul Radar')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIdSearchTab(),
          _buildRadarTab(),
        ],
      ),
    );
  }

  Widget _buildIdSearchTab() {
    final languageProvider = context.watch<LanguageProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final requests = chatProvider.friendRequests;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Friend Requests Section ===
          if (requests.isNotEmpty) ...[
            Text(
              languageProvider.getText('好友请求', 'Friend Requests'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: req.sender.avatarUrl != null && req.sender.avatarUrl!.isNotEmpty
                          ? NetworkImage(req.sender.avatarUrl!)
                          : null,
                      child: req.sender.avatarUrl == null || req.sender.avatarUrl!.isEmpty
                          ? Text(req.sender.nickname?[0] ?? '?')
                          : null,
                    ),
                    title: Text(req.sender.nickname ?? 'Unknown'),
                    subtitle: Text(languageProvider.getText('请求添加好友', 'Wants to be your friend')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await context.read<ChatProvider>().acceptFriendRequest(req.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(languageProvider.getText('已接受', 'Accepted'))),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await context.read<ChatProvider>().rejectFriendRequest(req.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(languageProvider.getText('已拒绝', 'Rejected'))),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 30),
          ],

          // === Search Section ===
          TextField(
            controller: _searchController, // Added controller
            decoration: InputDecoration(
              labelText: languageProvider.getText('输入好友 ID 或昵称', 'Enter Friend ID or Nickname'), // Changed label
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _isSearching 
                ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _searchUser, // Connected function
                  ),
            ),
            onSubmitted: (_) => _searchUser(), // Allow enter key
          ),
          const SizedBox(height: 20),
          Text(
            languageProvider.getText('可以通过对方的个人资料页查看 ID', 'You can find ID on their profile page'),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarTab() {
    final chatProvider = context.watch<ChatProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final myScores = SoulCalculator.calculateScores(chatProvider.allMeaningCards);
    
    // Calculate max value for radar chart
    double maxValue = 0.0;
    myScores.forEach((k, v) { if (v > maxValue) maxValue = v; });
    if (maxValue < 5.0) maxValue = 5.0; // Minimum scale

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Radar Area
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Chart
                RadarChartWidget(
                  data: myScores,
                  maxValue: maxValue,
                ),
                // Scanning Overlay
                if (_isScanning)
                  RotationTransition(
                    turns: _scanController,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.blue.withValues(alpha: 0.0),
                            Colors.blue.withValues(alpha: 0.2),
                            Colors.blue.withValues(alpha: 0.5),
                          ],
                          stops: const [0.5, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                // Scan Button (only visible when not scanning and no results yet)
                if (!_isScanning && _similarMatches.isEmpty)
                  ElevatedButton.icon(
                    onPressed: _startScan,
                    icon: const Icon(Icons.radar),
                    label: Text(languageProvider.getText('开始灵魂扫描', 'Start Soul Scan')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
              ],
            ),
          ),
          
          if (_isScanning)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(languageProvider.getText('正在寻找共鸣信号...', 'Searching for resonance signals...'), style: const TextStyle(color: Colors.grey)),
            ),

          if (!_isScanning && _similarMatches.isNotEmpty) ...[
            const Divider(),
            _buildMatchSection(languageProvider.getText('共鸣之魂 (相似)', 'Resonant Souls (Similar)'), _similarMatches, true, myScores, maxValue),
            const Divider(),
            _buildMatchSection(languageProvider.getText('互补之影 (互补)', 'Complementary Shadows (Complementary)'), _complementaryMatches, false, myScores, maxValue),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _startScan,
              child: Text(languageProvider.getText('重新扫描', 'Rescan')),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchSection(
    String title, 
    List<MatchedProfile> matches, 
    bool isSimilar,
    Map<MeaningDimension, double> myScores,
    double maxValue,
  ) {
    final languageProvider = context.read<LanguageProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final percentage = isSimilar 
                ? match.similarityPercentage 
                : match.complementaryPercentage;
            
            return ListTile(
              leading: CircleAvatar(child: Text(match.avatarUrl)),
              title: Text(match.name),
              subtitle: Text('${languageProvider.getText('匹配度', 'Match')}: $percentage%'),
              trailing: IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () async {
                  try {
                    await context.read<ChatProvider>().sendFriendRequest(match.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(languageProvider.getText('已发送好友请求给 ${match.name}', 'Friend request sent to ${match.name}'))),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(languageProvider.getText('发送失败: $e', 'Failed to send: $e'))),
                      );
                    }
                  }
                },
              ),
              onTap: () {
                _showComparisonDialog(context, match, myScores, maxValue);
              },
            );
          },
        ),
      ],
    );
  }

  void _showComparisonDialog(
    BuildContext context, 
    MatchedProfile match,
    Map<MeaningDimension, double> myScores,
    double maxValue,
  ) {
    final languageProvider = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.getText('与 ${match.name} 的共鸣', 'Resonance with ${match.name}')),
        content: SizedBox(
          width: 300,
          height: 350,
          child: Column(
            children: [
              Expanded(
                child: RadarChartWidget(
                  data: myScores,
                  comparisonData: match.scores,
                  maxValue: maxValue,
                  primaryColor: Colors.blue,
                  comparisonColor: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(languageProvider.getText('我', 'Me'), Colors.blue),
                  const SizedBox(width: 20),
                  _buildLegendItem(match.name, Colors.red),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.getText('关闭', 'Close')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<ChatProvider>().sendFriendRequest(match.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(languageProvider.getText('已发送好友请求给 ${match.name}', 'Friend request sent to ${match.name}'))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(languageProvider.getText('发送失败: $e', 'Failed to send: $e'))),
                  );
                }
              }
            },
            child: Text(languageProvider.getText('添加好友', 'Add Friend')),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
