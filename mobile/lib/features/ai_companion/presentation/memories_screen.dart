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
  String _selectedCategory = 'ALL';

  final List<String> _categoryTabs = ['ALL', 'PREFERENCE', 'BIOGRAPHICAL', 'RELATIONSHIP', 'EMOTIONAL_TRIGGER'];

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

  List<Map<String, dynamic>> get _filteredFacts {
    if (_selectedCategory == 'ALL') return _facts;
    return _facts.where((f) => (f['category']?.toString().toUpperCase() ?? '') == _selectedCategory).toList();
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

  void _showAddMemoryDialog() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    String selectedCat = 'PREFERENCE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Soulm8Theme.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bookmark_add_rounded, color: Soulm8Theme.primaryRose),
              SizedBox(width: 8),
              Text('Teach Companion a Fact', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category', style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  dropdownColor: Soulm8Theme.cardSurface,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PREFERENCE', child: Text('Preference (Food, Music, Outfits)')),
                    DropdownMenuItem(value: 'BIOGRAPHICAL', child: Text('Biographical (Name, Work, City)')),
                    DropdownMenuItem(value: 'RELATIONSHIP', child: Text('Relationship (Nicknames, Desires)')),
                    DropdownMenuItem(value: 'EMOTIONAL_TRIGGER', child: Text('Emotional (Comforts, Vulnerability)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Fact Topic (Key)', style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: keyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. favorite_color, coffee_habit',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Detail to Remember', style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: valueController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Loves warm black coffee with no sugar',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Soulm8Theme.primaryRose),
              onPressed: () async {
                final k = keyController.text.trim();
                final v = valueController.text.trim();
                if (k.isEmpty || v.isEmpty) return;

                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final repo = ref.read(aiCompanionRepositoryProvider);
                  await repo.addMemory(selectedCat, k, v);
                  await _fetchMemories();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memory recorded! Your companion now remembers this.')),
                    );
                  }
                } catch (_) {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Save Fact', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
    final score = (_pulse?['closenessScore'] ?? 15) as int;
    final mood = (_pulse?['currentMood'] ?? 'Warm & curious') as String;

    int levelNum = 1;
    String levelName = 'Acquaintance';
    String milestoneDesc = 'Next: Close Friend (Level 2 at 30%)';

    if (score >= 80) {
      levelNum = 4;
      levelName = 'Romantic Soulmate';
      milestoneDesc = 'Unconditional Bond (100%)';
    } else if (score >= 55) {
      levelNum = 3;
      levelName = 'Soul Confidant';
      milestoneDesc = 'Next: Romantic Soulmate (Level 4 at 80%)';
    } else if (score >= 30) {
      levelNum = 2;
      levelName = 'Close Friend';
      milestoneDesc = 'Next: Soul Confidant (Level 3 at 55%)';
    }

    return Scaffold(
      backgroundColor: Soulm8Theme.darkBackground,
      appBar: AppBar(
        backgroundColor: Soulm8Theme.cardSurface,
        title: const Text('Memory & Relationship Diary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Teach new fact',
            icon: const Icon(Icons.add_circle_outline, color: Soulm8Theme.primaryRose, size: 26),
            onPressed: _showAddMemoryDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Soulm8Theme.primaryRose))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Relationship Pulse & Closeness Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: Soulm8Theme.darkCardGradient,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Soulm8Theme.primaryRose.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.favorite, color: Soulm8Theme.primaryRose, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Level $levelNum · $levelName',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  milestoneDesc,
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Soulm8Theme.primaryRose.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.5)),
                              ),
                              child: Text(
                                '$score% Closeness',
                                style: const TextStyle(
                                  color: Soulm8Theme.primaryRose,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: score / 100.0,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(Soulm8Theme.primaryRose),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.psychology_outlined, size: 18, color: Soulm8Theme.lavenderWhisper),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Companion Heartbeat: $mood',
                                  style: const TextStyle(color: Soulm8Theme.lavenderWhisper, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Semantic Facts Header & Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Learned Memories & Facts',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddMemoryDialog,
                        icon: const Icon(Icons.add, size: 16, color: Soulm8Theme.primaryRose),
                        label: const Text('Add Fact', style: TextStyle(color: Soulm8Theme.primaryRose, fontSize: 13)),
                      ),
                    ],
                  ),
                  const Text(
                    'Soulm8 automatically remembers details you mention and keeps facts synchronized. You can also teach custom preferences or erase facts anytime.',
                    style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  // Category Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categoryTabs.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              cat.replaceAll('_', ' '),
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.white60,
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: Soulm8Theme.primaryRose,
                            backgroundColor: Soulm8Theme.cardSurface,
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_filteredFacts.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Soulm8Theme.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.history_edu, color: Colors.white24, size: 48),
                          const SizedBox(height: 10),
                          const Text(
                            'No memories in this category yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _showAddMemoryDialog,
                            child: const Text('Add your first memory', style: TextStyle(color: Soulm8Theme.primaryRose)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredFacts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final fact = _filteredFacts[idx];
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
