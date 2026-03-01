import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'core/theme/app_theme.dart';
import 'models/link_model.dart';
import 'models/folder_model.dart';
import 'services/storage_service.dart';
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

  /// HomeScreen'in dinleyeceği URL bildirimi.
  /// null → bekleyen URL yok.  String → bottom sheet açılacak.
  static final sharedUrlNotifier = ValueNotifier<String?>(null);

  @override
  State<LinkSaverApp> createState() => _LinkSaverAppState();
}

class _LinkSaverAppState extends State<LinkSaverApp> {
  @override
  void initState() {
    super.initState();
    _listenForSharedLinks();
  }

  // ─── Başka uygulamalardan gelen paylaşılan linkler ─────────────────────────

  void _listenForSharedLinks() {
    // Uygulama açıkken gelen paylaşım
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _notifyShared(files),
      onError: (_) {},
    );

    // Uygulama kapalıyken gelen paylaşım ile açılma
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _notifyShared(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _notifyShared(List<SharedMediaFile> files) {
    for (final file in files) {
      final text = file.path;
      if (text.isEmpty) continue;

      final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
      final match = urlRegex.firstMatch(text);
      final url = match?.group(0) ?? text;
      if (url.isEmpty) continue;

      // HomeScreen'e bildir — bottom sheet URL ile açılacak
      LinkSaverApp.sharedUrlNotifier.value = url;
      break; // ilk URL yeterli
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
