import 'package:flutter_test/flutter_test.dart';
import 'package:digital_card/features/cards/domain/card_data.dart';

void main() {
  group('CardData', () {
    const fullData = CardData(
      name: 'John Doe',
      title: 'Engineer',
      company: 'Acme',
      phone: '+1234567890',
      email: 'john@example.com',
      website: 'https://example.com',
      socials: [SocialLink(platform: 'github', url: 'https://github.com/john')],
      photoUrl: 'https://example.com/photo.jpg',
      template: CardTemplate.bold,
      accentColor: '#1A73E8',
    );

    test('empty factory creates valid default', () {
      final empty = CardData.empty();
      expect(empty.name, isEmpty);
      expect(empty.template, CardTemplate.minimal);
      expect(empty.accentColor, '#1A73E8');
      expect(empty.socials, isEmpty);
    });

    group('fromJson', () {
      test('parses full JSON', () {
        final json = {
          'name': 'John Doe',
          'title': 'Engineer',
          'company': 'Acme',
          'phone': '+1234567890',
          'email': 'john@example.com',
          'website': 'https://example.com',
          'socials': [
            {'platform': 'github', 'url': 'https://github.com/john'}
          ],
          'photo_url': 'https://example.com/photo.jpg',
          'template': 'bold',
          'accent_color': '#1A73E8',
        };
        final data = CardData.fromJson(json);
        expect(data.name, 'John Doe');
        expect(data.title, 'Engineer');
        expect(data.template, CardTemplate.bold);
        expect(data.socials.length, 1);
        expect(data.socials.first.platform, 'github');
      });

      test('handles missing optional fields', () {
        final json = {'name': 'Jane', 'template': 'minimal', 'accent_color': '#000000'};
        final data = CardData.fromJson(json);
        expect(data.name, 'Jane');
        expect(data.title, isNull);
        expect(data.socials, isEmpty);
      });

      test('unknown template falls back to minimal', () {
        final json = {'name': 'X', 'template': 'nonexistent', 'accent_color': '#000000'};
        final data = CardData.fromJson(json);
        expect(data.template, CardTemplate.minimal);
      });
    });

    group('toJson', () {
      test('includes required fields', () {
        final json = fullData.toJson();
        expect(json['name'], 'John Doe');
        expect(json['template'], 'bold');
        expect(json['accent_color'], '#1A73E8');
      });

      test('omits null optional fields', () {
        final json = CardData.empty().toJson();
        expect(json.containsKey('title'), isFalse);
        expect(json.containsKey('company'), isFalse);
        expect(json.containsKey('phone'), isFalse);
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('website'), isFalse);
        expect(json.containsKey('photo_url'), isFalse);
      });

      test('roundtrip: data -> json -> data', () {
        final json = fullData.toJson();
        final restored = CardData.fromJson(json);
        expect(restored.name, fullData.name);
        expect(restored.title, fullData.title);
        expect(restored.template, fullData.template);
        expect(restored.accentColor, fullData.accentColor);
        expect(restored.socials.length, fullData.socials.length);
      });
    });

    group('copyWith', () {
      test('changes specified fields', () {
        final updated = fullData.copyWith(name: 'Jane');
        expect(updated.name, 'Jane');
        expect(updated.title, fullData.title);
      });

      test('sets nullable fields to null', () {
        final updated = fullData.copyWith(title: null);
        expect(updated.title, isNull);
        expect(updated.name, fullData.name);
      });
    });
  });

  group('SocialLink', () {
    test('fromJson / toJson roundtrip', () {
      final json = {'platform': 'linkedin', 'url': 'https://linkedin.com/in/john'};
      final link = SocialLink.fromJson(json);
      expect(link.platform, 'linkedin');
      expect(link.toJson(), json);
    });
  });

  group('CardTemplate', () {
    test('all values have correct string representation', () {
      expect(CardTemplate.minimal.value, 'minimal');
      expect(CardTemplate.bold.value, 'bold');
      expect(CardTemplate.glass.value, 'glass');
    });

    test('fromString parses all templates', () {
      expect(CardTemplateX.fromString('minimal'), CardTemplate.minimal);
      expect(CardTemplateX.fromString('bold'), CardTemplate.bold);
      expect(CardTemplateX.fromString('glass'), CardTemplate.glass);
    });
  });
}
