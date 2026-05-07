import 'card_data.dart';

class CardModel {
  const CardModel({
    required this.id,
    required this.slug,
    required this.isActive,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.companyId,
    this.issuedById,
    this.issuedToId,
    this.issuedToEmail,
  });

  final String id;
  final String slug;
  final bool isActive;
  final CardData data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? companyId;
  final String? issuedById;
  final String? issuedToId;
  final String? issuedToEmail;

  bool get isIssued => issuedById != null;

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
        id: json['id'] as String,
        slug: json['slug'] as String,
        isActive: json['is_active'] as bool? ?? true,
        data: CardData.fromJson(json['data'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        companyId: json['company_id'] as String?,
        issuedById: json['issued_by_id'] as String?,
        issuedToId: json['issued_to_id'] as String?,
        issuedToEmail: json['issued_to_email'] as String?,
      );

  CardModel copyWith({CardData? data, bool? isActive}) => CardModel(
        id: id,
        slug: slug,
        isActive: isActive ?? this.isActive,
        data: data ?? this.data,
        createdAt: createdAt,
        updatedAt: updatedAt,
        companyId: companyId,
        issuedById: issuedById,
        issuedToId: issuedToId,
        issuedToEmail: issuedToEmail,
      );
}
