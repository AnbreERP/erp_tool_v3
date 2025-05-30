class MaterialModel {
  int? id; // Nullable for new entries
  String type;
  String unitType;
  String finish;
  double rate;
  DateTime dateAdded;

  MaterialModel({
    this.id,
    required this.type,
    required this.unitType,
    required this.finish,
    required this.rate,
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'unitType': unitType,
      'finish': finish,
      'rate': rate,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      unitType: map['unitType'] as String,
      finish: map['finish'] as String,
      rate: map['rate'] as double,
      dateAdded: DateTime.parse(map['dateAdded'] as String),
    );
  }
}
