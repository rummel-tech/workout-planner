import 'package:flutter/material.dart';

class StrengthMetricsScreen extends StatefulWidget {
  final String userId;

  const StrengthMetricsScreen({super.key, required this.userId});

  @override
  State<StrengthMetricsScreen> createState() => _StrengthMetricsScreenState();
}

class _StrengthMetricsScreenState extends State<StrengthMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  
  String _liftType = 'squat';
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setNumberController = TextEditingController();
  final _velocityController = TextEditingController();
  
  final List<String> _liftTypes = [
    'squat',
    'bench_press',
    'deadlift',
    'overhead_press',
    'front_squat',
    'power_clean',
    'snatch',
    'row',
    'pull_up',
  ];

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _setNumberController.dispose();
    _velocityController.dispose();
    super.dispose();
  }

  double? _calculate1RM() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    if (weight != null && reps != null && reps > 0) {
      // Epley formula: 1RM = weight × (1 + reps/30)
      return weight * (1 + reps / 30);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final estimated1RM = _calculate1RM();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strength Metrics'),
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

              DropdownButtonFormField<String>(
                value: _liftType,
                decoration: const InputDecoration(
                  labelText: 'Lift Type',
                  border: OutlineInputBorder(),
                ),
                items: _liftTypes.map((lift) => DropdownMenuItem(
                  value: lift,
                  child: Text(lift.replaceAll('_', ' ').toUpperCase()),
                )).toList(),
                onChanged: (val) => setState(() => _liftType = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _setNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Set Number',
                  helperText: 'Which set in your workout (1, 2, 3...)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _velocityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bar Velocity (m/s)',
                  helperText: 'Optional - if using velocity tracker',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 20),

              if (estimated1RM != null)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate, color: Colors.blue),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated 1RM', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('${estimated1RM.toStringAsFixed(1)} kg', 
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
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
                  label: const Text('Log Set'),
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

  void _saveMetrics() {
    if (_formKey.currentState!.validate()) {
      final metrics = {
        'user_id': widget.userId,
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'lift': _liftType,
        'weight': double.parse(_weightController.text),
        'reps': int.parse(_repsController.text),
        'set_number': int.parse(_setNumberController.text),
        'estimated_1rm': _calculate1RM(),
        'velocity_m_per_s': _velocityController.text.isNotEmpty ? double.tryParse(_velocityController.text) : null,
      };
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set logged successfully!')),
      );

      // Clear form for next set
      _setNumberController.text = (int.parse(_setNumberController.text) + 1).toString();
      _weightController.clear();
      _repsController.clear();
      _velocityController.clear();
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Recent Lifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text('SQUAT - ${120 + index * 5} kg × ${8 - index}'),
                      subtitle: Text('Set ${index + 1} • Est 1RM: ${(120 + index * 5) * 1.25} kg'),
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
