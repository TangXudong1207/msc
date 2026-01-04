import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  void initialize() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _checkStatus(results);
    });
  }

  void _checkStatus(List<ConnectivityResult> results) {
    bool isConnected = results.any((result) => result != ConnectivityResult.none);
    _connectionStatusController.add(isConnected);
  }
}

class NetworkStatusWrapper extends StatefulWidget {
  final Widget child;
  const NetworkStatusWrapper({super.key, required this.child});

  @override
  State<NetworkStatusWrapper> createState() => _NetworkStatusWrapperState();
}

class _NetworkStatusWrapperState extends State<NetworkStatusWrapper> {
  bool _isOffline = false;
  late StreamSubscription<bool> _subscription;

  @override
  void initState() {
    super.initState();
    NetworkService().initialize();
    _subscription = NetworkService().connectionStatus.listen((isConnected) {
      setState(() {
        _isOffline = !isConnected;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            color: Colors.red[700],
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Text(
              "No Internet Connection",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
