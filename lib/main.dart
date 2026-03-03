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
  static final sharedUrlNotifier = ValueNotifier<String?>(null);

  /// Dark / Light mod geçişi için global notifier.
  static final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  @override
  State<LinkSaverApp> createState() => _LinkSaverAppState();
}

class _LinkSaverAppState extends State<LinkSaverApp> {
  @override
  void initState() {
    super.initState();
    // Kayıtlı tema tercihini yükle
    final saved = StorageService.settingsBox
        .get('themeMode', defaultValue: 'light') as String;
    LinkSaverApp.themeNotifier.value =
        saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    LinkSaverApp.themeNotifier.addListener(_saveTheme);
    _listenForSharedLinks();
  }

  @override
  void dispose() {
    LinkSaverApp.themeNotifier.removeListener(_saveTheme);
    super.dispose();
  }

  void _saveTheme() {
    final isDark = LinkSaverApp.themeNotifier.value == ThemeMode.dark;
    StorageService.settingsBox.put('themeMode', isDark ? 'dark' : 'light');
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: LinkSaverApp.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'LinkSaver',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
