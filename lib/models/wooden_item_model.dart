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
