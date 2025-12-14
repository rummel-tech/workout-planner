import 'package:flutter/material.dart';
import '../../services/user_sync_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool enabled = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await UserSyncService().fetchSettings();
    enabled = s?["notifications"] ?? true;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Notification Settings")),
      body: SwitchListTile(
        title: const Text("Enable Notifications"),
        value: enabled,
        onChanged: (v) {
          setState(() => enabled = v);
          UserSyncService().updateSettings({"notifications": v});
        },
      ),
    );
  }
}
