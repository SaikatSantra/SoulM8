import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import 'human_chat_controller.dart';

class HumanChatScreen extends ConsumerStatefulWidget {
  final String friendId;
  final Map<String, dynamic>? friendData;

  const HumanChatScreen({
    super.key,
    required this.friendId,
    this.friendData,
  });

  @override
  ConsumerState<HumanChatScreen> createState() => _HumanChatScreenState();
}

class _HumanChatScreenState extends ConsumerState<HumanChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    ref.read(humanChatControllerProvider(widget.friendId).notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _sendImageMessage(String imageUrl, [String? caption]) {
    final text = caption?.trim().isNotEmpty == true ? caption!.trim() : '📷 Photo';
    ref.read(humanChatControllerProvider(widget.friendId).notifier).sendMessage(text, mediaUrl: imageUrl);
    _scrollToBottom();
  }

  void _showImagePickerModal() {
    final photoPresets = [
      {'name': 'Chai ☕', 'url': 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80'},
      {'name': 'Sunset 🌅', 'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80'},
      {'name': 'Roses 🌹', 'url': 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?auto=format&fit=crop&w=600&q=80'},
      {'name': 'Cute Pet 🐱', 'url': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=600&q=80'},
      {'name': 'Rain 🌧️', 'url': 'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?auto=format&fit=crop&w=600&q=80'},
      {'name': 'Cozy Read 📖', 'url': 'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=600&q=80'},
    ];

    final urlController = TextEditingController();
    final captionController = TextEditingController();
    String selectedUrl = photoPresets[0]['url']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Soulm8Theme.deepPlum,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Send a Photo',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Image Preview
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: urlController.text.trim().isNotEmpty ? urlController.text.trim() : selectedUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 150,
                          color: Soulm8Theme.cardSurface,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Quick Cozy Presets:', style: TextStyle(color: Soulm8Theme.softPeach, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final p = photoPresets[i];
                        final isSel = selectedUrl == p['url'];
                        return ChoiceChip(
                          label: Text(p['name']!),
                          selected: isSel,
                          selectedColor: Soulm8Theme.primaryRose,
                          backgroundColor: Soulm8Theme.cardSurface,
                          labelStyle: TextStyle(color: isSel ? Colors.white : Soulm8Theme.textLight, fontSize: 12),
                          onSelected: (_) {
                            setModalState(() {
                              selectedUrl = p['url']!;
                              urlController.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    onChanged: (_) => setModalState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Or paste image URL...',
                      hintStyle: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: Soulm8Theme.cardSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: captionController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add a warm caption...',
                      hintStyle: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: Soulm8Theme.cardSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Soulm8Theme.primaryRose,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      label: const Text('Send Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final targetUrl = urlController.text.trim().isNotEmpty ? urlController.text.trim() : selectedUrl;
                        Navigator.pop(ctx);
                        _sendImageMessage(targetUrl, captionController.text.trim());
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(humanChatControllerProvider(widget.friendId), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    final chatState = ref.watch(humanChatControllerProvider(widget.friendId));
    final friendName = widget.friendData?['displayName'] ?? 'Friend';
    final avatarUrl = widget.friendData?['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Soulm8Theme.primaryRose.withOpacity(0.2),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friendName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    chatState.isFriendTyping ? 'typing...' : 'End-to-end private chat',
                    style: TextStyle(
                      fontSize: 11,
                      color: chatState.isFriendTyping ? Soulm8Theme.softPeach : Soulm8Theme.textMuted,
                      fontStyle: chatState.isFriendTyping ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Soulm8Theme.primaryRose))
                : chatState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_border, size: 48, color: Soulm8Theme.softPeach),
                            const SizedBox(height: 12),
                            Text(
                              'Say hello to $friendName!',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Start your private, judgment-free conversation.',
                              style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, idx) {
                          final msg = chatState.messages[idx];
                          final isMe = msg['isMe'] == true;
                          final content = msg['content'] ?? '';
                          final createdAt = msg['createdAt'] != null
                              ? DateTime.tryParse(msg['createdAt'])
                              : null;
                          final timeStr = createdAt != null
                              ? DateFormat('hh:mm a').format(createdAt)
                              : '';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                gradient: isMe ? Soulm8Theme.primaryGradient : null,
                                color: isMe ? null : Soulm8Theme.cardSurface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (msg['mediaUrl'] != null && msg['mediaUrl'].toString().isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: msg['mediaUrl'].toString(),
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          height: 180,
                                          color: Soulm8Theme.cardSurface,
                                          child: const Center(
                                            child: CircularProgressIndicator(color: Soulm8Theme.primaryRose, strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                  if (content.isNotEmpty && content != '📷 Photo') ...[
                                    Text(
                                      content,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Soulm8Theme.textLight,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : Soulm8Theme.textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          msg['status'] == 'READ' ? Icons.done_all : Icons.check,
                                          size: 13,
                                          color: msg['status'] == 'READ'
                                              ? Colors.white
                                              : Colors.white70,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Soulm8Theme.cardSurface,
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Send Image or Photo',
                    icon: const Icon(Icons.photo_camera_outlined, color: Soulm8Theme.softPeach),
                    onPressed: _showImagePickerModal,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Soulm8Theme.deepPlum,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Soulm8Theme.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: Soulm8Theme.primaryGradient,
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
    );
  }
}
