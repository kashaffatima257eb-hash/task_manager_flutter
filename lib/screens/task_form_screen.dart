import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});
  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  final _subCtrl = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  late String _repeat;
  late Set<int> _days;
  late List<Subtask> _subs;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    final base = t?.dueDate ?? DateTime.now().add(const Duration(hours: 1));
    _title = TextEditingController(text: t?.title ?? '');
    _desc = TextEditingController(text: t?.description ?? '');
    _date = DateTime(base.year, base.month, base.day);
    _time = TimeOfDay.fromDateTime(base);
    _repeat = t?.repeatType ?? 'none';
    _days = <int>{...?t?.repeatDays};
    _subs = t?.subtasks
            .map((s) => Subtask(title: s.title, isDone: s.isDone))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _addSub() {
    final text = _subCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subs.add(Subtask(title: text));
      _subCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_repeat == 'weekly' && _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick at least one day 📅')));
      return;
    }
    final old = widget.task;
    final task = Task(
      id: old?.id,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      dueDate: DateTime(
          _date.year, _date.month, _date.day, _time.hour, _time.minute),
      repeatType: _repeat,
      repeatDays: _repeat == 'weekly' ? (_days.toList()..sort()) : [],
      isCompleted: old?.isCompleted ?? false,
      completedAt: old?.completedAt,
      subtasks: _subs,
    );
    final provider = context.read<TaskProvider>();
    final nav = Navigator.of(context);
    await provider.save(task);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.task != null;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(editing ? 'Edit task ✏️' : 'New task ✨',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _Section(
              emoji: '📝',
              title: 'What needs doing?',
              child: Column(children: [
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: softDecoration(context, 'Title',
                      icon: Icons.title_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Give your task a title'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: softDecoration(context, 'Description (optional)',
                      icon: Icons.notes_rounded),
                ),
              ]),
            ),
            _Section(
              emoji: '⏰',
              title: 'When?',
              child: Row(children: [
                Expanded(
                  child: _PickTile(
                    icon: Icons.calendar_month_rounded,
                    text: DateFormat('EEE, d MMM').format(_date),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickTile(
                    icon: Icons.access_time_rounded,
                    text: _time.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ]),
            ),
            _Section(
              emoji: '🔁',
              title: 'Repeat',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, children: [
                    for (final o in const [
                      ['none', 'Once'],
                      ['daily', 'Every day'],
                      ['weekly', 'Pick days'],
                    ])
                      ChoiceChip(
                        label: Text(o[1]),
                        selected: _repeat == o[0],
                        selectedColor: accent,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _repeat == o[0] ? Colors.white : null,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _repeat = o[0]),
                      ),
                  ]),
                  if (_repeat == 'weekly') ...[
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (var d = 1; d <= 7; d++)
                        GestureDetector(
                          onTap: () => setState(() {
                            if (!_days.add(d)) _days.remove(d);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _days.contains(d)
                                  ? accent
                                  : accent.withValues(alpha: 0.12),
                            ),
                            child: Text(
                              dayShort[d - 1].substring(0, 2),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: _days.contains(d)
                                    ? Colors.white
                                    : accent,
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ],
                ],
              ),
            ),
            _Section(
              emoji: '🧩',
              title: 'Subtasks',
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _subCtrl,
                      decoration: softDecoration(context, 'Add a step',
                          icon: Icons.add_task_rounded),
                      onSubmitted: (_) => _addSub(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: accent),
                    onPressed: _addSub,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ]),
                const SizedBox(height: 8),
                for (var i = 0; i < _subs.length; i++)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      Icon(Icons.circle, size: 8, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_subs[i].title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => setState(() => _subs.removeAt(i)),
                      ),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(editing ? 'Save changes' : 'Add task',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.emoji, required this.title, required this.child});
  final String emoji;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCard(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: softShadow(Theme.of(context).colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji  $title',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile(
      {required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: accent)),
            ),
          ],
        ),
      ),
    );
  }
}
