import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';
import '../models/meaning_spectrum.dart';
import '../widgets/soul_orb.dart';
import '../widgets/app_drawer.dart'; // Import AppDrawer
import '../utils/soul_calculator.dart';
import '../utils/demo_data_helper.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Map<MeaningDimension, double>? _demoScores;
  int _demoIndex = -1;
  int _renderStyle = 0; // 0: Legacy, 1: Crystal, 2: Nebula

  void _cycleDemoData() {
    setState(() {
      final presets = DemoDataHelper.getPresetScores();
      _demoIndex = (_demoIndex + 1) % (presets.length + 1);

      if (_demoIndex < presets.length) {
        _demoScores = presets[_demoIndex];
      } else {
        _demoScores = null; // Back to real data
      }
    });
  }

  void _cycleRenderStyle() {
    setState(() {
      _renderStyle = (_renderStyle + 1) % 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor:
          const Color(0xFF050508), // Deep dark background for the orb
      drawer: const AppDrawer(), // Add Drawer
      appBar: AppBar(
        title: Text(languageProvider.getText('灵魂球', 'Soul Orb')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        actions: [
          IconButton(
            icon: Icon(
              _renderStyle == 0
                  ? Icons.grid_3x3
                  : (_renderStyle == 1 ? Icons.diamond : Icons.cloud),
              color: Colors.cyanAccent,
            ),
            tooltip: 'Change Render Mode',
            onPressed: _cycleRenderStyle,
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          // Use SoulCalculator to compute scores with dynamic alpha
          // Now using allMeaningCards to include friend chat analysis
          Map<MeaningDimension, double> dimensionScores;
          if (_demoScores != null) {
            dimensionScores = _demoScores!;
          } else {
            dimensionScores =
                SoulCalculator.calculateScores(chatProvider.allMeaningCards);
          }

          // Find max value for normalization
          double maxValue = 0.0;
          dimensionScores.forEach((key, value) {
            if (value > maxValue) maxValue = value;
          });

          // Lower threshold because scores are now scaled by alpha
          if (maxValue < 0.5) maxValue = 0.5;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _demoScores != null
                      ? "${languageProvider.getText('演示模式', 'DEMO MODE')} #${_demoIndex + 1}"
                      : languageProvider.getText('您的灵魂形态', 'Your Soul Form'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: _demoScores != null
                        ? Colors.cyanAccent
                        : Colors.white70,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 40),
                SoulOrbWidget(
                  data: dimensionScores,
                  maxValue: maxValue,
                  renderStyle: _renderStyle,
                ),
                const SizedBox(height: 60),
                // Minimalist stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: dimensionScores.entries.map((e) {
                      // Only show dimensions with significant score
                      // Lowered threshold to 0.01 because scores are scaled by alpha
                      if (e.value < 0.01) return const SizedBox.shrink();

                      final parts = e.key.displayName.split('\n');
                      final name = languageProvider.isChinese
                          ? parts[1].replaceAll('(', '').replaceAll(')', '')
                          : parts[0];

                      return Column(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 2,
                            color: Colors.blueGrey.withValues(
                                alpha: 0.3 + (e.value / maxValue) * 0.7),
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
