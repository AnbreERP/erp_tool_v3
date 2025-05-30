class CoreWoodworkModel {
  final int? id;
  final int woodenItemId;
  final int woodworkFinishId; // Foreign key reference
  final String description;
  final String type;
  final double widthMm;
  final double heightMm;
  final double widthFeet;
  final double heightFeet;
  final double squareFeet;
  final int quantity;
  final double rate;
  final double amount;
  final double? totalAmount;

  CoreWoodworkModel({
    this.id,
    required this.woodenItemId,
    required this.woodworkFinishId,
    required this.description,
    required this.type,
    required this.widthMm,
    required this.heightMm,
    required this.widthFeet,
    required this.heightFeet,
    required this.squareFeet,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wooden_item_id': woodenItemId,
      'woodwork_finish_id': woodworkFinishId,
      'description': description,
      'type': type,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'widthFeet': widthFeet,
      'heightFeet': heightFeet,
      'squareFeet': squareFeet,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'totalAmount': totalAmount,
    };
  }

  static CoreWoodworkModel fromMap(Map<String, dynamic> map) {
    return CoreWoodworkModel(
      id: map['id'] as int?,
      woodenItemId: map['wooden_item_id'] as int,
      woodworkFinishId: map['woodwork_finish_id'] as int,
      description: map['description'] as String,
      type: map['type'] as String,
      widthMm: map['widthMm'] as double,
      heightMm: map['heightMm'] as double,
      widthFeet: map['widthFeet'] as double,
      heightFeet: map['heightFeet'] as double,
      squareFeet: map['squareFeet'] as double,
      quantity: map['quantity'] as int,
      rate: map['rate'] as double,
      amount: map['amount'] as double,
      totalAmount: map['totalAmount'] as double?,
    );
  }
}

class WoodenItemModel {
  final int? id;
  final String name;
  final String description;

  WoodenItemModel({
    this.id,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory WoodenItemModel.fromMap(Map<String, dynamic> map) {
    return WoodenItemModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }
}
