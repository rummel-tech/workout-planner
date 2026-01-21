import 'package:flutter/material.dart';
import 'package:health_integration/services/health_api_service.dart';

class HealthMetricsScreen extends StatefulWidget {
  final String userId;

  const HealthMetricsScreen({super.key, required this.userId});

  @override
  State<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends State<HealthMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _healthApi = HealthApiService();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingHistory = false;
  List<HealthSample> _historySamples = [];

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
            icon: _isLoadingHistory
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.history),
            onPressed: _isLoadingHistory ? null : _showHistory,
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
                  onPressed: _isSaving ? null : _saveMetrics,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Metrics'),
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

  Future<void> _saveMetrics() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final samples = <HealthSample>[];
      final startTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      // Add physical metrics as health samples
      if (_hrvController.text.isNotEmpty) {
        final value = double.tryParse(_hrvController.text);
        if (value != null) {
          samples.add(HealthSample(
            userId: widget.userId,
            sampleType: HealthSample.typeHrv,
            value: value,
            unit: 'ms',
            startTime: startTime,
            sourceApp: 'workout_planner',
          ));
        }
      }

      if (_restingHrController.text.isNotEmpty) {
        final value = double.tryParse(_restingHrController.text);
        if (value != null) {
          samples.add(HealthSample(
            userId: widget.userId,
            sampleType: HealthSample.typeRestingHr,
            value: value,
            unit: 'bpm',
            startTime: startTime,
            sourceApp: 'workout_planner',
          ));
        }
      }

      if (_vo2maxController.text.isNotEmpty) {
        final value = double.tryParse(_vo2maxController.text);
        if (value != null) {
          samples.add(HealthSample(
            userId: widget.userId,
            sampleType: HealthSample.typeVo2max,
            value: value,
            unit: 'mL/kg/min',
            startTime: startTime,
            sourceApp: 'workout_planner',
          ));
        }
      }

      if (_sleepHoursController.text.isNotEmpty) {
        final value = double.tryParse(_sleepHoursController.text);
        if (value != null) {
          samples.add(HealthSample(
            userId: widget.userId,
            sampleType: HealthSample.typeSleepStage,
            value: value,
            unit: 'hours',
            startTime: startTime,
            sourceApp: 'workout_planner',
          ));
        }
      }

      if (_weightKgController.text.isNotEmpty) {
        final value = double.tryParse(_weightKgController.text);
        if (value != null) {
          samples.add(HealthSample(
            userId: widget.userId,
            sampleType: HealthSample.typeWeight,
            value: value,
            unit: 'kg',
            startTime: startTime,
            sourceApp: 'workout_planner',
          ));
        }
      }

      // Add subjective ratings
      samples.add(HealthSample(
        userId: widget.userId,
        sampleType: HealthSample.typeRpe,
        value: _rpe.toDouble(),
        unit: 'rating',
        startTime: startTime,
        sourceApp: 'workout_planner',
      ));

      samples.add(HealthSample(
        userId: widget.userId,
        sampleType: HealthSample.typeSoreness,
        value: _soreness.toDouble(),
        unit: 'rating',
        startTime: startTime,
        sourceApp: 'workout_planner',
      ));

      samples.add(HealthSample(
        userId: widget.userId,
        sampleType: HealthSample.typeMood,
        value: _mood.toDouble(),
        unit: 'rating',
        startTime: startTime,
        sourceApp: 'workout_planner',
      ));

      // Save to API
      final inserted = await _healthApi.ingestSamplesTyped(samples);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $inserted health metrics!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final samples = await _healthApi.listSamplesTyped(widget.userId, limit: 50);
      setState(() {
        _historySamples = samples;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Group samples by date
    final samplesByDate = <String, List<HealthSample>>{};
    for (final sample in _historySamples) {
      final dateKey = '${sample.startTime.year}-${sample.startTime.month.toString().padLeft(2, '0')}-${sample.startTime.day.toString().padLeft(2, '0')}';
      samplesByDate.putIfAbsent(dateKey, () => []).add(sample);
    }

    final sortedDates = samplesByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Health Metrics History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: sortedDates.isEmpty
                    ? const Center(child: Text('No health metrics recorded yet'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedDates[index];
                          final dateSamples = samplesByDate[dateKey]!;
                          final date = DateTime.parse(dateKey);

                          // Extract key metrics for display
                          final hrvList = dateSamples.where((s) => s.sampleType == HealthSample.typeHrv);
                          final hrv = hrvList.isEmpty ? null : hrvList.first;
                          final sleepList = dateSamples.where((s) => s.sampleType == HealthSample.typeSleepStage);
                          final sleep = sleepList.isEmpty ? null : sleepList.first;
                          final rpeList = dateSamples.where((s) => s.sampleType == HealthSample.typeRpe);
                          final rpe = rpeList.isEmpty ? null : rpeList.first;

                          final summaryParts = <String>[];
                          if (hrv != null) summaryParts.add('HRV: ${hrv.value.toStringAsFixed(0)}ms');
                          if (sleep != null) summaryParts.add('Sleep: ${sleep.value.toStringAsFixed(1)}h');
                          if (rpe != null) summaryParts.add('RPE: ${rpe.value.toStringAsFixed(0)}');

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Text('${date.day}')),
                              title: Text('${date.month}/${date.day}/${date.year}'),
                              subtitle: Text(summaryParts.isEmpty ? 'No data' : summaryParts.join(' • ')),
                              trailing: Text('${dateSamples.length} metrics', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              onTap: () => _loadMetricsForDate(date),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadMetricsForDate(DateTime date) {
    // Find samples for this date
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dateSamples = _historySamples.where((s) {
      final sampleDate = '${s.startTime.year}-${s.startTime.month.toString().padLeft(2, '0')}-${s.startTime.day.toString().padLeft(2, '0')}';
      return sampleDate == dateKey;
    }).toList();

    // Populate form fields
    setState(() {
      _selectedDate = date;

      for (final sample in dateSamples) {
        switch (sample.sampleType) {
          case HealthSample.typeHrv:
            _hrvController.text = sample.value.toStringAsFixed(0);
            break;
          case HealthSample.typeRestingHr:
            _restingHrController.text = sample.value.toStringAsFixed(0);
            break;
          case HealthSample.typeVo2max:
            _vo2maxController.text = sample.value.toStringAsFixed(1);
            break;
          case HealthSample.typeSleepStage:
            _sleepHoursController.text = sample.value.toStringAsFixed(1);
            break;
          case HealthSample.typeWeight:
            _weightKgController.text = sample.value.toStringAsFixed(1);
            break;
          case HealthSample.typeRpe:
            _rpe = sample.value.round();
            break;
          case HealthSample.typeSoreness:
            _soreness = sample.value.round();
            break;
          case HealthSample.typeMood:
            _mood = sample.value.round();
            break;
        }
      }
    });

    Navigator.pop(context); // Close bottom sheet
  }
}
