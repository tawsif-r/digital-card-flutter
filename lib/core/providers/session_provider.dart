import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Emits the current user's ID. Changes only when the logged-in user actually
/// switches (null → id on login, id → null on logout, id-A → id-B on switch).
/// All user-specific feature providers watch this so they rebuild with fresh
/// data on every account change — no restart required.
final userSessionProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select((n) => n.user?.id));
});
