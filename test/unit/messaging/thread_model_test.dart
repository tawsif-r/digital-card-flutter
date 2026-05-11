import 'package:digital_card/features/messaging/domain/thread_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThreadModel', () {
    final json = {
      'id': 't1',
      'user_a_id': 'a-uuid',
      'user_b_id': 'b-uuid',
      'last_message_at': '2026-05-11T10:00:00.000Z',
      'last_message_id': 'm1',
      'user_a_last_read_at': '2026-05-11T09:00:00.000Z',
      'user_b_last_read_at': null,
      'created_at': '2026-05-01T00:00:00.000Z',
      'updated_at': '2026-05-11T10:00:00.000Z',
    };

    test('parses fromJson with nulls', () {
      final t = ThreadModel.fromJson(json);
      expect(t.id, 't1');
      expect(t.userAId, 'a-uuid');
      expect(t.userBId, 'b-uuid');
      expect(t.lastMessageId, 'm1');
      expect(t.userBLastReadAt, isNull);
    });

    test('peerId returns the other user', () {
      final t = ThreadModel.fromJson(json);
      expect(t.peerId('a-uuid'), 'b-uuid');
      expect(t.peerId('b-uuid'), 'a-uuid');
    });

    test('myLastReadAt picks correct column', () {
      final t = ThreadModel.fromJson(json);
      expect(t.myLastReadAt('a-uuid'), isNotNull);
      expect(t.myLastReadAt('b-uuid'), isNull);
    });

    test('isParticipant', () {
      final t = ThreadModel.fromJson(json);
      expect(t.isParticipant('a-uuid'), isTrue);
      expect(t.isParticipant('b-uuid'), isTrue);
      expect(t.isParticipant('other'), isFalse);
    });
  });
}
