import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // === System Config ===
  Future<String?> getConfig(String key) async {
    try {
      final response = await _supabase
          .from('system_config')
          .select('value')
          .eq('key', key)
          .maybeSingle();
      return response?['value'] as String?;
    } catch (e) {
      print('Error fetching config: $e');
      return null;
    }
  }

  Future<void> updateConfig(String key, String value) async {
    try {
      await _supabase.from('system_config').upsert({
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating config: $e');
      rethrow;
    }
  }

  // === Statistics ===
  Future<int> getUserCount() async {
    try {
      final count = await _supabase
          .from('profiles')
          .count(CountOption.exact);
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getMeaningCardCount() async {
    try {
      // Count messages that have a meaning_card (not null)
      final count = await _supabase
          .from('chat_messages')
          .count(CountOption.exact)
          .not('meaning_card', 'is', null);
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> getApiUsageToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

      final response = await _supabase
          .from('api_usage_logs')
          .select('tokens_input, tokens_output')
          .gte('created_at', startOfDay);

      int totalInput = 0;
      int totalOutput = 0;

      for (var row in response) {
        totalInput += (row['tokens_input'] as int? ?? 0);
        totalOutput += (row['tokens_output'] as int? ?? 0);
      }

      return {
        'input': totalInput,
        'output': totalOutput,
        'total': totalInput + totalOutput,
      };
    } catch (e) {
      return {'input': 0, 'output': 0, 'total': 0};
    }
  }

  // === User Management ===
  Future<List<Map<String, dynamic>>> getUsersList({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }
}
