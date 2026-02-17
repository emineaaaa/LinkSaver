import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/link_model.dart';
import '../services/storage_service.dart';
import '../services/metadata_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _uuid = const Uuid();
  String _searchQuery = '';
  String? _selectedTag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LinkModel> _filtered(List<LinkModel> all) {
    return all.where((link) {
      final matchesSearch = _searchQuery.isEmpty ||
          link.url.toLowerCase().contains(_searchQuery) ||
          (link.title?.toLowerCase().contains(_searchQuery) ?? false);
      final matchesTag =
          _selectedTag == null || link.tags.contains(_selectedTag);
      return matchesSearch && matchesTag;
    }).toList();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAddLinkDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_link, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Link Ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://...',
                prefixIcon: const Icon(Icons.link, color: Colors.indigo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Colors.indigo, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.save_alt),
                label: const Text('Kaydet',
                    style: TextStyle(fontSize: 16)),
                onPressed: () async {
                  final url = controller.text.trim();
                  if (url.isEmpty) return;
                  Navigator.pop(ctx);
                  await _saveLink(url);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLink(String url) async {
    final link = LinkModel(
      id: _uuid.v4(),
      url: url,
      savedAt: DateTime.now(),
    );
    await StorageService.add(link);

    MetadataService.fetch(url).then((meta) async {
      await StorageService.updateMetadata(
        link.id,
        title: meta['title'],
        description: meta['description'],
        faviconUrl: meta['favicon'],
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Link kaydedildi!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  void _showTagDialog(LinkModel link) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.label, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Etiketler',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, setModalState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ...link.tags.asMap().entries.map(
                            (e) => Chip(
                              label: Text(e.value),
                              backgroundColor: _tagColor(e.key).withAlpha(30),
                              side: BorderSide(
                                  color: _tagColor(e.key), width: 1),
                              labelStyle:
                                  TextStyle(color: _tagColor(e.key)),
                              deleteIconColor: _tagColor(e.key),
                              onDeleted: () async {
                                final newTags =
                                    List<String>.from(link.tags)
                                      ..remove(e.value);
                                await StorageService.updateTags(
                                    link.id, newTags);
                                setModalState(() {});
                                if (mounted) setState(() {});
                              },
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Yeni etiket...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                            prefixIcon: const Icon(Icons.tag, size: 18),
                          ),
                          onSubmitted: (_) async {
                            final tag = controller.text.trim();
                            if (tag.isNotEmpty &&
                                !link.tags.contains(tag)) {
                              final newTags =
                                  List<String>.from(link.tags)..add(tag);
                              await StorageService.updateTags(
                                  link.id, newTags);
                              controller.clear();
                              setModalState(() {});
                              if (mounted) setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(14),
                        ),
                        onPressed: () async {
                          final tag = controller.text.trim();
                          if (tag.isNotEmpty && !link.tags.contains(tag)) {
                            final newTags =
                                List<String>.from(link.tags)..add(tag);
                            await StorageService.updateTags(link.id, newTags);
                            controller.clear();
                            setModalState(() {});
                            if (mounted) setState(() {});
                          }
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshMetadata(LinkModel link) async {
    final meta = await MetadataService.fetch(link.url);
    await StorageService.updateMetadata(
      link.id,
      title: meta['title'],
      description: meta['description'],
      faviconUrl: meta['favicon'],
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Text('Bilgiler güncellendi!'),
            ],
          ),
          backgroundColor: Colors.teal.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  Color _tagColor(int index) {
    const colors = [
      Colors.indigo,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.blue,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Link Saver',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3F51B5), Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Align(
                  alignment: Alignment(0.9, -0.3),
                  child: Icon(Icons.bookmarks_rounded,
                      size: 80, color: Colors.white24),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_link, color: Colors.white),
                tooltip: 'Link Ekle',
                onPressed: _showAddLinkDialog,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Link veya başlık ara...',
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.indigo),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: StorageService.box.listenable(),
            builder: (context, box, _) {
              final all = StorageService.getAll();
              final allTags = StorageService.getAllTags();
              final links = _filtered(all);

              return SliverMainAxisGroup(
                slivers: [
                  if (allTags.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: ListView(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('Tümü'),
                                selected: _selectedTag == null,
                                selectedColor: Colors.indigo.shade100,
                                checkmarkColor: Colors.indigo,
                                onSelected: (_) =>
                                    setState(() => _selectedTag = null),
                              ),
                            ),
                            ...allTags.asMap().entries.map(
                                  (e) => Padding(
                                    padding:
                                        const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(e.value),
                                      selected: _selectedTag == e.value,
                                      selectedColor:
                                          _tagColor(e.key).withAlpha(40),
                                      checkmarkColor: _tagColor(e.key),
                                      onSelected: (sel) => setState(
                                        () => _selectedTag =
                                            sel ? e.value : null,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  if (links.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              all.isEmpty
                                  ? Icons.bookmark_add_outlined
                                  : Icons.search_off,
                              size: 72,
                              color: Colors.indigo.shade200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              all.isEmpty
                                  ? 'Henüz link yok!'
                                  : 'Sonuç bulunamadı',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              all.isEmpty
                                  ? '+ butonuna bas veya başka\nbir uygulamadan link paylaş'
                                  : 'Farklı bir arama dene',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      sliver: SliverList.separated(
                        itemCount: links.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final link = links[index];
                          return _LinkCard(
                            link: link,
                            onTap: () => _openLink(link.url),
                            onLongPress: () => _showTagDialog(link),
                            onDelete: () => StorageService.delete(link.id),
                            onRefresh: () => _refreshMetadata(link),
                            tagColorFn: _tagColor,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLinkDialog,
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_link),
        label: const Text('Link Ekle',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final LinkModel link;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final Color Function(int) tagColorFn;

  const _LinkCard({
    required this.link,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onRefresh,
    required this.tagColorFn,
  });

  Color _domainColor(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return Colors.red;
    } else if (url.contains('twitter.com') || url.contains('x.com')) {
      return Colors.blueGrey;
    } else if (url.contains('instagram.com')) {
      return Colors.purple;
    } else if (url.contains('facebook.com')) {
      return const Color(0xFF1877F2);
    } else if (url.contains('tiktok.com')) {
      return Colors.black87;
    } else if (url.contains('reddit.com')) {
      return Colors.deepOrange;
    } else if (url.contains('github.com')) {
      return Colors.black87;
    } else if (url.contains('linkedin.com')) {
      return const Color(0xFF0A66C2);
    } else if (url.contains('spotify.com')) {
      return Colors.green;
    } else if (url.contains('twitch.tv')) {
      return Colors.deepPurple;
    }
    return Colors.indigo;
  }

  IconData _domainIcon(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return Icons.play_circle_fill;
    } else if (url.contains('twitter.com') || url.contains('x.com')) {
      return Icons.alternate_email;
    } else if (url.contains('instagram.com')) {
      return Icons.camera_alt;
    } else if (url.contains('facebook.com')) {
      return Icons.facebook;
    } else if (url.contains('tiktok.com')) {
      return Icons.music_video;
    } else if (url.contains('reddit.com')) {
      return Icons.forum;
    } else if (url.contains('github.com')) {
      return Icons.code;
    } else if (url.contains('linkedin.com')) {
      return Icons.work;
    } else if (url.contains('spotify.com')) {
      return Icons.music_note;
    } else if (url.contains('twitch.tv')) {
      return Icons.videogame_asset;
    }
    return Icons.language;
  }

  @override
  Widget build(BuildContext context) {
    final color = _domainColor(link.url);
    final icon = _domainIcon(link.url);

    return Dismissible(
      key: Key(link.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, color: Colors.white, size: 28),
            Text('Yenile', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            Text('Sil', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onRefresh();
          return false; // kaydırma geri dönsün, silinmesin
        }
        return true; // endToStart → sil
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title ?? link.url,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (link.title != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            link.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      if (link.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 4,
                            children: link.tags.asMap().entries.map(
                              (e) {
                                final c = tagColorFn(e.key);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: c.withAlpha(80)),
                                  ),
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: c,
                                        fontWeight: FontWeight.w600),
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(link.savedAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.open_in_new,
                        size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }
}
