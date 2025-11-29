import 'package:flutter/material.dart';
import 'package:home_dashboard_ui/services/theme_controller.dart';
import 'package:home_dashboard_ui/services/theme_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeController? themeController;
  final String? healthError;
  final String? syncError;
  const ProfileScreen({
    super.key,
    this.themeController,
    this.healthError,
    this.syncError,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final _themeSvc = ThemeConfigService();
  bool _loading = true;
  bool _saving = false;
  String _themeMode = 'light';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cfg = await _themeSvc.load();

    setState(() {
      nameCtrl.text = prefs.getString('profile_name') ?? 'Your Name';
      ageCtrl.text = prefs.getString('profile_age') ?? '30';
      weightCtrl.text = prefs.getString('profile_weight') ?? '200';
      heightCtrl.text = prefs.getString('profile_height') ?? '70';
      _themeMode = cfg.mode;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', nameCtrl.text);
      await prefs.setString('profile_age', ageCtrl.text);
      await prefs.setString('profile_weight', weightCtrl.text);
      await prefs.setString('profile_height', heightCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _toggleTheme() async {
    final newMode = _themeMode == 'light' ? 'dark' : 'light';
    setState(() => _themeMode = newMode);

    if (widget.themeController != null) {
      final cfg = await _themeSvc.load();
      final newCfg = ThemeConfig(seedColor: cfg.seedColor, mode: newMode);
      await _themeSvc.save(newCfg);
      await widget.themeController!.apply(newCfg);
    }
  }

  Widget _buildDiagnosticsCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Health Data Issues Detected',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.healthError != null) ...[
              const Text('Health Error:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  widget.healthError!,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.syncError != null) ...[
              const Text('Sync Error:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  widget.syncError!,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 8),
            const Text('Common Causes & Solutions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _buildSolutionItem(
              '1. Permissions Not Granted',
              'Grant health data permissions in your device settings',
            ),
            _buildSolutionItem(
              '2. Health App Not Configured',
              'Ensure health tracking app (Apple Health/Google Fit) is set up',
            ),
            _buildSolutionItem(
              '3. Backend API Unavailable',
              'Check network connection and backend server status',
            ),
            _buildSolutionItem(
              '4. Browser Limitations',
              'Health data access may be limited in web browsers. Try mobile app.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Try pulling down on the home screen to manually sync health data.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionItem(String cause, String solution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cause, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(solution, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile & Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Personal Info",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: "Name",
              border: OutlineInputBorder(),
            ),
            enabled: !_saving,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ageCtrl,
            decoration: const InputDecoration(
              labelText: "Age",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_saving,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: weightCtrl,
            decoration: const InputDecoration(
              labelText: "Weight (lbs)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_saving,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: heightCtrl,
            decoration: const InputDecoration(
              labelText: "Height (inches)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: !_saving,
          ),
          const SizedBox(height: 32),
          const Text("Appearance",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text("Dark Mode"),
              subtitle: const Text("Toggle dark/light theme"),
              value: _themeMode == 'dark',
              onChanged: _saving ? null : (_) => _toggleTheme(),
              secondary: Icon(_themeMode == 'dark' ? Icons.dark_mode : Icons.light_mode),
            ),
          ),
          if (widget.healthError != null || widget.syncError != null) ...[
            const SizedBox(height: 32),
            const Text("Diagnostics",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDiagnosticsCard(),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _saving ? null : _saveProfile,
            icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
            label: Text(_saving ? "Saving..." : "Save"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          )
        ],
      ),
    );
  }
}
