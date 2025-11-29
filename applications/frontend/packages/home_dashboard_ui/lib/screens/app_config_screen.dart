import 'package:flutter/material.dart';
import '../services/theme_config_service.dart';
import '../services/theme_controller.dart';

class AppConfigScreen extends StatefulWidget {
  final ThemeController controller;
  const AppConfigScreen({super.key, required this.controller});

  @override
  State<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends State<AppConfigScreen> {
  final _svc = ThemeConfigService();
  int _seed = 0xFF2196F3;
  String _mode = 'light';
  bool _loading = true;

  @override
  void initState(){
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cfg = await _svc.load();
    setState((){ _seed = cfg.seedColor; _mode = cfg.mode; _loading = false; });
  }

  Future<void> _save() async {
    final cfg = ThemeConfig(seedColor: _seed, mode: _mode);
    await _svc.save(cfg);
    await widget.controller.apply(cfg);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = ThemeController.buildTheme(_seed, dark: _mode=='dark');
    final swatches = <int>[
      0xFF3B82F6, // blue-500
      0xFF22C55E, // emerald-500
      0xFFF97316, // orange-500
      0xFFE11D48, // rose-600
      0xFF8B5CF6, // violet-500
      0xFF06B6D4, // cyan-500
      0xFF10B981, // green-500
      0xFFF43F5E, // red-500
      0xFFF59E0B, // amber-500
      0xFF0EA5E9, // sky-500
    ];

    return Theme(data: theme, child: Scaffold(
      appBar: AppBar(title: const Text('App Theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Primary Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              for (final c in swatches)
                GestureDetector(
                  onTap: ()=> setState(()=> _seed = c),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: _seed==c ? Colors.black : Colors.transparent, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {_mode},
            onSelectionChanged: (s)=> setState(()=> _mode = s.first),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  TextField(decoration: InputDecoration(labelText: 'Text Field')),
                  SizedBox(height: 12),
                  Wrap(spacing: 8, children: [
                    Chip(label: Text('Chip')),
                    Chip(label: Text('Selected'), avatar: Icon(Icons.check)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save & Apply'),
          ),
        ),
      ),
    ));
  }
}
