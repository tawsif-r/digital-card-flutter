class CompanyModel {
  const CompanyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.size,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final int size;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        size: json['size'] as int,
        ownerId: json['owner_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
