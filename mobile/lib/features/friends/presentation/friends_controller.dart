import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/friends_repository.dart';
import '../../../core/network/socket_client.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) => FriendsRepository());

class FriendsState {
  final bool isLoading;
  final bool isSearching;
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> searchResults;
  final String? errorMessage;

  FriendsState({
    this.isLoading = false,
    this.isSearching = false,
    this.friends = const [],
    this.searchResults = const [],
    this.errorMessage,
  });

  FriendsState copyWith({
    bool? isLoading,
    bool? isSearching,
    List<Map<String, dynamic>>? friends,
    List<Map<String, dynamic>>? searchResults,
    String? errorMessage,
  }) {
    return FriendsState(
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      friends: friends ?? this.friends,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage,
    );
  }
}

class FriendsController extends StateNotifier<FriendsState> {
  final FriendsRepository _repo;

  FriendsController(this._repo) : super(FriendsState()) {
    loadFriends();
    _setupRealtimeListeners();
  }

  void reset() {
    state = FriendsState();
  }

  void _setupRealtimeListeners() {
    SocketClient.addConnectListener((socket) => _bindSocketEvents(socket));
    final existing = SocketClient.socket;
    if (existing != null) {
      _bindSocketEvents(existing);
    }
  }

  void _bindSocketEvents(dynamic socket) {
    socket.off('human:new_message');
    socket.on('human:new_message', (_) {
      loadFriends();
    });
    socket.off('friend:added');
    socket.on('friend:added', (_) {
      loadFriends();
    });
  }

  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getFriendsList();
      state = state.copyWith(isLoading: false, friends: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true);
    try {
      final results = await _repo.searchUsers(query);
      state = state.copyWith(isSearching: false, searchResults: results);
    } catch (e) {
      state = state.copyWith(isSearching: false, searchResults: []);
    }
  }

  Future<bool> addFriend(String friendId) async {
    try {
      await _repo.addFriend(friendId);
      await loadFriends();
      state = state.copyWith(searchResults: []);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final friendsControllerProvider = StateNotifierProvider<FriendsController, FriendsState>((ref) {
  final repo = ref.watch(friendsRepositoryProvider);
  return FriendsController(repo);
});
