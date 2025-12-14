import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/secure_config_service.dart';
import '../services/api_config.dart';

/// Setup wizard for first-time app configuration.
/// Guides users through configuring API endpoint and optional settings.
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _configService = SecureConfigService();
  final _pageController = PageController();

  // Form controllers
  final _apiUrlController = TextEditingController();
  final _openAiKeyController = TextEditingController();
  final _anthropicKeyController = TextEditingController();

  // State
  int _currentPage = 0;
  bool _isTestingConnection = false;
  bool _connectionSuccess = false;
  String? _connectionError;
  String _selectedAiProvider = 'none';
  bool _enableHealthKit = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final apiUrl = await _configService.getApiBaseUrl();
    final aiProvider = await _configService.getAiProvider();
    final healthKit = await _configService.isHealthKitEnabled();

    if (apiUrl != null) {
      _apiUrlController.text = apiUrl;
    }
    if (aiProvider != null) {
      setState(() => _selectedAiProvider = aiProvider);
    }
    setState(() => _enableHealthKit = healthKit);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiUrlController.dispose();
    _openAiKeyController.dispose();
    _anthropicKeyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _testConnection() async {
    final url = _apiUrlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _connectionError = 'Please enter an API URL';
        _connectionSuccess = false;
      });
      return;
    }

    if (!_configService.isValidApiUrl(url)) {
      setState(() {
        _connectionError = 'Invalid URL format. Use http:// or https://';
        _connectionSuccess = false;
      });
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _connectionError = null;
      _connectionSuccess = false;
    });

    try {
      final success = await _configService.testApiConnection(url);
      setState(() {
        _isTestingConnection = false;
        _connectionSuccess = success;
        _connectionError = success ? null : 'Could not connect to server';
      });
    } catch (e) {
      setState(() {
        _isTestingConnection = false;
        _connectionSuccess = false;
        _connectionError = 'Connection failed: $e';
      });
    }
  }

  Future<void> _saveAndContinue() async {
    // Save API URL
    final url = _apiUrlController.text.trim();
    if (url.isNotEmpty) {
      await _configService.setApiBaseUrl(url);
      // Update the runtime API config
      ApiConfig.configure(baseUrl: url);
    }

    // Save AI provider settings
    if (_selectedAiProvider != 'none') {
      await _configService.setAiProvider(_selectedAiProvider);

      if (_selectedAiProvider == 'openai' && _openAiKeyController.text.isNotEmpty) {
        await _configService.setOpenAiApiKey(_openAiKeyController.text.trim());
      } else if (_selectedAiProvider == 'anthropic' && _anthropicKeyController.text.isNotEmpty) {
        await _configService.setAnthropicApiKey(_anthropicKeyController.text.trim());
      }
    }

    // Save HealthKit preference
    await _configService.setHealthKitEnabled(_enableHealthKit);

    // Navigate to home
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildServerConfigPage(),
                  _buildAiConfigPage(),
                  _buildHealthConfigPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 1: Welcome
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Workout Planner',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s set up your app for the best experience. This will only take a minute.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildFeatureItem(Icons.cloud, 'Connect to your server'),
          const SizedBox(height: 12),
          _buildFeatureItem(Icons.psychology, 'Configure AI coaching (optional)'),
          const SizedBox(height: 12),
          _buildFeatureItem(Icons.favorite, 'Enable health data sync (optional)'),
          const Spacer(),
          FilledButton(
            onPressed: _nextPage,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }

  // Page 2: Server Configuration
  Widget _buildServerConfigPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the URL of your Workout Planner backend server.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _apiUrlController,
            decoration: InputDecoration(
              labelText: 'API Server URL',
              hintText: 'https://api.example.com',
              prefixIcon: const Icon(Icons.cloud),
              border: const OutlineInputBorder(),
              helperText: 'Example: https://your-server.com or http://192.168.1.100:8000',
              errorText: _connectionError,
              suffixIcon: _connectionSuccess
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => setState(() {
              _connectionSuccess = false;
              _connectionError = null;
            }),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isTestingConnection ? null : _testConnection,
            icon: _isTestingConnection
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find),
            label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
          ),
          if (_connectionSuccess) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connection successful!',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_connectionError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _connectionError!,
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: Connection test may fail in browsers due to CORS restrictions. '
                    'You can still continue if you\'re sure the URL is correct.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              OutlinedButton(
                onPressed: _previousPage,
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _apiUrlController.text.isNotEmpty ? _nextPage : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Page 3: AI Configuration
  Widget _buildAiConfigPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Coach (Optional)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure an AI provider for personalized workout recommendations and coaching.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _buildProviderOption(
            'none',
            'Skip for now',
            'You can configure AI later in settings',
            Icons.skip_next,
          ),
          const SizedBox(height: 12),
          _buildProviderOption(
            'openai',
            'OpenAI (GPT)',
            'Use ChatGPT for AI coaching',
            Icons.auto_awesome,
          ),
          if (_selectedAiProvider == 'openai') ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: TextField(
                controller: _openAiKeyController,
                decoration: const InputDecoration(
                  labelText: 'OpenAI API Key',
                  hintText: 'sk-...',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autocorrect: false,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildProviderOption(
            'anthropic',
            'Anthropic (Claude)',
            'Use Claude for AI coaching',
            Icons.psychology,
          ),
          if (_selectedAiProvider == 'anthropic') ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: TextField(
                controller: _anthropicKeyController,
                decoration: const InputDecoration(
                  labelText: 'Anthropic API Key',
                  hintText: 'sk-ant-...',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autocorrect: false,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              OutlinedButton(
                onPressed: _previousPage,
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _nextPage,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderOption(String value, String title, String subtitle, IconData icon) {
    final isSelected = _selectedAiProvider == value;
    return InkWell(
      onTap: () => setState(() => _selectedAiProvider = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedAiProvider,
              onChanged: (v) => setState(() => _selectedAiProvider = v!),
            ),
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 4: Health Data Configuration
  Widget _buildHealthConfigPage() {
    final showHealthKit = !kIsWeb; // Only show on mobile platforms

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Data (Optional)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showHealthKit
                ? 'Sync your health data for personalized insights and readiness scores.'
                : 'Health data sync is available on mobile devices.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (showHealthKit) ...[
            SwitchListTile(
              title: const Text('Enable Health Data Sync'),
              subtitle: const Text('Connect to Apple Health or Google Fit'),
              secondary: const Icon(Icons.favorite),
              value: _enableHealthKit,
              onChanged: (value) => setState(() => _enableHealthKit = value),
            ),
            const SizedBox(height: 16),
            if (_enableHealthKit)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data we\'ll access:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _buildHealthDataItem('Workouts'),
                    _buildHealthDataItem('Heart Rate'),
                    _buildHealthDataItem('HRV (Heart Rate Variability)'),
                    _buildHealthDataItem('Sleep Analysis'),
                    _buildHealthDataItem('Steps'),
                    _buildHealthDataItem('Active Energy'),
                  ],
                ),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Download the mobile app to sync health data from Apple Health or Google Fit.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'re all set!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can change these settings anytime in the app.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: _previousPage,
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saveAndContinue,
                  child: const Text('Finish Setup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDataItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
