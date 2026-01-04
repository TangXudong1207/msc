import 'meaning_spectrum.dart';

class MeaningCard {
  final String content;
  final double score;
  final MeaningSpectrum spectrum;

  MeaningCard({
    required this.content,
    this.score = 0.0,
    this.spectrum = MeaningSpectrum.structure,
  });

  factory MeaningCard.fromJson(Map<String, dynamic> json) {
    return MeaningCard(
      content: json['content'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      spectrum: MeaningSpectrumExtension.fromString(json['spectrum']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'score': score,
      'spectrum': spectrum.name,
    };
  }
  
  @override
  String toString() {
    return content;
  }
}
