import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/language_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Durum çubuğu şeffaf
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A1128),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Servisleri başlat
  final storage = StorageService();
  await storage.init();

  final lang = LanguageService(storage);

  runApp(DayTrackApp(storage: storage, lang: lang));
}

class DayTrackApp extends StatefulWidget {
  final StorageService storage;
  final LanguageService lang;

  const DayTrackApp({
    super.key,
    required this.storage,
    required this.lang,
  });

  @override
  State<DayTrackApp> createState() => _DayTrackAppState();
}

class _DayTrackAppState extends State<DayTrackApp> {
  @override
  void initState() {
    super.initState();
    // Dil değişiminde rebuild
    widget.lang.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    widget.lang.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DayTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomePage(
        storage: widget.storage,
        lang: widget.lang,
      ),
    );
  }
}
