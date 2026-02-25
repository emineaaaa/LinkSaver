import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import 'core/theme/app_theme.dart';
import 'models/link_model.dart';
import 'models/folder_model.dart';
import 'services/storage_service.dart';
import 'services/metadata_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LinkModelAdapter());
  Hive.registerAdapter(FolderModelAdapter());
  await StorageService.init();
  runApp(const LinkSaverApp());
}

class LinkSaverApp extends StatefulWidget {
  const LinkSaverApp({super.key});

  @override
  State<LinkSaverApp> createState() => _LinkSaverAppState();
}

class _LinkSaverAppState extends State<LinkSaverApp> {
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _listenForSharedLinks();
  }

  // ─── Başka uygulamalardan gelen paylaşılan linkler ─────────────────────────

  void _listenForSharedLinks() {
    // Uygulama açıkken gelen paylaşım
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _handleShared(files),
      onError: (_) {},
    );

    // Uygulama kapalıyken gelen paylaşım ile açılma
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handleShared(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> _handleShared(List<SharedMediaFile> files) async {
    for (final file in files) {
      final text = file.path;
      if (text.isEmpty) continue;

      final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
      final match = urlRegex.firstMatch(text);
      final url = match?.group(0) ?? text;

      final link = LinkModel(
        id: _uuid.v4(),
        url: url,
        savedAt: DateTime.now(),
      );
      await StorageService.add(link);

      // Arka planda metadata çek ve güncelle
      MetadataService.fetch(url).then((meta) async {
        await StorageService.updateMetadata(
          link.id,
          title: meta['title'],
          description: meta['description'],
          faviconUrl: meta['favicon'],
        );
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkSaver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}