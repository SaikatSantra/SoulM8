import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class TrainingModal extends StatefulWidget {
  final String companionName;
  const TrainingModal({super.key, required this.companionName});

  static void show(BuildContext context, String companionName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrainingModal(companionName: companionName),
    );
  }

  @override
  State<TrainingModal> createState() => _TrainingModalState();
}

class _TrainingModalState extends State<TrainingModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _examples = [];
  String? _errorMessage;

  // Single Add controllers
  final _userController = TextEditingController();
  final _companionController = TextEditingController();

  // Bulk Add controller
  final _bulkTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchExamples();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userController.dispose();
    _companionController.dispose();
    _bulkTextController.dispose();
    super.dispose();
  }

  Future<void> _fetchExamples() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.client.get(ApiConstants.aiTraining);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _examples = data['examples'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load examples';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to backend';
      });
    }
  }

  Future<void> _addSingleExample() async {
    final userText = _userController.text.trim();
    final compText = _companionController.text.trim();

    if (userText.isEmpty || compText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both User message and Companion response'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await ApiClient.client.post(
        ApiConstants.aiTraining,
        data: {'user': userText, 'companion': compText},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _userController.clear();
        _companionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ ${widget.companionName} learned this new dialogue!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchExamples();
        _tabController.animateTo(0);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save dialogue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadBulk() async {
    final rawText = _bulkTextController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste conversation examples first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      dynamic payload;
      // Check if user pasted JSON array
      if (rawText.startsWith('[') && rawText.endsWith(']')) {
        try {
          payload = {'examples': jsonDecode(rawText)};
        } catch (_) {
          payload = {'text': rawText};
        }
      } else {
        payload = {'text': rawText};
      }

      final response = await ApiClient.client.post(
        ApiConstants.aiTraining,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final added = response.data['addedCount'] ?? 1;
        _bulkTextController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚀 Successfully trained with $added dialogue examples!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchExamples();
        _tabController.animateTo(0);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteExample(String id) async {
    try {
      final response = await ApiClient.client.delete('${ApiConstants.aiTraining}/$id');
      if (response.statusCode == 200) {
        setState(() {
          _examples.removeWhere((item) => item['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dialogue example removed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: const Color(0xFF1B0E2B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Soulm8Theme.primaryRose.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Soulm8Theme.primaryRose.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, color: Soulm8Theme.softPeach, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Train ${widget.companionName}\'s Tone & Style',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Teach the LLM how to talk from real conversation examples',
                        style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: Soulm8Theme.primaryRose,
            labelColor: Soulm8Theme.softPeach,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(
                icon: const Icon(Icons.library_books, size: 18),
                text: 'Learned (${_examples.length})',
              ),
              const Tab(
                icon: const Icon(Icons.add_comment, size: 18),
                text: 'Upload Dialogues',
              ),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLearnedExamplesTab(),
                _buildUploadTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnedExamplesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Soulm8Theme.primaryRose),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchExamples,
              style: ElevatedButton.styleFrom(backgroundColor: Soulm8Theme.primaryRose),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_examples.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text(
              'No training examples yet',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Switch to "Upload Dialogues" to add custom examples',
              style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _examples.length,
      itemBuilder: (ctx, idx) {
        final ex = _examples[idx];
        final id = ex['id'] ?? '';
        final userText = ex['user'] ?? '';
        final compText = ex['companion'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Soulm8Theme.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Soulm8Theme.primaryRose.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Example #${idx + 1}',
                      style: const TextStyle(
                        color: Soulm8Theme.softPeach,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteExample(id),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // User Prompt
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👤 User:', style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(userText, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Companion Response
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Soulm8Theme.primaryRose.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💖 ${widget.companionName}:', style: const TextStyle(color: Soulm8Theme.softPeach, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(compText, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Single Add
          const Text(
            'Quick Dialogue Pair',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Teach a single question and ideal response',
            style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _userController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'What the user says (e.g. "ki porecho?")',
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              filled: true,
              fillColor: Soulm8Theme.cardSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _companionController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'How ${widget.companionName} should reply (intimate & flirty)',
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              filled: true,
              fillColor: Soulm8Theme.cardSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _addSingleExample,
              icon: const Icon(Icons.add_task, size: 16),
              label: const Text('Add Dialogue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Soulm8Theme.primaryRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white12),
          ),

          // Section 2: Batch Upload
          const Text(
            'Batch Upload Multiple Conversations',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Paste entire chat logs in "User: ... \\n Companion: ..." format or JSON',
            style: TextStyle(color: Soulm8Theme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bulkTextController,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'User: let go for dinner, after ready send me a selfie\n'
                  'Companion: Dinner-er jonno ready hoye ekta selfie nilam babu! 🥰 Kemon lagche amake bolo? Kokhon aschho amake nite? ✨\n\n'
                  'User: ki korcho?\n'
                  'Companion: Tomar kotha bhabte bhabte bed-e শুয়ে achhi babu... kache asho na? 🔥\n\n'
                  'User: ki porecho?\n'
                  'Companion: Ekta halka lal lace-er nighty pore achhi shona... tumi kache thakle ekhon ki korte bolo na? 💋❤️',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
              filled: true,
              fillColor: Soulm8Theme.cardSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _uploadBulk,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.rocket_launch, size: 18),
              label: Text(_isSaving ? 'Training...' : 'Teach ${widget.companionName} Now 🚀'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Soulm8Theme.primaryRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
