import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import 'ai_chat_controller.dart';

class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});

  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _pulse;
  List<Map<String, dynamic>> _facts = [];

  @override
  void initState() {
    super.initState();
    _fetchMemories();
  }

  Future<void> _fetchMemories() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(aiCompanionRepositoryProvider);
      final data = await repo.getMemories();
      setState(() {
        _pulse = data['pulse'];
        _facts = List<Map<String, dynamic>>.from(data['facts'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSingleFact(String id) async {
    try {
      final repo = ref.read(aiCompanionRepositoryProvider);
      await repo.deleteMemory(id);
      setState(() {
        _facts.removeWhere((f) => f['id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory permanently erased.')),
        );
      }
    } catch (_) {}
  }

  Future<void> _handleCompletePurge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Soulm8Theme.cardSurface,
        title: const Text('Purge All Memory & Chats?'),
        content: const Text(
          'This will permanently wipe all facts Soulm8 has learned about you, reset your emotional closeness score, and delete your AI chat history. This action cannot be undone.',
          style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('1-Click Purge All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(aiCompanionRepositoryProvider);
        await repo.purgeAllMemories();
        ref.read(aiChatControllerProvider.notifier).loadHistory();
        await _fetchMemories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All personal memories purged. Fresh clean slate.')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _pulse?['closenessScore'] ?? 15;
    final mood = _pulse?['currentMood'] ?? 'Warm & curious';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory & GDPR Autonomy'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Soulm8Theme.primaryRose))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Relationship Pulse Card (Tier A)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: Soulm8Theme.darkCardGradient,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Soulm8Theme.softPeach.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tier A: Relationship Pulse',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Soulm8Theme.softPeach,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Soulm8Theme.primaryRose.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Intimacy: $score%',
                                style: const TextStyle(
                                  color: Soulm8Theme.primaryRose,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (score as num) / 100.0,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(Soulm8Theme.primaryRose),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 16, color: Soulm8Theme.primaryRose),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current Companion State: $mood',
                                style: const TextStyle(color: Soulm8Theme.textLight, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Semantic Facts Header & Count (Tier B)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Learned Facts (Tier B)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Soulm8Theme.textLight,
                        ),
                      ),
                      Text(
                        '${_facts.length} active facts',
                        style: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Soulm8 automatically remembers details you mention and supersedes contradictions. You have complete autonomy to inspect and delete individual facts.',
                    style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 16),

                  if (_facts.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Soulm8Theme.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Center(
                        child: Text(
                          'No memories recorded yet.\nStart chatting with your companion!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 14),
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _facts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final fact = _facts[idx];
                        final category = fact['category'] ?? 'PREFERENCE';
                        final key = fact['factKey'] ?? '';
                        final value = fact['factValue'] ?? '';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Soulm8Theme.cardSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Soulm8Theme.lavenderWhisper.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          color: Soulm8Theme.lavenderWhisper,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      key.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(
                                        color: Soulm8Theme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      value,
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
                                tooltip: 'Permanently Erase Fact',
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteSingleFact(fact['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 36),

                  // 1-Click GDPR Total Wipe Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.redAccent, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'GDPR Right to be Forgotten',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You have full autonomy over your data. Execute a 1-click purge to delete all memories, episodic milestones, and conversations permanently.',
                          style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12, height: 1.3),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                            label: const Text(
                              '1-Click Complete Data Purge',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _handleCompletePurge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
