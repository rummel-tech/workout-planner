import 'package:flutter/material.dart';
import '../services/metrics_api_service.dart';

class SwimMetricsScreen extends StatefulWidget {
  final String userId;

  const SwimMetricsScreen({super.key, required this.userId});

  @override
  State<SwimMetricsScreen> createState() => _SwimMetricsScreenState();
}

class _SwimMetricsScreenState extends State<SwimMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _metricsApi = MetricsApiService();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingHistory = false;
  List<SwimMetrics> _historyMetrics = [];

  final _distanceController = TextEditingController();
  final _avgPaceController = TextEditingController();
  final _strokeRateController = TextEditingController();

  String _waterType = SwimMetrics.waterTypePool;

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
      return SwimMetrics.formatPace(paceSeconds);
    }
    return '';
  }

  String _calculateTotalTime() {
    final distance = double.tryParse(_distanceController.text);
    final pace = double.tryParse(_avgPaceController.text);
    if (distance != null && pace != null) {
      final totalSeconds = SwimMetrics.calculateDuration(distance, pace);
      return SwimMetrics.formatDuration(totalSeconds);
    }
    return '0:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Swim'),
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
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Pool'),
                      value: SwimMetrics.waterTypePool,
                      groupValue: _waterType,
                      onChanged: (val) => setState(() => _waterType = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Open Water'),
                      value: SwimMetrics.waterTypeOpenWater,
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
                onChanged: (_) => setState(() {}),
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
              if (_distanceController.text.isNotEmpty &&
                  _avgPaceController.text.isNotEmpty)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workout Summary',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.7))),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Distance',
                                    style: TextStyle(fontSize: 11)),
                                Text(
                                    '${double.tryParse(_distanceController.text)?.toStringAsFixed(0) ?? '0'}m',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pace',
                                    style: TextStyle(fontSize: 11)),
                                Text(_formatPace(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Time',
                                    style: TextStyle(fontSize: 11)),
                                Text(_calculateTotalTime(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer)),
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
                  onPressed: _isSaving ? null : _saveMetrics,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Log Swim'),
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
      final distance = double.parse(_distanceController.text);
      final pace = double.parse(_avgPaceController.text);
      final duration = SwimMetrics.calculateDuration(distance, pace);

      final metrics = SwimMetrics(
        userId: widget.userId,
        date: _selectedDate,
        distanceMeters: distance,
        durationSeconds: duration,
        avgPaceSeconds: pace,
        waterType: _waterType,
        strokeRate: _strokeRateController.text.isNotEmpty
            ? double.tryParse(_strokeRateController.text)
            : null,
      );

      await _metricsApi.logSwim(metrics);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Logged ${distance.toStringAsFixed(0)}m swim - ${SwimMetrics.formatDuration(duration)}'),
          ),
        );

        _distanceController.clear();
        _avgPaceController.clear();
        _strokeRateController.clear();
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
      final metrics = await _metricsApi.getSwimMetrics(widget.userId);
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
              const Text('Recent Swims',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: _historyMetrics.isEmpty
                    ? const Center(child: Text('No swim metrics recorded yet'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _historyMetrics.length,
                        itemBuilder: (context, index) {
                          final m = _historyMetrics[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.pool),
                              title: Text(
                                  '${m.distanceMeters.toStringAsFixed(0)}m swim'),
                              subtitle: Text(
                                  '${m.paceDisplay} - ${m.durationDisplay}'),
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

  void _loadMetricsEntry(SwimMetrics m) {
    setState(() {
      _selectedDate = m.date;
      _distanceController.text = m.distanceMeters.toStringAsFixed(0);
      _avgPaceController.text = m.avgPaceSeconds.toStringAsFixed(0);
      _waterType = m.waterType;
      if (m.strokeRate != null) {
        _strokeRateController.text = m.strokeRate.toString();
      }
    });
    Navigator.pop(context);
  }
}
