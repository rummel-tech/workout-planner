import 'package:flutter/material.dart';

class TodaysWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Function(Map<String, dynamic>)? onSave;

  const TodaysWorkoutScreen({super.key, required this.plan, this.onSave});

  @override
  State<TodaysWorkoutScreen> createState() => _TodaysWorkoutScreenState();
}

class _TodaysWorkoutScreenState extends State<TodaysWorkoutScreen> {
  bool _isEditing = false;
  late List<String> _warmup;
  late List<String> _main;
  late List<String> _cooldown;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _warmup = List<String>.from((widget.plan['warmup'] ?? []).map((e) => e.toString()));
    _main = List<String>.from((widget.plan['main'] ?? []).map((e) => e.toString()));
    _cooldown = List<String>.from((widget.plan['cooldown'] ?? []).map((e) => e.toString()));
    _notesController = TextEditingController(text: widget.plan['notes'] ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    final updatedPlan = {
      'warmup': _warmup,
      'main': _main,
      'cooldown': _cooldown,
      'notes': _notesController.text,
      'status': widget.plan['status'] ?? 'pending',
    };

    try {
      if (widget.onSave != null) {
        await widget.onSave!(updatedPlan);
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addItem(List<String> list) {
    setState(() {
      list.add('');
    });
  }

  void _removeItem(List<String> list, int index) {
    setState(() {
      list.removeAt(index);
    });
  }

  void _updateItem(List<String> list, int index, String value) {
    setState(() {
      list[index] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Workout"),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _warmup = List<String>.from((widget.plan['warmup'] ?? []).map((e) => e.toString()));
                    _main = List<String>.from((widget.plan['main'] ?? []).map((e) => e.toString()));
                    _cooldown = List<String>.from((widget.plan['cooldown'] ?? []).map((e) => e.toString()));
                    _notesController.text = widget.plan['notes'] ?? '';
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Save',
                onPressed: _saveChanges,
              ),
            ],
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection("Warmup", _warmup),
          _buildSection("Main Set", _main),
          _buildSection("Cooldown", _cooldown),
          _sectionTitle("Notes"),
          if (_isEditing)
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add notes about today\'s workout...',
              ),
            )
          else if (_notesController.text.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _notesController.text,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_isEditing) ...[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addItem(_getListForSection(title)),
                tooltip: 'Add item',
              ),
            ],
          ],
        ),
      );

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        ...List.generate(items.length, (index) {
          if (_isEditing) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: items[index])
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: items[index].length),
                          ),
                        onChanged: (value) => _updateItem(items, index, value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Exercise description...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeItem(items, index),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  items[index],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }
        }),
      ],
    );
  }

  List<String> _getListForSection(String title) {
    if (title.contains('Warmup')) return _warmup;
    if (title.contains('Main')) return _main;
    if (title.contains('Cooldown')) return _cooldown;
    return [];
  }
}
