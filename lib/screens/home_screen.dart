import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flower_decor.dart';
import '../widgets/task_card.dart';
import 'settings_screen.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TaskProvider>().load();
    }
  }

  Future<void> _export(String type) async {
    final tasks = context.read<TaskProvider>().all;
    final messenger = ScaffoldMessenger.of(context);
    if (tasks.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No tasks to export yet 📭')));
      return;
    }
    if (type == 'csv') {
      await ExportService.exportCsv(tasks);
    } else if (type == 'pdf') {
      await ExportService.exportPdf(tasks);
    } else {
      final ok = await ExportService.exportEmail(tasks);
      if (!ok) {
        messenger.showSnackBar(
            const SnackBar(content: Text('No email app found')));
      }
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    final accent = context.watch<SettingsProvider>().accent;
    final lists = [p.today, p.completed, p.repeated];
    final tasks = lists[_index];

    const emptyEmoji = ['🧸', '🌷', '⏰'];
    const emptyTitle = [
      'Nothing due today',
      'No completed tasks yet',
      'No repeating tasks',
    ];
    const emptySub = [
      'Tap "New task" to plan something fun!',
      'Finish a task and it lands here.',
      'Add a task with a repeat setting.',
    ];

    return Scaffold(
      body: Column(
        children: [
          _Header(
            index: _index,
            greeting: _greeting(),
            accent: accent,
            done: p.todayDone,
            total: p.todayTotal,
            completedCount: p.completed.length,
            repeatedCount: p.repeated.length,
            onExport: _export,
            onSettings: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlowerDecor(
                    spots: pageSpots,
                    opacity: Theme.of(context).brightness == Brightness.dark
                        ? 0.10
                        : 0.55,
                  ),
                ),
                p.loading
                    ? const Center(child: CircularProgressIndicator())
                    : tasks.isEmpty
                        ? _Empty(
                            emoji: emptyEmoji[_index],
                            title: emptyTitle[_index],
                            sub: emptySub[_index])
                        : _TaskList(tasks: tasks),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded, size: 26),
        label: const Text('New task',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen())),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny_rounded),
              label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline_rounded),
              selectedIcon: Icon(Icons.check_circle_rounded),
              label: 'Completed'),
          NavigationDestination(
              icon: Icon(Icons.repeat_rounded),
              selectedIcon: Icon(Icons.repeat_on_rounded),
              label: 'Repeated'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.greeting,
    required this.accent,
    required this.done,
    required this.total,
    required this.completedCount,
    required this.repeatedCount,
    required this.onExport,
    required this.onSettings,
  });

  final int index;
  final String greeting;
  final Color accent;
  final int done;
  final int total;
  final int completedCount;
  final int repeatedCount;
  final void Function(String) onExport;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hc = dark ? Colors.white : ink; // header text colour
    final title = index == 0
        ? greeting
        : index == 1
            ? 'Completed ✅'
            : 'Repeated ⏰';
    final subtitle = index == 0
        ? DateFormat('EEEE, d MMMM').format(DateTime.now())
        : index == 1
            ? '$completedCount task${completedCount == 1 ? '' : 's'} finished'
            : '$repeatedCount routine${repeatedCount == 1 ? '' : 's'} running';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: headerGradient(accent, dark),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
                child: FlowerDecor(spots: headerSpots, opacity: dark ? 0.35 : 0.9)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 10, 12, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(
                                    color: hc,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style: TextStyle(
                                    color: hc.withValues(alpha: 0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.ios_share_rounded, color: hc),
                        tooltip: 'Export',
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        onSelected: onExport,
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'csv', child: Text('📄  Export as CSV')),
                          PopupMenuItem(
                              value: 'pdf', child: Text('📕  Export as PDF')),
                          PopupMenuItem(
                              value: 'email', child: Text('✉️  Send by email')),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.settings_rounded, color: hc),
                        onPressed: onSettings,
                      ),
                    ],
                  ),
                  if (index == 0) ...[
                    const SizedBox(height: 16),
                    _StatusCard(
                        done: done, total: total, accent: accent, dark: dark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(
      {required this.done,
      required this.total,
      required this.accent,
      required this.dark});
  final int done;
  final int total;
  final Color accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    String mascot;
    String msg;
    if (total == 0) {
      mascot = '🧸';
      msg = 'Free day!';
    } else if (done == total) {
      mascot = '🎉';
      msg = 'All done, superstar!';
    } else if (done == 0) {
      mascot = '🐣';
      msg = "Let's get started!";
    } else {
      mascot = '🌸';
      msg = 'Keep blooming, almost there!';
    }
    final value = total == 0 ? 0.0 : done / total;
    final tc = dark ? Colors.white : ink;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dark ? 0.12 : 0.62),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.2 : 0.9), width: 1.5),
      ),
      child: Row(
        children: [
          Text(mascot, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg,
                    style: TextStyle(
                        color: tc, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  total == 0
                      ? 'No tasks scheduled for today'
                      : '$done of $total tasks done today',
                  style: TextStyle(
                      color: tc.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor:
                        dark ? Colors.white24 : Colors.white,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.emoji, required this.title, required this.sub});
  final String emoji;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 84)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65))),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 110),
      itemCount: tasks.length,
      itemBuilder: (_, i) => TaskCard(task: tasks[i]),
    );
  }
}
