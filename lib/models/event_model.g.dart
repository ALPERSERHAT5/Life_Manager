// GENERATED CODE - manuel olarak hazırlanmıştır (build_runner ile de üretilebilir)
part of 'event_model.dart';

class EventModelAdapter extends TypeAdapter<EventModel> {
  @override
  final int typeId = 2;

  @override
  EventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventModel(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      date: fields[3] as DateTime,
      time: fields[4] as String,
      location: fields[5] as String,
      note: fields[6] as String,
      hasNotification: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.hasNotification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
