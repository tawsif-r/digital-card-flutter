import 'message_model.dart';

class MessagesPage {
  const MessagesPage({required this.data, this.nextCursor});

  final List<MessageModel> data;
  final String? nextCursor;

  factory MessagesPage.fromJson(Map<String, dynamic> json) => MessagesPage(
        data: (json['data'] as List)
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );
}
