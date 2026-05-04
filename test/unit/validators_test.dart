import 'package:flutter_test/flutter_test.dart';
import 'package:digital_card/shared/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('null returns error', () {
      expect(Validators.required(null), isNotNull);
    });
    test('empty string returns error', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });
    test('valid value returns null', () {
      expect(Validators.required('John'), isNull);
    });
    test('custom field name in message', () {
      final msg = Validators.required('', field: 'Name');
      expect(msg, contains('Name'));
    });
  });

  group('Validators.email', () {
    test('null returns error', () {
      expect(Validators.email(null), isNotNull);
    });
    test('invalid email returns error', () {
      expect(Validators.email('notanemail'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@nodomain.com'), isNotNull);
    });
    test('valid email returns null', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user+tag@sub.domain.org'), isNull);
    });
  });

  group('Validators.password', () {
    test('null returns error', () {
      expect(Validators.password(null), isNotNull);
    });
    test('too short returns error', () {
      expect(Validators.password('abc'), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
    });
    test('too long returns error', () {
      expect(Validators.password('a' * 73), isNotNull);
    });
    test('valid password returns null', () {
      expect(Validators.password('password123'), isNull);
      expect(Validators.password('a' * 72), isNull);
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.url', () {
    test('empty/null returns null (optional field)', () {
      expect(Validators.url(null), isNull);
      expect(Validators.url(''), isNull);
      expect(Validators.url('   '), isNull);
    });
    test('missing scheme returns error', () {
      expect(Validators.url('example.com'), isNotNull);
      expect(Validators.url('www.example.com'), isNotNull);
    });
    test('http and https accepted', () {
      expect(Validators.url('https://example.com'), isNull);
      expect(Validators.url('http://example.com'), isNull);
    });
  });

  group('Validators.hexColor', () {
    test('empty returns error', () {
      expect(Validators.hexColor(''), isNotNull);
      expect(Validators.hexColor(null), isNotNull);
    });
    test('invalid hex returns error', () {
      expect(Validators.hexColor('1A73E8'), isNotNull);
      expect(Validators.hexColor('#ZZZ000'), isNotNull);
      expect(Validators.hexColor('#1A73'), isNotNull);
    });
    test('valid hex returns null', () {
      expect(Validators.hexColor('#1A73E8'), isNull);
      expect(Validators.hexColor('#ffffff'), isNull);
      expect(Validators.hexColor('#000000'), isNull);
    });
  });
}
