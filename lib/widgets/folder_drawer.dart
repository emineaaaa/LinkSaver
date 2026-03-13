import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../models/folder_model.dart';
import '../models/link_model.dart';
import '../services/storage_service.dart';
import '../screens/folder_detail_screen.dart';
import 'logo_widget.dart';

/// Figma Anasayfa-click (Drawer) ekranına sadık sol navigasyon paneli.
///
/// Navigasyon BUG FIX:
///   Drawer içinden Navigator.push yapılıp arkasından Navigator.pop çağrılırsa
///   push edilen ekran hemen pop edilir. Doğru sıralama:
///   1. nav.pop()  → Drawer kapanır  → Stack: [HomeScreen]
///   2. nav.push() → FolderDetail açılır → Stack: [HomeScreen, FolderDetail]
class FolderDrawer extends StatelessWidget {
  const FolderDrawer({super.key});

  // ─── Navigasyon — şifre varsa önce kontrol et ────────────────────────────

  Future<void> _goToFolder(BuildContext context, FolderModel folder) async {
    if (folder.password != null && folder.password!.isNotEmpty) {
      final unlocked = await _checkPassword(context, folder.password!);
      if (!unlocked || !context.mounted) return;
    }
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(
      builder: (_) => FolderDetailScreen(folderName: folder.name),
    ));
  }

  // ─── Şifre doğrulama dialogu ──────────────────────────────────────────────

  Future<bool> _checkPassword(BuildContext context, String correct) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PasswordCheckDialog(correct: correct),
        ) ??
        false;
  }

  // ─── Favori link aç ──────────────────────────────────────────────────────

  Future<void> _openLink(BuildContext context, String url) async {
    Navigator.pop(context); // Drawer kapat
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Klasör seçenekleri ───────────────────────────────────────────────────

  void _showFolderOptions(BuildContext context, FolderModel folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _FolderOptionsSheet(folder: folder, parentContext: context),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: const LinkSaverLogo(size: 42, showText: true),
            ),
            const Divider(height: 1),

            // ── Liste ────────────────────────────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  StorageService.box.listenable(),
                  StorageService.folderBox.listenable(),
                ]),
                builder: (ctx, _) {
                  final folders = StorageService.getAllFolders();
                  final favLinks = StorageService.getFavorites();
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      // ── Klasörlerim ──────────────────────────────────
                      const _SectionHeader(title: 'Klasörlerim'),
                      ...folders.map((f) => _FolderTile(
                            folder: f,
                            count: StorageService.getFolderLinkCount(f.name),
                            onTap: () => _goToFolder(context, f),
                            onMoreTap: () => _showFolderOptions(context, f),
                            onFavoriteTap: () =>
                                StorageService.toggleFolderFavorite(f.id),
                          )),
                      if (folders.isEmpty)
                        const _EmptyHint(
                          'Henüz klasör yok.\n'
                          'Link kaydederken klasör oluşturabilirsiniz.',
                        ),

                      const SizedBox(height: 8),
                      const Divider(),

                      // ── Favorilerim ──────────────────────────────────
                      const _SectionHeader(title: 'Favorilerim'),
                      ...favLinks.map((l) => _FavoriteLinkTile(
                            link: l,
                            onTap: () => _openLink(context, l.url),
                            onUnfavorite: () =>
                                StorageService.toggleFavorite(l.id),
                          )),
                      if (favLinks.isEmpty)
                        const _EmptyHint(
                          'Favori linkiniz yok.\n'
                          'Kart üzerindeki ★ ile favoriye ekleyin.',
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bölüm başlığı ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.drawerSectionColor, // Figma: mor/indigo ton
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Klasör satırı ────────────────────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  final FolderModel folder;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;
  final VoidCallback onFavoriteTap;

  const _FolderTile({
    required this.folder,
    required this.count,
    required this.onTap,
    required this.onMoreTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            // Klasör ikonu
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            // İsim + adet
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      '${folder.name} ($count)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (folder.password != null && folder.password!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
            // Yıldız butonu
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: Icon(
                  folder.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 18,
                  color: folder.isFavorite
                      ? Colors.amber.shade600
                      : AppColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                onPressed: onFavoriteTap,
              ),
            ),
            // Üç nokta menü
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                onPressed: onMoreTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Favori link satırı ──────────────────────────────────────────────────

class _FavoriteLinkTile extends StatelessWidget {
  final LinkModel link;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  const _FavoriteLinkTile({
    required this.link,
    required this.onTap,
    required this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                link.title?.isNotEmpty == true
                    ? link.title!
                    : _domain(link.url),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                icon: Icon(Icons.more_vert_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                onPressed: () => _showLinkOptions(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            const SizedBox(height: 12),
            Text(
              link.title?.isNotEmpty == true ? link.title! : _domain(link.url),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 20),
            ListTile(
              leading: Icon(Icons.star_border_rounded,
                  color: Colors.amber.shade600),
              title: const Text('Favorilerden kaldır'),
              onTap: () {
                Navigator.pop(ctx);
                onUnfavorite();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _domain(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

// ─── Boş ipucu ────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

// ─── Sürükleme kolu yardımcısı ─────────────────────────────────────────────

Widget _dragHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFDDDDEE),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

// ─── Klasör seçenekleri bottom sheet ──────────────────────────────────────

class _FolderOptionsSheet extends StatelessWidget {
  final FolderModel folder;
  final BuildContext parentContext;

  const _FolderOptionsSheet({
    required this.folder,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          const SizedBox(height: 14),
          Text(
            folder.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Divider(height: 20),

          // Yeniden adlandır
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
            title: const Text('Yeniden adlandır'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(parentContext);
            },
          ),

          // Şifre
          ListTile(
            leading: Icon(
              folder.password != null && folder.password!.isNotEmpty
                  ? Icons.lock_open_rounded
                  : Icons.lock_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              folder.password != null && folder.password!.isNotEmpty
                  ? 'Şifre Yönet'
                  : 'Şifre Koy',
            ),
            onTap: () {
              Navigator.pop(context);
              _showPasswordSetDialog(parentContext);
            },
          ),

          // Sil
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            title: const Text('Klasörü sil',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _showPasswordSetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _PasswordSetDialog(folder: folder),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yeniden adlandır'),
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
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await StorageService.renameFolder(folder.id, name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext sheetContext) async {
    // Şifre varsa — sheet hâlâ açıkken doğrula (sheetContext geçerli)
    if (folder.password != null && folder.password!.isNotEmpty) {
      final unlocked = await showDialog<bool>(
            context: sheetContext,
            barrierDismissible: false,
            builder: (ctx) => PasswordCheckDialog(correct: folder.password!),
          ) ??
          false;
      if (!unlocked) return;
    }

    // Sheet'i kapat
    if (sheetContext.mounted) Navigator.pop(sheetContext);

    // Silme onayını parentContext üzerinden göster (sheet kapandıktan sonra)
    if (!parentContext.mounted) return;
    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Klasörü sil'),
        content: Text(
          '"${folder.name}" silinsin mi?\n'
          'Linkler silinmez, sadece bu klasörden çıkarılır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await StorageService.deleteFolder(folder.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

// ─── Şifre belirleme dialogu ───────────────────────────────────────────────

class _PasswordSetDialog extends StatefulWidget {
  final FolderModel folder;
  const _PasswordSetDialog({required this.folder});

  @override
  State<_PasswordSetDialog> createState() => _PasswordSetDialogState();
}

class _PasswordSetDialogState extends State<_PasswordSetDialog> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool get _hasPassword =>
      widget.folder.password != null && widget.folder.password!.isNotEmpty;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_hasPassword ? 'Şifreyi Değiştir / Kaldır' : 'Şifre Koy'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasPassword)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Boş bırakırsan şifre kaldırılır.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          TextField(
            controller: _ctrl,
            autofocus: true,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'Şifre',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        if (_hasPassword)
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) =>
                        PasswordCheckDialog(correct: widget.folder.password!),
                  ) ??
                  false;
              if (!confirmed || !context.mounted) return;
              await StorageService.setFolderPassword(widget.folder.id, null);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifre kaldırıldı')),
                );
              }
            },
            child: const Text('Şifreyi Kaldır',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ElevatedButton(
          onPressed: () async {
            final pw = _ctrl.text.trim();
            if (pw.isEmpty) return; // boş bırakılırsa "Şifreyi Kaldır" butonu kullanılmalı
            await StorageService.setFolderPassword(widget.folder.id, pw);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Şifre kaydedildi')),
              );
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

// ─── Şifre doğrulama dialogu ───────────────────────────────────────────────

class PasswordCheckDialog extends StatefulWidget {
  final String correct;
  const PasswordCheckDialog({super.key, required this.correct});

  @override
  State<PasswordCheckDialog> createState() => PasswordCheckDialogState();
}

class PasswordCheckDialogState extends State<PasswordCheckDialog> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _wrong = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ctrl.text == widget.correct) {
      Navigator.pop(context, true);
    } else {
      setState(() => _wrong = true);
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Şifre Gerekli'),
        ],
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        obscureText: _obscure,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Şifre',
          errorText: _wrong ? 'Yanlış şifre' : null,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Aç'),
        ),
      ],
    );
  }
}