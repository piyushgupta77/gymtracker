import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
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
      context.read<WorkoutProvider>().initialize();
    });
  }

  void _onDateSelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Load workout for selected date
    context.read<WorkoutProvider>().setSelectedDate(selectedDay);
  }

  void _openWorkoutDetailsScreen() async {
    final workoutProvider = context.read<WorkoutProvider>();
    await workoutProvider.setSelectedDate(_selectedDay);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Tracker'),
        elevation: 0,
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
                        return workoutProvider.getWorkoutForDate(day) != null
                            ? [workoutProvider.getWorkoutForDate(day)!]
                            : [];
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
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          shape: BoxShape.circle,
                        ),
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
                // Workout Details for Selected Date
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                       if (workoutProvider.selectedWorkout != null)
                         Card(
                           elevation: 2,
                           child: Padding(
                             padding: const EdgeInsets.all(16.0),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Text(
                                       workoutProvider.selectedWorkout!.title,
                                       style:
                                           Theme.of(context).textTheme.headlineSmall,
                                     ),
                                     Container(
                                       padding: const EdgeInsets.symmetric(
                                         horizontal: 12,
                                         vertical: 6,
                                       ),
                                       decoration: BoxDecoration(
                                         color: Theme.of(context)
                                             .colorScheme
                                             .primaryContainer,
                                         borderRadius: BorderRadius.circular(16),
                                       ),
                                       child: Text(
                                         workoutProvider.selectedWorkout!.timeOfDay
                                             .name
                                             .toUpperCase(),
                                         style: Theme.of(context)
                                             .textTheme
                                             .labelSmall,
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 12),
                                 Text(
                                   workoutProvider.selectedWorkout!.notes,
                                   style: Theme.of(context).textTheme.bodyMedium,
                                   maxLines: 3,
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ],
                             ),
                           ),
                         )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No workout recorded for this date',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
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
        onPressed: _openWorkoutDetailsScreen,
        tooltip: 'Add Workout',
        child: const Icon(Icons.add),
      ),
    );
  }
}


