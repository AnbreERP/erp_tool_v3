class Product {
  int? id;
  String description;
  String light_details;
  double material_rate;
  double labour_rate;
  double boq_material_rate;
  double boq_labour_rate;

  @override
  String toString() {
    return 'Product{id: $id, description: $description, light_details: $light_details, material_rate: $material_rate, labour_rate: $labour_rate, boq_material_rate: $boq_material_rate, boq_labour_rate: $boq_labour_rate}';
  }

  Product({
    this.id,
    required this.description,
    required this.light_details,
    required this.material_rate,
    required this.labour_rate,
    required this.boq_material_rate,
    required this.boq_labour_rate,
  });

// Convert a Map to a Product object
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      description: map['description'],
      light_details: map['light_details'],
      material_rate: map['material_rate'],
      labour_rate: map['labour_rate'],
      boq_material_rate: map['boq_material_rate'],
      boq_labour_rate: map['boq_labour_rate'],
    );
  }

  // Convert a Product object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'light_details': light_details,
      'material_rate': material_rate,
      'labour_rate': labour_rate,
      'boq_material_rate': boq_material_rate,
      'boq_labour_rate': boq_labour_rate,
    };
  }
}
