import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent google_fonts from hitting fonts.gstatic.com at runtime.
  // The study runs in a controlled lab environment that may have no internet.
  // Fonts fall back to system Roboto until TTF files are bundled in assets/fonts/.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lock to portrait — HRV waveforms and the sync ring are designed for
  // a tall viewport; landscape breaks the calibration breathing layout (§3.4).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // ProviderScope at the top so every ConsumerWidget in the tree can read
    // the same provider container — important for the auth redirect in GoRouter
    // which reads providers synchronously during route resolution.
    const ProviderScope(child: SyncTeamApp()),
  );
}

class SyncTeamApp extends ConsumerWidget {
  const SyncTeamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SyncTeam',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: router,
    );
  }
}
