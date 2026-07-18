import 'package:hive/hive.dart';

part 'event_model.g.dart';

@HiveType(typeId: 2)
class EventModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String type; // Randevu, Toplantı, Ders, Not, Etkinlik

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String time;

  @HiveField(5)
  String location;

  @HiveField(6)
  String note;

  @HiveField(7)
  bool hasNotification;

  EventModel({
    required this.id,
    required this.title,
    this.type = 'Etkinlik',
    required this.date,
    this.time = '',
    this.location = '',
    this.note = '',
    this.hasNotification = true,
  });
}
