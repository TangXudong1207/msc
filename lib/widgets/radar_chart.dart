import 'dart:math';
import 'package:flutter/material.dart';
import '../models/meaning_spectrum.dart';

class RadarChartWidget extends StatelessWidget {
  final Map<MeaningDimension, double> data;
  final Map<MeaningDimension, double>? comparisonData; // New: For comparing with another user
  final double maxValue;
  final Color primaryColor;
  final Color? comparisonColor;

  const RadarChartWidget({
    super.key,
    required this.data,
    this.comparisonData,
    required this.maxValue,
    this.primaryColor = Colors.blue,
    this.comparisonColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(300, 300),
      painter: _RadarChartPainter(
        data, 
        comparisonData, 
        maxValue,
        primaryColor,
        comparisonColor ?? Colors.red,
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<MeaningDimension, double> data;
  final Map<MeaningDimension, double>? comparisonData;
  final double maxValue;
  final Color primaryColor;
  final Color comparisonColor;

  _RadarChartPainter(
    this.data, 
    this.comparisonData, 
    this.maxValue,
    this.primaryColor,
    this.comparisonColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.8;
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dimensions = MeaningDimension.values;
    final angleStep = 2 * pi / dimensions.length;

    // Draw webs (background polygons)
    for (int i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      final path = Path();
      for (int j = 0; j < dimensions.length; j++) {
        final angle = j * angleStep - pi / 2;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw axis lines
    for (int j = 0; j < dimensions.length; j++) {
      final angle = j * angleStep - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), paint);

      // Draw labels
      final labelX = center.dx + (radius + 20) * cos(angle);
      final labelY = center.dy + (radius + 20) * sin(angle);
      
      final textSpan = TextSpan(
        text: dimensions[j].displayName,
        style: const TextStyle(color: Colors.black87, fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // Helper to draw a data polygon
    void drawPolygon(Map<MeaningDimension, double> chartData, Color color) {
      final path = Path();
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int j = 0; j < dimensions.length; j++) {
        final dimension = dimensions[j];
        final value = chartData[dimension] ?? 0.0;
        final normalizedValue = maxValue == 0 ? 0.0 : (value / maxValue);
        // Clamp to 0..1 just in case
        final clampedValue = normalizedValue > 1.0 ? 1.0 : (normalizedValue < 0 ? 0.0 : normalizedValue);
        
        final r = radius * clampedValue;
        final angle = j * angleStep - pi / 2;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }

    // Draw comparison data first (so it's behind if overlapping, or mix mode)
    if (comparisonData != null) {
      drawPolygon(comparisonData!, comparisonColor);
    }

    // Draw primary data
    drawPolygon(data, primaryColor);
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.comparisonData != comparisonData ||
           oldDelegate.maxValue != maxValue;
  }
}
