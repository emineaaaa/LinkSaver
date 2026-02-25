import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../models/link_model.dart';
import '../models/folder_model.dart';
import '../services/storage_service.dart';
import '../services/metadata_service.dart';
import 'logo_widget.dart';

/// Figma Anasayfa-Save ekranına birebir sadık "Link Kaydetme" bottom sheet'i.
/// Sahne:
///   • Sürükleme kolu
///   • Logo merkez
///   • [Klasör seçin ▼]  ← tıklanınca klasör listesi açılır
///   • (klasör açıksa) Klasör listesi + "✚ Yeni klasör oluştur" satırı
///   • (yeni klasör modundaysa) Giriş + Kaydet kartı
///   • Link başlığı alanı
///   • Linkinizi buraya yapıştırın alanı
///   • [✓ Kaydet] düğmesi
class SaveLinkBottomSheet extends StatefulWidget {
  final String? initialUrl;

  const SaveLinkBottomSheet({super.key, this.initialUrl});

  static Future<void> show(BuildContext context, {String? initialUrl}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SaveLinkBottomSheet(initialUrl: initialUrl),
    );
  }

  @override
  State<SaveLinkBottomSheet> createState() => _SaveLinkBottomSheetState();
}

class _SaveLinkBottomSheetState extends State<SaveLinkBottomSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _newFolderController = TextEditingController();
  final _uuid = const Uuid();

  bool _showFolderDropdown = false;
  bool _showNewFolderInput = false;
  bool _isSaving = false;

  // Seçili klasör adları (çoklu seçim)
  final Set<String> _selectedFolders = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _newFolderController.dispose();
    super.dispose();
  }

  // ─── İşlemler ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isSaving = true);

    final link = LinkModel(
      id: _uuid.v4(),
      url: url,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      savedAt: DateTime.now(),
      tags: _selectedFolders.toList(),
    );

    await StorageService.add(link);

    // Seçilen klasörleri kayıt et (yoksa oluştur)
    for (final name in _selectedFolders) {
      await StorageService.addFolder(name);
    }

    if (mounted) Navigator.pop(context);

    // Arka planda metadata çek
    MetadataService.fetch(url).then((meta) async {
      await StorageService.updateMetadata(
        link.id,
        title: link.title == null ? meta['title'] : null,
        description: meta['description'],
        faviconUrl: meta['favicon'],
      );
    });
  }

  Future<void> _createNewFolder() async {
    final name = _newFolderController.text.trim();
    if (name.isEmpty) return;

    final folder = await StorageService.addFolder(name);
    setState(() {
      _selectedFolders.add(folder.name);
      _newFolderController.clear();
      _showNewFolderInput = false;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() => _urlController.text = data.text!);
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final folders = StorageService.getAllFolders();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sürükleme kolu ───────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDEE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Logo merkez ──────────────────────────────────────────────
          const Center(child: LinkSaverLogo(size: 36)),
          const SizedBox(height: 18),

          // ── Klasör seçici ────────────────────────────────────────────
          _FolderSelector(
            selectedFolders: _selectedFolders,
            isOpen: _showFolderDropdown,
            onToggle: () => setState(() {
              _showFolderDropdown = !_showFolderDropdown;
              if (!_showFolderDropdown) _showNewFolderInput = false;
            }),
          ),

          // ── Klasör açılır listesi ─────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _showFolderDropdown
                ? _FolderDropdownList(
                    folders: folders,
                    selectedFolders: _selectedFolders,
                    showNewFolderInput: _showNewFolderInput,
                    newFolderController: _newFolderController,
                    onToggleFolder: (name) => setState(() {
                      if (_selectedFolders.contains(name)) {
                        _selectedFolders.remove(name);
                      } else {
                        _selectedFolders.add(name);
                      }
                    }),
                    onNewFolderTap: () => setState(
                        () => _showNewFolderInput = !_showNewFolderInput),
                    onNewFolderSave: _createNewFolder,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          // ── Link başlığı ──────────────────────────────────────────────
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Link başlığı...',
              prefixIcon: Icon(
                Icons.title_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── URL alanı ─────────────────────────────────────────────────
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Linkinizi buraya yapıştırın...',
              prefixIcon: const Icon(
                Icons.link_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.content_paste_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: _pasteFromClipboard,
                tooltip: 'Panodan yapıştır',
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Kaydet düğmesi ────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Klasör seçici butonu ──────────────────────────────────────────────────

class _FolderSelector extends StatelessWidget {
  final Set<String> selectedFolders;
  final bool isOpen;
  final VoidCallback onToggle;

  const _FolderSelector({
    required this.selectedFolders,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final label = selectedFolders.isEmpty
        ? 'Klasör seçin...'
        : selectedFolders.join(', ');

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.searchFill,
          borderRadius: BorderRadius.circular(14),
          border: isOpen
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.folder_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedFolders.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: selectedFolders.isEmpty
                      ? FontWeight.w400
                      : FontWeight.w500,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Açılır klasör listesi ────────────────────────────────────────────────

class _FolderDropdownList extends StatelessWidget {
  final List<FolderModel> folders;
  final Set<String> selectedFolders;
  final bool showNewFolderInput;
  final TextEditingController newFolderController;
  final void Function(String) onToggleFolder;
  final VoidCallback onNewFolderTap;
  final VoidCallback onNewFolderSave;

  const _FolderDropdownList({
    required this.folders,
    required this.selectedFolders,
    required this.showNewFolderInput,
    required this.newFolderController,
    required this.onToggleFolder,
    required this.onNewFolderTap,
    required this.onNewFolderSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mevcut klasörler listesi
          ...folders.map((folder) {
            final selected = selectedFolders.contains(folder.name);
            return _FolderCheckItem(
              name: folder.name,
              selected: selected,
              onTap: () => onToggleFolder(folder.name),
            );
          }),

          // Yeni klasör oluşturma inputu
          if (showNewFolderInput) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: newFolderController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Yeni klasör ismi girin...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => onNewFolderSave(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onNewFolderSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Yeni klasör oluştur butonu
          const Divider(height: 1),
          InkWell(
            onTap: onNewFolderTap,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '+ Yeni klasör oluştur',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Klasör onay kutusu satırı ────────────────────────────────────────────

class _FolderCheckItem extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _FolderCheckItem({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // "A" avatar (Figma'daki klasör baş harfi)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.searchFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Onay kutusu ikonu
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}