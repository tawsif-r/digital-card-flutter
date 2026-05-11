import 'package:dio/dio.dart';
import '../../../shared/domain/paged_result.dart';
import '../domain/message_model.dart';
import '../domain/messages_page.dart';
import '../domain/thread_model.dart';
import '../domain/thread_with_peer.dart';

class MessagingRepository {
  MessagingRepository(this._dio);

  final Dio _dio;

  Future<ThreadModel> createOrGetThread({
    String? contactId,
    String? userId,
  }) async {
    assert(
      contactId != null || userId != null,
      'createOrGetThread requires contactId or userId',
    );
    final res = await _dio.post('/messaging/threads', data: {
      if (contactId != null) 'contactId': contactId,
      if (userId != null) 'userId': userId,
    });
    return ThreadModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PagedResult<ThreadWithPeer>> listThreads({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/messaging/threads',
      queryParameters: {'page': page, 'limit': limit},
    );
    return PagedResult.fromJson(res.data!, ThreadWithPeer.fromJson);
  }

  Future<ThreadModel> getThread(String threadId) async {
    final res = await _dio.get('/messaging/threads/$threadId');
    return ThreadModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MessagesPage> getMessages(
    String threadId, {
    String? cursor,
    int limit = 30,
    String direction = 'before',
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/messaging/threads/$threadId/messages',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
        'direction': direction,
      },
    );
    return MessagesPage.fromJson(res.data!);
  }

  Future<MessageModel> sendMessage(
    String threadId,
    String body, {
    String? clientNonce,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/messaging/threads/$threadId/messages',
      data: {
        'body': body,
        if (clientNonce != null) 'clientNonce': clientNonce,
      },
    );
    return MessageModel.fromJson(_extractMessagePayload(res.data));
  }

  Future<MessageModel> editMessage(String messageId, String body) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/messaging/messages/$messageId',
      data: {'body': body},
    );
    return MessageModel.fromJson(_extractMessagePayload(res.data));
  }

  Map<String, dynamic> _extractMessagePayload(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw const FormatException('Empty response body');
    }

    if (payload['id'] is String) return payload;

    final message = payload['message'];
    if (message is Map<String, dynamic>) return message;
    if (message is Map) return Map<String, dynamic>.from(message);

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      if (data['id'] is String) return data;
      final nestedMessage = data['message'];
      if (nestedMessage is Map<String, dynamic>) return nestedMessage;
      if (nestedMessage is Map) return Map<String, dynamic>.from(nestedMessage);
    }
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap['id'] is String) return dataMap;
      final nestedMessage = dataMap['message'];
      if (nestedMessage is Map<String, dynamic>) return nestedMessage;
      if (nestedMessage is Map) {
        return Map<String, dynamic>.from(nestedMessage);
      }
    }

    throw const FormatException('Unexpected message response format');
  }

  Future<void> deleteMessage(String messageId) async {
    await _dio.delete('/messaging/messages/$messageId');
  }

  Future<DateTime> markRead(String threadId, {DateTime? lastReadAt}) async {
    final res = await _dio.post(
      '/messaging/threads/$threadId/read',
      data: {
        if (lastReadAt != null) 'lastReadAt': lastReadAt.toIso8601String(),
      },
    );
    final data = res.data as Map<String, dynamic>;
    return DateTime.parse(data['lastReadAt'] as String);
  }

  Future<int> getUnreadCount(String threadId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/messaging/threads/$threadId/unread-count',
    );
    return _extractUnreadCount(res.data);
  }

  int _extractUnreadCount(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw const FormatException('Empty unread-count response body');
    }

    final direct =
        payload['count'] ?? payload['unread_count'] ?? payload['unreadCount'];
    final parsedDirect = _parseCountValue(direct);
    if (parsedDirect != null) return parsedDirect;

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final parsedNested = _parseCountValue(
        data['count'] ?? data['unread_count'] ?? data['unreadCount'],
      );
      if (parsedNested != null) return parsedNested;
    }
    if (data is Map) {
      final parsedNested = _parseCountValue(
        data['count'] ?? data['unread_count'] ?? data['unreadCount'],
      );
      if (parsedNested != null) return parsedNested;
    }

    throw const FormatException('Unexpected unread-count response format');
  }

  int? _parseCountValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      throw FormatException('Invalid unread count value: $value');
    }
    return null;
  }
}

String extractMessagingError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List && msg.isNotEmpty) return msg.join(', ');
    }
    switch (e.response?.statusCode) {
      case 400:
        return 'Cannot start chat. Contact has no registered account.';
      case 403:
        return 'You are not a participant in this thread.';
      case 404:
        return 'Thread or message not found.';
      case 429:
        return 'Sending too fast. Slow down.';
    }
  }
  if (e is FormatException) {
    return 'Unexpected server response format.';
  }
  return 'Something went wrong. Try again.';
}
