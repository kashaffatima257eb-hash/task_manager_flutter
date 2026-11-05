import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final accent = s.accent;

    Widget section(String title, Widget child) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceCard(context),
            borderRadius: BorderRadius.circular(28),
            boxShadow: softShadow(accent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              child,
            ],
          ),
        );

    Widget themeTile(ThemeMode m, String emoji, String label) {
      final selected = s.themeMode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => s.setThemeMode(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? accent : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : accent)),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Settings ⚙️',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          section(
            '🎨  Theme',
            Row(children: [
              themeTile(ThemeMode.light, '☀️', 'Light'),
              themeTile(ThemeMode.dark, '🌙', 'Dark'),
              themeTile(ThemeMode.system, '📱', 'Auto'),
            ]),
          ),
          section(
            '🌈  Accent color',
            Wrap(spacing: 14, runSpacing: 12, children: [
              for (var i = 0; i < accentPalettes.length; i++)
                GestureDetector(
                  onTap: () => s.setAccent(i),
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentPalettes[i].color,
                        border: Border.all(
                          color: s.accentIndex == i
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Text(accentPalettes[i].emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(height: 4),
                    Text(accentPalettes[i].name,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
          ),
          section(
            '🔔  Notification sound',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final o in SoundOption.values)
                    ChoiceChip(
                      label: Text(o.label),
                      selected: s.sound == o,
                      selectedColor: accent,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: s.sound == o ? Colors.white : null,
                      ),
                      onSelected: (_) async {
                        final tasks = context.read<TaskProvider>();
                        await s.setSound(o);
                        await tasks.rescheduleAll();
                      },
                    ),
                ]),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    foregroundColor: accent,
                    side: BorderSide(color: accent, width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Send test notification',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: () => NotificationService.showTest(s.sound),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
