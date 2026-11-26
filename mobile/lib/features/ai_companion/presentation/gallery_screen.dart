import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme.dart';
import '../data/ai_companion_repository.dart';
import 'ai_chat_controller.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _photos = [];
  String _selectedCategory = 'ALL';

  final List<Map<String, String>> _categories = [
    {'id': 'ALL', 'label': 'All Moments 📸'},
    {'id': 'TRADITIONAL', 'label': 'Traditional & Saree 🥻'},
    {'id': 'CASUAL', 'label': 'Cozy & Casual ☕'},
    {'id': 'NIGHTWEAR', 'label': 'Nightwear & Bedtime 🌙'},
    {'id': 'PORTRAIT', 'label': 'Portraits & Smiles ✨'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(aiCompanionRepositoryProvider);
      final list = await repo.getGallery();
      setState(() {
        _photos = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPhotos {
    if (_selectedCategory == 'ALL') return _photos;
    return _photos.where((p) => (p['category']?.toString().toUpperCase() ?? '') == _selectedCategory).toList();
  }

  void _openPhotoDetail(Map<String, dynamic> photo) {
    final url = photo['url']?.toString() ?? '';
    final caption = photo['caption']?.toString() ?? 'Soulm8 Moment';
    final category = photo['category']?.toString() ?? '';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.5,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator(color: Soulm8Theme.primaryRose)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 240,
                    color: Soulm8Theme.cardSurface,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white30, size: 48)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Soulm8Theme.cardSurface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Soulm8Theme.primaryRose.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Soulm8Theme.primaryRose.withOpacity(0.4)),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(color: Soulm8Theme.primaryRose, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Saved in your Soulm8 Sanctuary',
                        icon: const Icon(Icons.favorite, color: Soulm8Theme.primaryRose, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Photo added to favorites! 💕'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caption,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Soulm8Theme.darkBackground,
      appBar: AppBar(
        backgroundColor: Soulm8Theme.cardSurface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.photo_library_rounded, color: Soulm8Theme.primaryRose, size: 22),
            SizedBox(width: 8),
            Text(
              'Moments & Gallery',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadGallery,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      cat['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat['id']!);
                    },
                    backgroundColor: Soulm8Theme.cardSurface,
                    selectedColor: Soulm8Theme.primaryRose,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Soulm8Theme.primaryRose : Colors.white12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Photo grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Soulm8Theme.primaryRose))
                : _filteredPhotos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_album_outlined, color: Colors.white24, size: 64),
                            const SizedBox(height: 12),
                            const Text(
                              'No photos in this category yet',
                              style: TextStyle(color: Colors.white60, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => setState(() => _selectedCategory = 'ALL'),
                              icon: const Icon(Icons.restore, color: Soulm8Theme.primaryRose),
                              label: const Text('View All Moments', style: TextStyle(color: Soulm8Theme.primaryRose)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadGallery,
                        color: Soulm8Theme.primaryRose,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.76,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredPhotos.length,
                          itemBuilder: (context, index) {
                            final photo = _filteredPhotos[index];
                            final url = photo['url']?.toString() ?? '';
                            final caption = photo['caption']?.toString() ?? '';

                            return GestureDetector(
                              onTap: () => _openPhotoDetail(photo),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Soulm8Theme.cardSurface,
                                  border: Border.all(color: Colors.white12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Soulm8Theme.cardSurface,
                                        child: const Center(
                                          child: CircularProgressIndicator(color: Soulm8Theme.primaryRose, strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Soulm8Theme.cardSurface,
                                        child: const Center(
                                          child: Icon(Icons.broken_image, color: Colors.white24, size: 36),
                                        ),
                                      ),
                                    ),
                                    // Gradient overlay
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.85),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          caption,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
