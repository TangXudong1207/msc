import '../models/meaning_spectrum.dart';

class UserProfile {
  final String id;
  final String email;
  final String? nickname;
  final String? avatarUrl;
  final String? bio;
  
  // 灵魂维度分数
  final Map<MeaningDimension, double> soulScores;

  UserProfile({
    required this.id,
    required this.email,
    this.nickname,
    this.avatarUrl,
    this.bio,
    this.soulScores = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? email}) {
    // 解析分数
    final scores = <MeaningDimension, double>{};
    scores[MeaningDimension.agency] = (json['score_agency'] ?? 0).toDouble();
    scores[MeaningDimension.coherence] = (json['score_coherence'] ?? 0).toDouble();
    scores[MeaningDimension.curiosity] = (json['score_curiosity'] ?? 0).toDouble();
    scores[MeaningDimension.transcendence] = (json['score_transcendence'] ?? 0).toDouble();
    scores[MeaningDimension.care] = (json['score_care'] ?? 0).toDouble();
    scores[MeaningDimension.reflection] = (json['score_reflection'] ?? 0).toDouble();
    scores[MeaningDimension.aesthetic] = (json['score_aesthetic'] ?? 0).toDouble();

    return UserProfile(
      id: json['id'] ?? '',
      email: email ?? json['email'] ?? '', 
      nickname: json['nickname'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      soulScores: scores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'bio': bio,
      'score_agency': soulScores[MeaningDimension.agency],
      'score_coherence': soulScores[MeaningDimension.coherence],
      'score_curiosity': soulScores[MeaningDimension.curiosity],
      'score_transcendence': soulScores[MeaningDimension.transcendence],
      'score_care': soulScores[MeaningDimension.care],
      'score_reflection': soulScores[MeaningDimension.reflection],
      'score_aesthetic': soulScores[MeaningDimension.aesthetic],
    };
  }

  UserProfile copyWith({
    String? nickname,
    String? avatarUrl,
    String? bio,
    Map<MeaningDimension, double>? soulScores,
  }) {
    return UserProfile(
      id: id,
      email: email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      soulScores: soulScores ?? this.soulScores,
    );
  }
}
