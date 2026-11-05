import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'tasks.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            due_date TEXT NOT NULL,
            repeat_type TEXT NOT NULL DEFAULT 'none',
            repeat_days TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_at TEXT
          )''');
        await d.execute('''
          CREATE TABLE subtasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
          )''');
      },
    );
  }

  Future<List<Task>> getAllTasks() async {
    final d = await db;
    final taskRows = await d.query('tasks', orderBy: 'due_date ASC');
    final subRows = await d.query('subtasks', orderBy: 'id ASC');
    final map = <int, List<Subtask>>{};
    for (final r in subRows) {
      final s = Subtask.fromMap(r);
      map.putIfAbsent(s.taskId!, () => []).add(s);
    }
    return taskRows.map((r) {
      final t = Task.fromMap(r);
      t.subtasks = map[t.id] ?? [];
      return t;
    }).toList();
  }

  Future<int> insertTask(Task t) async {
    final d = await db;
    return d.transaction((txn) async {
      final id = await txn.insert('tasks', t.toMap()..remove('id'));
      for (final s in t.subtasks) {
        await txn.insert('subtasks', s.toMap()
          ..remove('id')
          ..['task_id'] = id);
      }
      return id;
    });
  }

  Future<void> updateTask(Task t) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.update('tasks', t.toMap()..remove('id'),
          where: 'id = ?', whereArgs: [t.id]);
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [t.id]);
      for (final s in t.subtasks) {
        await txn.insert('subtasks', s.toMap()
          ..remove('id')
          ..['task_id'] = t.id);
      }
    });
  }

  Future<void> deleteTask(int id) async {
    final d = await db;
    await d.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setCompleted(int id, bool done) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.update(
        'tasks',
        {
          'is_completed': done ? 1 : 0,
          'completed_at': done ? DateTime.now().toIso8601String() : null,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      if (done) {
        await txn.update('subtasks', {'is_done': 1},
            where: 'task_id = ?', whereArgs: [id]);
      }
    });
  }

  Future<void> setSubtaskDone(int id, bool done) async {
    final d = await db;
    await d.update('subtasks', {'is_done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Repeating tasks completed on an earlier day become pending again
  /// (with subtasks cleared) so they show up in "Today" automatically.
  Future<void> resetRepeating() async {
    final d = await db;
    final now = DateTime.now();
    final startOfToday =
        DateTime(now.year, now.month, now.day).toIso8601String();
    await d.transaction((txn) async {
      await txn.rawUpdate('''
        UPDATE subtasks SET is_done = 0 WHERE task_id IN (
          SELECT id FROM tasks
          WHERE repeat_type != 'none' AND is_completed = 1 AND completed_at < ?)
      ''', [startOfToday]);
      await txn.rawUpdate('''
        UPDATE tasks SET is_completed = 0, completed_at = NULL
        WHERE repeat_type != 'none' AND is_completed = 1 AND completed_at < ?
      ''', [startOfToday]);
    });
  }
}
