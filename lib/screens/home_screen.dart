import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../models/link_model.dart';
import '../services/storage_service.dart';
import '../services/metadata_service.dart';
import '../widgets/link_card.dart';
import '../widgets/save_link_bottom_sheet.dart';
import '../widgets/folder_drawer.dart';
import '../widgets/logo_widget.dart';

/// Figma Anasayfa ekranı
///   • Beyaz AppBar — sol hamburger, ortada Logo
///   • HOŞGELDİNİZ ! (teal, bold)
///   • Alt yazı (gri)
///   • Arama çubuğu (lavanta dolgu, yuvarlak)
///   • Link listesi (ValueListenableBuilder)
///   • "+Save a link" teal pill FAB
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Listenable'ı bir kez oluştur — her build'de yeni nesne üretmesin
  late final _linksListenable = StorageService.box.listenable();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Arama filtresi ────────────────────────────────────────────────────────

  List<LinkModel> _filtered(List<LinkModel> all) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((l) {
      return l.url.toLowerCase().contains(q) ||
          (l.title?.toLowerCase().contains(q) ?? false) ||
          (l.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ─── Link aç ───────────────────────────────────────────────────────────────

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Metadata yenile ───────────────────────────────────────────────────────

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
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Bilgiler güncellendi!'),
            ],
          ),
        ),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      // Drawer navigasyonu FolderDrawer içinde yönetilir (nav.pop → nav.push)
      drawer: const FolderDrawer(),
      appBar: _buildAppBar(),
      body: ValueListenableBuilder(
        valueListenable: _linksListenable,
        builder: (context, box, child) {
          final all = StorageService.getAll();
          final links = _filtered(all);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Karşılama + Arama ─────────────────────────────────────
              SliverToBoxAdapter(
                child: _WelcomeHeader(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (v) =>
                      setState(() => _searchQuery = v),
                  onSearchClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),

              // ── Liste ya da boş durum ──────────────────────────────────
              if (links.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(hasLinks: all.isNotEmpty),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: links.length,
                    separatorBuilder: (ctx, idx) =>
                        const SizedBox(height: 10),
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
                  ),
                ),
            ],
          );
        },
      ),

      // ── "+Save a link" FAB ────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SaveLinkBottomSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          '+Save a link',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded,
            color: AppColors.textPrimary, size: 26),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Menü',
      ),
      title: const LinkSaverLogo(size: 36),
      centerTitle: true,
    );
  }
}

// ─── HOŞGELDİNİZ + Arama bölümü ─────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final void Function(String) onSearchChanged;
  final VoidCallback onSearchClear;

  const _WelcomeHeader({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HOŞGELDİNİZ !
          const Text(
            'HOŞGELDİNİZ !',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary, // Figma teal
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bu gün ne kaydetmek istersiniz ?',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),

          // Arama çubuğu
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Ara...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textSecondary, size: 18),
                      onPressed: onSearchClear,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Boş durum ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasLinks;
  const _EmptyState({required this.hasLinks});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                hasLinks
                    ? Icons.search_off_rounded
                    : Icons.bookmark_add_outlined,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasLinks ? 'Sonuç bulunamadı' : 'Henüz link yok!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasLinks
                  ? 'Farklı bir arama terimi deneyin.'
                  : '"+Save a link" düğmesiyle\nilk linkinizi kaydedin.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
