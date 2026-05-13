import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/message_model.dart';
import '../domain/socket_events.dart';

class MessagingSocket {
  MessagingSocket(this._storage);

  final SecureStorage _storage;
  io.Socket? _socket;
  bool _disposed = false;
  int _authRetryCount = 0;
  // Threads to (re-)join whenever socket connects or reconnects
  final Set<String> _activeThreads = {};

  final _statusCtrl = StreamController<SocketStatus>.broadcast();
  final _messageNewCtrl = StreamController<MessageModel>.broadcast();
  final _messageUpdatedCtrl = StreamController<MessageModel>.broadcast();
  final _messageDeletedCtrl = StreamController<MessageDeletedEvent>.broadcast();
  final _readUpdatedCtrl = StreamController<ReadEvent>.broadcast();
  final _typingStartCtrl = StreamController<TypingEvent>.broadcast();
  final _typingStopCtrl = StreamController<TypingEvent>.broadcast();
  final _threadBumpedCtrl = StreamController<ThreadBumpEvent>.broadcast();
  final _reactionUpdatedCtrl = StreamController<ReactionUpdatedEvent>.broadcast();

  Stream<SocketStatus> get status$ => _statusCtrl.stream;
  Stream<MessageModel> get messageNew$ => _messageNewCtrl.stream;
  Stream<MessageModel> get messageUpdated$ => _messageUpdatedCtrl.stream;
  Stream<MessageDeletedEvent> get messageDeleted$ => _messageDeletedCtrl.stream;
  Stream<ReadEvent> get readUpdated$ => _readUpdatedCtrl.stream;
  Stream<TypingEvent> get typingStart$ => _typingStartCtrl.stream;
  Stream<TypingEvent> get typingStop$ => _typingStopCtrl.stream;
  Stream<ThreadBumpEvent> get threadBumped$ => _threadBumpedCtrl.stream;
  Stream<ReactionUpdatedEvent> get reactionUpdated$ => _reactionUpdatedCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_disposed) return;
    final token = await _storage.read(StorageKeys.accessToken);
    if (token == null || token.isEmpty) {
      _statusCtrl.add(SocketStatus.authError);
      return;
    }

    _socket?.dispose();
    _statusCtrl.add(SocketStatus.connecting);

    final url = '${AppConstants.baseUrl}/messaging';
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      _authRetryCount = 0;
      _statusCtrl.add(SocketStatus.connected);
      // (Re-)join every thread that was registered before or during connect
      for (final threadId in _activeThreads) {
        socket.emitWithAck('thread:join', {'threadId': threadId}, ack: (_) {});
      }
    });
    socket.onDisconnect((_) => _statusCtrl.add(SocketStatus.disconnected));
    socket.onConnectError((err) async {
      final isAuth = _looksLikeAuthError(err);
      if (isAuth && _authRetryCount < 1) {
        _authRetryCount++;
        final fresh = await _storage.read(StorageKeys.accessToken);
        if (fresh != null && fresh.isNotEmpty) {
          socket.auth = {'token': fresh};
          socket.connect();
          return;
        }
      }
      _statusCtrl
          .add(isAuth ? SocketStatus.authError : SocketStatus.disconnected);
    });
    socket.onError((_) {
      _statusCtrl.add(SocketStatus.disconnected);
    });

    socket.on('message:new', (data) {
      if (data is Map) {
        _messageNewCtrl.add(
          MessageModel.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });
    socket.on('message:updated', (data) {
      if (data is Map) {
        _messageUpdatedCtrl.add(
          MessageModel.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });
    socket.on('message:deleted', (data) {
      if (data is Map) {
        _messageDeletedCtrl.add(
          MessageDeletedEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });
    socket.on('read:updated', (data) {
      if (data is Map) {
        _readUpdatedCtrl.add(
          ReadEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });
    socket.on('typing:start', (data) {
      if (data is Map) {
        _typingStartCtrl.add(
          TypingEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });
    socket.on('typing:stop', (data) {
      if (data is Map) {
        _typingStopCtrl.add(
          TypingEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });
    socket.on('thread:bumped', (data) {
      if (data is Map) {
        _threadBumpedCtrl.add(
          ThreadBumpEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });
    socket.on('reaction:updated', (data) {
      if (data is Map) {
        _reactionUpdatedCtrl.add(
          ReactionUpdatedEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    _socket = socket;
    socket.connect();
  }

  void disconnect() {
    _activeThreads.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _authRetryCount = 0;
    _statusCtrl.add(SocketStatus.disconnected);
  }

  void joinThread(String threadId) {
    _activeThreads.add(threadId);
    final socket = _socket;
    if (socket != null && socket.connected) {
      socket.emitWithAck('thread:join', {'threadId': threadId}, ack: (_) {});
    }
    // If not yet connected, onConnect will flush _activeThreads
  }

  void leaveThread(String threadId) {
    _activeThreads.remove(threadId);
    _socket?.emit('thread:leave', {'threadId': threadId});
  }

  void sendTypingStart(String threadId) {
    _socket?.emit('typing:start', {'threadId': threadId});
  }

  void sendTypingStop(String threadId) {
    _socket?.emit('typing:stop', {'threadId': threadId});
  }

  void emitRead(String threadId, DateTime lastReadAt) {
    _socket?.emit('message:read', {
      'threadId': threadId,
      'lastReadAt': lastReadAt.toIso8601String(),
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    disconnect();
    await Future.wait([
      _statusCtrl.close(),
      _messageNewCtrl.close(),
      _messageUpdatedCtrl.close(),
      _messageDeletedCtrl.close(),
      _readUpdatedCtrl.close(),
      _typingStartCtrl.close(),
      _typingStopCtrl.close(),
      _threadBumpedCtrl.close(),
      _reactionUpdatedCtrl.close(),
    ]);
  }

  bool _looksLikeAuthError(dynamic err) {
    final s = err?.toString().toLowerCase() ?? '';
    return s.contains('auth') ||
        s.contains('jwt') ||
        s.contains('unauthorized') ||
        s.contains('401');
  }
}
