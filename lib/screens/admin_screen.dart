import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/chat_provider.dart';
import '../services/admin_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminService _adminService = AdminService();
  
  // Stats
  int _userCount = 0;
  int _meaningCardCount = 0;
  Map<String, int> _apiUsage = {'input': 0, 'output': 0, 'total': 0};
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final userCount = await _adminService.getUserCount();
    final cardCount = await _adminService.getMeaningCardCount();
    final apiUsage = await _adminService.getApiUsageToday();
    final users = await _adminService.getUsersList();

    if (mounted) {
      setState(() {
        _userCount = userCount;
        _meaningCardCount = cardCount;
        _apiUsage = apiUsage;
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    
    // Colors
    final paperColor = const Color(0xFFF4ECD8);
    final ivyGreen = const Color(0xFF6B8E23);
    final terracotta = const Color(0xFFBC5D48);
    final inkBlack = const Color(0xFF2C2C2C);

    return Scaffold(
      backgroundColor: paperColor,
      appBar: AppBar(
        backgroundColor: paperColor,
        elevation: 0,
        iconTheme: IconThemeData(color: inkBlack),
        title: Text(
          "ADMIN CONSOLE",
          style: TextStyle(
            color: inkBlack,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. System Status & API Usage
                  _buildSectionHeader("SYSTEM STATUS & API USAGE (TODAY)"),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ivyGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard("Total Users", "$_userCount", Icons.people, terracotta),
                            _buildStatCard("Meaning Cards", "$_meaningCardCount", Icons.card_membership, ivyGreen),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard("Input Tokens", "${_apiUsage['input']}", Icons.input, Colors.blueGrey),
                            _buildStatCard("Output Tokens", "${_apiUsage['output']}", Icons.output, Colors.blueGrey),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Total Tokens: ${_apiUsage['total']}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: inkBlack),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 2. Configuration
                  _buildSectionHeader("CONFIGURATION"),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ivyGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Meaning Card Threshold", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(chatProvider.meaningCardThreshold.toStringAsFixed(2), style: TextStyle(color: terracotta, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Higher value = Harder to trigger meaning cards (0.0 - 1.0)",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Slider(
                          value: chatProvider.meaningCardThreshold,
                          min: 0.1,
                          max: 0.9,
                          divisions: 8,
                          activeColor: terracotta,
                          inactiveColor: terracotta.withValues(alpha: 0.2),
                          label: chatProvider.meaningCardThreshold.toStringAsFixed(1),
                          onChanged: (value) {
                            chatProvider.setMeaningCardThreshold(value);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 3. User Management
                  _buildSectionHeader("RECENT USERS"),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ivyGreen.withValues(alpha: 0.2)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: ivyGreen.withValues(alpha: 0.1)),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: terracotta.withValues(alpha: 0.1),
                            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                            child: user['avatar_url'] == null 
                                ? Text((user['nickname'] ?? '?')[0], style: TextStyle(color: terracotta))
                                : null,
                          ),
                          title: Text(user['nickname'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(user['id'] ?? '', style: const TextStyle(fontSize: 10)),
                          trailing: Text(
                            user['created_at'] != null 
                                ? DateTime.parse(user['created_at']).toString().split(' ')[0] 
                                : '-',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
        color: Color(0xFF6B8E23), // Ivy Green
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
