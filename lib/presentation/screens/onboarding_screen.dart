/// Onboarding screen — first-run setup gate (P4ME-25).
/// Shown only when UserPreferences.onboardingComplete == false.
import 'package:flutter/material.dart';

/// Placeholder for Onboarding screen (P4ME-25).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Onboarding')),
        body: const Center(child: Text('Onboarding')),
      );
}
