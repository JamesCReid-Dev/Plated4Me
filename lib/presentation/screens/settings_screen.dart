/// Settings screen — user preferences and app configuration.
/// P4ME-25: Replaces ProfileScreen as the third bottom nav tab.
import 'package:flutter/material.dart';

/// Placeholder for Settings screen (P4ME-25).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Settings')),
      );
}
