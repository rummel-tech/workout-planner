import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool enabled = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Notification settings will be loaded from backend API in future update
    // For now, using local state
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Notification Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Enable Notifications"),
            subtitle: const Text("Local setting only - sync coming soon"),
            value: enabled,
            onChanged: (v) {
              // TODO: Implement notification settings API endpoint
              setState(() => enabled = v);
            },
          ),
          const SizedBox(height: 20),
          const Text(
            "Note: Notification preferences will sync with backend in next update",
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
