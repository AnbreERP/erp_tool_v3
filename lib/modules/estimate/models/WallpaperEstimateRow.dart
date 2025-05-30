class WallpaperEstimateRow {
  int? id;
  final int estimateId;
  final String room;
  final String description;
  final double length;
  final double height;
  final double rate;
  final double quantity;
  final double amount;
  final bool primerIncluded;
  final double transportCost;
  final double labour;
  final double discount;
  final double gstPercentage;
  double totalAmount;

  WallpaperEstimateRow({
    this.id,
    required this.estimateId,
    required this.room,
    required this.description,
    required this.length,
    required this.height,
    required this.rate,
    required this.quantity,
    required this.amount,
    required this.primerIncluded,
    required this.discount,
    required this.gstPercentage,
    required this.labour,
    required this.transportCost,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimateId': estimateId,
      'room': room,
      'description': description,
      'length': length,
      'height': height,
      'rate': rate,
      'quantity': quantity,
      'amount': amount,
      'primerIncluded': primerIncluded ? 1 : 0,
      'transportCost': transportCost,
      'labour': labour,
      'gstPercentage': gstPercentage,
      'discount': discount,
      'totalAmount': totalAmount,
    };
  }

  factory WallpaperEstimateRow.fromMap(Map<String, dynamic> map) {
    return WallpaperEstimateRow(
      id: map['id'],
      estimateId: map['estimateId'],
      room: map['room'],
      description: map['description'],
      length: map['length'],
      height: map['height'],
      rate: map['rate'],
      quantity: map['quantity'],
      amount: map['amount'],
      primerIncluded: map['primerIncluded'] == 1,
      discount: map['discount'],
      gstPercentage: map['gstPercentage'],
      labour: map['labour'],
      transportCost: map['transportCost'],
      totalAmount: map['totalAmount'],
    );
  }
}
