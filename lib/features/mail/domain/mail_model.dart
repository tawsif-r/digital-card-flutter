class MailModel {
  const MailModel({
    required this.id,
    required this.to,
    required this.subject,
    this.textBody,
    this.htmlBody,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final List<String> to;
  final String subject;
  final String? textBody;
  final String? htmlBody;
  final String status;
  final DateTime createdAt;

  factory MailModel.fromJson(Map<String, dynamic> json) => MailModel(
        id: json['id'] as String,
        to: (json['to'] as List).map((e) => e as String).toList(),
        subject: json['subject'] as String,
        textBody: json['textBody'] as String?,
        htmlBody: json['htmlBody'] as String?,
        status: json['status'] as String? ?? 'sent',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
