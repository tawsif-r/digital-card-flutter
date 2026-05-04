import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DigitalCardApp()));
}

class DigitalCardApp extends ConsumerStatefulWidget {
  const DigitalCardApp({super.key});

  @override
  ConsumerState<DigitalCardApp> createState() => _DigitalCardAppState();
}

class _DigitalCardAppState extends ConsumerState<DigitalCardApp> {
  @override
  void initState() {
    super.initState();
    ref.read(themeProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
