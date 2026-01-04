import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';
import '../models/meaning_spectrum.dart';
import '../widgets/soul_orb.dart';
import '../widgets/app_drawer.dart'; // Import AppDrawer
import '../utils/soul_calculator.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF050508), // Deep dark background for the orb
      drawer: const AppDrawer(), // Add Drawer
      appBar: AppBar(
        title: Text(languageProvider.getText('灵魂球', 'Soul Orb')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          // Use SoulCalculator to compute scores with dynamic alpha
          // Now using allMeaningCards to include friend chat analysis
          final dimensionScores = SoulCalculator.calculateScores(chatProvider.allMeaningCards);

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
                  languageProvider.getText('您的灵魂形态', 'Your Soul Form'),
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w300,
                    color: Colors.white70,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 40),
                SoulOrbWidget(
                  data: dimensionScores,
                  maxValue: maxValue,
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
                              letterSpacing: 1.0
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 2,
                            color: Colors.blueGrey.withValues(alpha: 0.3 + (e.value/maxValue)*0.7),
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
