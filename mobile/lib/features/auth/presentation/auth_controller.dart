import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/network/socket_client.dart';
import '../../friends/presentation/friends_controller.dart';
import '../../ai_companion/presentation/ai_chat_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthController(this._repo, this._ref) : super(AuthState(isLoading: true)) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      state = AuthState(isLoading: false, isAuthenticated: false);
      return;
    }

    try {
      final user = await _repo.getMe();
      if (user != null) {
        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        SocketClient.connect();
      } else {
        state = AuthState(isLoading: false, isAuthenticated: false);
      }
    } catch (_) {
      // Fallback to locally cached user info if offline
      final localUserJson = await SecureStorageService.getUserRaw();
      if (localUserJson != null) {
        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          user: jsonDecode(localUserJson),
        );
        SocketClient.connect();
      } else {
        state = AuthState(isLoading: false, isAuthenticated: false);
      }
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Clean previous session state
      _ref.read(friendsControllerProvider.notifier).reset();
      _ref.read(aiChatControllerProvider.notifier).reset();
      await LocalDatabaseHelper.wipeAllLocalData();
      SocketClient.disconnect();

      final res = await _repo.login(identifier: identifier, password: password);
      state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        user: res['user'],
      );
      await SocketClient.connect();
      _ref.read(friendsControllerProvider.notifier).loadFriends();
      _ref.read(aiChatControllerProvider.notifier).loadHistory();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register({
    String? email,
    String? phoneNumber,
    required String password,
    required String displayName,
    String? bio,
    String? companionName,
    String? companionGender,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Clean previous session state
      _ref.read(friendsControllerProvider.notifier).reset();
      _ref.read(aiChatControllerProvider.notifier).reset();
      await LocalDatabaseHelper.wipeAllLocalData();
      SocketClient.disconnect();

      final res = await _repo.register(
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        displayName: displayName,
        bio: bio,
        companionName: companionName,
        companionGender: companionGender,
      );
      state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        user: res['user'],
      );
      await SocketClient.connect();
      _ref.read(friendsControllerProvider.notifier).loadFriends();
      _ref.read(aiChatControllerProvider.notifier).loadHistory();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    try {
      final updatedUser = await _repo.updateProfile(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  void updateUserProfile(Map<String, dynamic> updatedUser) {
    state = state.copyWith(user: updatedUser);
    SecureStorageService.saveUserRaw(jsonEncode(updatedUser));
  }

  Future<void> logout() async {
    SocketClient.disconnect();
    await _repo.logout();
    await LocalDatabaseHelper.wipeAllLocalData();
    _ref.read(friendsControllerProvider.notifier).reset();
    _ref.read(aiChatControllerProvider.notifier).reset();
    state = AuthState(isAuthenticated: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo, ref);
});
