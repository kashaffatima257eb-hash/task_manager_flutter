const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class Subtask {
  int? id;
  int? taskId;
  String title;
  bool isDone;

  Subtask({this.id, this.taskId, required this.title, this.isDone = false});

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'title': title,
        'is_done': isDone ? 1 : 0,
      };

  factory Subtask.fromMap(Map<String, Object?> m) => Subtask(
        id: m['id'] as int?,
        taskId: m['task_id'] as int?,
        title: m['title'] as String,
        isDone: (m['is_done'] as int) == 1,
      );
}

class Task {
  int? id;
  String title;
  String description;
  DateTime dueDate; // date + time of day
  String repeatType; // 'none' | 'daily' | 'weekly'
  List<int> repeatDays; // DateTime.weekday values 1..7 (for 'weekly')
  bool isCompleted;
  DateTime? completedAt;
  List<Subtask> subtasks;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.repeatType = 'none',
    List<int>? repeatDays,
    this.isCompleted = false,
    this.completedAt,
    List<Subtask>? subtasks,
  })  : repeatDays = repeatDays ?? [],
        subtasks = subtasks ?? [];

  bool get isRepeating => repeatType != 'none';

  double get progress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    return subtasks.where((s) => s.isDone).length / subtasks.length;
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (repeatType == 'daily') return !startDay.isAfter(today);
    if (repeatType == 'weekly') {
      return !startDay.isAfter(today) && repeatDays.contains(today.weekday);
    }
    return !startDay.isAfter(today); // due today or overdue
  }

  String get repeatLabel {
    switch (repeatType) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        final d = [...repeatDays]..sort();
        return d.map((e) => dayShort[e - 1]).join(', ');
      default:
        return 'None';
    }
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'repeat_type': repeatType,
        'repeat_days': repeatDays.join(','),
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.toIso8601String(),
      };

  factory Task.fromMap(Map<String, Object?> m) {
    final days = (m['repeat_days'] as String?) ?? '';
    return Task(
      id: m['id'] as int?,
      title: m['title'] as String,
      description: (m['description'] as String?) ?? '',
      dueDate: DateTime.parse(m['due_date'] as String),
      repeatType: m['repeat_type'] as String,
      repeatDays:
          days.isEmpty ? [] : days.split(',').map(int.parse).toList(),
      isCompleted: (m['is_completed'] as int) == 1,
      completedAt: m['completed_at'] == null
          ? null
          : DateTime.parse(m['completed_at'] as String),
    );
  }
}
