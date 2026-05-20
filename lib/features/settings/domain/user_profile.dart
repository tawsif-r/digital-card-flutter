class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.designation,
    this.department,
    this.company,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? designation;
  final String? department;
  final String? company;
  final String? photoUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String?,
        phone: json['phone'] as String?,
        designation: json['designation'] as String?,
        department: json['department'] as String?,
        company: json['company'] as String?,
        photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (designation != null) 'designation': designation,
        if (department != null) 'department': department,
        if (company != null) 'company': company,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  UserProfile copyWith({
    String? email,
    String? fullName,
    String? phone,
    String? designation,
    String? department,
    String? company,
    String? photoUrl,
  }) =>
      UserProfile(
        id: id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        designation: designation ?? this.designation,
        department: department ?? this.department,
        company: company ?? this.company,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}
