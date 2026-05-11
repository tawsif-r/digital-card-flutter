import 'package:digital_card/features/messaging/domain/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageModel', () {
    Map<String, dynamic> base() => {
          'id': 'm1',
          'thread_id': 't1',
          'sender_id': 'u1',
          'body': 'hello',
          'edited_at': null,
          'deleted_at': null,
          'created_at': '2026-05-11T10:00:00.000Z',
          'updated_at': '2026-05-11T10:00:00.000Z',
        };

    test('parses fromJson', () {
      final m = MessageModel.fromJson(base());
      expect(m.id, 'm1');
      expect(m.body, 'hello');
      expect(m.isDeleted, isFalse);
      expect(m.isEdited, isFalse);
    });

    test('isDeleted when deleted_at present', () {
      final json = base()
        ..['deleted_at'] = '2026-05-11T11:00:00.000Z'
        ..['body'] = null;
      final m = MessageModel.fromJson(json);
      expect(m.isDeleted, isTrue);
      expect(m.body, isNull);
    });

    test('isEdited when edited_at present', () {
      final json = base()..['edited_at'] = '2026-05-11T11:00:00.000Z';
      final m = MessageModel.fromJson(json);
      expect(m.isEdited, isTrue);
    });

    test('isMine compares senderId', () {
      final m = MessageModel.fromJson(base());
      expect(m.isMine('u1'), isTrue);
      expect(m.isMine('u2'), isFalse);
    });

    test('copyWith preserves clientNonce + pending flags', () {
      final m = MessageModel.fromJson(base()).copyWith(
        clientNonce: 'n1',
        pending: true,
      );
      expect(m.clientNonce, 'n1');
      expect(m.pending, isTrue);
      final reconciled = m.copyWith(pending: false);
      expect(reconciled.pending, isFalse);
      expect(reconciled.clientNonce, 'n1');
    });
  });
}
