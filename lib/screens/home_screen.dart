import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
import '../utils/category_colors.dart';
import 'workout_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = Workout.normalizeDate(DateTime.now());
    _selectedDay = _focusedDay;

    // Initialize provider and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider = context.read<WorkoutProvider>();
      workoutProvider.initialize().then((_) {
        if (mounted) {
          workoutProvider.setSelectedDate(_selectedDay);
        }
      });
    });
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted || authProvider.errorMessage == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage!),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showDeleteConfirmationDialog({required int workoutId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteWorkout(workoutId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorkout(int workoutId) async {
    final workoutProvider = context.read<WorkoutProvider>();
    await workoutProvider.deleteWorkout(workoutId);

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
            content: Text('Workout deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _onDateSelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Load workouts for selected date
    context.read<WorkoutProvider>().setSelectedDate(selectedDay);
  }

  void _openWorkoutDetailsScreen(Workout workout) async {
    final workoutProvider = context.read<WorkoutProvider>();
    workoutProvider.setSelectedDate(workout.date);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WorkoutDetailsScreen(),
        ),
      ).then((_) async {
        // Reload workouts after returning from details screen
        if (mounted) {
          await workoutProvider.loadAllWorkouts();
        }
      });
    }
  }

  void _startNewWorkout() async {
    final workoutProvider = context.read<WorkoutProvider>();
    await workoutProvider.startNewWorkout(_selectedDay);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WorkoutDetailsScreen(),
        ),
      ).then((_) async {
        // Reload workouts after returning from details screen
        if (mounted) {
          await workoutProvider.loadAllWorkouts();
        }
      });
    }
  }

  /// Get all workouts for a specific date
  List<Workout> _getWorkoutsForDate(WorkoutProvider provider, DateTime date) {
    final normalizedDate = Workout.normalizeDate(date);
    return provider.workouts
        .where((workout) => Workout.normalizeDate(workout.date) == normalizedDate)
        .toList();
  }

  /// Build a compact workout card
  Widget _buildCompactWorkoutCard(Workout workout) {
    return GestureDetector(
      onTap: () => _openWorkoutDetailsScreen(workout),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: CategoryColors.getColor(workout.title),
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Time Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        workout.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: CategoryColors.getColor(workout.title),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        workout.timeOfDay.name.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                if (workout.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    workout.notes,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Delete button
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () => _showDeleteConfirmationDialog(workoutId: workout.id ?? 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.purple,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Tracker'),
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return IconButton(
                onPressed: authProvider.isLoading ? null : _logout,
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
              );
            },
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Calendar Widget
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: _onDateSelected,
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      // Display workouts as events
                      eventLoader: (day) {
                        return _getWorkoutsForDate(workoutProvider, day);
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return null;

                          final workout = events.first as Workout;
                          final categoryColor = CategoryColors.getColor(
                            workout.title,
                          );

                          return Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: categoryColor,
                                shape: BoxShape.circle,
                              ),
                              width: 8,
                              height: 8,
                            ),
                          );
                        },
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextFormatter: (date, locale) {
                          return '${date.month}/${date.year}';
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Workouts List for Selected Date
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workouts for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final workouts = _getWorkoutsForDate(workoutProvider, _selectedDay);

                          if (workouts.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'No workouts recorded for this date',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: workouts.length,
                            itemBuilder: (context, index) {
                              return _buildCompactWorkoutCard(workouts[index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewWorkout,
        tooltip: 'Add Workout',
        child: const Icon(Icons.add),
      ),
    );
  }
}
