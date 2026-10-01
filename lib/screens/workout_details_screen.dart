import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';

const List<String> _workoutCategories = <String>[
  'Chest',
  'Back',
  'Shoulder',
  'Legs',
  'Arms',
  'Others',
];

class WorkoutDetailsScreen extends StatefulWidget {
  const WorkoutDetailsScreen({super.key});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  late TextEditingController _customHeadingController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  late WorkoutTime _selectedTime;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final workoutProvider = context.read<WorkoutProvider>();
    final selectedWorkout = workoutProvider.selectedWorkout;
    final workoutTitle = selectedWorkout?.title.trim() ?? '';

    if (selectedWorkout == null || workoutTitle.isEmpty) {
      _selectedCategory = 'Chest';
    } else {
      _selectedCategory = _workoutCategories.firstWhere(
        (category) =>
            category.toLowerCase() != 'others' &&
            category.toLowerCase() == workoutTitle.toLowerCase(),
        orElse: () => 'Others',
      );
    }

    _customHeadingController = TextEditingController(
      text: _selectedCategory == 'Others' ? selectedWorkout?.title ?? '' : '',
    );
    _notesController = TextEditingController(
      text: selectedWorkout?.notes ?? '',
    );
    _selectedTime = selectedWorkout?.timeOfDay ?? WorkoutTime.morning;

    // Listen for text changes to track if there are unsaved changes
    _customHeadingController.addListener(_onTextChanged);
    _notesController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null || newCategory == _selectedCategory) return;

    setState(() {
      _selectedCategory = newCategory;
      _hasChanges = true;
    });
  }

  void _onTimeChanged(WorkoutTime newTime) {
    if (newTime != _selectedTime) {
      setState(() {
        _selectedTime = newTime;
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _customHeadingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCancel() {
    if (_hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    final title = _selectedCategory == 'Others'
        ? _customHeadingController.text.trim()
        : _capitalize(_selectedCategory);
    final notes = _notesController.text;

    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a heading for the workout'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final workoutProvider = context.read<WorkoutProvider>();
    await workoutProvider.saveWorkout(
      title: title,
      notes: notes,
      timeOfDay: _selectedTime,
    );

    if (mounted) {
      if (workoutProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(workoutProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _categoryLabel(String value) {
    return value == 'Others' ? 'Others' : _capitalize(value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onCancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workout Details'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onCancel,
            tooltip: 'Cancel',
          ),
          elevation: 0,
        ),
        body: Consumer<WorkoutProvider>(
          builder: (context, workoutProvider, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${workoutProvider.selectedDate.day}/${workoutProvider.selectedDate.month}/${workoutProvider.selectedDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Heading/Title Input
                      Text(
                        'Heading/Title',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        items: _workoutCategories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(_categoryLabel(category)),
                              ),
                            )
                            .toList(),
                        onChanged: _onCategoryChanged,
                      ),
                      if (_selectedCategory == 'Others') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customHeadingController,
                          decoration: InputDecoration(
                            hintText: 'Enter custom heading/title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          maxLength: 100,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Time of Day Selector
                      Text(
                        'Time of Day',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<WorkoutTime>(
                        segments: const <ButtonSegment<WorkoutTime>>[
                          ButtonSegment<WorkoutTime>(
                            value: WorkoutTime.morning,
                            label: Text('Morning'),
                            icon: Icon(Icons.wb_sunny),
                          ),
                          ButtonSegment<WorkoutTime>(
                            value: WorkoutTime.evening,
                            label: Text('Evening'),
                            icon: Icon(Icons.nights_stay),
                          ),
                        ],
                        selected: <WorkoutTime>{_selectedTime},
                        onSelectionChanged: (Set<WorkoutTime> newSelection) {
                          _onTimeChanged(newSelection.first);
                        },
                      ),
                      const SizedBox(height: 10),
                      // Detailed Notes Input
                      Text(
                        'Workout Notes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: TextField(
                          controller: _notesController,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: 'Enter your workout details, exercises, reps, sets, etc.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Loading indicator
                      if (workoutProvider.isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else
                        const SizedBox.shrink(),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            );
          },
        ),
        bottomNavigationBar: Consumer<WorkoutProvider>(
          builder: (context, workoutProvider, child) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 36,
                left: 12,
                right: 12,
                top: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: workoutProvider.isLoading ? null : _onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: workoutProvider.isLoading ? null : _onSave,
                      child: workoutProvider.isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}



