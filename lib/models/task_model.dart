import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String time; // "14:30" formatında saklanır

  @HiveField(5)
  String priority; // Düşük - Orta - Yüksek

  @HiveField(6)
  String category; // Kişisel, İş, Okul, Sağlık, Spor, Alışveriş, Diğer

  @HiveField(7)
  String repeat; // Yok, Her gün, Haftalık, Aylık

  @HiveField(8)
  bool isCompleted;

  @HiveField(9)
  DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.time,
    this.priority = 'Orta',
    this.category = 'Diğer',
    this.repeat = 'Yok',
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
