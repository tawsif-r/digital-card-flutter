import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/contact_repository.dart';
import '../domain/contact_model.dart';
import '../../../core/di/providers.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(ref.watch(dioProvider));
});

class ContactsState {
  const ContactsState({
    this.contacts = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
    this.search,
    this.sourceFilter,
  });

  final List<ContactModel> contacts;
  final int total;
  final int page;
  final bool isLoadingMore;
  final String? search;
  final String? sourceFilter;

  bool get hasMore => contacts.length < total;

  ContactsState copyWith({
    List<ContactModel>? contacts,
    int? total,
    int? page,
    bool? isLoadingMore,
    String? search,
    Object? sourceFilter = _sentinel,
  }) =>
      ContactsState(
        contacts: contacts ?? this.contacts,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        search: search ?? this.search,
        sourceFilter:
            sourceFilter == _sentinel ? this.sourceFilter : sourceFilter as String?,
      );

  static const Object _sentinel = Object();
}

class ContactsNotifier extends AsyncNotifier<ContactsState> {
  static const _limit = 20;

  @override
  Future<ContactsState> build() => _fetchPage(1);

  Future<ContactsState> _fetchPage(
    int page, {
    String? search,
    String? source,
  }) async {
    final result = await ref.read(contactRepositoryProvider).getAll(
          search: search,
          source: source,
          page: page,
          limit: _limit,
        );
    return ContactsState(
      contacts: result.data,
      total: result.total,
      page: result.page,
      search: search,
      sourceFilter: source,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchPage(1, search: current?.search, source: current?.sourceFilter),
    );
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchPage(1, search: query.isEmpty ? null : query, source: current?.sourceFilter),
    );
  }

  Future<void> setSourceFilter(String? source) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchPage(1, search: current?.search, source: source),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final result = await ref.read(contactRepositoryProvider).getAll(
            search: current.search,
            source: current.sourceFilter,
            page: nextPage,
            limit: _limit,
          );
      state = AsyncData(current.copyWith(
        contacts: [...current.contacts, ...result.data],
        total: result.total,
        page: result.page,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<(ContactModel?, String?)> addBySlug(String slug, {String? notes}) async {
    try {
      final contact = await ref.read(contactRepositoryProvider).addBySlug(slug, notes: notes);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          contacts: [contact, ...current.contacts],
          total: current.total + 1,
        ));
      }
      return (contact, null);
    } catch (e) {
      return (null, _extractError(e));
    }
  }

  Future<(ContactModel?, String?)> addByEmail(String email, {String? notes}) async {
    try {
      final contact = await ref.read(contactRepositoryProvider).addByEmail(email, notes: notes);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          contacts: [contact, ...current.contacts],
          total: current.total + 1,
        ));
      }
      return (contact, null);
    } catch (e) {
      return (null, _extractError(e));
    }
  }

  Future<(PhoneImportResult?, String?)> importFromPhone(
    List<Map<String, String?>> contacts,
  ) async {
    try {
      final result = await ref.read(contactRepositoryProvider).importFromPhone(contacts);
      if (result.matched.isNotEmpty) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncData(current.copyWith(
            contacts: [...result.matched, ...current.contacts],
            total: current.total + result.matched.length,
          ));
        }
      }
      return (result, null);
    } catch (e) {
      return (null, _extractError(e));
    }
  }

  Future<String?> updateNotes(String id, String? notes) async {
    try {
      final updated = await ref.read(contactRepositoryProvider).updateNotes(id, notes);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          contacts: current.contacts.map((c) => c.id == id ? updated : c).toList(),
        ));
      }
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> delete(String id) async {
    final current = state.valueOrNull;
    if (current == null) return null;

    state = AsyncData(current.copyWith(
      contacts: current.contacts.where((c) => c.id != id).toList(),
      total: current.total - 1,
    ));
    try {
      await ref.read(contactRepositoryProvider).delete(id);
      return null;
    } catch (e) {
      state = AsyncData(current);
      return _extractError(e);
    }
  }

  Future<(String?, String?)> shareMyCard(String contactId, {String? cardId}) async {
    try {
      final result = await ref
          .read(contactRepositoryProvider)
          .shareMyCard(contactId, cardId: cardId);
      return (result['recipient_email'], null);
    } catch (e) {
      return (null, _extractError(e));
    }
  }

  String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
      }
      final status = e.response?.statusCode;
      if (status == 409) return 'Contact already saved.';
      if (status == 400) return 'Cannot add yourself.';
      if (status == 404) return 'Card or user not found.';
      if (status == 422) return 'Contact has no email — cannot share.';
      if (status == 403) return 'Permission denied.';
    }
    return 'Something went wrong. Try again.';
  }
}

final contactsProvider =
    AsyncNotifierProvider<ContactsNotifier, ContactsState>(ContactsNotifier.new);

final contactDetailProvider =
    FutureProvider.family<ContactModel, String>((ref, id) async {
  return ref.read(contactRepositoryProvider).getOne(id);
});
