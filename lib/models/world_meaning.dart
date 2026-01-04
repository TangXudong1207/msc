import 'meaning_spectrum.dart';

class WorldMeaning {
  final String id;
  final double latitude;
  final double longitude;
  final MeaningDimension dimension; // Changed from MeaningSpectrum to MeaningDimension
  final DateTime timestamp;
  final bool isUser;

  WorldMeaning({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.dimension,
    required this.timestamp,
    this.isUser = false,
  });

  factory WorldMeaning.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Parse dimension string to enum
    MeaningDimension dim = MeaningDimension.agency;
    try {
      dim = MeaningDimension.values.firstWhere(
        (e) => e.toString().split('.').last == json['dimension'],
        orElse: () => MeaningDimension.agency,
      );
    } catch (_) {}

    return WorldMeaning(
      id: json['id'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      dimension: dim,
      timestamp: DateTime.parse(json['created_at']),
      isUser: json['user_id'] == currentUserId,
    );
  }

  // Helper to determine layer
  bool get isGeological => DateTime.now().difference(timestamp).inDays > 30;
  bool get isSurface => !isGeological && !isUser;
  bool get isSatellite => isUser && !isGeological; // Only recent user meanings are satellites
}
