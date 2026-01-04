import 'dart:math';
import 'package:dio/dio.dart'; // Added Dio
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/world_meaning.dart';
import '../models/meaning_card.dart';
import '../models/meaning_spectrum.dart';

class WorldService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();
  final Dio _dio = Dio(); // Dio instance

  Future<List<WorldMeaning>> fetchWorldMeanings() async {
    try {
      // Fetch latest 1000 points
      final response = await _supabase
          .from('world_meanings')
          .select()
          .order('created_at', ascending: false)
          .limit(1000);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => WorldMeaning.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching world meanings: $e');
      return [];
    }
  }

  Future<void> publishMeaning(MeaningCard card) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Get approximate location from IP
      final location = await _getLocationFromIP();
      
      // 2. Add fuzzing (Random offset ~5-10km)
      // 0.1 degree is roughly 11km
      final double latOffset = (_random.nextDouble() - 0.5) * 0.2; 
      final double lonOffset = (_random.nextDouble() - 0.5) * 0.2;
      
      final double lat = location['lat']! + latOffset;
      final double lon = location['lon']! + lonOffset;

      // 3. Insert into DB (Anonymous: No content, only dimension/color)
      await _supabase.from('world_meanings').insert({
        'user_id': userId,
        'latitude': lat,
        'longitude': lon,
        'dimension': card.spectrum.dimension.toString().split('.').last,
        // Content is intentionally OMITTED for anonymity
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error publishing meaning: $e');
      // Fail silently or rethrow depending on needs. 
      // For auto-publish, silent fail is usually better to not disrupt chat.
    }
  }

  Future<Map<String, double>> _getLocationFromIP() async {
    try {
      // Use ip-api.com (Free for non-commercial)
      final response = await _dio.get('http://ip-api.com/json');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return {
          'lat': (response.data['lat'] as num).toDouble(),
          'lon': (response.data['lon'] as num).toDouble(),
        };
      }
    } catch (e) {
      print('IP Location failed: $e');
    }
    
    // Fallback to random location if IP fails
    return {
      'lat': (_random.nextDouble() * 130) - 60,
      'lon': (_random.nextDouble() * 360) - 180,
    };
  }
}
