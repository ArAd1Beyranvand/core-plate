import 'package:flutter/material.dart';

import 'src/screens/about_screen.dart';
import 'src/screens/catalogue_screen.dart';
import 'src/screens/playground_screen.dart';
import 'src/sources/sources.dart';

void main() => runApp(const GalleryApp());

/// Every plate every country package in this repo can draw, in one app.
class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'plate_gallery',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0F7A3D)),
    darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0F7A3D), brightness: Brightness.dark),
    home: const _GalleryShell(),
  );
}

class _GalleryShell extends StatefulWidget {
  const _GalleryShell();

  @override
  State<_GalleryShell> createState() => _GalleryShellState();
}

class _GalleryShellState extends State<_GalleryShell> {
  int _screen = 0;

  /// The plate the playground is editing. Held here rather than inside that
  /// screen so a card tapped on the catalogue can set it and switch tabs.
  GalleryEntry _entry = gallerySources.first.entries.first;

  void _open(GalleryEntry entry) => setState(() {
    _entry = entry;
    _screen = 1;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('plate_gallery'), centerTitle: false),
    body: SafeArea(
      // IndexedStack, not a swap: the playground owns a PlateController and a
      // half-typed plate should still be there when you come back from the
      // catalogue.
      child: IndexedStack(
        index: _screen,
        children: <Widget>[
          CatalogueScreen(onOpen: _open),
          PlaygroundScreen(entry: _entry, onEntryChanged: (GalleryEntry entry) => setState(() => _entry = entry)),
          const AboutScreen(),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _screen,
      onDestinationSelected: (int index) => setState(() => _screen = index),
      destinations: const <Widget>[
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view),
          label: 'Catalogue',
        ),
        NavigationDestination(icon: Icon(Icons.edit_outlined), selectedIcon: Icon(Icons.edit), label: 'Playground'),
        NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'About'),
      ],
    ),
  );
}
