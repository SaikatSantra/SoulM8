import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/widgets/dynamic_mode_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../friends/presentation/friends_controller.dart';
import '../../ai_companion/presentation/companion_settings_dialog.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _searchController = TextEditingController();
  bool _filterOnlyStartedChats = true; // Show only friends who have started a chat by default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsControllerProvider.notifier).loadFriends();
      _setupRealtimeNotifications();
    });
  }

  void _setupRealtimeNotifications() {
    SocketClient.addConnectListener((socket) {
      socket.off('friend:added');
      socket.on('friend:added', (data) {
        if (!mounted) return;
        final msg = data?['message'] ?? 'Someone connected with you on Soulm8!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Soulm8Theme.primaryRose,
            content: Row(
              children: [
                const Icon(Icons.person_add, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(friendsControllerProvider.notifier).loadFriends();
      });

      socket.off('notification:new_message');
      socket.on('notification:new_message', (data) {
        if (!mounted) return;
        final senderName = data?['senderName'] ?? 'Friend';
        final content = data?['content'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Soulm8Theme.deepPlum,
            content: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Soulm8Theme.softPeach, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '💬 $senderName: $content',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(friendsControllerProvider.notifier).loadFriends();
      });
    });
  }

  void _openEditProfile() {
    final user = ref.read(authControllerProvider).user;
    showDialog(
      context: context,
      builder: (_) => EditProfileDialog(currentUser: user),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChatWithUser(Map<String, dynamic> userMap) async {
    _searchController.clear();
    ref.read(friendsControllerProvider.notifier).search('');
    await context.push('/chat/${userMap['id']}', extra: userMap);
    // Reload friends list immediately upon returning to show latest chat
    ref.read(friendsControllerProvider.notifier).loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final friendsState = ref.watch(friendsControllerProvider);
    final user = authState.user;

    final companion = user?['companion'];
    final companionName = companion?['name'] ?? 'Soulie';
    final companionMode = companion?['currentMode'] ?? 'ROMANTIC';

    // Filter friends who have started a chat (have messages)
    final allFriends = friendsState.friends;
    final activeChats = allFriends.where((f) => f['hasStartedChat'] == true || f['lastMessage'] != null).toList();
    final displayedFriends = _filterOnlyStartedChats ? activeChats : allFriends;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soulm8 Sanctuary'),
        actions: [
          IconButton(
            tooltip: 'AI Memories & Privacy',
            icon: const Icon(Icons.memory, color: Soulm8Theme.softPeach),
            onPressed: () => context.push('/memories'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(friendsControllerProvider.notifier).loadFriends();
          await ref.read(authControllerProvider.notifier).checkInitialAuth();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: Soulm8Theme.darkCardGradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _openEditProfile,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Soulm8Theme.primaryRose.withOpacity(0.2),
                            backgroundImage: user?['avatarUrl'] != null
                                ? NetworkImage(user!['avatarUrl'])
                                : null,
                            child: user?['avatarUrl'] == null
                                ? const Icon(Icons.person, color: Colors.white, size: 34)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Soulm8Theme.primaryRose,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?['displayName'] ?? 'Soul Traveler',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?['phoneNumber'] ?? user?['email'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Soulm8Theme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?['bio'] ?? 'Finding peace, healing, and connection.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Soulm8Theme.softPeach,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit Profile & Photo',
                      icon: const Icon(Icons.tune, color: Soulm8Theme.softPeach, size: 22),
                      onPressed: _openEditProfile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI COMPANION HERO CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B1E38), Color(0xFF24142D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Soulm8Theme.primaryRose.withOpacity(0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Soulm8Theme.primaryRose.withOpacity(0.2),
                          ),
                          child: const Text('✨', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Companion • $companionName',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Attentive & persistent memory • 0 Downtime',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Soulm8Theme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DynamicModeBadge(mode: companionMode),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/ai-chat'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: Soulm8Theme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Chat with AI Companion',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => CompanionSettingsDialog.show(context, initialProfile: companion),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Soulm8Theme.backgroundDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.4)),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.tune_rounded, color: Soulm8Theme.accentGold, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Customize Partner (Name, Photo, Gender)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // FRIEND SEARCH BAR (Search by phone or email like WhatsApp/Facebook)
              const Text(
                'Add Friends by Mobile or Email',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Soulm8Theme.textLight,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Soulm8Theme.cardSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(friendsControllerProvider.notifier).search(val);
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search mobile number or email...',
                    hintStyle: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Soulm8Theme.softPeach, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(friendsControllerProvider.notifier).search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              // Search Results Area (Instant "Start Chat" Action)
              if (friendsState.searchResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Soulm8Theme.cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Soulm8Theme.lavenderWhisper.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search Results',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Soulm8Theme.softPeach,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: friendsState.searchResults.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                        itemBuilder: (context, idx) {
                          final item = friendsState.searchResults[idx];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Soulm8Theme.lavenderWhisper.withOpacity(0.2),
                              backgroundImage: item['avatarUrl'] != null
                                  ? NetworkImage(item['avatarUrl'])
                                  : null,
                              child: item['avatarUrl'] == null
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              item['displayName'] ?? '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              item['phoneNumber'] ?? item['email'] ?? '',
                              style: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 12),
                            ),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Soulm8Theme.primaryRose,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                              label: const Text('Start Chat', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                // Add friend and immediately open chat!
                                await ref
                                    .read(friendsControllerProvider.notifier)
                                    .addFriend(item['id']);
                                _openChatWithUser(item);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // CONNECTED FRIENDS LIST / CHATS (Show friend list if they start chat)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filterOnlyStartedChats ? 'Active Chats' : 'Your Friends & Chats',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Soulm8Theme.textLight,
                    ),
                  ),
                  Row(
                    children: [
                      // Toggle to show only started chats or all friends
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _filterOnlyStartedChats = !_filterOnlyStartedChats;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _filterOnlyStartedChats
                                ? Soulm8Theme.primaryRose.withOpacity(0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _filterOnlyStartedChats ? Soulm8Theme.primaryRose : Colors.white12,
                            ),
                          ),
                          child: Text(
                            _filterOnlyStartedChats ? 'Active Chats (${activeChats.length})' : 'All (${allFriends.length})',
                            style: TextStyle(
                              fontSize: 12,
                              color: _filterOnlyStartedChats ? Soulm8Theme.primaryRose : Soulm8Theme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (friendsState.isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: Soulm8Theme.primaryRose),
                  ),
                ),
              ] else if (displayedFriends.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Soulm8Theme.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.chat_outlined, size: 48, color: Soulm8Theme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        _filterOnlyStartedChats ? 'No active chats yet' : 'No friends yet',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _filterOnlyStartedChats
                            ? 'Search for a contact above and send a message to start a chat!'
                            : 'Search above using a mobile number or email to add friends and start chatting.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedFriends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = displayedFriends[index];
                    final friend = item['friend'];
                    final lastMsg = item['lastMessage'];
                    final unreadCount = item['unreadCount'] ?? 0;
                    final hasStartedChat = item['hasStartedChat'] == true || lastMsg != null;

                    String timeString = '';
                    if (lastMsg != null && lastMsg['createdAt'] != null) {
                      final dt = DateTime.tryParse(lastMsg['createdAt']);
                      if (dt != null) {
                        timeString = DateFormat('hh:mm a').format(dt.toLocal());
                      }
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Soulm8Theme.cardSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: unreadCount > 0
                              ? Soulm8Theme.primaryRose.withOpacity(0.3)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _openChatWithUser(friend),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Soulm8Theme.primaryRose.withOpacity(0.2),
                          backgroundImage: friend['avatarUrl'] != null
                              ? NetworkImage(friend['avatarUrl'])
                              : null,
                          child: friend['avatarUrl'] == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                friend['displayName'] ?? 'Friend',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timeString.isNotEmpty)
                              Text(
                                timeString,
                                style: const TextStyle(
                                  color: Soulm8Theme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            if (lastMsg != null && lastMsg['isSender'] == true) ...[
                              Icon(
                                lastMsg['status'] == 'READ' ? Icons.done_all : Icons.check,
                                size: 14,
                                color: lastMsg['status'] == 'READ' ? Soulm8Theme.primaryRose : Colors.white60,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                lastMsg != null
                                    ? lastMsg['content']
                                    : (hasStartedChat ? 'Chat started' : 'Tap to start 1-on-1 chat...'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unreadCount > 0 ? Colors.white : Soulm8Theme.textMuted,
                                  fontSize: 13,
                                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontStyle: lastMsg == null ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: unreadCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Soulm8Theme.primaryRose,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
