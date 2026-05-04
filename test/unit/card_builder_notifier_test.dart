import 'package:flutter_test/flutter_test.dart';
import 'package:digital_card/features/cards/providers/card_builder_provider.dart';
import 'package:digital_card/features/cards/domain/card_data.dart';

void main() {
  late CardBuilderNotifier notifier;

  setUp(() {
    notifier = CardBuilderNotifier();
  });

  tearDown(() {
    notifier.dispose();
  });

  test('starts with empty CardData', () {
    expect(notifier.state.name, isEmpty);
    expect(notifier.state.template, CardTemplate.minimal);
    expect(notifier.state.accentColor, '#1A73E8');
  });

  test('initializes with provided data', () {
    const data = CardData(
      name: 'John',
      template: CardTemplate.bold,
      accentColor: '#FF0000',
    );
    final n = CardBuilderNotifier(data);
    expect(n.state.name, 'John');
    expect(n.state.template, CardTemplate.bold);
    n.dispose();
  });

  group('field setters', () {
    test('setName updates name', () {
      notifier.setName('Alice');
      expect(notifier.state.name, 'Alice');
    });

    test('setTitle sets and clears title', () {
      notifier.setTitle('Manager');
      expect(notifier.state.title, 'Manager');
      notifier.setTitle('');
      expect(notifier.state.title, isNull);
    });

    test('setEmail sets and clears email', () {
      notifier.setEmail('a@b.com');
      expect(notifier.state.email, 'a@b.com');
      notifier.setEmail('');
      expect(notifier.state.email, isNull);
    });

    test('setTemplate updates template', () {
      notifier.setTemplate(CardTemplate.glass);
      expect(notifier.state.template, CardTemplate.glass);
    });

    test('setAccentColor updates accent color', () {
      notifier.setAccentColor('#FF5722');
      expect(notifier.state.accentColor, '#FF5722');
    });
  });

  group('social links', () {
    const link1 = SocialLink(platform: 'github', url: 'https://github.com/a');
    const link2 = SocialLink(platform: 'linkedin', url: 'https://linkedin.com/in/a');

    test('addSocial appends link', () {
      notifier.addSocial(link1);
      expect(notifier.state.socials.length, 1);
      notifier.addSocial(link2);
      expect(notifier.state.socials.length, 2);
    });

    test('removeSocial removes by index', () {
      notifier.addSocial(link1);
      notifier.addSocial(link2);
      notifier.removeSocial(0);
      expect(notifier.state.socials.length, 1);
      expect(notifier.state.socials.first.platform, 'linkedin');
    });

    test('updateSocial replaces by index', () {
      notifier.addSocial(link1);
      const updated = SocialLink(platform: 'twitter', url: 'https://x.com/a');
      notifier.updateSocial(0, updated);
      expect(notifier.state.socials.first.platform, 'twitter');
    });
  });

  test('reset restores empty state', () {
    notifier.setName('Alice');
    notifier.addSocial(const SocialLink(platform: 'x', url: 'https://x.com'));
    notifier.reset();
    expect(notifier.state.name, isEmpty);
    expect(notifier.state.socials, isEmpty);
  });

  test('reset with data restores to provided data', () {
    const data = CardData(name: 'Bob', template: CardTemplate.glass, accentColor: '#000000');
    notifier.setName('Alice');
    notifier.reset(data);
    expect(notifier.state.name, 'Bob');
  });
}
