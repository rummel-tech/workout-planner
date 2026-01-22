import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Profile data will be loaded from backend API in future update
    // For now, user can enter data locally
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: "Age")),
          TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: "Weight (lbs)")),
          TextField(controller: heightCtrl, decoration: const InputDecoration(labelText: "Height (in)")),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement profile update API endpoint
              // Will be connected to /auth/profile PUT endpoint
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile updates coming soon")),
              );
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
          const SizedBox(height: 20),
          Text(
            "Note: Profile sync with backend coming in next update",
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
