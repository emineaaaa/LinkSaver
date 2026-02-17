import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
import 'models/link_model.dart';
import 'services/storage_service.dart';
import 'services/metadata_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LinkModelAdapter());
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _listenForSharedLinks();
  }

  void _listenForSharedLinks() {
    // Uygulama açıkken paylaşılan linkler
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _handleShared(files),
      onError: (_) {},
    );

    // Uygulama kapalıyken paylaşılan link ile açıldığında
    ReceiveSharingIntent.instance.getInitialMedia().then(
      (files) {
        _handleShared(files);
        ReceiveSharingIntent.instance.reset();
      },
    );
  }

  Future<void> _handleShared(List<SharedMediaFile> files) async {
    for (final file in files) {
      final text = file.path;
      if (text.isEmpty) continue;

      // URL içeren metni bul
      final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);
      final match = urlRegex.firstMatch(text);
      final url = match?.group(0) ?? text;

      // Önce kaydet, sonra metadata çek
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Link Saver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
