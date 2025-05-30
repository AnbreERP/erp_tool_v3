import 'BaseEstimateRow.dart';

class QuartzEstimateRow extends BaseEstimateRow {
  double thickness;
  double panelRft;

  QuartzEstimateRow({
    super.id,
    super.estimateId,
    super.version,
    required super.sNo,
    super.description,
    super.quantity,
    super.rate,
    super.amount,
    this.thickness = 0.0,
    this.panelRft = 0.0,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimateId': estimateId,
      'version': version,
      'sNo': sNo,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'thickness': thickness,
      'panelRft': panelRft,
    };
  }

  factory QuartzEstimateRow.fromMap(Map<String, dynamic> map) {
    return QuartzEstimateRow(
      id: map['id'],
      estimateId: map['estimateId'],
      version: map['version'],
      sNo: map['sNo'],
      description: map['description'],
      quantity: map['quantity'],
      rate: map['rate'],
      amount: map['amount'],
      thickness: map['thickness'],
      panelRft: map['panelRft'],
    );
  }
}
