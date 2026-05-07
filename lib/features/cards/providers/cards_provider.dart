import 'package:dio/dio.dart';
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

  Future<(CardModel?, String?)> createCard(CardData data) async {
    try {
      final card = await ref.read(cardRepositoryProvider).create(data);
      state = AsyncData([card, ...state.valueOrNull ?? []]);
      return (card, null);
    } catch (e) {
      return (null, _extractError(e));
    }
  }

  Future<(bool, String?)> updateCard(String id, CardData data) async {
    try {
      final updated = await ref.read(cardRepositoryProvider).update(id, data);
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.map((c) => c.id == id ? updated : c).toList());
      return (true, null);
    } catch (e) {
      return (false, _extractError(e));
    }
  }

  String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
        if (msg is Map) return msg['message']?.toString() ?? 'Validation error.';
      }
      final status = e.response?.statusCode;
      if (status == 401) return 'Session expired. Please log in again.';
      if (status == 403) return 'Permission denied.';
      if (status == 400) return 'Validation error: check your fields.';
    }
    return 'Failed to save. Try again.';
  }

  Future<bool> deleteCard(String id) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncData(previous.where((c) => c.id != id).toList());
    try {
      await ref.read(cardRepositoryProvider).delete(id);
      return true;
    } catch (_) {
      state = AsyncData(previous);
      return false;
    }
  }

  Future<(CardModel?, String?)> issueCard(String email, CardData data) async {
    try {
      final card = await ref.read(cardRepositoryProvider).issue(
            issuedToEmail: email,
            data: data,
          );
      state = AsyncData([card, ...state.valueOrNull ?? []]);
      return (card, null);
    } catch (e) {
      return (null, _extractError(e));
    }
  }
}

final cardsProvider = AsyncNotifierProvider<CardsNotifier, List<CardModel>>(CardsNotifier.new);

class IssuedCardsNotifier extends AsyncNotifier<List<CardModel>> {
  @override
  Future<List<CardModel>> build() async {
    return ref.read(cardRepositoryProvider).getIssuedToMe();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cardRepositoryProvider).getIssuedToMe());
  }
}

final issuedCardsProvider =
    AsyncNotifierProvider<IssuedCardsNotifier, List<CardModel>>(IssuedCardsNotifier.new);
