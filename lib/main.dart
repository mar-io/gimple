// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gantt/flutter_gantt.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visual Project Board',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: const GanttHomePage(),
    );
  }
}

class GanttHomePage extends StatefulWidget {
  const GanttHomePage({super.key});

  @override
  State<GanttHomePage> createState() => _GanttHomePageState();
}

class _GanttHomePageState extends State<GanttHomePage> {
  // State variables
  List<Task> tasks = [];
  int nextTaskId = 0;
  String currentView = 'month';
  DateTime timelineStartDate = DateTime.now();
  DateTime timelineEndDate = DateTime.now();
  Map<String, int> customQuarters = {'q1': 1, 'q2': 4, 'q3': 7, 'q4': 10};
  String currentQView = 'all';

  late GanttController _controller;

  // Colors
  final List<Color> taskColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.yellow,
    Colors.purple,
    Colors.teal,
    Colors.orange,
  ];
  final List<Color> quarterColors = [
    Colors.blue.withOpacity(0.1),
    Colors.green.withOpacity(0.1),
    Colors.yellow.withOpacity(0.1),
    Colors.orange.withOpacity(0.1),
  ];

  final List<String> monthAbbreviations = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  // Controller for add task input
  final TextEditingController _addTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupInitialDates();
    _controller = GanttController(startDate: timelineStartDate);
    _loadInitialTasks();
  }

  void _setupInitialDates() {
    final today = DateTime.now();
    timelineStartDate = DateTime(today.year, today.month, 1);
    timelineEndDate = timelineStartDate.add(const Duration(days: 29));
  }

  void _loadInitialTasks() {
    final today = DateTime.now();
    tasks = [
      Task(
        id: 0,
        name: 'Brainstorm Ideas',
        start: today.subtract(const Duration(days: 10)),
        end: today.subtract(const Duration(days: 5)),
        color: taskColors[0],
        description: '',
      ),
      Task(
        id: 1,
        name: 'Create Mockups',
        start: today.subtract(const Duration(days: 4)),
        end: today.add(const Duration(days: 4)),
        color: taskColors[1],
        description: '<p>Initial design concepts and wireframes.</p><ul><li>Homepage</li><li>Dashboard</li></ul>',
      ),
      // Add other initial tasks similarly
    ];
    nextTaskId = tasks.length;
    setState(() {});
  }

  void _handleViewChange(String newView) {
    setState(() {
      currentView = newView;
      // Update timelineStartDate and timelineEndDate based on view
      final today = DateTime.now();
      if (newView == 'week') {
        timelineStartDate = today.subtract(Duration(days: today.weekday - 1));
        timelineEndDate = timelineStartDate.add(const Duration(days: 6));
      } else if (newView == 'month') {
        timelineStartDate = DateTime(today.year, today.month, 1);
        timelineEndDate = DateTime(today.year, today.month + 1, 0);
      } else if (newView == 'year') {
        timelineStartDate = DateTime(today.year, 1, 1);
        timelineEndDate = DateTime(today.year, 12, 31);
      } else if (newView == 'quarter') {
        // Handle quarter subviews
      } // Implement custom similarly
      // Update controller if possible
    });
  }

  void _addTask(String name) {
    final newTask = Task(
      id: nextTaskId++,
      name: name,
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 3)),
      color: taskColors[tasks.length % taskColors.length],
      description: '',
    );
    setState(() {
      tasks.add(newTask);
    });
    _addTaskController.clear();
    _openTaskModal(newTask);
  }

  void _deleteTask(int id) {
    setState(() {
      tasks.removeWhere((t) => t.id == id);
    });
  }

  void _openTaskModal(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskEditDialog(
        task: task,
        onSave: (updatedTask) {
          setState(() {
            final index = tasks.indexWhere((t) => t.id == updatedTask.id);
            if (index != -1) tasks[index] = updatedTask;
          });
        },
      ),
    );
  }

  List<GantActivity<dynamic>> _getActivities() {
    return tasks.map((task) => GantActivity<dynamic>(
      key: task.id.toString(),
      start: task.start,
      end: task.end,
      title: task.name,
      color: task.color,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Board'),
        actions: [
          // View switcher buttons
          ToggleButtons(
            isSelected: [currentView == 'week', currentView == 'month', currentView == 'quarter', currentView == 'year', currentView == 'custom'],
            onPressed: (index) {
              String newView;
              if (index == 0) newView = 'week';
              else if (index == 1) newView = 'month';
              else if (index == 2) newView = 'quarter';
              else if (index == 3) newView = 'year';
              else newView = 'custom';
              _handleViewChange(newView);
            },
            children: const [Text('Week'), Text('Month'), Text('Quarter'), Text('Year'), Text('Custom')],
          ),
          // Quarter submenu if quarter view
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 300,
            child: Column(
              children: [
                TextField(
                  controller: _addTaskController,
                  decoration: const InputDecoration(labelText: 'Add Task'),
                  onSubmitted: _addTask,
                ),
                ElevatedButton(
                  onPressed: () => _addTask(_addTaskController.text),
                  child: const Text('Add Task'),
                ),
                // Quarter settings: ExpansionTile with dropdowns for q1,q2 etc.
                ExpansionTile(
                  title: const Text('Quarter Settings'),
                  children: [
                    // Dropdown for Q1
                    DropdownButton<int>(
                      value: customQuarters['q1'],
                      onChanged: (value) => setState(() => customQuarters['q1'] = value!),
                      items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(monthAbbreviations[i]))),
                    ),
                    // Similar for q2, q3, q4
                    DropdownButton<int>(
                      value: customQuarters['q2'],
                      onChanged: (value) => setState(() => customQuarters['q2'] = value!),
                      items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(monthAbbreviations[i]))),
                    ),
                    DropdownButton<int>(
                      value: customQuarters['q3'],
                      onChanged: (value) => setState(() => customQuarters['q3'] = value!),
                      items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(monthAbbreviations[i]))),
                    ),
                    DropdownButton<int>(
                      value: customQuarters['q4'],
                      onChanged: (value) => setState(() => customQuarters['q4'] = value!),
                      items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(monthAbbreviations[i]))),
                    ),
                  ],
                ),
                // Task list
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: task.color),
                        title: Text(task.name),
                        subtitle: Text('${DateFormat('yyyy-MM-dd').format(task.start)}'),
                        onTap: () => _openTaskModal(task),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTask(task.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Gantt area
          Expanded(
            child: Gantt(
              controller: _controller,
              activitiesAsync: (start, end, activity) async => _getActivities(),
              holidaysAsync: (start, end, holidays) async => [], // Add holidays if needed
              onActivityChanged: (activity, newStart, newEnd) {
                // Update task start/end
                final task = tasks.firstWhereOrNull((t) => t.name == activity.title);
                if (task != null && newStart != null && newEnd != null) {
                  setState(() {
                    task.start = newStart;
                    task.end = newEnd;
                  });
                }
              },
              // Customize theme, add quarter shades via background builder if possible
            ),
          ),
        ],
      ),
    );
  }
}

