import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final settings = SettingsProvider();
  await settings.load();
  final tasks = TaskProvider(settings);
  await tasks.load();
  await tasks.rescheduleAll();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: tasks),
    ],
    child: const TaskManagerApp(),
  ));
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: buildTheme(settings.accent, Brightness.light),
      darkTheme: buildTheme(settings.accent, Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
