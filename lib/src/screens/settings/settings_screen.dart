import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> settings = {"notifications": true};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Settings will be loaded from backend API in future update
    // For now, using local state
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Enable Notifications"),
            subtitle: const Text("Settings sync coming soon"),
            value: settings["notifications"] ?? true,
            onChanged: (v) {
              // TODO: Implement settings update API endpoint
              setState(() => settings["notifications"] = v);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings saved locally")),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Note: Settings sync with backend coming in next update",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