// Task model
class Task {
  final int id;
  String name;
  DateTime start;
  DateTime end;
  Color color;
  String description;

  Task({required this.id, required this.name, required this.start, required this.end, required this.color, required this.description});
}

// Task Edit Dialog
class TaskEditDialog extends StatefulWidget {
  final Task task;
  final Function(Task) onSave;

  const TaskEditDialog({super.key, required this.task, required this.onSave});

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  late TextEditingController nameController;
  late DateTime startDate;
  late DateTime dueDate;
  late QuillController quillController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.task.name);
    startDate = widget.task.start;
    dueDate = widget.task.end;
    final delta = HtmlToDelta().convert(widget.task.description);  // Convert HTML to Delta
    Delta effectiveDelta = delta;
    if (delta.isEmpty) {
      effectiveDelta = Delta()..insert('\n');
    }
    quillController = QuillController(
      document: Document.fromDelta(effectiveDelta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Task Name'),
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(startDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => startDate = picked);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Due Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => dueDate = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Description'),
            QuillToolbar.basic(
              controller: quillController,
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: QuillEditor.basic(
                controller: quillController,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final delta = quillController.document.toDelta();
            final converter = QuillDeltaToHtmlConverter(delta.toJson());
            final updatedTask = Task(
              id: widget.task.id,
              name: nameController.text,
              start: startDate,
              end: dueDate,
              color: widget.task.color,
              description: converter.convert(),
            );
            widget.onSave(updatedTask);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
