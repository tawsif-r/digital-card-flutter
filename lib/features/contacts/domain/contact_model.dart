enum ContactStatus { pending, accepted, blocked }

ContactStatus _statusFromString(String s) => switch (s) {
      'accepted' => ContactStatus.accepted,
      'blocked' => ContactStatus.blocked,
      _ => ContactStatus.pending,
    };

class ContactPeerCard {
  const ContactPeerCard({
    required this.name,
    this.title,
    this.company,
    this.phone,
    this.email,
    this.photoUrl,
  });

  final String name;
  final String? title;
  final String? company;
  final String? phone;
  final String? email;
  final String? photoUrl;

  factory ContactPeerCard.fromJson(Map<String, dynamic> json) => ContactPeerCard(
        name: json['name'] as String? ?? '',
        title: json['title'] as String?,
        company: json['company'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        photoUrl: json['photo_url'] as String?,
      );
}

class ContactPeer {
  const ContactPeer({
    required this.id,
    required this.email,
    this.name,
    this.card,
  });

  final String id;
  final String email;
  final String? name;
  final ContactPeerCard? card;

  String get displayName => card?.name ?? name ?? email;
  String? get displayTitle => card?.title;
  String? get displayCompany => card?.company;
  String? get displayPhone => card?.phone;
  String? get displayEmail => card?.email ?? email;
  String? get photoUrl => card?.photoUrl;

  factory ContactPeer.fromJson(Map<String, dynamic> json) => ContactPeer(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        card: json['card'] != null
            ? ContactPeerCard.fromJson(json['card'] as Map<String, dynamic>)
            : null,
      );
}

class ContactModel {
  const ContactModel({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.addresseeNotes,
    this.peerData,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final ContactStatus status;
  final String? notes;
  final String? addresseeNotes;
  // Backend enriches and returns the other person as `peer` (already resolved server-side)
  final ContactPeer? peerData;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Backend already resolved peer relative to current user; fall back gracefully
  ContactPeer? peer(String myUserId) => peerData;

  String? myNotes(String myUserId) =>
      requesterId == myUserId ? notes : addresseeNotes;

  ContactModel copyWith({
    ContactStatus? status,
    String? notes,
    String? addresseeNotes,
  }) =>
      ContactModel(
        id: id,
        requesterId: requesterId,
        addresseeId: addresseeId,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        addresseeNotes: addresseeNotes ?? this.addresseeNotes,
        peerData: peerData,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        id: json['id'] as String,
        requesterId: json['requester_id'] as String,
        addresseeId: json['addressee_id'] as String,
        status: _statusFromString(json['status'] as String? ?? 'pending'),
        notes: json['notes'] as String?,
        addresseeNotes: json['addressee_notes'] as String?,
        peerData: json['peer'] != null
            ? ContactPeer.fromJson(json['peer'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.email,
    this.name,
    this.card,
    this.relationStatus,
  });

  final String id;
  final String email;
  final String? name;
  final ContactPeerCard? card;
  final ContactStatus? relationStatus;

  String get displayName => card?.name ?? name ?? email;
  String? get displayTitle => card?.title;
  String? get displayCompany => card?.company;

  UserSearchResult withStatus(ContactStatus status) => UserSearchResult(
        id: id,
        email: email,
        name: name,
        card: card,
        relationStatus: status,
      );

  factory UserSearchResult.fromJson(Map<String, dynamic> json) => UserSearchResult(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        card: json['card'] != null
            ? ContactPeerCard.fromJson(json['card'] as Map<String, dynamic>)
            : null,
        relationStatus: json['relation_status'] != null
            ? _statusFromString(json['relation_status'] as String)
            : null,
      );
}
