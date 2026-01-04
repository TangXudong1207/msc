import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 注册
  Future<void> register(String email, String password) async {
    try {
      await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      // print('注册失败: $e');
      rethrow; // 把错误抛出去，让 UI 层处理
    }
  }

  // 登录
  Future<void> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      // print('登录失败: $e');
      rethrow; // 把错误抛出去，让 UI 层处理
    }
  }

  // 注销
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // 检查登录状态
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // 获取当前用户邮箱
  String? getCurrentUser() {
    return _supabase.auth.currentUser?.email;
  }

  // 获取当前用户ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // 获取当前用户资料 (从 profiles 表异步获取)
  Future<UserProfile?> fetchUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return UserProfile.fromJson(data, email: user.email);
    } catch (e) {
      // print('获取用户资料失败: $e');
      return null;
    }
  }

  // 更新用户资料 (更新 profiles 表)
  Future<void> updateUserProfile({String? nickname, String? avatarUrl, String? bio}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (nickname != null) updates['nickname'] = nickname;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;

    if (updates.isEmpty) return;

    // 更新 profiles 表
    await _supabase.from('profiles').upsert({
      'id': user.id,
      ...updates,
    });
    
    // 同时更新 Auth Metadata (保持兼容性)
    await _supabase.auth.updateUser(
      UserAttributes(data: updates),
    );
  }
}
