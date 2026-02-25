import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../models/link_model.dart';
import '../models/folder_model.dart';
import '../services/storage_service.dart';
import '../services/metadata_service.dart';
import '../widgets/link_card.dart';
import '../widgets/save_link_bottom_sheet.dart';

/// Figma Anasayfa-6 ekranına sadık "Klasör Detay" ekranı:
///   • Geri ok (sol)
///   • Klasör adı (teal, merkez)
///   • Düzenle / Sil / Yıldız ikonları (sağ)
///   • Aynı LinkCard listesi
///   • Sağ alt mavi "+" FAB
class FolderDetailScreen extends StatefulWidget {
  final String folderName;

  const FolderDetailScreen({super.key, required this.folderName});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  late String _currentFolderName;

  @override
  void initState() {
    super.initState();
    _currentFolderName = widget.folderName;
  }

  // ─── Klasör model erişimi ─────────────────────────────────────────────────

  FolderModel? get _folder {
    return StorageService.getAllFolders()
        .where((f) => f.name == _currentFolderName)
        .firstOrNull;
  }

  // ─── Link açma ─────────────────────────────────────────────────────────────

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Metadata yenileme ─────────────────────────────────────────────────────

  Future<void> _refreshMetadata(LinkModel link) async {
    final meta = await MetadataService.fetch(link.url);
    await StorageService.updateMetadata(
      link.id,
      title: meta['title'],
      description: meta['description'],
      faviconUrl: meta['favicon'],
    );
  }

  // ─── Yeniden adlandır ──────────────────────────────────────────────────────

  void _showRenameDialog() {
    final folder = _folder;
    if (folder == null) return;
    final ctrl = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Klasörü yeniden adlandır'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Yeni klasör adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                await StorageService.renameFolder(folder.id, newName);
                setState(() => _currentFolderName = newName);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // ─── Klasörü sil ──────────────────────────────────────────────────────────

  void _showDeleteDialog() {
    final folder = _folder;
    if (folder == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Klasörü sil'),
        content: Text(
          '"$_currentFolderName" klasörünü silmek istediğinizden emin misiniz?\nLinkler silinmez, sadece bu klasörden çıkarılır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final nav = Navigator.of(context);
              await StorageService.deleteFolder(folder.id);
              if (ctx.mounted) Navigator.pop(ctx);
              nav.pop(); // detay ekranını kapat
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ValueListenableBuilder(
        valueListenable: StorageService.box.listenable(),
        builder: (context, box, child) {
          final links =
              StorageService.getLinksInFolder(_currentFolderName);

          if (links.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: links.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final link = links[i];
              return LinkCard(
                link: link,
                onTap: () => _openLink(link.url),
                onDelete: () => StorageService.delete(link.id),
                onRefresh: () => _refreshMetadata(link),
                onToggleFavorite: () =>
                    StorageService.toggleFavorite(link.id),
              );
            },
          );
        },
      ),

      // ── "+" FAB ─────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            SaveLinkBottomSheet.show(context),
        backgroundColor: AppColors.logoEnd, // mavi-mor
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _currentFolderName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      centerTitle: true,
      actions: [
        // Düzenle
        IconButton(
          icon: const Icon(
            Icons.edit_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: _showRenameDialog,
          tooltip: 'Yeniden adlandır',
        ),
        // Sil
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: _showDeleteDialog,
          tooltip: 'Klasörü sil',
        ),
        // Favori
        ValueListenableBuilder(
          valueListenable: StorageService.folderBox.listenable(),
          builder: (ctx, box, child) {
            final fav = _folder?.isFavorite ?? false;
            return IconButton(
              icon: Icon(
                fav ? Icons.star_rounded : Icons.star_border_rounded,
                color: fav ? Colors.amber.shade600 : AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () async {
                final f = _folder;
                if (f != null) {
                  await StorageService.toggleFolderFavorite(f.id);
                  setState(() {});
                }
              },
              tooltip: fav ? 'Favoriden kaldır' : 'Favorilere ekle',
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Boş durum ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '"$_currentFolderName" klasörü boş',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '"+" düğmesiyle bu klasöre link ekleyin.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}