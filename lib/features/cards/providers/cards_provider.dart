import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/card_repository.dart';
import '../domain/card_model.dart';
import '../domain/card_data.dart';
import '../../../core/di/providers.dart';

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(dioProvider));
});

class CardsNotifier extends AsyncNotifier<List<CardModel>> {
  @override
  Future<List<CardModel>> build() async {
    return ref.read(cardRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cardRepositoryProvider).getAll());
  }

  Future<CardModel?> createCard(CardData data) async {
    try {
      final card = await ref.read(cardRepositoryProvider).create(data);
      state = AsyncData([card, ...state.valueOrNull ?? []]);
      return card;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCard(String id, CardData data) async {
    try {
      final updated = await ref.read(cardRepositoryProvider).update(id, data);
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.map((c) => c.id == id ? updated : c).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCard(String id) async {
    final previous = state.valueOrNull ?? [];
    // Optimistic removal
    state = AsyncData(previous.where((c) => c.id != id).toList());
    try {
      await ref.read(cardRepositoryProvider).delete(id);
      return true;
    } catch (_) {
      state = AsyncData(previous);
      return false;
    }
  }
}

final cardsProvider = AsyncNotifierProvider<CardsNotifier, List<CardModel>>(CardsNotifier.new);
