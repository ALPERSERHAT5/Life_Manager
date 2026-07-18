import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';
import 'hive_service.dart';

/// Tüm uygulama verisini (görevler, işlemler, etkinlikler, profil) JSON olarak
/// dışa aktarma / paylaşma ve bir yedekten geri yükleme işlemlerini yönetir.
class BackupService {
  BackupService._();

  static Future<Map<String, dynamic>> _buildBackupMap() async {
    final prefs = await SharedPreferences.getInstance();

    final tasks = HiveService.tasks.values
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'date': t.date.toIso8601String(),
              'time': t.time,
              'priority': t.priority,
              'category': t.category,
              'repeat': t.repeat,
              'isCompleted': t.isCompleted,
              'createdAt': t.createdAt.toIso8601String(),
            })
        .toList();

    final transactions = HiveService.transactions.values
        .map((t) => {
              'id': t.id,
              'amount': t.amount,
              'description': t.description,
              'date': t.date.toIso8601String(),
              'category': t.category,
              'isIncome': t.isIncome,
            })
        .toList();

    final events = HiveService.events.values
        .map((e) => {
              'id': e.id,
              'title': e.title,
              'type': e.type,
              'date': e.date.toIso8601String(),
              'time': e.time,
              'location': e.location,
              'note': e.note,
              'hasNotification': e.hasNotification,
            })
        .toList();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': {
        'name': prefs.getString('profile_name'),
        'photoPath': prefs.getString('profile_photo_path'),
      },
      'tasks': tasks,
      'transactions': transactions,
      'events': events,
    };
  }

  /// Tüm veriyi bir JSON dosyasına yazar ve sistem paylaşım penceresini açar.
  static Future<void> exportAndShare() async {
    final data = await _buildBackupMap();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/life_manager_yedek_$stamp.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles([XFile(file.path)], text: 'Life Manager yedeği');
  }

  /// Kullanıcıya bir .json yedek dosyası seçtirir ve tüm verileri onunla
  /// değiştirir. Mevcut görev/işlem/etkinlik verileri silinir.
  /// Başarılıysa true, kullanıcı iptal ettiyse false döner.
  static Future<bool> pickAndRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    await _restore(data);
    return true;
  }

  static Future<void> _restore(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final profile = data['profile'] as Map<String, dynamic>?;
    if (profile != null) {
      if (profile['name'] != null) await prefs.setString('profile_name', profile['name']);
      if (profile['photoPath'] != null) {
        await prefs.setString('profile_photo_path', profile['photoPath']);
      }
    }

    await HiveService.tasks.clear();
    for (final raw in (data['tasks'] as List? ?? [])) {
      final m = raw as Map<String, dynamic>;
      final task = TaskModel(
        id: m['id'],
        title: m['title'],
        description: m['description'] ?? '',
        date: DateTime.parse(m['date']),
        time: m['time'] ?? '',
        priority: m['priority'] ?? 'Orta',
        category: m['category'] ?? 'Diğer',
        repeat: m['repeat'] ?? 'Yok',
        isCompleted: m['isCompleted'] ?? false,
        createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt']) : null,
      );
      await HiveService.tasks.put(task.id, task);
    }

    await HiveService.transactions.clear();
    for (final raw in (data['transactions'] as List? ?? [])) {
      final m = raw as Map<String, dynamic>;
      final tx = TransactionModel(
        id: m['id'],
        amount: (m['amount'] as num).toDouble(),
        description: m['description'] ?? '',
        date: DateTime.parse(m['date']),
        category: m['category'],
        isIncome: m['isIncome'],
      );
      await HiveService.transactions.put(tx.id, tx);
    }

    await HiveService.events.clear();
    for (final raw in (data['events'] as List? ?? [])) {
      final m = raw as Map<String, dynamic>;
      final ev = EventModel(
        id: m['id'],
        title: m['title'],
        type: m['type'] ?? 'Etkinlik',
        date: DateTime.parse(m['date']),
        time: m['time'] ?? '',
        location: m['location'] ?? '',
        note: m['note'] ?? '',
        hasNotification: m['hasNotification'] ?? true,
      );
      await HiveService.events.put(ev.id, ev);
    }
  }
}
