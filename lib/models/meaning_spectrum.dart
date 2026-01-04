import 'package:flutter/material.dart';

enum MeaningDimension {
  agency,
  coherence,
  curiosity,
  transcendence,
  care,
  reflection,
  aesthetic,
}

extension MeaningDimensionExtension on MeaningDimension {
  String get displayName {
    switch (this) {
      case MeaningDimension.agency: return 'Agency\n(主体性)';
      case MeaningDimension.coherence: return 'Coherence\n(连贯性)';
      case MeaningDimension.curiosity: return 'Curiosity\n(好奇心)';
      case MeaningDimension.transcendence: return 'Transcendence\n(超越性)';
      case MeaningDimension.care: return 'Care\n(关怀)';
      case MeaningDimension.reflection: return 'Reflection\n(反思)';
      case MeaningDimension.aesthetic: return 'Aesthetic\n(美学)';
    }
  }

  double get baseAlpha {
    switch (this) {
      case MeaningDimension.agency: return 0.18; // Vitality (Fast)
      case MeaningDimension.coherence: return 0.12; // Rationality (Medium)
      case MeaningDimension.curiosity: return 0.15; // Curiosity (Medium Fast)
      case MeaningDimension.transcendence: return 0.05; // Transcendence (Very Slow)
      case MeaningDimension.care: return 0.10; // Care (Medium Slow)
      case MeaningDimension.reflection: return 0.08; // Reflection (Slow)
      case MeaningDimension.aesthetic: return 0.08; // Aesthetic (Slow)
    }
  }

  Color get color {
    switch (this) {
      case MeaningDimension.agency: return const Color(0xFFFF7F00); // Orange
      case MeaningDimension.coherence: return const Color(0xFF00CCFF); // Cyan
      case MeaningDimension.curiosity: return const Color(0xFF00E676); // Green
      case MeaningDimension.transcendence: return const Color(0xFF9D00FF); // Purple
      case MeaningDimension.care: return const Color(0xFFFF4081); // Pink
      case MeaningDimension.reflection: return const Color(0xFF536DFE); // Indigo
      case MeaningDimension.aesthetic: return const Color(0xFFAB47BC); // Magenta
    }
  }
}

enum MeaningSpectrum {
  conflict,
  hubris,
  vitality,
  rationality,
  structure,
  truth,
  curiosity,
  mystery,
  nihilism,
  mortality,
  consciousness,
  empathy,
  heritage,
  melancholy,
  aesthetic,
  entropy,
}

extension MeaningSpectrumExtension on MeaningSpectrum {
  MeaningDimension get dimension {
    switch (this) {
      case MeaningSpectrum.conflict:
      case MeaningSpectrum.hubris:
      case MeaningSpectrum.vitality:
        return MeaningDimension.agency;
      
      case MeaningSpectrum.rationality:
      case MeaningSpectrum.structure:
      case MeaningSpectrum.truth:
        return MeaningDimension.coherence;
      
      case MeaningSpectrum.curiosity:
      case MeaningSpectrum.mystery:
        return MeaningDimension.curiosity;
      
      case MeaningSpectrum.nihilism:
      case MeaningSpectrum.mortality:
      case MeaningSpectrum.consciousness:
        return MeaningDimension.transcendence;
      
      case MeaningSpectrum.empathy:
      case MeaningSpectrum.heritage:
        return MeaningDimension.care;
      
      case MeaningSpectrum.melancholy:
        return MeaningDimension.reflection;
      
      case MeaningSpectrum.aesthetic:
      case MeaningSpectrum.entropy:
        return MeaningDimension.aesthetic;
    }
  }

  String get displayName {
    switch (this) {
      case MeaningSpectrum.conflict: return 'Conflict (冲突)';
      case MeaningSpectrum.hubris: return 'Hubris (傲慢)';
      case MeaningSpectrum.vitality: return 'Vitality (生命力)';
      case MeaningSpectrum.rationality: return 'Rationality (理性)';
      case MeaningSpectrum.structure: return 'Structure (结构)';
      case MeaningSpectrum.truth: return 'Truth (真理)';
      case MeaningSpectrum.curiosity: return 'Curiosity (求知)';
      case MeaningSpectrum.mystery: return 'Mystery (神秘)';
      case MeaningSpectrum.nihilism: return 'Nihilism (虚无)';
      case MeaningSpectrum.mortality: return 'Mortality (必死性)';
      case MeaningSpectrum.consciousness: return 'Consciousness (意识)';
      case MeaningSpectrum.empathy: return 'Empathy (共情)';
      case MeaningSpectrum.heritage: return 'Heritage (传承)';
      case MeaningSpectrum.melancholy: return 'Melancholy (忧郁)';
      case MeaningSpectrum.aesthetic: return 'Aesthetic (审美)';
      case MeaningSpectrum.entropy: return 'Entropy (熵)';
    }
  }

