import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../data/mail_repository.dart';
import '../domain/mail_model.dart';
import '../../../core/providers/session_provider.dart';

final mailRepositoryProvider = Provider<MailRepository>((ref) {
  return MailRepository(ref.watch(dioProvider));
});

class MailNotifier extends AsyncNotifier<List<MailModel>> {
  @override
  Future<List<MailModel>> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return const [];
    return ref.read(mailRepositoryProvider).getSent();
  }

  Future<void> send({
    required List<String> to,
    required String subject,
    String? textBody,
    String? htmlBody,
  }) async {
    final repo = ref.read(mailRepositoryProvider);
    await repo.send(to: to, subject: subject, textBody: textBody, htmlBody: htmlBody);
  }
}

final mailProvider = AsyncNotifierProvider<MailNotifier, List<MailModel>>(MailNotifier.new);
