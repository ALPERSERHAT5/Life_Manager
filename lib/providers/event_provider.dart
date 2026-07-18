import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../services/hive_service.dart';

const _uuid = Uuid();

class EventNotifier extends StateNotifier<List<EventModel>> {
  EventNotifier() : super(HiveService.events.values.toList());

  void _refresh() => state = HiveService.events.values.toList();

  Future<void> addEvent({
    required String title,
    String type = 'Etkinlik',
    required DateTime date,
    String time = '',
    String location = '',
    String note = '',
  }) async {
    final event = EventModel(
      id: _uuid.v4(),
      title: title,
      type: type,
      date: date,
      time: time,
      location: location,
      note: note,
    );
    await HiveService.events.put(event.id, event);
    _refresh();
  }

  Future<void> deleteEvent(EventModel event) async {
    await event.delete();
    _refresh();
  }

  List<EventModel> eventsOn(DateTime day) {
    return state.where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day).toList();
  }

  bool hasEventsOn(DateTime day) => eventsOn(day).isNotEmpty;
}

final eventProvider = StateNotifierProvider<EventNotifier, List<EventModel>>(
  (ref) => EventNotifier(),
);
