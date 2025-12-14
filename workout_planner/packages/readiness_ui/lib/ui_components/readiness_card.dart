import 'package:flutter/material.dart';

class ReadinessCard extends StatelessWidget {
  final double readiness;        // 0.0–1.0
  final double hrv;
  final double sleepHours;
  final int restingHr;
  final String status;           // "high", "moderate", "low"
  final String limitingFactor;

  const ReadinessCard({
    super.key,
    required this.readiness,
    required this.hrv,
    required this.sleepHours,
    required this.restingHr,
    required this.status,
    required this.limitingFactor,
  });

  Color _statusColor() {
    switch (status) {
      case "high": return Colors.green;
      case "moderate": return Colors.orange;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Readiness: "+( (readiness * 100).toStringAsFixed(0))+"%",
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: readiness,
              backgroundColor: Colors.grey.shade300,
              color: _statusColor(),
              minHeight: 12,
            ),
            const SizedBox(height: 20),
            _metric("HRV", "${hrv.toStringAsFixed(1)} ms"),
            _metric("Sleep", "${sleepHours.toStringAsFixed(1)} hours"),
            _metric("Resting HR", "$restingHr bpm"),
            const Divider(height: 32),
            Text("Limited by: $limitingFactor",
                style: const TextStyle(fontSize: 16)),
            Text("Status: ${status.toUpperCase()}",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _statusColor())),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
