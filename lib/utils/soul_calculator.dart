import 'dart:math';
import '../models/meaning_card.dart';
import '../models/meaning_spectrum.dart';

class SoulCalculator {
  /// Calculates the current scores for each dimension based on the meaning cards.
  /// Uses a dynamic alpha based on variance to constrain growth.
  /// Formula: alpha_dim = baseAlpha * (1 + min(1, variance_norm))
  static Map<MeaningDimension, double> calculateScores(List<MeaningCard> cards) {
    final Map<MeaningDimension, double> currentScores = {};
    final Map<MeaningDimension, List<double>> history = {};

    // Initialize
    for (var dim in MeaningDimension.values) {
      currentScores[dim] = 0.0;
      history[dim] = [];
    }

    for (var card in cards) {
      final spectrum = card.spectrum;
      final dimension = spectrum.dimension;
      double score = card.score;
      
      // Handle zero score case (legacy or default)
      if (score == 0) score = 0.5;

      // Add to history for variance calculation
      history[dimension]!.add(score);

      // Calculate Variance
      double variance = 0.0;
      final scores = history[dimension]!;
      if (scores.length > 1) {
        double mean = scores.reduce((a, b) => a + b) / scores.length;
        double sumSquaredDiff = scores.fold(0.0, (sum, s) => sum + pow(s - mean, 2));
        variance = sumSquaredDiff / scores.length;
      }

      // Calculate Alpha
      // alpha_dim = baseAlpha * (1 + min(1, variance_norm))
      // Assuming variance_norm = variance * 10 for 0-1 range scores to make it sensitive
      // If variance is 0.1 (high for 0-1 range), varianceNorm is 1.0.
      double varianceNorm = variance * 10.0;
      double alpha = dimension.baseAlpha * (1 + min(1.0, varianceNorm));

      // Update Score (Accumulation with Constraint)
      // We accumulate the score scaled by alpha.
      // This means dimensions with higher alpha (faster/more volatile) grow faster.
      currentScores[dimension] = (currentScores[dimension] ?? 0) + score * alpha;
    }

    return currentScores;
  }
}
