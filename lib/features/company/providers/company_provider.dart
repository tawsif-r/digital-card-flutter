import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/company_repository.dart';
import '../domain/company_model.dart';
import '../../../core/di/providers.dart';
import '../../../core/providers/session_provider.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(ref.watch(dioProvider));
});

class CompanyNotifier extends AsyncNotifier<CompanyModel?> {
  @override
  Future<CompanyModel?> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return null;
    return ref.read(companyRepositoryProvider).getMe();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(companyRepositoryProvider).getMe());
  }

  Future<String?> onboard({
    required String name,
    required String description,
    required int size,
  }) async {
    try {
      final company = await ref.read(companyRepositoryProvider).onboard(
            name: name,
            description: description,
            size: size,
          );
      state = AsyncData(company);
      return null;
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'];
          if (msg is String) return msg;
          if (msg is List && msg.isNotEmpty) return msg.join(', ');
        }
        return 'Server error ${e.response?.statusCode}: ${e.response?.data}';
      }
      return e.toString();
    }
  }
}

final companyProvider = AsyncNotifierProvider<CompanyNotifier, CompanyModel?>(CompanyNotifier.new);
