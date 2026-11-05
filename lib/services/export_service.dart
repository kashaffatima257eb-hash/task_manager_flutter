import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';

class ExportService {
  static final _fmt = DateFormat('yyyy-MM-dd HH:mm');

  static List<List<String>> _rows(List<Task> tasks) => [
        ['Title', 'Description', 'Due', 'Repeat', 'Status', 'Progress'],
        ...tasks.map((t) => [
              t.title,
              t.description,
              _fmt.format(t.dueDate),
              t.repeatLabel,
              t.isCompleted ? 'Completed' : 'Pending',
              '${(t.progress * 100).round()}%',
            ]),
      ];

  static Future<File> _write(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$name');
    return f.writeAsBytes(bytes, flush: true);
  }

  static Future<void> exportCsv(List<Task> tasks) async {
    final csv = const ListToCsvConverter().convert(_rows(tasks));
    final f = await _write('tasks.csv', utf8.encode(csv));
    await Share.shareXFiles([XFile(f.path)], subject: 'My tasks (CSV)');
  }

  static Future<void> exportPdf(List<Task> tasks) async {
    final rows = _rows(tasks);
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (ctx) => [
        pw.Header(
            level: 0,
            child: pw.Text('My Tasks',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold))),
        pw.TableHelper.fromTextArray(
          headers: rows.first,
          data: rows.skip(1).toList(),
          headerStyle:
              pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ));
    final f = await _write('tasks.pdf', await doc.save());
    await Share.shareXFiles([XFile(f.path)], subject: 'My tasks (PDF)');
  }

  /// Opens the email app with a plain-text summary. Returns false on failure.
  static Future<bool> exportEmail(List<Task> tasks) async {
    final body = StringBuffer('My tasks\n\n');
    for (final t in tasks) {
      body.writeln('${t.isCompleted ? "[x]" : "[ ]"} ${t.title} '
          '- ${_fmt.format(t.dueDate)} (${t.repeatLabel})');
    }
    final uri = Uri.parse('mailto:?subject=${Uri.encodeComponent("My tasks")}'
        '&body=${Uri.encodeComponent(body.toString())}');
    return launchUrl(uri);
  }
}
