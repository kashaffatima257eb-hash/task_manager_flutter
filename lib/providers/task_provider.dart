import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this.settings);
  final SettingsProvider settings;
  final _db = DatabaseHelper.instance;

  List<Task> _all = [];
  bool loading = true;

  List<Task> get all => _all;

  List<Task> get today {
    final l = _all.where((t) => !t.isCompleted && t.isDueToday).toList();
    l.sort((a, b) => (a.dueDate.hour * 60 + a.dueDate.minute)
        .compareTo(b.dueDate.hour * 60 + b.dueDate.minute));
    return l;
  }

  List<Task> get completed {
    final l = _all.where((t) => t.isCompleted).toList();
    l.sort((a, b) => (b.completedAt ?? b.dueDate)
        .compareTo(a.completedAt ?? a.dueDate));
    return l;
  }

  List<Task> get repeated => _all.where((t) => t.isRepeating).toList();


  bool _inTodayScope(Task t) {
    if (!t.isDueToday) return false;
    if (!t.isCompleted) return true;
    final c = t.completedAt;
    final n = DateTime.now();
    return c != null && c.year == n.year && c.month == n.month && c.day == n.day;
  }

  int get todayTotal => _all.where(_inTodayScope).length;
  int get todayDone =>
      _all.where((t) => _inTodayScope(t) && t.isCompleted).length;

  Task? _find(int id) {
    for (final t in _all) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> load() async {
    await _db.resetRepeating();
    _all = await _db.getAllTasks();
    loading = false;
    notifyListeners();
  }

  Future<void> rescheduleAll() =>
      NotificationService.rescheduleAll(_all, settings.sound);

  Future<void> save(Task t) async {
    int id;
    if (t.id == null) {
      id = await _db.insertTask(t);
    } else {
      await _db.updateTask(t);
      id = t.id!;
    }
    await load();
    final saved = _find(id);
    if (saved != null) await NotificationService.schedule(saved, settings.sound);
  }

  Future<void> delete(Task t) async {
    if (t.id == null) return;
    await NotificationService.cancel(t.id!);
    await _db.deleteTask(t.id!);
    await load();
  }

  Future<void> setCompleted(Task t, bool done) async {
    await _db.setCompleted(t.id!, done);
    await load();
    final updated = _find(t.id!);
    if (updated != null) {
      await NotificationService.schedule(updated, settings.sound);
    }
  }

  Future<void> toggleSubtask(Task t, Subtask s) async {
    await _db.setSubtaskDone(s.id!, !s.isDone);
    await load();
    final updated = _find(t.id!);
    if (updated == null || updated.subtasks.isEmpty) return;
    final allDone = updated.subtasks.every((x) => x.isDone);
    if (allDone != updated.isCompleted) {
      await setCompleted(updated, allDone);
    }
  }
}
