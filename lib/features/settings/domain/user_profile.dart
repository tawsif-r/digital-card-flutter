class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.designation,
    this.department,
    this.company,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? designation;
  final String? department;
  final String? company;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String?,
        phone: json['phone'] as String?,
        designation: json['designation'] as String?,
        department: json['department'] as String?,
        company: json['company'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (designation != null) 'designation': designation,
        if (department != null) 'department': department,
        if (company != null) 'company': company,
      };

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? designation,
    String? department,
    String? company,
  }) =>
      UserProfile(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        designation: designation ?? this.designation,
        department: department ?? this.department,
        company: company ?? this.company,
      );
}
