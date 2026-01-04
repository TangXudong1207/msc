import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import '../models/world_meaning.dart';
import '../models/meaning_spectrum.dart';

class RealWorldGlobeWidget extends StatefulWidget {
  final List<WorldMeaning> meanings;

  const RealWorldGlobeWidget({super.key, required this.meanings});

  @override
  State<RealWorldGlobeWidget> createState() => _RealWorldGlobeWidgetState();
}

class _RealWorldGlobeWidgetState extends State<RealWorldGlobeWidget> {
  late FlutterEarthGlobeController _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
      // Use local asset for stability
      surface: const AssetImage('assets/textures/earth_night.jpg'),
    );
    
    // Load content after a short delay to ensure controller is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
        _updateContent();
      }
    });
  }

  @override
  void didUpdateWidget(covariant RealWorldGlobeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLoaded && oldWidget.meanings != widget.meanings) {
      _updateContent();
    }
  }

  void _updateContent() {
    for (var meaning in widget.meanings) {
      final id = '${meaning.latitude}_${meaning.longitude}_${meaning.hashCode}';
      final coords = GlobeCoordinates(meaning.latitude, meaning.longitude);
      final color = meaning.dimension.color;

      if (meaning.isSatellite) {
        _controller.addSatellite(
          Satellite(
            id: id,
            coordinates: coords,
            altitude: 200, // High altitude
            isLabelVisible: true,
            style: SatelliteStyle(color: Colors.transparent, size: 0), // Hide default dot
            labelBuilder: (context, satellite, isHovering, isVisible) => _buildSatelliteWidget(color),
          ),
        );
      } else if (meaning.isGeological) {
        // Geological data - maybe slightly different style
        _controller.addPoint(
          Point(
            id: id,
            coordinates: coords,
            isLabelVisible: true,
            style: PointStyle(color: Colors.transparent, size: 0), // Hide default dot
            labelBuilder: (context, point, isHovering, isVisible) => _buildGeologicalWidget(color),
          ),
        );
      } else {
        // Surface Node
        _controller.addPoint(
          Point(
            id: id,
            coordinates: coords,
            isLabelVisible: true,
            style: PointStyle(color: Colors.transparent, size: 0), // Hide default dot
            labelBuilder: (context, point, isHovering, isVisible) => _buildSurfaceWidget(color),
          ),
        );
      }
    }
  }

  Widget _buildSatelliteWidget(Color color) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Outer faint glow
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
          ),
          // 2. Inner glow
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.4)),
          ),
          // 3. Core halo
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.8)),
          ),
          // 4. Bright White Core
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          ),
          // 5. Crosshairs
          CustomPaint(
            size: const Size(40, 40),
            painter: _CrosshairPainter(),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceWidget(Color color) {
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.3)),
          ),
          // Core
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildGeologicalWidget(Color color) {
    return Container(
      width: 4, height: 4,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive radius
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final radius = (screenWidth < screenHeight ? screenWidth : screenHeight) / 2 * 0.85;

    return Stack(
      children: [
        Container(color: Colors.black), // Ensure black background
        Center(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: FlutterEarthGlobe(
              controller: _controller,
              radius: radius,
              onZoomChanged: (zoom) {},
              onTap: (coordinates) {},
              onHover: (coordinates) {},
            ),
          ),
        ),
      ],
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    double s = 8.0; // size
    double w = size.width;
    double h = size.height;
    
    // Top Left
    canvas.drawLine(Offset(w/2 - s, h/2 - s/2), Offset(w/2 - s, h/2 - s), paint);
    canvas.drawLine(Offset(w/2 - s, h/2 - s), Offset(w/2 - s/2, h/2 - s), paint);
    
    // Bottom Right
    canvas.drawLine(Offset(w/2 + s, h/2 + s/2), Offset(w/2 + s, h/2 + s), paint);
    canvas.drawLine(Offset(w/2 + s, h/2 + s), Offset(w/2 + s/2, h/2 + s), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
