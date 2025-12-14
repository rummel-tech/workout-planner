import 'package:flutter/material.dart';
import '../ui_components/insight_card.dart';

class AIInsightsScreen extends StatelessWidget {
  final Map<String, dynamic> insights;

  const AIInsightsScreen({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final summary = insights['summary'] ?? "No summary available.";
    final recs = (insights['recommendations'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(title: const Text("AI Insights")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Summary", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          Text("Recommendations", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final rec in recs) InsightCard(rec: rec),
        ],
      ),
    );
  }
}
