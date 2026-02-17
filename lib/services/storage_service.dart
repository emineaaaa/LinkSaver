import 'package:hive_flutter/hive_flutter.dart';
import '../models/link_model.dart';

class StorageService {
  static const String _boxName = 'links';
  static Box<LinkModel>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<LinkModel>(_boxName);
  }

  static Box<LinkModel> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _box!;
  }

  static List<LinkModel> getAll() {
    return box.values.toList()
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
}
