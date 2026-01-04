import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added import
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  bool _hasSeenOnboarding = false;
  String? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = true; // 初始加载状态

  bool get isAuthenticated => _isAuthenticated;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Supabase 初始化是同步的，直接检查即可
    _isAuthenticated = _authService.isLoggedIn();
    
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (_isAuthenticated) {
      _currentUser = _authService.getCurrentUser();
      // 从数据库加载完整资料
      _userProfile = await _authService.fetchUserProfile();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    await _authService.login(username, password);
    _isAuthenticated = true;
    _currentUser = username;
    // 登录成功后加载资料
    _userProfile = await _authService.fetchUserProfile();
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    // 注册成功后自动登录
    await _authService.register(username, password);
    // 如果注册没有抛出异常，说明成功了（或者需要验证邮箱，但我们关了验证）
    // 尝试直接登录
    await login(username, password);
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _currentUser = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? nickname, String? avatarUrl, String? bio}) async {
    await _authService.updateUserProfile(
      nickname: nickname,
      avatarUrl: avatarUrl,
      bio: bio,
    );
    // Refresh profile from DB
    _userProfile = await _authService.fetchUserProfile();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    // 1. Delete from Supabase (Requires RLS or Edge Function in production)
    // For MVP, we assume the client can delete their own profile, 
    // and cascading deletes handle the rest (messages, cards, etc.)
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final supabase = Supabase.instance.client;
      await supabase.from('profiles').delete().eq('id', userId);
      await _authService.logout();
      _isAuthenticated = false;
      _currentUser = null;
      _userProfile = null;
      notifyListeners();
    }
  }
}

