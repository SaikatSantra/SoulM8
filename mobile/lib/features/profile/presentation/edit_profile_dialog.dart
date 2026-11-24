import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/utils/media_picker_helper.dart';
import '../../auth/presentation/auth_controller.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? currentUser;

  const EditProfileDialog({super.key, required this.currentUser});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;
  late String _selectedAvatarUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=400&q=80',
    'https://api.dicebear.com/7.x/bottts/svg?seed=Soulm8Lover',
    'https://api.dicebear.com/7.x/bottts/svg?seed=Stargazer',
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.currentUser;
    _nameController = TextEditingController(text: user?['displayName'] ?? '');
    _bioController = TextEditingController(text: user?['bio'] ?? '');
    _selectedAvatarUrl = user?['avatarUrl'] ?? _avatarPresets[0];
    _avatarUrlController = TextEditingController(text: _selectedAvatarUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatarFromMobile() async {
    setState(() => _isUploading = true);
    try {
      final uploadedUrl = await MediaPickerHelper.pickAndUploadImage(folder: 'avatars');
      if (uploadedUrl != null && mounted) {
        setState(() {
          _selectedAvatarUrl = uploadedUrl;
          _avatarUrlController.text = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar uploaded from mobile! ✨'),
            backgroundColor: Soulm8Theme.primaryRose,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await ref.read(authControllerProvider.notifier).updateProfile(
          displayName: newName,
          bio: _bioController.text.trim(),
          avatarUrl: _avatarUrlController.text.trim().isNotEmpty
              ? _avatarUrlController.text.trim()
              : _selectedAvatarUrl,
        );

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Soulm8Theme.deepPlum,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Your Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile Picture Preview & Selector
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  InkWell(
                    onTap: _isUploading ? null : _pickAvatarFromMobile,
                    borderRadius: BorderRadius.circular(46),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Soulm8Theme.primaryRose.withOpacity(0.3),
                      backgroundImage: NetworkImage(_selectedAvatarUrl),
                      onBackgroundImageError: (_, __) {},
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : (_selectedAvatarUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white, size: 40)
                              : null),
                    ),
                  ),
                  InkWell(
                    onTap: _isUploading ? null : _pickAvatarFromMobile,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Soulm8Theme.primaryRose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _isUploading ? null : _pickAvatarFromMobile,
                icon: const Icon(Icons.photo_library_rounded, size: 16, color: Soulm8Theme.accentGold),
                label: const Text(
                  'Upload Photo from Mobile Gallery',
                  style: TextStyle(color: Soulm8Theme.accentGold, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Curated Avatar Preset Selector
            const Text(
              'Choose Avatar Preset',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Soulm8Theme.softPeach),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _avatarPresets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final preset = _avatarPresets[idx];
                  final isSelected = _selectedAvatarUrl == preset;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatarUrl = preset;
                        _avatarUrlController.text = preset;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Soulm8Theme.primaryRose : Colors.white24,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(preset),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Custom Avatar URL Input
            TextField(
              controller: _avatarUrlController,
              onChanged: (val) {
                if (val.trim().isNotEmpty) {
                  setState(() => _selectedAvatarUrl = val.trim());
                }
              },
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Or Paste Custom Image URL',
                labelStyle: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 12),
                filled: true,
                fillColor: Soulm8Theme.cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // Display Name Field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.person_outline, color: Soulm8Theme.softPeach, size: 20),
                filled: true,
                fillColor: Soulm8Theme.cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),

            // Bio Field
            TextField(
              controller: _bioController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Bio / Emotional Sanctuary Note',
                labelStyle: const TextStyle(color: Soulm8Theme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.edit_note, color: Soulm8Theme.softPeach, size: 20),
                filled: true,
                fillColor: Soulm8Theme.cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Soulm8Theme.primaryRose,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
