import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled in assets/google_fonts.
  GoogleFonts.config.allowRuntimeFetching = false;
  _registerFontLicenses();

  // Firebase itself is initialized by `firebaseInitProvider`, so the splash
  // screen can show progress and errors instead of a blank launch screen.
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromEnvironment()),
      ],
      child: const PennywiseApp(),
    ),
  );
}

void _registerFontLicenses() {
  const fonts = {
    'DM Sans': 'assets/licenses/OFL-DMSans.txt',
    'Bricolage Grotesque': 'assets/licenses/OFL-BricolageGrotesque.txt',
  };
  for (final MapEntry(key: name, value: path) in fonts.entries) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(path));
    });
  }
}
