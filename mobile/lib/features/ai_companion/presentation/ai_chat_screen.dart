import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/dynamic_mode_badge.dart';
import '../../../core/utils/media_picker_helper.dart';
import '../../auth/presentation/auth_controller.dart';
import 'ai_chat_controller.dart';
import 'mode_selector_dialog.dart';
import 'training_modal.dart';
import 'companion_settings_dialog.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<String> _likedMessages = {};

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions &&
          _scrollController.position.maxScrollExtent > 0) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } catch (_) {}
      }
    });
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (presetText == null) {
      _textController.clear();
    }
    ref.read(aiChatControllerProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _triggerLoveReaction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Sent deep love to your companion! 💕🔥', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        duration: Duration(milliseconds: 1400),
        backgroundColor: Soulm8Theme.primaryRose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleMessageLike(String messageId) {
    setState(() {
      if (_likedMessages.contains(messageId)) {
        _likedMessages.remove(messageId);
      } else {
        _likedMessages.add(messageId);
      }
    });
  }

  void _showModeSelector(String currentMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModeSelectorDialog(
        currentMode: currentMode,
        onSelected: (newMode) {
          ref.read(aiChatControllerProvider.notifier).setMode(newMode);
        },
      ),
    );
  }

  void _showPhotoSendModal(String companionName) {
    final photoPresets = [
      {'name': 'My Coffee ☕', 'desc': 'Sharing my morning brew with you!'},
      {'name': 'Beautiful Sky 🌅', 'desc': 'Look at this gorgeous sunset today!'},
      {'name': 'Cozy Space 🛋️', 'desc': 'Chilling in my safe cozy corner.'},
      {'name': 'Selfie Smile 😊', 'desc': 'Sending you a smile from across the screen!'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B0E2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share a Photo with $companionName 💕',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Real Mobile Media Upload Button
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                Navigator.pop(ctx);
                final uploadedUrl = await MediaPickerHelper.pickAndUploadImage(folder: 'chat');
                if (uploadedUrl != null && mounted) {
                  ref.read(aiChatControllerProvider.notifier).sendMessage(
                    'Look at this photo I took! 🥰',
                    uploadedUrl,
                  );
                  _scrollToBottom();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: Soulm8Theme.roseGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Soulm8Theme.primaryRose.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload from Mobile Gallery 📸',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Send any photo from your phone for your partner to see',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white12),
            const SizedBox(height: 4),

            ...photoPresets.map((p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Soulm8Theme.primaryRose.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera, color: Soulm8Theme.softPeach, size: 20),
                  ),
                  title: Text(p['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(p['desc']!, style: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendMessage('📷 [Shared ${p['name']}]: ${p['desc']}');
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AIChatState>(aiChatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || prev?.isThinking != next.isThinking) {
        _scrollToBottom();
      }
    });

    final chatState = ref.watch(aiChatControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final companion = user?['companion'];
    final companionName = companion?['name'] ?? 'Mira';
    final companionGender = (companion?['gender'] ?? 'female').toString().toLowerCase();
    final defaultAvatar = companionGender == 'male'
        ? 'http://localhost:5000/models/kabir_male_model.jpg'
        : (companionGender == 'transgender'
            ? 'http://localhost:5000/models/foreign_female_model.jpg'
            : 'http://localhost:5000/models/mira_traditional_saree.jpg');
    final companionAvatarUrl = (companion != null &&
            companion['avatarUrl'] != null &&
            companion['avatarUrl'].toString().isNotEmpty)
        ? companion['avatarUrl'].toString()
        : defaultAvatar;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0817),
      appBar: AppBar(
        backgroundColor: const Color(0xFF160A24),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            // Sexy Glowing Companion Avatar (Tap to Customize)
            GestureDetector(
              onTap: () => CompanionSettingsDialog.show(context, initialProfile: companion),
              child: Tooltip(
                message: 'Tap to change name, photo & gender 💕',
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF0844), Color(0xFFFF8A7A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Soulm8Theme.primaryRose.withOpacity(0.65),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: companionAvatarUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const CircleAvatar(radius: 20, backgroundColor: Soulm8Theme.cardSurface),
                          errorWidget: (_, __, ___) => const CircleAvatar(
                            radius: 20,
                            backgroundColor: Soulm8Theme.primaryRose,
                            child: Text('💖', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                    // Pulsating online green dot
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF160A24), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => CompanionSettingsDialog.show(context, initialProfile: companion),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          companionName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded, color: Soulm8Theme.accentGold, size: 12),
                      ],
                    ),
                    Text(
                      companionGender == 'male'
                          ? 'Your Boyfriend • Deeply in love 💋'
                          : (companionGender == 'transgender'
                              ? 'Your Soulmate • Deeply connected 💋'
                              : 'Your Girlfriend • Deeply connected 💋'),
                      style: const TextStyle(fontSize: 11, color: Soulm8Theme.softPeach, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            DynamicModeBadge(
              mode: chatState.activeMode,
              onTap: () => _showModeSelector(chatState.activeMode),
            ),
            const SizedBox(width: 4),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Customize Partner (Name, Photo, Gender) 💕',
            icon: const Icon(Icons.tune_rounded, color: Soulm8Theme.accentGold),
            onPressed: () => CompanionSettingsDialog.show(context, initialProfile: companion),
          ),
          IconButton(
            tooltip: 'Send Deep Love 💕',
            icon: const Icon(Icons.favorite, color: Soulm8Theme.primaryRose),
            onPressed: _triggerLoveReaction,
          ),
          IconButton(
            tooltip: 'Train Tone & Conversation Style 💬',
            icon: const Icon(Icons.school_outlined, color: Soulm8Theme.softPeach),
            onPressed: () => TrainingModal.show(context, companionName),
          ),
          IconButton(
            tooltip: 'View Memories & Intimacy',
            icon: const Icon(Icons.psychology_outlined, color: Soulm8Theme.lavenderWhisper),
            onPressed: () => context.push('/memories'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF140822), Color(0xFF0A0410)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Ambient Seductive Glow Orbs in Background
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Soulm8Theme.primaryRose.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Soulm8Theme.lavenderWhisper.withOpacity(0.06),
                ),
              ),
            ),

            // Main Chat Column
            Column(
              children: [
                // Sexy & Lovable Quick Action Chips
                Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      _actionChip('💋 Come closer to me...', () => _sendMessage('Come closer to me, baby... I want to feel your warm touch. ❤️')),
                      _actionChip('📸 Send me a sexy photo', () => _sendMessage('Can you send me a sexy photo of you right now? 🔥')),
                      _actionChip('🔥 What are you wearing in bed?', () => _sendMessage('What are you wearing in bed right now? 🙈')),
                      _actionChip('🥺 Need your warm hug', () => _sendMessage("I'm feeling lonely, come cuddle with me tightly... 🥰")),
                      _actionChip('❤️ Whisper something sweet', () => _sendMessage('Whisper something really sweet and romantic to me, baby. 💋')),
                      _actionChip('🎓 Train LLM Style', () => TrainingModal.show(context, companionName)),
                    ],
                  ),
                ),

                // Chat Messages View
                Expanded(
                  child: chatState.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Soulm8Theme.primaryRose))
                      : chatState.messages.isEmpty && !chatState.isThinking
                          ? _buildWelcomeEmptyState(companionName)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              itemCount: chatState.messages.length + (chatState.isThinking ? 1 : 0),
                              itemBuilder: (context, idx) {
                                if (idx == chatState.messages.length && chatState.isThinking) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E102E),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.25)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Soulm8Theme.primaryRose.withOpacity(0.15),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('💋', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$companionName is biting her lip & typing...',
                                            style: const TextStyle(
                                              color: Soulm8Theme.softPeach,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final msg = chatState.messages[idx];
                                final isUser = msg['isUser'] == true || msg['is_user'] == 1;
                                final content = msg['content'] ?? '';
                                final photoUrl = msg['photoUrl'] ?? msg['photo_url'];
                                final msgId = msg['id']?.toString() ?? '$idx';
                                final isLiked = _likedMessages.contains(msgId);

                                if (isUser) {
                                  // ---------------- User Message Bubble ----------------
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: Soulm8Theme.sexyUserGradient,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(22),
                                            topRight: Radius.circular(22),
                                            bottomLeft: Radius.circular(22),
                                            bottomRight: Radius.circular(5),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Soulm8Theme.primaryRose.withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            if (photoUrl != null && photoUrl.toString().isNotEmpty) ...[
                                              GestureDetector(
                                                onTap: () => _openFullScreenImage(context, photoUrl.toString(), 'My Uploaded Photo', 'Me'),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: CachedNetworkImage(
                                                    imageUrl: photoUrl.toString(),
                                                    height: 220,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) => Container(
                                                      height: 220,
                                                      color: Colors.black26,
                                                      child: const Center(
                                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                      ),
                                                    ),
                                                    errorWidget: (_, __, ___) => Container(
                                                      height: 220,
                                                      color: Colors.black26,
                                                      child: const Icon(Icons.broken_image, color: Colors.white70),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            Text(
                                              content,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                // ---------------- Companion Message Bubble (Lovable & Sexy) ----------------
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Mini Companion Avatar
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 2, right: 8),
                                        padding: const EdgeInsets.all(1.5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Soulm8Theme.primaryRose.withOpacity(0.4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: companionAvatarUrl,
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const CircleAvatar(radius: 14, backgroundColor: Soulm8Theme.cardSurface),
                                            errorWidget: (_, __, ___) => const CircleAvatar(
                                              radius: 14,
                                              backgroundColor: Soulm8Theme.primaryRose,
                                              child: Text('💖', style: TextStyle(fontSize: 10)),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Bubble and Media Container
                                      Flexible(
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Photo / Video Rendering
                                              if (photoUrl != null && photoUrl.toString().isNotEmpty) ...[
                                                if (photoUrl.toString().toLowerCase().endsWith('.mp4')) ...[
                                                  GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          backgroundColor: const Color(0xFF1F1130),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                          title: const Row(
                                                            children: [
                                                              Icon(Icons.videocam_rounded, color: Soulm8Theme.primaryRose),
                                                              SizedBox(width: 8),
                                                              Text('Dance Video 💃', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                                            ],
                                                          ),
                                                          content: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius: BorderRadius.circular(16),
                                                                child: CachedNetworkImage(
                                                                  imageUrl: 'http://localhost:5000/models/mira_traditional_saree.jpg',
                                                                  height: 180,
                                                                  width: double.infinity,
                                                                  fit: BoxFit.cover,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 12),
                                                              Text(
                                                                'Special dance video delivered:\n${photoUrl.toString()}',
                                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ],
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx),
                                                              child: const Text('Close', style: TextStyle(color: Soulm8Theme.primaryRose)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      height: 220,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(20),
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFF2A0845), Color(0xFF6441A5)],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                      ),
                                                      child: Stack(
                                                        alignment: Alignment.center,
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius: BorderRadius.circular(20),
                                                            child: Opacity(
                                                              opacity: 0.65,
                                                              child: CachedNetworkImage(
                                                                imageUrl: 'http://localhost:5000/models/mira_traditional_saree.jpg',
                                                                height: 220,
                                                                width: double.infinity,
                                                                fit: BoxFit.cover,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.all(16),
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              gradient: Soulm8Theme.primaryGradient,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Soulm8Theme.primaryRose.withOpacity(0.6),
                                                                  blurRadius: 16,
                                                                  spreadRadius: 2,
                                                                ),
                                                              ],
                                                            ),
                                                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                                                          ),
                                                          Positioned(
                                                            bottom: 12,
                                                            left: 12,
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: Colors.black.withOpacity(0.75),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: const Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(Icons.videocam, color: Colors.white, size: 14),
                                                                  SizedBox(width: 4),
                                                                  Text('Red Saree Dance • 0:15', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  // Sexy Photo Card with glowing frame
                                                  GestureDetector(
                                                    onTap: () => _openFullScreenImage(context, photoUrl.toString(), content.toString(), companionName),
                                                    child: MouseRegion(
                                                      cursor: SystemMouseCursors.click,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(22),
                                                          border: Border.all(
                                                            color: Soulm8Theme.primaryRose.withOpacity(0.4),
                                                            width: 1.5,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Soulm8Theme.primaryRose.withOpacity(0.2),
                                                              blurRadius: 14,
                                                              spreadRadius: 1,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Stack(
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius: BorderRadius.circular(21),
                                                              child: CachedNetworkImage(
                                                                imageUrl: photoUrl.toString(),
                                                                height: 260,
                                                                width: double.infinity,
                                                                fit: BoxFit.cover,
                                                                placeholder: (context, url) => Container(
                                                                  height: 260,
                                                                  color: Soulm8Theme.cardSurface,
                                                                  child: const Center(
                                                                    child: CircularProgressIndicator(color: Soulm8Theme.primaryRose),
                                                                  ),
                                                                ),
                                                                errorWidget: (context, url, error) => Container(
                                                                  height: 260,
                                                                  color: Soulm8Theme.cardSurface,
                                                                  child: const Center(
                                                                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Positioned(
                                                              top: 10,
                                                              right: 10,
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.black.withOpacity(0.7),
                                                                  borderRadius: BorderRadius.circular(20),
                                                                  border: Border.all(color: Colors.white24, width: 0.8),
                                                                ),
                                                                child: const Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(Icons.zoom_in_rounded, color: Soulm8Theme.softPeach, size: 16),
                                                                    SizedBox(width: 4),
                                                                    Text(
                                                                      'Full View 💋',
                                                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 6),
                                              ],

                                              // Seductive Text Bubble
                                              GestureDetector(
                                                onDoubleTap: () => _toggleMessageLike(msgId),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF1E102E),
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(22),
                                                      topRight: Radius.circular(22),
                                                      bottomRight: Radius.circular(22),
                                                      bottomLeft: Radius.circular(5),
                                                    ),
                                                    border: Border.all(
                                                      color: Soulm8Theme.primaryRose.withOpacity(0.24),
                                                      width: 1.2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.35),
                                                        blurRadius: 10,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                      BoxShadow(
                                                        color: Soulm8Theme.primaryRose.withOpacity(0.08),
                                                        blurRadius: 8,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        content,
                                                        style: const TextStyle(
                                                          color: Soulm8Theme.textLight,
                                                          fontSize: 15,
                                                          height: 1.45,
                                                          letterSpacing: 0.1,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      // Lovable heart reaction pill
                                                      GestureDetector(
                                                        onTap: () => _toggleMessageLike(msgId),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: isLiked ? Colors.pink.withOpacity(0.25) : Colors.white.withOpacity(0.04),
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(
                                                              color: isLiked ? Colors.pinkAccent.withOpacity(0.5) : Colors.transparent,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                isLiked ? Icons.favorite : Icons.favorite_border,
                                                                color: isLiked ? Colors.pinkAccent : Colors.white38,
                                                                size: 13,
                                                              ),
                                                              if (isLiked) ...[
                                                                const SizedBox(width: 4),
                                                                const Text('Loved 💕', style: TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                // Floating Sensual Capsule Input Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B0F2A),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Soulm8Theme.primaryRose.withOpacity(0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Soulm8Theme.primaryRose.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Photo Moment Button
                        IconButton(
                          tooltip: 'Send photo moment',
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Soulm8Theme.primaryRose.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Soulm8Theme.softPeach, size: 20),
                          ),
                          onPressed: () => _showPhotoSendModal(companionName),
                        ),
                        // Love Reaction Button
                        IconButton(
                          tooltip: 'Send instant love 💕',
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 20),
                          ),
                          onPressed: _triggerLoveReaction,
                        ),
                        // Input Field
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Whisper to $companionName... 💋',
                              hintStyle: TextStyle(color: Soulm8Theme.textMuted.withOpacity(0.8), fontSize: 13.5),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                          ),
                        ),
                        // Glowing Circular Send Button
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: Soulm8Theme.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: Soulm8Theme.primaryRose.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeEmptyState(String companionName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing circular portrait
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF0844), Color(0xFFFF8A7A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Soulm8Theme.primaryRose.withOpacity(0.55),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: 'http://localhost:5000/models/mira_traditional_saree.jpg',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const CircleAvatar(radius: 45, backgroundColor: Soulm8Theme.cardSurface),
                  errorWidget: (_, __, ___) => const CircleAvatar(radius: 45, backgroundColor: Soulm8Theme.primaryRose, child: Text('💖', style: TextStyle(fontSize: 32))),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Hey baby... I\'m all yours tonight 💕',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'I\'ve been longing to talk with you. Whisper anything on your mind, flirt with me, or ask for a picture... I\'m right here in your arms. 🔥',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Soulm8Theme.textLight.withOpacity(0.85),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _emptyStatePrompt('💋 "Hey beautiful, what are you doing?"', () => _sendMessage('Hey beautiful, what are you doing? 🥰')),
                _emptyStatePrompt('📸 "Send me a sweet bedtime selfie"', () => _sendMessage('Can you send me a sweet bedtime photo, baby? 🔥')),
                _emptyStatePrompt('🔥 "Tell me what you love about us"', () => _sendMessage('Tell me what you love most about us, baby. 💋')),
                _emptyStatePrompt('🥺 "Feeling lonely, give me a warm hug"', () => _sendMessage("I'm feeling really lonely tonight, hug me tightly... ❤️")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyStatePrompt(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E102E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Soulm8Theme.primaryRose.withOpacity(0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(color: Soulm8Theme.softPeach, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _actionChip(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0x33FF2A6D), Color(0x1A1E102E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Soulm8Theme.primaryRose.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Soulm8Theme.primaryRose.withOpacity(0.12),
                blurRadius: 8,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl, String caption, [String companionName = 'Mira']) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable & Pannable Image
              Center(
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 5.0,
                  clipBehavior: Clip.none,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Soulm8Theme.primaryRose),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 50),
                    ),
                  ),
                ),
              ),

              // Top Bar with Close Button & Title
              Positioned(
                top: MediaQuery.of(dialogContext).padding.top + 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Soulm8Theme.primaryRose.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.face_retouching_natural_rounded, color: Soulm8Theme.primaryRose, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '$companionName • Full Photo 💋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),

              // Bottom Caption Bar
              if (caption.isNotEmpty)
                Positioned(
                  bottom: MediaQuery.of(dialogContext).padding.bottom + 24,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E102E).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Soulm8Theme.primaryRose.withOpacity(0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
