import '../../cards/domain/card_model.dart';

class ContactModel {
  const ContactModel({
    required this.id,
    required this.ownerId,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.cardId,
    this.cardSlug,
    this.contactUserId,
    this.notes,
    this.card,
  });

  final String id;
  final String ownerId;
  final String? cardId;
  final String? cardSlug;
  final String? contactUserId;
  final String source; // 'scan' | 'phone_import' | 'email_import'
  final String? notes;
  final CardModel? card;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName => card?.data.name ?? cardSlug ?? 'Unknown';
  String? get displayEmail => card?.data.email;
  String? get displayPhone => card?.data.phone;
  String? get displayCompany => card?.data.company;

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        cardId: json['card_id'] as String?,
        cardSlug: json['card_slug'] as String?,
        contactUserId: json['contact_user_id'] as String?,
        source: json['source'] as String,
        notes: json['notes'] as String?,
        card: json['card'] != null
            ? CardModel.fromJson(json['card'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  ContactModel copyWith({
    String? notes,
    CardModel? card,
  }) =>
      ContactModel(
        id: id,
        ownerId: ownerId,
        cardId: cardId,
        cardSlug: cardSlug,
        contactUserId: contactUserId,
        source: source,
        notes: notes ?? this.notes,
        card: card ?? this.card,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class PhoneImportResult {
  const PhoneImportResult({
    required this.matched,
    required this.notFound,
    required this.skippedDuplicates,
  });

  final List<ContactModel> matched;
  final int notFound;
  final int skippedDuplicates;

  factory PhoneImportResult.fromJson(Map<String, dynamic> json) =>
      PhoneImportResult(
        matched: (json['matched'] as List)
            .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        notFound: json['not_found'] as int,
        skippedDuplicates: json['skipped_duplicates'] as int,
      );
}
