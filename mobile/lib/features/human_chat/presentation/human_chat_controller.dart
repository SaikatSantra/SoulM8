import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/human_chat_repository.dart';
import '../../../core/network/socket_client.dart';

final humanChatRepositoryProvider = Provider<HumanChatRepository>((ref) => HumanChatRepository());

class ChatState {
  final bool isLoading;
  final List<Map<String, dynamic>> messages;
  final bool isFriendTyping;

  ChatState({
    this.isLoading = false,
    this.messages = const [],
    this.isFriendTyping = false,
  });

  ChatState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? messages,
    bool? isFriendTyping,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      isFriendTyping: isFriendTyping ?? this.isFriendTyping,
    );
  }
}

class HumanChatController extends StateNotifier<ChatState> {
  final HumanChatRepository _repo;
  final String friendId;
  Timer? _pollingTimer;

  HumanChatController(this._repo, this.friendId) : super(ChatState(isLoading: true)) {
    initChat();
  }

  void initChat() async {
    await loadMessages();
    _setupSocketListeners();
    // Background polling fallback every 3s to guarantee zero missed messages
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _silentRefresh();
    });
  }

  Future<void> _silentRefresh() async {
    try {
      final msgs = await _repo.getMessages(friendId);
      if (msgs.length != state.messages.length) {
        state = state.copyWith(messages: msgs);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMessages() async {
    try {
      final msgs = await _repo.getMessages(friendId);
      state = state.copyWith(isLoading: false, messages: msgs);
    } catch (e) {
      debugPrint('⚠️ loadMessages fallback: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void _setupSocketListeners() {
    // If socket is already connected or whenever it connects
    SocketClient.addConnectListener((socket) => _bindEvents(socket));
    final existingSocket = SocketClient.socket;
    if (existingSocket != null) {
      _bindEvents(existingSocket);
    }
  }

  void _bindEvents(dynamic socket) {
    // Listen to incoming messages from friend
    socket.off('human:new_message');
    socket.on('human:new_message', (data) {
      if (data != null && data['senderId'] == friendId) {
        state = state.copyWith(
          messages: [...state.messages, Map<String, dynamic>.from(data as Map)],
        );
        _repo.markAsRead(friendId).catchError((_) {});
      }
    });

    // Listen to sent acknowledgments
    socket.off('human:message_sent_ack');
    socket.on('human:message_sent_ack', (data) {
      if (data == null) return;
      final clientTempId = data['clientTempId'];
      final message = data['message'];
      if (clientTempId != null && message != null) {
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m['id'] == clientTempId) {
              return {
                ...Map<String, dynamic>.from(message as Map),
                'isMe': true,
              };
            }
            return m;
          }).toList(),
        );
      }
    });

    // Typing indicators
    socket.off('human:typing');
    socket.on('human:typing', (data) {
      if (data != null && data['senderId'] == friendId) {
        state = state.copyWith(isFriendTyping: data['isTyping'] ?? false);
      }
    });
  }

  Future<void> sendMessage(String text, {String? mediaUrl}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && (mediaUrl == null || mediaUrl.isEmpty)) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'content': cleanText,
      'mediaUrl': mediaUrl,
      'senderId': 'me',
      'receiverId': friendId,
      'isMe': true,
      'status': 'SENT',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 1. Instant optimistic UI update
    state = state.copyWith(messages: [...state.messages, tempMsg]);

    try {
      final socket = SocketClient.socket;
      if (socket != null && socket.connected) {
        socket.emit('human:send_message', {
          'recipientId': friendId,
          'content': cleanText,
          'mediaUrl': mediaUrl,
          'clientTempId': tempId,
        });
      } else {
        // Fallback to REST API
        final sent = await _repo.sendMessage(friendId, cleanText, mediaUrl: mediaUrl);
        state = state.copyWith(
          messages: state.messages.map((m) => m['id'] == tempId ? sent : m).toList(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ sendMessage error: $e');
      // Keep optimistic message displayed so user never loses their typed message
    }
  }

  void emitTyping(bool isTyping) {
    final socket = SocketClient.socket;
    if (socket != null && socket.connected) {
      socket.emit('human:typing', {
        'recipientId': friendId,
        'isTyping': isTyping,
      });
    }
  }
}

final humanChatControllerProvider = StateNotifierProvider.family<HumanChatController, ChatState, String>(
  (ref, friendId) {
    final repo = ref.watch(humanChatRepositoryProvider);
    return HumanChatController(repo, friendId);
  },
);
