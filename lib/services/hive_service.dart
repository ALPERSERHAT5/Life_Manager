import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/transaction_model.dart';
import '../models/event_model.dart';

class HiveService {
  static const String taskBox = 'tasks_box';
  static const String transactionBox = 'transactions_box';
  static const String eventBox = 'events_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());
    Hive.registerAdapter(EventModelAdapter());

    await Hive.openBox<TaskModel>(taskBox);
    await Hive.openBox<TransactionModel>(transactionBox);
    await Hive.openBox<EventModel>(eventBox);
  }

  static Box<TaskModel> get tasks => Hive.box<TaskModel>(taskBox);
  static Box<TransactionModel> get transactions => Hive.box<TransactionModel>(transactionBox);
  static Box<EventModel> get events => Hive.box<EventModel>(eventBox);
}
