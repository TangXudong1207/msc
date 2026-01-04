import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // Added
import 'dart:convert'; 
import '../models/message.dart';
import '../models/meaning_card.dart'; 
import '../models/meaning_spectrum.dart'; 
import '../models/friend.dart'; 
import '../models/friend_request.dart'; 
import '../models/user_profile.dart'; 
import '../utils/soul_calculator.dart'; 
import '../services/deepseek_service.dart';
import '../services/vertex_service.dart';
import '../services/world_service.dart'; 
import '../services/notification_service.dart'; // Added

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final List<MeaningCard> _friendMeaningCards = []; // Store friend chat meaning cards
  final DeepSeekService _apiService = DeepSeekService();
  final VertexService _vertexService = VertexService(); // 新增
  final WorldService _worldService = WorldService(); // Added
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _jumpToMessageId; // 跳转目标 ID
  bool _shouldShowMeaningCardIntro = false; // 是否显示意义卡引导
  
  List<FriendRequest> _friendRequests = [];
  List<FriendRequest> get friendRequests => _friendRequests;

  List<Message> get messages => _messages;
  
  // Combine all meaning cards from main chat and friend chats
  List<MeaningCard> get allMeaningCards {
    final mainChatCards = _messages
        .map((m) => m.meaningCard)
        .whereType<MeaningCard>()
        .toList();
    return [...mainChatCards, ..._friendMeaningCards];
  }

  bool get isLoading => _isLoading;
  String? get jumpToMessageId => _jumpToMessageId;
  bool get shouldShowMeaningCardIntro => _shouldShowMeaningCardIntro;

  // Admin / Config
  double _meaningCardThreshold = 0.4;
  double get meaningCardThreshold => _meaningCardThreshold;

  Future<void> loadSystemConfig() async {
    try {
      final response = await _supabase
          .from('system_config')
          .select('value')
          .eq('key', 'meaning_card_threshold')
          .maybeSingle();
      
      if (response != null) {
        _meaningCardThreshold = double.tryParse(response['value']) ?? 0.4;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading system config: $e');
    }
  }

  Future<void> setMeaningCardThreshold(double value) async {
    _meaningCardThreshold = value;
    notifyListeners();
    
    // Persist to DB
    try {
      await _supabase.from('system_config').upsert({
        'key': 'meaning_card_threshold',
        'value': value.toString(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving threshold: $e');
    }
  }

  void markMeaningCardIntroSeen() async {
    _shouldShowMeaningCardIntro = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_meaning_card_intro', true);
    notifyListeners();
  }

  // Friend Management
  // final List<Friend> _friends = List.from(mockFriends); // Mutable copy
  final List<Friend> _friends = []; // Real friends list (initially empty)

  List<Friend> get friends {
    // Sort by last message time descending
    _friends.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return _friends;
  }
  
  List<Friend> get contacts {
    // Sort by name
    final list = List<Friend>.from(_friends);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  // === 新增：发送好友请求 ===
  Future<void> sendFriendRequest(String friendId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('friendships').insert({
        'user_id': userId,
        'friend_id': friendId,
        'status': 'pending',
      });
    } catch (e) {
      // 如果是重复请求 (违反唯一约束)，Supabase 会报错
      if (e.toString().contains('duplicate key')) {
        throw '已发送过请求 (Request already sent)';
      }
      rethrow;
    }
  }

  // === 新增：加载好友请求 ===
  Future<void> loadFriendRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. 获取发给我的 pending 请求
      final response = await _supabase
          .from('friendships')
          .select()
          .eq('friend_id', userId)
          .eq('status', 'pending');

      final List<FriendRequest> requests = [];
      
      // 2. 获取发送者的资料
      for (var row in response) {
        final senderId = row['user_id'];
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', senderId)
            .maybeSingle();
            
        if (profileData != null) {
          final senderProfile = UserProfile.fromJson(profileData);
          requests.add(FriendRequest(
            id: row['id'],
            sender: senderProfile,
            createdAt: DateTime.parse(row['created_at']),
          ));
        }
      }
      
      _friendRequests = requests;
      notifyListeners();
    } catch (e) {
      debugPrint('加载好友请求失败: $e');
    }
  }

  // === 新增：接受好友请求 ===
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', requestId);
      
      // 重新加载请求和好友列表
      await loadFriendRequests();
      await loadFriends();
    } catch (e) {
      debugPrint('接受好友请求失败: $e');
      rethrow;
    }
  }

  // === 新增：拒绝好友请求 ===
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'rejected'})
          .eq('id', requestId);
      
      // 重新加载请求
      await loadFriendRequests();
    } catch (e) {
      debugPrint('拒绝好友请求失败: $e');
      rethrow;
    }
  }

  // === 新增：删除好友 ===
  Future<void> deleteFriend(String friendId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 删除双向关系中的任何一种情况
      await _supabase
          .from('friendships')
          .delete()
          .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');
      
      // 从本地列表中移除
      _friends.removeWhere((f) => f.id == friendId);
      notifyListeners();
    } catch (e) {
      debugPrint('删除好友失败: $e');
      rethrow;
    }
  }

  // === 新增：加载好友列表 ===
  Future<void> loadFriends() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. 获取所有 accepted 的关系 (我是发起方 OR 我是接收方)
      final response = await _supabase
          .from('friendships')
          .select()
          .or('user_id.eq.$userId,friend_id.eq.$userId')
          .eq('status', 'accepted');

      final List<Friend> loadedFriends = [];

      for (var row in response) {
        // 确定对方的 ID
        final String otherId = (row['user_id'] == userId) 
            ? row['friend_id'] 
            : row['user_id'];
            
        // 获取对方资料
        final profileData = await _supabase
            .from('profiles')
            .select()
            .eq('id', otherId)
            .maybeSingle();
            
        if (profileData != null) {
          final profile = UserProfile.fromJson(profileData);
          
          loadedFriends.add(Friend(
            id: profile.id,
            name: profile.nickname ?? 'Unknown',
            avatarUrl: profile.avatarUrl ?? '',
            lastMessage: 'New Friend', // 暂时为空，后续可从 chat_messages 加载最后一条
            lastMessageTime: DateTime.parse(row['created_at']), // 使用建立关系的时间作为初始时间
            unreadCount: 0,
          ));
        }
      }
      
      _friends.clear();
      _friends.addAll(loadedFriends);
      notifyListeners();
    } catch (e) {
      debugPrint('加载好友列表失败: $e');
    }
  }

  void sendFriendMessage(String friendId, String content) {
    final friendIndex = _friends.indexWhere((f) => f.id == friendId);
    if (friendIndex != -1) {
      final friend = _friends[friendIndex];
      final newMessage = Message(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );
      
      friend.messages.add(newMessage);
      friend.lastMessage = content;
      friend.lastMessageTime = newMessage.timestamp;
      
      notifyListeners();
    }
  }
  
  void receiveFriendMessage(String friendId, String content) {
     final friendIndex = _friends.indexWhere((f) => f.id == friendId);
    if (friendIndex != -1) {
      final friend = _friends[friendIndex];
      final newMessage = Message(
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      friend.messages.add(newMessage);
      friend.lastMessage = content;
      friend.lastMessageTime = newMessage.timestamp;
      friend.unreadCount++;
      
      notifyListeners();
    }
  }

  void setJumpToMessage(String id) {
    _jumpToMessageId = id;
    notifyListeners();
  }

  void clearJumpToMessage() {
    _jumpToMessageId = null;
    // 不调用 notifyListeners 以免触发不必要的重绘
  }

  // 加载历史消息
  Future<void> loadMessages() async {
    // Load config first
    loadSystemConfig();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      _messages.clear();
      for (var row in response) {
        MeaningCard? card;
        if (row['meaning_card'] != null) {
          try {
            // 尝试解析 JSON
            final jsonMap = jsonDecode(row['meaning_card']);
            card = MeaningCard.fromJson(jsonMap);
          } catch (e) {
            // 兼容旧数据（如果是纯文本）
            card = MeaningCard(content: row['meaning_card']);
          }
        }

        final typeStr = row['type'] as String? ?? 'text';
        final type = typeStr == 'image' ? MessageType.image : MessageType.text;

        _messages.add(
          Message(
            id: row['id'],
            content: row['content'],
            isUser: row['is_user'],
            timestamp: DateTime.parse(row['created_at']),
            meaningCard: card,
            type: type,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载消息失败: $e');
    }
  }

  // 发送图片
  Future<void> sendImage(XFile image) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.$fileExt';
      final filePath = '$userId/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage.from('chat_images').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final imageUrl = _supabase.storage.from('chat_images').getPublicUrl(filePath);

      // Add to local list
      final userMessage = Message(
        content: imageUrl,
        isUser: true,
        type: MessageType.image,
      );
      _messages.add(userMessage);
      notifyListeners();

      // Save to DB
      await _supabase.from('chat_messages').insert({
        'content': imageUrl,
        'is_user': true,
        'user_id': userId,
        'type': 'image',
      });

      // Simulate AI response
      _isLoading = true;
      notifyListeners();
      
      await Future.delayed(const Duration(seconds: 2));
      
      final aiMessage = Message(
        content: "I received your image. Visual analysis is coming soon!",
        isUser: false,
      );
      _messages.add(aiMessage);
      _isLoading = false;
      notifyListeners();

      // Trigger notification (for demo purposes, usually triggered by incoming message)
      NotificationService().showNotification('New Message', 'AI: I received your image.');

    } catch (e) {
      debugPrint('Error sending image: $e');
    }
  }

  // 发送消息
  Future<void> sendMessage(String content, {bool isChinese = true}) async {
    if (content.trim().isEmpty) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // 1. 添加用户消息 (本地 + 数据库)
    final userMessage = Message(content: content, isUser: true);
    _messages.add(userMessage);
    notifyListeners();

    try {
      // 先保存基本消息
      final response = await _supabase.from('chat_messages').insert({
        'content': content,
        'is_user': true,
        'user_id': userId,
      }).select();

      // 异步触发 Vertex AI 分析 (不阻塞聊天流程)
      _analyzeMeaning(userMessage, response.first['id'], isChinese: isChinese);
    } catch (e) {
      debugPrint('保存用户消息失败: $e');
    }

    // 2. 设置加载状态
    _isLoading = true;
    notifyListeners();

    try {
      // 3. 调用真实 API
      final systemPrompt = isChinese 
          ? 'You are a helpful AI assistant. Please reply in Chinese.' 
          : 'You are a helpful AI assistant. Please reply in English.';
      
      final aiResponse = await _apiService.sendMessage(content, systemPrompt: systemPrompt);

      final aiMessage = Message(content: aiResponse, isUser: false);
      _messages.add(aiMessage);

      // 4. 保存 AI 回复到数据库
      await _supabase.from('chat_messages').insert({
        'content': aiResponse,
        'is_user': false,
        'user_id': userId,
      });
    } catch (e) {
      _messages.add(Message(content: "Error: $e", isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 内部方法：调用 Vertex AI 分析意义
  Future<void> _analyzeMeaning(Message message, String dbMessageId, {bool isChinese = true}) async {
    try {
      // 获取最近的几条上下文 (例如最近 5 条)
      final contextHistory = _messages
          .where((m) => m != message) // 排除当前这条
          .take(5)
          .map((m) => "${m.isUser ? '用户' : 'AI'}: ${m.content}")
          .toList();

      final meaningJsonString = await _vertexService.analyzeMeaning(
        message.content,
        contextHistory,
        language: isChinese ? 'chinese' : 'english',
      );

      // 解析 JSON
      try {
        // 简单清洗数据，防止返回非 JSON 字符串
        if (!meaningJsonString.trim().startsWith('{')) {
          debugPrint('Vertex AI 返回了非 JSON 数据: $meaningJsonString');
          return;
        }

        final jsonMap = jsonDecode(meaningJsonString);
        
        // 检查 score 阈值 (例如 0.4)
        final double score = jsonMap['score'] is num ? (jsonMap['score'] as num).toDouble() : 0.0;
        final bool hasContent = jsonMap['content'] != null && jsonMap['content'].toString().isNotEmpty;
        
        // 获取动态阈值 (默认为 0.4)
        // TODO: 从 AdminProvider 或配置中获取
        final double threshold = _meaningCardThreshold;

        if (hasContent && score >= threshold) {
           final card = MeaningCard.fromJson(jsonMap);
           
           // 更新本地状态
           message.meaningCard = card;
           
           // 检查是否需要显示引导
           final prefs = await SharedPreferences.getInstance();
           final hasSeen = prefs.getBool('has_seen_meaning_card_intro') ?? false;
           if (!hasSeen) {
             _shouldShowMeaningCardIntro = true;
           }
           
           notifyListeners();

           // 更新数据库 (存储完整的 JSON，包含 score)
           await _supabase
               .from('chat_messages')
               .update({'meaning_card': jsonEncode(card.toJson())})
               .eq('id', dbMessageId);

           // === 新增：更新用户的灵魂光谱分数 ===
           _updateUserSoulProfile();

           // === 新增：自动发布到世界地图 (匿名) ===
           _worldService.publishMeaning(card);

        } else {
           debugPrint('未生成意义卡内容');
        }
      } catch (e) {
        debugPrint('解析意义卡 JSON 失败: $e');
      }

    } catch (e) {
      debugPrint('意义分析失败: $e');
    }
  }

  // Analyze a message from Friend Chat
  Future<MeaningCard?> analyzeFriendMessage(String friendId, String content, List<String> contextHistory, {bool isChinese = true}) async {
    try {
      final meaningJsonString = await _vertexService.analyzeMeaning(
        content,
        contextHistory,
        language: isChinese ? 'chinese' : 'english',
      );

      // Parse JSON
      final jsonMap = jsonDecode(meaningJsonString);
      
      if (jsonMap['content'] != null && jsonMap['content'].toString().isNotEmpty) {
         final card = MeaningCard.fromJson(jsonMap);
         
         // Add to friend meaning cards list
         _friendMeaningCards.add(card);
         
         // Attach to last message of friend
         final friendIndex = _friends.indexWhere((f) => f.id == friendId);
         if (friendIndex != -1 && _friends[friendIndex].messages.isNotEmpty) {
           _friends[friendIndex].messages.last.meaningCard = card;
         }

         notifyListeners(); // Update Soul Orb and Chat UI
         
         return card;
      }
    } catch (e) {
      debugPrint('Friend chat analysis failed: $e');
    }
    return null;
  }

  void clearMessages() async {
    _messages.clear();
    notifyListeners();
    // 可选：是否也要清空数据库？
    // await _supabase.from('chat_messages').delete().eq('user_id', _supabase.auth.currentUser!.id);
  }

  // === 新增：计算并更新用户灵魂画像 ===
  Future<void> _updateUserSoulProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // 1. 计算当前所有卡片的总分
    final scores = SoulCalculator.calculateScores(allMeaningCards);

    try {
      // 2. 更新 profiles 表
      // 使用 upsert (插入或更新)
      await _supabase.from('profiles').upsert({
        'id': userId,
        'updated_at': DateTime.now().toIso8601String(),
        'score_agency': scores[MeaningDimension.agency] ?? 0.0,
        'score_coherence': scores[MeaningDimension.coherence] ?? 0.0,
        'score_curiosity': scores[MeaningDimension.curiosity] ?? 0.0,
        'score_transcendence': scores[MeaningDimension.transcendence] ?? 0.0,
        'score_care': scores[MeaningDimension.care] ?? 0.0,
        'score_reflection': scores[MeaningDimension.reflection] ?? 0.0,
        'score_aesthetic': scores[MeaningDimension.aesthetic] ?? 0.0,
      });
      debugPrint('灵魂画像已更新');
    } catch (e) {
      debugPrint('更新灵魂画像失败: $e');
    }
  }
}