  Color get color {
    switch (this) {
      case MeaningSpectrum.conflict: return const Color(0xFFFF2B2B);
      case MeaningSpectrum.hubris: return const Color(0xFFFFD700);
      case MeaningSpectrum.vitality: return const Color(0xFFFF7F00);
      case MeaningSpectrum.rationality: return const Color(0xFF00CCFF);
      case MeaningSpectrum.structure: return const Color(0xFFE0E0E0);
      case MeaningSpectrum.truth: return const Color(0xFFFFFFFF);
      case MeaningSpectrum.curiosity: return const Color(0xFF00E676);
      case MeaningSpectrum.mystery: return const Color(0xFF9D00FF);
      case MeaningSpectrum.nihilism: return const Color(0xFF607D8B);
      case MeaningSpectrum.mortality: return const Color(0xFF212121);
      case MeaningSpectrum.consciousness: return const Color(0xFF69F0AE);
      case MeaningSpectrum.empathy: return const Color(0xFFFF4081);
      case MeaningSpectrum.heritage: return const Color(0xFF795548);
      case MeaningSpectrum.melancholy: return const Color(0xFF536DFE);
      case MeaningSpectrum.aesthetic: return const Color(0xFFAB47BC);
      case MeaningSpectrum.entropy: return const Color(0xFF546E7A);
    }
  }

  String get philosophy {
    switch (this) {
      case MeaningSpectrum.conflict: return '愤怒、对抗、打破规则的力量。';
      case MeaningSpectrum.hubris: return '自信过剩、自我中心、挑战神明。';
      case MeaningSpectrum.vitality: return '纯粹的生存本能、激情、野性。';
      case MeaningSpectrum.rationality: return '逻辑、数学、冷静的分析。';
      case MeaningSpectrum.structure: return '秩序、建筑感、系统的美。';
      case MeaningSpectrum.truth: return '绝对的客观事实、冷酷的现实。';
      case MeaningSpectrum.curiosity: return '对未知的探索、新鲜感。';
      case MeaningSpectrum.mystery: return '无法解释的事物、隐喻、魔法。';
      case MeaningSpectrum.nihilism: return '意义的消解、空无、无所谓。';
      case MeaningSpectrum.mortality: return '对死亡、终结、时间流逝的凝视。';
      case MeaningSpectrum.consciousness: return '觉察、灵性、从高处俯瞰自我。';
      case MeaningSpectrum.empathy: return '感同身受、温暖、爱。';
      case MeaningSpectrum.heritage: return '历史、记忆、家庭、根源。';
      case MeaningSpectrum.melancholy: return '蓝色的沉思、必要的悲伤、内省。';
      case MeaningSpectrum.aesthetic: return '纯粹的形式美、艺术感、感官享受。';
      case MeaningSpectrum.entropy: return '混乱之美、衰败、无序。';
    }
  }

  static MeaningSpectrum fromString(String? value) {
    if (value == null) return MeaningSpectrum.structure; // Default
    
    final normalizedValue = value.toLowerCase().trim();
    
    // 1. 尝试直接匹配英文枚举名
    try {
      return MeaningSpectrum.values.firstWhere(
        (e) => e.name.toLowerCase() == normalizedValue,
      );
    } catch (_) {}

    // 2. 尝试匹配中文名称或包含关系
    if (normalizedValue.contains('conflict') || normalizedValue.contains('冲突')) return MeaningSpectrum.conflict;
    if (normalizedValue.contains('hubris') || normalizedValue.contains('傲慢')) return MeaningSpectrum.hubris;
    if (normalizedValue.contains('vitality') || normalizedValue.contains('生命力')) return MeaningSpectrum.vitality;
    if (normalizedValue.contains('rationality') || normalizedValue.contains('理性')) return MeaningSpectrum.rationality;
    if (normalizedValue.contains('structure') || normalizedValue.contains('结构')) return MeaningSpectrum.structure;
    if (normalizedValue.contains('truth') || normalizedValue.contains('真理')) return MeaningSpectrum.truth;
    if (normalizedValue.contains('curiosity') || normalizedValue.contains('求知')) return MeaningSpectrum.curiosity;
    if (normalizedValue.contains('mystery') || normalizedValue.contains('神秘')) return MeaningSpectrum.mystery;
    if (normalizedValue.contains('nihilism') || normalizedValue.contains('虚无')) return MeaningSpectrum.nihilism;
    if (normalizedValue.contains('mortality') || normalizedValue.contains('必死') || normalizedValue.contains('死亡')) return MeaningSpectrum.mortality;
    if (normalizedValue.contains('consciousness') || normalizedValue.contains('意识')) return MeaningSpectrum.consciousness;
    if (normalizedValue.contains('empathy') || normalizedValue.contains('共情')) return MeaningSpectrum.empathy;
    if (normalizedValue.contains('heritage') || normalizedValue.contains('传承')) return MeaningSpectrum.heritage;
    if (normalizedValue.contains('melancholy') || normalizedValue.contains('忧郁')) return MeaningSpectrum.melancholy;
    if (normalizedValue.contains('aesthetic') || normalizedValue.contains('审美')) return MeaningSpectrum.aesthetic;
    if (normalizedValue.contains('entropy') || normalizedValue.contains('熵')) return MeaningSpectrum.entropy;

    // 3. 默认回退
    return MeaningSpectrum.structure;
  }
}
