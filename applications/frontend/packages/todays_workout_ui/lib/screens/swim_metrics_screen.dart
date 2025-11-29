import 'package:flutter/material.dart';

class SwimMetricsScreen extends StatefulWidget {
  final String userId;

  const SwimMetricsScreen({super.key, required this.userId});

  @override
  State<SwimMetricsScreen> createState() => _SwimMetricsScreenState();
}

class _SwimMetricsScreenState extends State<SwimMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  
  final _distanceController = TextEditingController();
  final _avgPaceController = TextEditingController();
  final _strokeRateController = TextEditingController();
  
  String _waterType = 'pool';

  @override
  void dispose() {
    _distanceController.dispose();
    _avgPaceController.dispose();
    _strokeRateController.dispose();
    super.dispose();
  }

  String _formatPace() {
    final paceSeconds = double.tryParse(_avgPaceController.text);
    if (paceSeconds != null) {
      final minutes = (paceSeconds / 60).floor();
      final seconds = (paceSeconds % 60).round();
      return '${minutes}:${seconds.toString().padLeft(2, '0')} / 100m';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swim Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text('${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Pool'),
                      value: 'pool',
                      groupValue: _waterType,
                      onChanged: (val) => setState(() => _waterType = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Open Water'),
                      value: 'open_water',
                      groupValue: _waterType,
                      onChanged: (val) => setState(() => _waterType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Distance (meters)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., 1000 for 1km',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _avgPaceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Average Pace (seconds per 100m)',
                  border: const OutlineInputBorder(),
                  helperText: _formatPace(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _strokeRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stroke Rate (strokes per minute)',
                  helperText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 20),

              if (_distanceController.text.isNotEmpty && _avgPaceController.text.isNotEmpty)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Workout Summary', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Distance', style: TextStyle(fontSize: 11)),
                                Text('${double.tryParse(_distanceController.text)?.toStringAsFixed(0) ?? '0'}m', 
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pace', style: TextStyle(fontSize: 11)),
                                Text(_formatPace(), 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Time', style: TextStyle(fontSize: 11)),
                                Text(_calculateTotalTime(), 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveMetrics,
                  icon: const Icon(Icons.save),
                  label: const Text('Log Swim'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateTotalTime() {
    final distance = double.tryParse(_distanceController.text);
    final pace = double.tryParse(_avgPaceController.text);
    if (distance != null && pace != null) {
      final totalSeconds = (distance / 100) * pace;
      final minutes = (totalSeconds / 60).floor();
      final seconds = (totalSeconds % 60).round();
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
    return '0:00';
  }

  void _saveMetrics() {
    if (_formKey.currentState!.validate()) {
      final metrics = {
        'user_id': widget.userId,
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'distance_meters': double.parse(_distanceController.text),
        'avg_pace_seconds': double.parse(_avgPaceController.text),
        'stroke_rate': _strokeRateController.text.isNotEmpty ? double.tryParse(_strokeRateController.text) : null,
        'water_type': _waterType,
      };
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Swim logged successfully!')),
      );
      
      print('Logging swim: $metrics');
      
      _distanceController.clear();
      _avgPaceController.clear();
      _strokeRateController.clear();
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Recent Swims', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.pool),
                      title: Text('${1000 + index * 200}m swim'),
                      subtitle: Text('1:${45 + index * 2}/100m • ${20 + index} min'),
                      trailing: Text('11/${15 - index}/2025', style: const TextStyle(fontSize: 11)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
