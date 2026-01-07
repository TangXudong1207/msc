import 'dart:math';
import 'package:flutter/material.dart';
import '../models/meaning_spectrum.dart';
import '../models/world_meaning.dart';

class DemoDataHelper {
  static final Random _random = Random();

  /// 生成随机的个人维度分数
  static Map<MeaningDimension, double> generateRandomScores() {
    final Map<MeaningDimension, double> scores = {};
    for (var dimension in MeaningDimension.values) {
      // 生成 0.1 到 1.0 之间的分值
      scores[dimension] = 0.1 + _random.nextDouble() * 0.9;
    }
    return scores;
  }

  /// 生成各种典型的维度分数配置
  static List<Map<MeaningDimension, double>> getPresetScores() {
    return [
      // 1. 均衡型 (Balanced High)
      {for (var d in MeaningDimension.values) d: 0.7},

      // 2. 均衡型低分 (Balanced Low)
      {for (var d in MeaningDimension.values) d: 0.3},

      // 3. 活力型 (Vitality): Agency & Curiosity
      {
        MeaningDimension.agency: 0.9,
        MeaningDimension.curiosity: 0.9,
        MeaningDimension.coherence: 0.4,
        MeaningDimension.transcendence: 0.3,
        MeaningDimension.care: 0.3,
        MeaningDimension.reflection: 0.2,
        MeaningDimension.aesthetic: 0.5,
      },

      // 4. 深沉型 (Deep): Transcendence & Reflection
      {
        MeaningDimension.agency: 0.2,
        MeaningDimension.curiosity: 0.3,
        MeaningDimension.coherence: 0.5,
        MeaningDimension.transcendence: 0.9,
        MeaningDimension.care: 0.4,
        MeaningDimension.reflection: 0.9,
        MeaningDimension.aesthetic: 0.6,
      },

      // 5. 感性型 (Sensitive): Care & Aesthetic [Low Agency]
      {
        MeaningDimension.agency: 0.1, // Very Low Agency
        MeaningDimension.curiosity: 0.4,
        MeaningDimension.coherence: 0.2,
        MeaningDimension.transcendence: 0.5,
        MeaningDimension.care: 0.95,
        MeaningDimension.reflection: 0.5,
        MeaningDimension.aesthetic: 0.9,
      },

      // 6. 理性型 (Rational): Coherence [Low Agency]
      {
        MeaningDimension.agency: 0.2, // Low Agency
        MeaningDimension.curiosity: 0.5,
        MeaningDimension.coherence: 0.95,
        MeaningDimension.transcendence: 0.3,
        MeaningDimension.care: 0.2,
        MeaningDimension.reflection: 0.6,
        MeaningDimension.aesthetic: 0.2,
      },

      // 7. 纯粹好奇 (Pure Curiosity) [Low Agency, Low Coherence]
      {
        MeaningDimension.agency: 0.3,
        MeaningDimension.curiosity: 0.95,
        MeaningDimension.coherence: 0.2,
        MeaningDimension.transcendence: 0.4,
        MeaningDimension.care: 0.3,
        MeaningDimension.reflection: 0.3,
        MeaningDimension.aesthetic: 0.4,
      },

      // 8. 混乱美学 (Chaos Aesthetic) [High Aesthetic, Low Coherence]
      {
        MeaningDimension.agency: 0.4,
        MeaningDimension.curiosity: 0.6,
        MeaningDimension.coherence: 0.1, // Very Low Coherence
        MeaningDimension.transcendence: 0.5,
        MeaningDimension.care: 0.2,
        MeaningDimension.reflection: 0.3,
        MeaningDimension.aesthetic: 0.95,
      },

      // 9. 慈悲守护 (Guardian) [High Care, High Coherence]
      {
        MeaningDimension.agency: 0.3,
        MeaningDimension.curiosity: 0.2,
        MeaningDimension.coherence: 0.8,
        MeaningDimension.transcendence: 0.6,
        MeaningDimension.care: 0.9,
        MeaningDimension.reflection: 0.5,
        MeaningDimension.aesthetic: 0.4,
      },

      // 10. 内省虚无 (Void/Nihilism) [High Transcendence, Very Low Agency]
      {
        MeaningDimension.agency: 0.05, // Almost zero
        MeaningDimension.curiosity: 0.1,
        MeaningDimension.coherence: 0.2,
        MeaningDimension.transcendence: 0.95,
        MeaningDimension.care: 0.1,
        MeaningDimension.reflection: 0.8,
        MeaningDimension.aesthetic: 0.2,
      },

      // 11. 随机尖刺 (Random Spiky)
      {
        MeaningDimension.agency: 0.2,
        MeaningDimension.curiosity: 0.8,
        MeaningDimension.coherence: 0.1,
        MeaningDimension.transcendence: 0.7,
        MeaningDimension.care: 0.2,
        MeaningDimension.reflection: 0.9,
        MeaningDimension.aesthetic: 0.1,
      },
    ];
  }

  /// 生成随机的世界意义点
  static List<WorldMeaning> generateRandomWorldMeanings(int count) {
    final List<WorldMeaning> meanings = [];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      // 随机经纬度
      final lat = -60 + _random.nextDouble() * 120; // 避开极地
      final lng = -180 + _random.nextDouble() * 360;

      // 随机维度类型
      final dimension = MeaningDimension
          .values[_random.nextInt(MeaningDimension.values.length)];

      // 随机时间 (最近30天内，也有一些旧的)
      final daysAgo = _random.nextInt(40);
      final timestamp = now.subtract(Duration(days: daysAgo));

      meanings.add(WorldMeaning(
        id: 'demo_$i',
        latitude: lat,
        longitude: lng,
        dimension: dimension,
        timestamp: timestamp,
        isUser: _random.nextDouble() > 0.9, // 10% 是用户自己的
      ));
    }
    return meanings;
  }
}
