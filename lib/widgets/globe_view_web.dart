// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class GlobeView extends StatefulWidget {
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
  State<GlobeView> createState() => _GlobeViewState();
}

class _GlobeViewState extends State<GlobeView> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'globe-viz-${DateTime.now().millisecondsSinceEpoch}';
    
    // Register the view factory
    // We create a DivElement that will hold the Globe
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final element = html.DivElement()
        ..id = _viewId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none';
      
      return element;
    });

    // Call the JS init function after the view is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGlobe();
    });
  }

  @override
  void didUpdateWidget(covariant GlobeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groundDataJson != widget.groundDataJson ||
        oldWidget.satDataJson != widget.satDataJson ||
        oldWidget.ringsDataJson != widget.ringsDataJson) {
      _initGlobe();
    }
  }

  void _initGlobe() {
    // Call the global JS function defined in index.html
    js.context.callMethod('initGlobe', [
      _viewId,
      widget.groundDataJson,
      widget.satDataJson,
      widget.ringsDataJson,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
