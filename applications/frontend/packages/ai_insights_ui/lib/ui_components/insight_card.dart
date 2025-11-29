import 'package:flutter/material.dart';

class InsightCard extends StatelessWidget {
  final Map<String, dynamic> rec;

  const InsightCard({super.key, required this.rec});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rec['title'] ?? 'Insight', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(rec['detail'] ?? '', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
