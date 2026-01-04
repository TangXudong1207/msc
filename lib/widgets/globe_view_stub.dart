import 'package:flutter/material.dart';

class GlobeView extends StatelessWidget {
  final String groundDataJson;
  final String satDataJson;
  final String ringsDataJson;

  const GlobeView({
    super.key,
    required this.groundDataJson,
    required this.satDataJson,
    required this.ringsDataJson,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '3D Globe is only available on Web',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
