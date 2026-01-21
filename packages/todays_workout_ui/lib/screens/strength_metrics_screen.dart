import 'package:flutter/material.dart';
import '../services/metrics_api_service.dart';

class StrengthMetricsScreen extends StatefulWidget {
  final String userId;

  const StrengthMetricsScreen({super.key, required this.userId});

  @override
  State<StrengthMetricsScreen> createState() => _StrengthMetricsScreenState();
}

class _StrengthMetricsScreenState extends State<StrengthMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _metricsApi = MetricsApiService();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingHistory = false;
  List<StrengthMetrics> _historyMetrics = [];

  String _liftType = 'squat';
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setNumberController = TextEditingController(text: '1');
  final _velocityController = TextEditingController();

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
      return StrengthMetrics.calculate1RM(weight, reps);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final estimated1RM = _calculate1RM();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Strength'),
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
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                      '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}'),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
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
                items: StrengthMetrics.liftTypes
                    .map((lift) => DropdownMenuItem(
                          value: lift,
                          child: Text(StrengthMetrics.liftDisplayName(lift)),
                        ))
                    .toList(),
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
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.calculate,
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimated 1RM',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withOpacity(0.7))),
                            Text('${estimated1RM.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer)),
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
                  onPressed: _isSaving ? null : _saveMetrics,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Log Set'),
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

  Future<void> _saveMetrics() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final metrics = StrengthMetrics(
        userId: widget.userId,
        date: _selectedDate,
        lift: _liftType,
        weight: double.parse(_weightController.text),
        reps: int.parse(_repsController.text),
        setNumber: int.parse(_setNumberController.text),
        velocityMPerS: _velocityController.text.isNotEmpty
            ? double.tryParse(_velocityController.text)
            : null,
      );

      await _metricsApi.logStrengthSet(metrics);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Logged ${StrengthMetrics.liftDisplayName(_liftType)} - Set ${metrics.setNumber}'),
          ),
        );

        // Increment set number for next entry
        final nextSet = int.parse(_setNumberController.text) + 1;
        _setNumberController.text = nextSet.toString();
        _weightController.clear();
        _repsController.clear();
        _velocityController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to save: ${e.toString().replaceAll('Exception: ', '')}'),
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
      final metrics = await _metricsApi.getStrengthMetrics(widget.userId);
      setState(() {
        _historyMetrics = metrics;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to load history: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

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
              const Text('Recent Lifts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: _historyMetrics.isEmpty
                    ? const Center(child: Text('No strength metrics recorded yet'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _historyMetrics.length,
                        itemBuilder: (context, index) {
                          final m = _historyMetrics[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.fitness_center),
                              title: Text(
                                  '${StrengthMetrics.liftDisplayName(m.lift)} - ${m.weight}kg x ${m.reps}'),
                              subtitle: Text(
                                  'Set ${m.setNumber} - Est 1RM: ${m.estimated1rmDisplay}'),
                              trailing: Text(
                                '${m.date.month}/${m.date.day}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () => _loadMetricsEntry(m),
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

  void _loadMetricsEntry(StrengthMetrics m) {
    setState(() {
      _selectedDate = m.date;
      _liftType = m.lift;
      _weightController.text = m.weight.toString();
      _repsController.text = m.reps.toString();
      _setNumberController.text = m.setNumber.toString();
      if (m.velocityMPerS != null) {
        _velocityController.text = m.velocityMPerS.toString();
      }
    });
    Navigator.pop(context);
  }
}
