import 'package:flutter/material.dart';
import '../../services/user_sync_service.dart';

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

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final data = await UserSyncService().fetchUserProfile();
    if (data != null) {
      nameCtrl.text = data["name"] ?? "";
      ageCtrl.text = (data["age"] ?? "").toString();
      weightCtrl.text = (data["weight_lbs"] ?? "").toString();
      heightCtrl.text = (data["height_in"] ?? "").toString();
    }
    setState(() => loading = false);
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
              UserSyncService().updateUserProfile({
                "name": nameCtrl.text,
                "age": int.tryParse(ageCtrl.text),
                "weight_lbs": double.tryParse(weightCtrl.text),
                "height_in": double.tryParse(heightCtrl.text),
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}
