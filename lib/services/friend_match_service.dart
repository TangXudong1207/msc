import 'dart:math';
import '../models/meaning_spectrum.dart';

class FriendMatchService {
  // Calculate Cosine Similarity between two dimension maps
  // Returns a value between -1.0 (opposite) and 1.0 (identical)
  static double calculateSimilarity(
    Map<MeaningDimension, double> userScores,
    Map<MeaningDimension, double> friendScores,
  ) {
    // Convert maps to vectors (ordered by enum index)
    List<double> vecA = [];
    List<double> vecB = [];

    for (var dim in MeaningDimension.values) {
      vecA.add(userScores[dim] ?? 0.0);
      vecB.add(friendScores[dim] ?? 0.0);
    }

    // Dot product
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  // Generate a random soul profile for testing
  static Map<MeaningDimension, double> generateRandomProfile() {
    final random = Random();
    final Map<MeaningDimension, double> profile = {};
    
    for (var dim in MeaningDimension.values) {
      // Generate score between 0.0 and 10.0
      profile[dim] = random.nextDouble() * 10.0;
    }
    
    return profile;
  }
}

class MatchedProfile {
  final String id;
  final String name;
  final String avatarUrl;
  final Map<MeaningDimension, double> scores;
  final double similarity; // 1.0 = identical, -1.0 = opposite

  MatchedProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.scores,
    required this.similarity,
  });
  
  // Helper to get match percentage (0-100%)
  // Maps similarity -1..1 to 0..100% for display? 
  // Or maybe we want to show "98% Similar" vs "95% Complementary"
  
  int get similarityPercentage => ((similarity + 1) / 2 * 100).round();
  
  // Complementary score: distance from 0 (neutral) or -1 (opposite)
  // A high complementary score means similarity is close to -1 or very low.
  int get complementaryPercentage => ((1 - similarity) / 2 * 100).round();
}
