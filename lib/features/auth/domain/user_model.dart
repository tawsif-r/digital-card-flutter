enum UserRole {
  employer,
  employee;

  static UserRole fromString(String s) =>
      s == 'employee' ? UserRole.employee : UserRole.employer;
}

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        role: UserRole.fromString(json['role'] as String? ?? 'employer'),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  UserModel copyWith({String? name}) => UserModel(
        id: id,
        email: email,
        name: name ?? this.name,
        role: role,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
