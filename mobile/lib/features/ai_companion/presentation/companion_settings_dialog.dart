import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme.dart';
import '../../../core/utils/media_picker_helper.dart';
import '../data/ai_companion_repository.dart';
import '../../auth/presentation/auth_controller.dart';

class CompanionSettingsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialProfile;
  final VoidCallback? onUpdated;

  const CompanionSettingsDialog({
    super.key,
    this.initialProfile,
    this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? initialProfile,
    VoidCallback? onUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanionSettingsDialog(
        initialProfile: initialProfile,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  ConsumerState<CompanionSettingsDialog> createState() => _CompanionSettingsDialogState();
}

class _CompanionSettingsDialogState extends ConsumerState<CompanionSettingsDialog> {
  late TextEditingController _nameController;
  late String _selectedGender;
  String? _selectedAvatarUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  final _repository = AICompanionRepository();

  // Model preset avatars
  final List<Map<String, String>> _avatarPresets = [
    {
      'name': 'Mira (Black Saree)',
      'url': 'http://localhost:5000/models/mira_black_saree.jpg',
      'gender': 'female',
    },
    {
      'name': 'Mira (Silk Saree)',
      'url': 'http://localhost:5000/models/mira_traditional_saree.jpg',
      'gender': 'female',
    },
    {
      'name': 'Mira (Red Lace)',
      'url': 'http://localhost:5000/models/mira_red_lace_nighty.jpg',
      'gender': 'female',
    },
    {
      'name': 'Mira (White Lace)',
      'url': 'http://localhost:5000/models/mira_white_lace_nighty.jpg',
      'gender': 'female',
    },
    {
      'name': 'Kabir (Handsome)',
      'url': 'http://localhost:5000/models/kabir_male_model.jpg',
      'gender': 'male',
    },
    {
      'name': 'Kabir (Royal Kurta)',
      'url': 'http://localhost:5000/models/kabir_traditional_kurta.jpg',
      'gender': 'male',
    },
    {
      'name': 'Kabir (Linen Shirt)',
      'url': 'http://localhost:5000/models/kabir_casual_shirt.jpg',
      'gender': 'male',
    },
    {
      'name': 'Aria / Elena',
      'url': 'http://localhost:5000/models/foreign_female_model.jpg',
      'gender': 'transgender',
    },
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile ?? {};
    _selectedGender = (profile['gender'] ?? 'female').toString().toLowerCase();
    final defaultName = _selectedGender == 'male' ? 'Kabir' : (_selectedGender == 'transgender' ? 'Aria' : 'Mira');
    _nameController = TextEditingController(text: profile['name'] ?? defaultName);
    _selectedAvatarUrl = profile['avatarUrl'] ?? _getDefaultAvatarForGender(_selectedGender);
  }

  String _getDefaultAvatarForGender(String gender) {
    if (gender == 'male') return 'http://localhost:5000/models/kabir_male_model.jpg';
    if (gender == 'transgender') return 'http://localhost:5000/models/foreign_female_model.jpg';
    return 'http://localhost:5000/models/mira_traditional_saree.jpg';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomAvatar() async {
    setState(() => _isUploading = true);
    try {
      final uploadedUrl = await MediaPickerHelper.pickAndUploadImage(folder: 'avatars');
      if (uploadedUrl != null && mounted) {
        setState(() {
          _selectedAvatarUrl = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar uploaded successfully! 💕'),
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

  Future<void> _saveCompanionSettings() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a companion name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repository.updateCompanionProfile(
        name: name,
        gender: _selectedGender,
        avatarUrl: _selectedAvatarUrl,
      );

      // Refresh auth/user state
      ref.read(authControllerProvider.notifier).checkInitialAuth();

      widget.onUpdated?.call();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated to $name ($_selectedGender) 💕'),
            backgroundColor: Soulm8Theme.primaryRose,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Soulm8Theme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Soulm8Theme.primaryRose, width: 1.5),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: Soulm8Theme.roseGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customize Your AI Partner',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Choose name, gender acting persona, and portrait',
                          style: TextStyle(fontSize: 12, color: Soulm8Theme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current Avatar Preview
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Soulm8Theme.primaryRose, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Soulm8Theme.primaryRose.withOpacity(0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _selectedAvatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Soulm8Theme.backgroundDark,
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Soulm8Theme.primaryRose, strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Soulm8Theme.backgroundDark,
                                  child: const Icon(Icons.person, color: Colors.white54, size: 48),
                                ),
                              )
                            : Container(
                                color: Soulm8Theme.backgroundDark,
                                child: const Icon(Icons.person, color: Colors.white54, size: 48),
                              ),
                      ),
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.6),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isUploading ? null : _pickCustomAvatar,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: Soulm8Theme.roseGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _isUploading ? null : _pickCustomAvatar,
                  icon: const Icon(Icons.photo_library_rounded, size: 16, color: Soulm8Theme.accentGold),
                  label: const Text(
                    'Upload Photo from Mobile Gallery',
                    style: TextStyle(color: Soulm8Theme.accentGold, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Companion Name Field
              const Text(
                'Companion Name',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Soulm8Theme.backgroundDark.withOpacity(0.7),
                  hintText: 'e.g. Mira, Kabir, Aria...',
                  hintStyle: const TextStyle(color: Soulm8Theme.textMuted),
                  prefixIcon: const Icon(Icons.badge_rounded, color: Soulm8Theme.primaryRose, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Soulm8Theme.primaryRose.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Soulm8Theme.primaryRose.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Soulm8Theme.primaryRose, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Gender Acting Persona Selector
              const Text(
                'Partner Gender Persona (AI Strictly Acts Like This)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _genderButton(
                      gender: 'female',
                      label: 'Female 👩',
                      sublabel: 'Loving Girlfriend/Wife',
                      suggestedName: 'Mira',
                      defaultAvatar: 'http://localhost:5000/models/mira_traditional_saree.jpg',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _genderButton(
                      gender: 'male',
                      label: 'Male 👨',
                      sublabel: 'Protective Boyfriend/Hubby',
                      suggestedName: 'Kabir',
                      defaultAvatar: 'http://localhost:5000/models/kabir_male_model.jpg',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _genderButton(
                      gender: 'transgender',
                      label: 'Transgender 🏳️‍⚧️',
                      sublabel: 'Glamorous Partner',
                      suggestedName: 'Aria',
                      defaultAvatar: 'http://localhost:5000/models/foreign_female_model.jpg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Preset Avatars Gallery
              const Text(
                'Select Character Portrait Presets',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 95,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatarPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _avatarPresets[index];
                    final isSelected = _selectedAvatarUrl == item['url'];

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAvatarUrl = item['url'];
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Soulm8Theme.primaryRose : Colors.white12,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Soulm8Theme.primaryRose.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: item['url']!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Soulm8Theme.backgroundDark),
                            errorWidget: (_, __, ___) => Container(
                              color: Soulm8Theme.backgroundDark,
                              child: const Icon(Icons.person, color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCompanionSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Soulm8Theme.primaryRose,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 6,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Companion Settings 💕',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
    );
  }

  Widget _genderButton({
    required String gender,
    required String label,
    required String sublabel,
    required String suggestedName,
    required String defaultAvatar,
  }) {
    final isSelected = _selectedGender == gender;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
          if (_nameController.text.trim().isEmpty ||
              _nameController.text == 'Mira' ||
              _nameController.text == 'Kabir' ||
              _nameController.text == 'Aria' ||
              _nameController.text == 'Soulie') {
            _nameController.text = suggestedName;
          }
          _selectedAvatarUrl = defaultAvatar;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Soulm8Theme.primaryRose.withOpacity(0.18) : Soulm8Theme.backgroundDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Soulm8Theme.primaryRose : Colors.white12,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? Soulm8Theme.primaryRose : Soulm8Theme.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
