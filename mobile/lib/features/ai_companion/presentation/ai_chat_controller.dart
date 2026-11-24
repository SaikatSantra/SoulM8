import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_companion_repository.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/storage/secure_storage.dart';
import '../../offline_simulator/offline_companion_engine.dart';

final aiCompanionRepositoryProvider = Provider<AICompanionRepository>((ref) => AICompanionRepository());

class AIChatState {
  final bool isLoading;
  final bool isThinking;
  final String activeMode; // 'ROMANTIC', 'SUPPORTIVE', 'MINDFUL'
  final List<Map<String, dynamic>> messages;
  final String? errorMessage;

  AIChatState({
    this.isLoading = false,
    this.isThinking = false,
    this.activeMode = 'ROMANTIC',
    this.messages = const [],
    this.errorMessage,
  });

  AIChatState copyWith({
    bool? isLoading,
    bool? isThinking,
    String? activeMode,
    List<Map<String, dynamic>>? messages,
    String? errorMessage,
  }) {
    return AIChatState(
      isLoading: isLoading ?? this.isLoading,
      isThinking: isThinking ?? this.isThinking,
      activeMode: activeMode ?? this.activeMode,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
    );
  }
}

class AIChatController extends StateNotifier<AIChatState> {
  final AICompanionRepository _repo;

  AIChatController(this._repo) : super(AIChatState(isLoading: false)) {
    init();
  }

  void reset() {
    state = AIChatState(isLoading: false, messages: []);
  }

  Future<void> init() async {
    try {
      final savedMode = await SecureStorageService.getCompanionMode();
      state = state.copyWith(activeMode: savedMode);
      await loadHistory();
    } catch (e) {
      debugPrint('⚠️ AIChatController init error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadHistory() async {
    try {
      final history = await _repo.getHistory();
      if (history.isNotEmpty || state.messages.isEmpty) {
        state = state.copyWith(isLoading: false, messages: history);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setMode(String newMode) async {
    state = state.copyWith(activeMode: newMode);
    await SecureStorageService.saveCompanionMode(newMode);
    _repo.switchMode(newMode).catchError((_) {});
  }

  Future<void> sendMessage(String text, [String? userPhotoUrl]) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && (userPhotoUrl == null || userPhotoUrl.isEmpty)) return;

    final id = 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final userMsg = {
      'id': id,
      'isUser': true,
      'content': cleanText.isNotEmpty ? cleanText : '📷 [Photo]',
      'photoUrl': userPhotoUrl,
      'activeMode': state.activeMode,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 1. UPDATE STATE IMMEDIATELY so the user message appears instantly on screen!
    state = state.copyWith(
      isLoading: false,
      messages: [...state.messages, userMsg],
      isThinking: true,
      errorMessage: null,
    );

    // 2. Safe local DB cache
    LocalDatabaseHelper.insertAIMessage(
      id: id,
      isUser: true,
      content: cleanText.isNotEmpty ? cleanText : '📷 [Photo]',
      activeMode: state.activeMode,
      photoUrl: userPhotoUrl,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ).catchError((e) => debugPrint('Safe DB error: $e'));

    try {
      // 3. Call backend AI API
      final res = await _repo.sendChatMessage(cleanText, state.activeMode, userPhotoUrl);

      final reply = (res['reply'] ?? '').toString();
      final photoUrl = res['photoUrl']?.toString();
      final msgId = (res['messageId'] ?? 'ai_${DateTime.now().millisecondsSinceEpoch}').toString();
      final createdAt = (res['createdAt'] ?? DateTime.now().toIso8601String()).toString();

      final aiMsg = {
        'id': msgId,
        'isUser': false,
        'content': reply,
        'photoUrl': (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null,
        'activeMode': state.activeMode,
        'createdAt': createdAt,
      };

      state = state.copyWith(
        isLoading: false,
        isThinking: false,
        messages: [...state.messages, aiMsg],
      );
    } catch (e) {
      debugPrint('⚠️ AI API failed, activating zero-downtime empathetic simulator: $e');

      // 4. Zero-Downtime Empathetic Companion Simulator Fallback
      final offlineRes = OfflineCompanionEngine.generateOfflineResponse(
        userMessage: cleanText,
        mode: state.activeMode,
      );
      final offlineReply = (offlineRes['reply'] ?? '').toString();
      final offlinePhotoUrl = offlineRes['photoUrl']?.toString();

      final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final offlineMsg = {
        'id': offlineId,
        'isUser': false,
        'content': offlineReply,
        'photoUrl': offlinePhotoUrl,
        'activeMode': state.activeMode,
        'createdAt': DateTime.now().toIso8601String(),
      };

      LocalDatabaseHelper.insertAIMessage(
        id: offlineId,
        isUser: false,
        content: offlineReply,
        activeMode: state.activeMode,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ).catchError((_) {});

      state = state.copyWith(
        isLoading: false,
        isThinking: false,
        messages: [...state.messages, offlineMsg],
      );
    }
  }
}

final aiChatControllerProvider = StateNotifierProvider<AIChatController, AIChatState>((ref) {
  final repo = ref.watch(aiCompanionRepositoryProvider);
  return AIChatController(repo);
});
