import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/providers/session_provider.dart';
import '../data/messaging_socket.dart';
import '../domain/socket_events.dart';

final messagingSocketProvider = Provider<MessagingSocket>((ref) {
  final socket = MessagingSocket(ref.watch(secureStorageProvider));

  ref.listen<String?>(userSessionProvider, (prev, next) {
    if (next != null && next.isNotEmpty) {
      socket.connect();
    } else {
      socket.disconnect();
    }
  }, fireImmediately: true);

  ref.onDispose(() {
    socket.dispose();
  });

  return socket;
});

final socketStatusProvider = StreamProvider<SocketStatus>((ref) {
  final socket = ref.watch(messagingSocketProvider);
  return socket.status$;
});
