import 'package:flutter/material.dart';
import 'package:plate_number/showcase/theme/poster_tokens.dart';

import '../screens/showcase_screen.dart';

class PlateNumberShowcaseApp extends StatelessWidget {
  const PlateNumberShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plate Number Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: PosterTokens.accent,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: PosterTokens.bg,
        useMaterial3: true,
      ),
      home: const ShowcaseScreen(),
    );
  }
}
