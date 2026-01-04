import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/world_meaning.dart';
import '../models/meaning_spectrum.dart';
import 'globe_view.dart';

class CustomGlobe extends StatelessWidget {
  final List<WorldMeaning> meanings;

  const CustomGlobe({super.key, required this.meanings});

  String _dimColor(String hex, double factor) {
    if (!hex.startsWith('#')) return "#444444";
    try {
      String cleanHex = hex.replaceFirst('#', '');
      if (cleanHex.length == 8) cleanHex = cleanHex.substring(2); // Remove alpha if present
      if (cleanHex.length != 6) return "#444444";

      int r = int.parse(cleanHex.substring(0, 2), radix: 16);
      int g = int.parse(cleanHex.substring(2, 4), radix: 16);
      int b = int.parse(cleanHex.substring(4, 6), radix: 16);

      r = (r * factor).toInt();
      g = (g * factor).toInt();
      b = (b * factor).toInt();

      return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    } catch (e) {
      return "#444444";
    }
  }

  @override
  Widget build(BuildContext context) {
    final groundData = <Map<String, dynamic>>[];
    final satelliteData = <Map<String, dynamic>>[];
    final ringsData = <Map<String, dynamic>>[];

    for (var node in meanings) {
      final colorValue = node.dimension.color.value;
      final hexColor = '#${(colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
      
      final lat = node.latitude;
      final lng = node.longitude;
      final label = node.dimension.displayName.split('\n').first;

      if (node.isGeological) {
        groundData.add({
          "lat": lat, "lng": lng, "alt": 0.0, "radius": 0.2,
          "color": _dimColor(hexColor, 0.4), "label": "History: $label"
        });
      } else if (!node.isUser) {
        groundData.add({
          "lat": lat, "lng": lng, "alt": 0.005, "radius": 0.6,
          "color": hexColor, "label": "Light: $label"
        });
      } else {
        // Current User
        final altitude = 0.15 + (node.hashCode % 25) / 100.0;
        satelliteData.add({
          "lat": lat, "lng": lng, "alt": altitude, "radius": 0.6,
          "color": hexColor, "label": "ME: $label"
        });
        ringsData.add({
          "lat": lat, "lng": lng, "alt": altitude, "color": hexColor,
          "maxR": 3, "prop": 0.4
        });
      }
    }

    return GlobeView(
      groundDataJson: jsonEncode(groundData),
      satDataJson: jsonEncode(satelliteData),
      ringsDataJson: jsonEncode(ringsData),
    );
  }
}
