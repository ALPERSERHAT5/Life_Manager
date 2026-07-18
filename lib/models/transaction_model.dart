import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String category; // Market, Kira, Fatura, Yakıt, Yemek, Maaş, Freelance, Yatırım, Diğer

  @HiveField(5)
  bool isIncome; // true = gelir, false = gider

  TransactionModel({
    required this.id,
    required this.amount,
    this.description = '',
    required this.date,
    required this.category,
    required this.isIncome,
  });
}
