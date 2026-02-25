import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/link_model.dart';
import '../models/folder_model.dart';

class StorageService {
  static const String _linksBoxName = 'links';
  static const String _foldersBoxName = 'folders';

  static Box<LinkModel>? _box;
  static Box<FolderModel>? _folderBox;

  static Future<void> init() async {
    _box = await Hive.openBox<LinkModel>(_linksBoxName);
    _folderBox = await Hive.openBox<FolderModel>(_foldersBoxName);
  }

  // ─── Kutular ────────────────────────────────────────────────────────────────

  static Box<LinkModel> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('StorageService henüz başlatılmadı. init() çağrın.');
    }
    return _box!;
  }

  static Box<FolderModel> get folderBox {
    if (_folderBox == null || !_folderBox!.isOpen) {
      throw StateError('StorageService henüz başlatılmadı. init() çağrın.');
    }
    return _folderBox!;
  }

  // ─── Linkler ────────────────────────────────────────────────────────────────

  static List<LinkModel> getAll() {
    return box.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  static List<LinkModel> getFavorites() {
    return box.values.where((l) => l.isFavorite).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  static List<LinkModel> getLinksInFolder(String folderName) {
    return box.values
        .where((l) => l.tags.contains(folderName))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  static Future<void> add(LinkModel link) async {
    await box.put(link.id, link);
  }

  static Future<void> delete(String id) async {
    await box.delete(id);
  }

  static Future<void> updateTags(String id, List<String> tags) async {
    final link = box.get(id);
    if (link != null) {
      link.tags = tags;
      await link.save();
    }
  }

  static Future<void> toggleFavorite(String id) async {
    final link = box.get(id);
    if (link != null) {
      link.isFavorite = !link.isFavorite;
      await link.save();
    }
  }

  static Future<void> updateMetadata(
    String id, {
    String? title,
    String? description,
    String? faviconUrl,
  }) async {
    final link = box.get(id);
    if (link != null) {
      if (title != null) link.title = title;
      if (description != null) link.description = description;
      if (faviconUrl != null) link.faviconUrl = faviconUrl;
      await link.save();
    }
  }

  static List<String> getAllTags() {
    final tags = <String>{};
    for (final link in box.values) {
      tags.addAll(link.tags);
    }
    return tags.toList()..sort();
  }

  // ─── Klasörler ──────────────────────────────────────────────────────────────

  static List<FolderModel> getAllFolders() {
    return folderBox.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static List<FolderModel> getFavoriteFolders() {
    return folderBox.values.where((f) => f.isFavorite).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static int getFolderLinkCount(String folderName) {
    return box.values.where((l) => l.tags.contains(folderName)).length;
  }

  /// Yeni klasör oluşturur; aynı isimde varsa mevcut olanı döndürür.
  static Future<FolderModel> addFolder(String name) async {
    final trimmed = name.trim();
    final existing = folderBox.values
        .where((f) => f.name.toLowerCase() == trimmed.toLowerCase())
        .firstOrNull;
    if (existing != null) return existing;

    final folder = FolderModel(
      id: const Uuid().v4(),
      name: trimmed,
      createdAt: DateTime.now(),
    );
    await folderBox.put(folder.id, folder);
    return folder;
  }

  static Future<void> deleteFolder(String id) async {
    final folder = folderBox.get(id);
    if (folder == null) return;
    // Klasörü tüm linklerin tags listesinden kaldır
    for (final link in box.values) {
      if (link.tags.contains(folder.name)) {
        link.tags = List.from(link.tags)..remove(folder.name);
        await link.save();
      }
    }
    await folderBox.delete(id);
  }

  static Future<void> renameFolder(String id, String newName) async {
    final folder = folderBox.get(id);
    if (folder == null) return;
    final oldName = folder.name;
    folder.name = newName.trim();
    await folder.save();
    // Tüm linklerdeki eski klasör adını güncelle
    for (final link in box.values) {
      if (link.tags.contains(oldName)) {
        final newTags = List<String>.from(link.tags)
          ..remove(oldName)
          ..add(folder.name);
        link.tags = newTags;
        await link.save();
      }
    }
  }

  static Future<void> toggleFolderFavorite(String id) async {
    final folder = folderBox.get(id);
    if (folder != null) {
      folder.isFavorite = !folder.isFavorite;
      await folder.save();
    }
  }
}