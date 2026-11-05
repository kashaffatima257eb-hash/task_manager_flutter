# Task Manager (Flutter + SQLite)

A pastel-themed task management app built with Flutter. Tasks are stored locally in SQLite, can repeat daily or on selected weekdays, trigger local notifications, track progress through subtasks, and be exported to CSV, PDF or email.

> Course project: Task Management Application (Flutter + SQLite)

## Features

| Area | What it does |
|------|--------------|
| Views | **Today**, **Completed** and **Repeated** tabs |
| Task management | Add, edit, delete, and mark tasks complete (completed tasks move to the Completed tab automatically) |
| Task details | Title, description, due date and time, optional repeat setting |
| Repeat tasks | Daily or selected days of the week; repeating tasks reset automatically each day |
| Progress tracking | Subtasks with a progress bar and percentage; finishing all subtasks completes the task |
| Notifications | Local notification at the task's due date and time, including repeating tasks |
| Customization | Light / Dark / System theme, 5 accent colors, notification sound (Default, Alarm, Ringtone, Silent) |
| Export | CSV, PDF, and email |
| Storage | SQLite via `sqflite` (`tasks` and `subtasks` tables, cascade delete) |

## Screenshots

Add screenshots to a `screenshots/` folder and reference them here:

```
![Today](screenshots/today.png)
![New task](screenshots/new_task.png)
![Settings](screenshots/settings.png)
```

## Download

The release APK is available under the repository's **Releases** page, or in `release/app-release.apk`.

## Video demo

Add your demo link here (YouTube unlisted / Google Drive).

## Tech stack

- Flutter (Material 3), Dart
- `sqflite` for the SQLite database
- `provider` for state management
- `flutter_local_notifications` + `timezone` for scheduled notifications
- `shared_preferences` for theme, accent and sound settings
- `csv`, `pdf`, `share_plus`, `url_launcher` for export

## Project structure

```
lib/
  main.dart
  models/        Task, Subtask
  db/            DatabaseHelper (SQLite)
  providers/     TaskProvider, SettingsProvider
  services/      NotificationService, ExportService
  screens/       Home, Task form, Settings
  widgets/       TaskCard, flower decorations
  theme/         Pastel theme and palettes
```

## Database schema

```
tasks(id, title, description, due_date, repeat_type, repeat_days,
      is_completed, completed_at)
subtasks(id, task_id -> tasks.id ON DELETE CASCADE, title, is_done)
```

## Run it

Requirements: Flutter SDK, Android Studio (Android SDK), and an Android phone or emulator. The app targets Android (sqflite and notifications do not run on Chrome or Windows).

```bash
git clone <your-repo-url>
cd <repo-folder>
flutter pub get
flutter run --release
```

Build an APK:

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android configuration notes

- Core library desugaring is enabled in `android/app/build.gradle.kts` (needed by `flutter_local_notifications`).
- Release builds have `isMinifyEnabled = false` and `isShrinkResources = false`, because R8 breaks the notification plugin's boot receiver otherwise.
- `AndroidManifest.xml` declares the notification permissions and receivers.

## User manual

1. **Add a task**: tap **New task**, enter a title (and optionally a description), choose the date and time, pick a repeat option, add subtasks if you like, then tap **Add task**.
2. **Complete a task**: tap the round checkbox. The task moves to **Completed**.
3. **Edit or delete**: tap a task to edit it, or use the three-dot menu for Edit / Delete.
4. **Repeat tasks**: choose *Every day* or *Pick days* in the form. They appear in **Today** on the scheduled days and reset automatically the next day.
5. **Progress**: add subtasks in the form. Tick them on the task card to fill the progress bar.
6. **Export**: tap the share icon at the top and choose CSV, PDF or email.
7. **Settings**: tap the gear icon to change theme, accent color and notification sound, or send a test notification.
