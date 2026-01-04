import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/meaning_spectrum.dart';

class SoulOrbWidget extends StatefulWidget {
  final Map<MeaningDimension, double> data;
  final double maxValue;
  final double width;
  final double height;

  const SoulOrbWidget({
    super.key,
    required this.data,
    required this.maxValue,
    this.width = 300,
    this.height = 300,
  });

  @override
  State<SoulOrbWidget> createState() => _SoulOrbWidgetState();
}

class _SoulOrbWidgetState extends State<SoulOrbWidget>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late Ticker _ticker;
  double _time = 0.0;
  
  // Manual rotation state
  double _rotationX = 0.0; // Yaw
  double _rotationY = 0.0; // Pitch

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    });
    _ticker.start();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/soul_orb.frag');
      setState(() {
        _program = program;
      });
    } catch (e) {
      debugPrint('Failed to load shader: $e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // Helper to normalize value 0.0 - 1.0
  double _norm(MeaningDimension dim) {
    if (widget.maxValue == 0) return 0.0;
    return (widget.data[dim] ?? 0.0) / widget.maxValue;
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // Sensitivity factor
          _rotationX -= details.delta.dx * 0.005;
          _rotationY += details.delta.dy * 0.005;
          
          // Clamp pitch to avoid flipping upside down too easily
          _rotationY = _rotationY.clamp(-1.5, 1.5);
        });
      },
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _SoulOrbPainter(
          program: _program!,
          time: _time,
          turbulence: _norm(MeaningDimension.agency),
          spikes: _norm(MeaningDimension.coherence),
          innerGlow: _norm(MeaningDimension.care),
          holeRadius: _norm(MeaningDimension.transcendence) * 0.8,
          colorShiftSpeed: _norm(MeaningDimension.curiosity),
          saturation: _norm(MeaningDimension.aesthetic),
          auraIntensity: _norm(MeaningDimension.transcendence),
          manualRotation: Offset(_rotationX, _rotationY),
        ),
      ),
    );
  }
}

class _SoulOrbPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double turbulence;
  final double spikes;
  final double innerGlow;
  final double holeRadius;
  final double colorShiftSpeed;
  final double saturation;
  final double auraIntensity;
  final Offset manualRotation;

  _SoulOrbPainter({
    required this.program,
    required this.time,
    required this.turbulence,
    required this.spikes,
    required this.innerGlow,
    required this.holeRadius,
    required this.colorShiftSpeed,
    required this.saturation,
    required this.auraIntensity,
    required this.manualRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // Uniforms must match the order in the .frag file
    // uniform vec2 u_resolution;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    
    // uniform float u_time;
    shader.setFloat(2, time);
    
    // uniform float u_turbulence;
    shader.setFloat(3, turbulence);
    
    // uniform float u_spikes;
    shader.setFloat(4, spikes);
    
    // uniform float u_inner_glow;
    shader.setFloat(5, innerGlow);
    
    // uniform float u_hole_radius;
    shader.setFloat(6, holeRadius);
    
    // uniform float u_color_shift_speed;
    shader.setFloat(7, colorShiftSpeed);
    
    // uniform float u_saturation;
    shader.setFloat(8, saturation);
    
    // uniform float u_aura_intensity;
    shader.setFloat(9, auraIntensity);

    // uniform vec2 u_mouse;
    shader.setFloat(10, manualRotation.dx);
    shader.setFloat(11, manualRotation.dy);

    // Removed complex offset/scale logic as we simplified the shader
    // to use normalized coordinates.

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _SoulOrbPainter oldDelegate) {
    return oldDelegate.time != time ||
           oldDelegate.manualRotation != manualRotation ||
           oldDelegate.turbulence != turbulence;
  }
}
