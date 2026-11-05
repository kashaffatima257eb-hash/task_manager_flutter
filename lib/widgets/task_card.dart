import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/task_form_screen.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final p = context.read<TaskProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tone = cardToneFor(task.id);
    final c = tone.deep;
    final bg = dark
        ? Color.alphaBlend(c.withValues(alpha: 0.22), surfaceCard(context))
        : tone.pastel;
    final pct = (task.progress * 100).round();
    final overdue = !task.isCompleted &&
        !task.isRepeating &&
        task.dueDate.isBefore(DateTime.now());
    final textColor = inkOf(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: dark ? c.withValues(alpha: 0.4) : Colors.white, width: 2),
        boxShadow: softShadow(c),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => TaskFormScreen(task: task))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoundCheck(
                      done: task.isCompleted,
                      color: c,
                      onTap: () => p.setCompleted(task, !task.isCompleted),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: task.isCompleted
                                  ? textColor.withValues(alpha: 0.5)
                                  : textColor,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.65)),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            _Pill(
                              icon: Icons.schedule_rounded,
                              text: task.isRepeating
                                  ? DateFormat('hh:mm a').format(task.dueDate)
                                  : DateFormat('MMM d, hh:mm a')
                                      .format(task.dueDate),
                              color: c,
                            ),
                            if (task.isRepeating)
                              _Pill(
                                  icon: Icons.repeat_rounded,
                                  text: task.repeatLabel,
                                  color: c),
                            if (overdue)
                              const _Pill(
                                  icon: Icons.warning_amber_rounded,
                                  text: 'Overdue',
                                  color: Color(0xFFD6336C)),
                          ]),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          color: textColor.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TaskFormScreen(task: task)));
                        } else {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete task? 🗑️'),
                              content: Text('"${task.title}" will be removed.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) p.delete(task);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('✏️  Edit')),
                        PopupMenuItem(value: 'delete', child: Text('🗑️  Delete')),
                      ],
                    ),
                  ],
                ),
                if (task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: task.progress,
                            minHeight: 10,
                            backgroundColor: Colors.white.withValues(alpha: 0.7),
                            valueColor: AlwaysStoppedAnimation(c),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$pct%',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: c)),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  for (final s in task.subtasks)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => p.toggleSubtask(task, s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 2),
                        child: Row(children: [
                          _RoundCheck(
                              done: s.isDone, color: c, size: 22, onTap: null),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.title,
                              style: TextStyle(
                                color: s.isDone
                                    ? textColor.withValues(alpha: 0.5)
                                    : textColor,
                                decoration: s.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundCheck extends StatelessWidget {
  const _RoundCheck(
      {required this.done, required this.color, this.size = 30, this.onTap});
  final bool done;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? color : Colors.white.withValues(alpha: 0.75),
          border: Border.all(color: color, width: 2.5),
        ),
        child: done
            ? Icon(Icons.check_rounded, size: size * 0.66, color: Colors.white)
            : null,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dark ? 0.1 : 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: inkOf(context))),
      ]),
    );
  }
}
