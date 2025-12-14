import 'package:flutter/material.dart';

class HealthMetricsScreen extends StatefulWidget {
  final String userId;

  const HealthMetricsScreen({super.key, required this.userId});

  @override
  State<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends State<HealthMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  
  final _hrvController = TextEditingController();
  final _restingHrController = TextEditingController();
  final _vo2maxController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _weightKgController = TextEditingController();
  
  int _rpe = 5;
  int _soreness = 5;
  int _mood = 5;

  @override
  void dispose() {
    _hrvController.dispose();
    _restingHrController.dispose();
    _vo2maxController.dispose();
    _sleepHoursController.dispose();
    _weightKgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Health Metrics'),
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
              // Date picker
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

              // Physical Metrics Section
              Text('Physical Metrics', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _hrvController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'HRV (ms)',
                  helperText: 'Heart Rate Variability',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _restingHrController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Resting Heart Rate (bpm)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _vo2maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'VO2 Max (ml/kg/min)',
                  helperText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _sleepHoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sleep Hours',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Invalid number' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _weightKgController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  helperText: 'Optional',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 24),

              // Subjective Metrics Section
              Text('Subjective Ratings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              
              _buildSlider(
                'Rate of Perceived Exertion (RPE)',
                _rpe,
                (val) => setState(() => _rpe = val.round()),
                'How hard did yesterday feel?',
              ),
              
              _buildSlider(
                'Soreness',
                _soreness,
                (val) => setState(() => _soreness = val.round()),
                'Overall muscle soreness',
              ),
              
              _buildSlider(
                'Mood',
                _mood,
                (val) => setState(() => _mood = val.round()),
                'Overall mood and energy',
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveMetrics,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Metrics'),
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

  Widget _buildSlider(String label, int value, ValueChanged<double> onChanged, String helperText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(helperText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Row(
          children: [
            const Text('1'),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: value.toString(),
                onChanged: onChanged,
              ),
            ),
            const Text('10'),
            const SizedBox(width: 12),
            Container(
              width: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _saveMetrics() {
    if (_formKey.currentState!.validate()) {
      // TODO: Call API to save metrics
      final metrics = {
        'user_id': widget.userId,
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'hrv_ms': _hrvController.text.isNotEmpty ? double.tryParse(_hrvController.text) : null,
        'resting_hr': _restingHrController.text.isNotEmpty ? int.tryParse(_restingHrController.text) : null,
        'vo2max': _vo2maxController.text.isNotEmpty ? double.tryParse(_vo2maxController.text) : null,
        'sleep_hours': _sleepHoursController.text.isNotEmpty ? double.tryParse(_sleepHoursController.text) : null,
        'weight_kg': _weightKgController.text.isNotEmpty ? double.tryParse(_weightKgController.text) : null,
        'rpe': _rpe,
        'soreness': _soreness,
        'mood': _mood,
      };
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health metrics saved!')),
      );
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Health Metrics History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().subtract(Duration(days: index));
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${date.day}')),
                      title: Text('${date.month}/${date.day}/${date.year}'),
                      subtitle: const Text('HRV: 45ms • Sleep: 7.5h • RPE: 6'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Load metrics for this date
                      },
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
