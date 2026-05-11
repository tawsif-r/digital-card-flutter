import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/contact_repository.dart';
import '../domain/contact_model.dart';
import '../../../core/di/providers.dart';
import '../../../core/providers/session_provider.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(ref.watch(dioProvider));
});

// ── Accepted Contacts ────────────────────────────────────────────────────────

class ContactsState {
  const ContactsState({
    this.contacts = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
    this.search,
    this.pendingCount = 0,
  });

  final List<ContactModel> contacts;
  final int total;
  final int page;
  final bool isLoadingMore;
  final String? search;
  final int pendingCount;

  bool get hasMore => contacts.length < total;

  ContactsState copyWith({
    List<ContactModel>? contacts,
    int? total,
    int? page,
    bool? isLoadingMore,
    String? search,
    int? pendingCount,
  }) =>
      ContactsState(
        contacts: contacts ?? this.contacts,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        search: search ?? this.search,
        pendingCount: pendingCount ?? this.pendingCount,
      );
}

class ContactsNotifier extends AsyncNotifier<ContactsState> {
  static const _limit = 20;

  @override
  Future<ContactsState> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return const ContactsState();
    final results = await Future.wait([
      ref.read(contactRepositoryProvider).getAccepted(page: 1, limit: _limit),
      ref.read(contactRepositoryProvider).getPending(),
    ]);
    final accepted = results[0] as dynamic;
    final pending = results[1] as List<ContactModel>;
    return ContactsState(
      contacts: accepted.data as List<ContactModel>,
      total: accepted.total as int,
      page: accepted.page as int,
      pendingCount: pending.length,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final results = await Future.wait([
        ref.read(contactRepositoryProvider).getAccepted(
              search: current?.search,
              page: 1,
              limit: _limit,
            ),
        ref.read(contactRepositoryProvider).getPending(),
      ]);
      final accepted = results[0] as dynamic;
      final pending = results[1] as List<ContactModel>;
      return ContactsState(
        contacts: accepted.data as List<ContactModel>,
        total: accepted.total as int,
        page: accepted.page as int,
        search: current?.search,
        pendingCount: pending.length,
      );
    });
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(contactRepositoryProvider).getAccepted(
            search: query.isEmpty ? null : query,
            page: 1,
            limit: _limit,
          );
      return ContactsState(
        contacts: result.data,
        total: result.total,
        page: result.page,
        search: query.isEmpty ? null : query,
        pendingCount: state.valueOrNull?.pendingCount ?? 0,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref.read(contactRepositoryProvider).getAccepted(
            search: current.search,
            page: current.page + 1,
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

  Future<String?> removeContact(String id) async {
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

  Future<String?> updateNotes(String id, String? notes) async {
    try {
      await ref.read(contactRepositoryProvider).updateNotes(id, notes);
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  void decrementPending() {
    final current = state.valueOrNull;
    if (current == null) return;
    final newCount = (current.pendingCount - 1).clamp(0, 9999);
    state = AsyncData(current.copyWith(pendingCount: newCount));
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
      if (status == 409) return 'Already connected.';
      if (status == 403) return 'Permission denied.';
      if (status == 404) return 'Not found.';
    }
    return 'Something went wrong. Try again.';
  }
}

final contactsProvider =
    AsyncNotifierProvider<ContactsNotifier, ContactsState>(ContactsNotifier.new);

// ── Pending Requests ─────────────────────────────────────────────────────────

class PendingRequestsNotifier extends AsyncNotifier<List<ContactModel>> {
  @override
  Future<List<ContactModel>> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return [];
    return ref.read(contactRepositoryProvider).getPending();
  }

  Future<String?> accept(String contactId) async {
    try {
      await ref.read(contactRepositoryProvider).accept(contactId);
      state = AsyncData(
        (state.valueOrNull ?? []).where((c) => c.id != contactId).toList(),
      );
      ref.read(contactsProvider.notifier).refresh();
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  Future<String?> reject(String contactId) async {
    try {
      await ref.read(contactRepositoryProvider).reject(contactId);
      final updated = (state.valueOrNull ?? []).where((c) => c.id != contactId).toList();
      state = AsyncData(updated);
      ref.read(contactsProvider.notifier).decrementPending();
      return null;
    } catch (e) {
      return _extractError(e);
    }
  }

  String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String) return msg;
      }
    }
    return 'Something went wrong. Try again.';
  }
}

final pendingRequestsProvider =
    AsyncNotifierProvider<PendingRequestsNotifier, List<ContactModel>>(
        PendingRequestsNotifier.new);

// ── Contact Detail ────────────────────────────────────────────────────────────

final contactDetailProvider =
    FutureProvider.family<ContactModel, String>((ref, id) async {
  final userId = ref.watch(userSessionProvider);
  if (userId == null) throw StateError('Not authenticated');
  return ref.read(contactRepositoryProvider).getOne(id);
});

// ── User Search ───────────────────────────────────────────────────────────────

class UserSearchState {
  const UserSearchState({
    this.results = const [],
    this.total = 0,
    this.page = 1,
    this.query = '',
    this.isLoading = false,
  });

  final List<UserSearchResult> results;
  final int total;
  final int page;
  final String query;
  final bool isLoading;

  bool get hasMore => results.length < total;
  bool get isEmpty => query.isEmpty;

  UserSearchState copyWith({
    List<UserSearchResult>? results,
    int? total,
    int? page,
    String? query,
    bool? isLoading,
  }) =>
      UserSearchState(
        results: results ?? this.results,
        total: total ?? this.total,
        page: page ?? this.page,
        query: query ?? this.query,
        isLoading: isLoading ?? this.isLoading,
      );
}

class UserSearchNotifier extends AsyncNotifier<UserSearchState> {
  @override
  Future<UserSearchState> build() async => const UserSearchState();

  Future<void> search(String q) async {
    if (q.trim().isEmpty) {
      state = const AsyncData(UserSearchState());
      return;
    }
    state = AsyncData(state.valueOrNull?.copyWith(isLoading: true, query: q) ??
        UserSearchState(query: q, isLoading: true));
    try {
      final result = await ref
          .read(contactRepositoryProvider)
          .searchUsers(q: q.trim(), page: 1);
      state = AsyncData(UserSearchState(
        results: result.data,
        total: result.total,
        page: 1,
        query: q.trim(),
      ));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoading) return;
    state = AsyncData(current.copyWith(isLoading: true));
    try {
      final result = await ref
          .read(contactRepositoryProvider)
          .searchUsers(q: current.query, page: current.page + 1);
      state = AsyncData(current.copyWith(
        results: [...current.results, ...result.data],
        total: result.total,
        page: result.page,
        isLoading: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoading: false));
    }
  }

  Future<String?> sendRequest(String userId) async {
    try {
      await ref.read(contactRepositoryProvider).sendRequest(userId);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          results: current.results
              .map((u) => u.id == userId ? u.withStatus(ContactStatus.pending) : u)
              .toList(),
        ));
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'];
          if (msg is String) return msg;
        }
        if (e.response?.statusCode == 409) return 'Already connected or request pending.';
      }
      return 'Something went wrong. Try again.';
    }
  }
}

final userSearchProvider =
    AsyncNotifierProvider<UserSearchNotifier, UserSearchState>(UserSearchNotifier.new);
