import 'package:flutter/material.dart';
import 'package:home_dashboard_ui/services/theme_controller.dart';
import 'package:home_dashboard_ui/services/theme_config_service.dart';
import 'package:home_dashboard_ui/services/secure_config_service.dart';
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
  final _secureConfig = SecureConfigService();
  bool _loading = true;
  bool _saving = false;
  String _themeMode = 'light';

  // Secure config state
  String? _apiBaseUrl;
  String? _aiProvider;
  String? _maskedOpenAiKey;
  String? _maskedAnthropicKey;
  bool _healthKitEnabled = false;
  DateTime? _configuredAt;

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

    // Load secure config
    final apiUrl = await _secureConfig.getApiBaseUrl();
    final aiProvider = await _secureConfig.getAiProvider();
    final openAiKey = await _secureConfig.getOpenAiApiKey();
    final anthropicKey = await _secureConfig.getAnthropicApiKey();
    final healthKitEnabled = await _secureConfig.isHealthKitEnabled();
    final configuredAt = await _secureConfig.getConfiguredAt();

    setState(() {
      nameCtrl.text = prefs.getString('profile_name') ?? 'Your Name';
      ageCtrl.text = prefs.getString('profile_age') ?? '30';
      weightCtrl.text = prefs.getString('profile_weight') ?? '200';
      heightCtrl.text = prefs.getString('profile_height') ?? '70';
      _themeMode = cfg.mode;
      _apiBaseUrl = apiUrl;
      _aiProvider = aiProvider;
      _maskedOpenAiKey = _secureConfig.maskApiKey(openAiKey);
      _maskedAnthropicKey = _secureConfig.maskApiKey(anthropicKey);
      _healthKitEnabled = healthKitEnabled;
      _configuredAt = configuredAt;
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

  void _showEditApiUrlDialog() {
    final controller = TextEditingController(text: _apiBaseUrl ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit API Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Base URL',
            hintText: 'https://your-server.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty && _secureConfig.isValidApiUrl(url)) {
                await _secureConfig.setApiBaseUrl(url);
                setState(() => _apiBaseUrl = url);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API URL updated. Restart app to apply.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid URL format'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditApiKeyDialog(String provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${provider == 'openai' ? 'OpenAI' : 'Anthropic'} API Key'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: provider == 'openai' ? 'sk-...' : 'sk-ant-...',
            border: const OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                if (provider == 'openai') {
                  await _secureConfig.setOpenAiApiKey(key);
                  setState(() => _maskedOpenAiKey = _secureConfig.maskApiKey(key));
                } else {
                  await _secureConfig.setAnthropicApiKey(key);
                  setState(() => _maskedAnthropicKey = _secureConfig.maskApiKey(key));
                }
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API Key updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeAiProvider(String? provider) async {
    if (provider != null) {
      await _secureConfig.setAiProvider(provider);
      setState(() => _aiProvider = provider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Provider changed to ${provider == 'openai' ? 'OpenAI' : 'Anthropic'}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleHealthKit(bool enabled) async {
    await _secureConfig.setHealthKitEnabled(enabled);
    setState(() => _healthKitEnabled = enabled);
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server Configuration
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns),
              title: const Text('API Server'),
              subtitle: Text(_apiBaseUrl ?? 'Not configured'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _showEditApiUrlDialog,
              ),
            ),
            const Divider(),

            // AI Provider Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.psychology),
              title: const Text('AI Provider'),
              subtitle: Text(_aiProvider == 'anthropic' ? 'Anthropic Claude' : 'OpenAI'),
              trailing: DropdownButton<String>(
                value: _aiProvider ?? 'openai',
                items: const [
                  DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                  DropdownMenuItem(value: 'anthropic', child: Text('Anthropic')),
                ],
                onChanged: _changeAiProvider,
              ),
            ),
            const Divider(),

            // OpenAI API Key
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.key),
              title: const Text('OpenAI API Key'),
              subtitle: Text(_maskedOpenAiKey ?? 'Not configured'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditApiKeyDialog('openai'),
              ),
            ),

            // Anthropic API Key
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.key),
              title: const Text('Anthropic API Key'),
              subtitle: Text(_maskedAnthropicKey ?? 'Not configured'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditApiKeyDialog('anthropic'),
              ),
            ),
            const Divider(),

            // HealthKit Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.favorite),
              title: const Text('HealthKit Sync'),
              subtitle: const Text('Sync health data from Apple Health'),
              value: _healthKitEnabled,
              onChanged: _toggleHealthKit,
            ),

            // Configuration timestamp
            if (_configuredAt != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Last configured: ${_configuredAt!.toLocal().toString().split('.')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
          const SizedBox(height: 32),
          const Text("Configuration",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildConfigurationCard(),
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
