/// App router — manages top-level navigation and route guards.
import 'package:flutter/material.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    PlaceholderPage(label: 'Home'),
    PlaceholderPage(label: 'Browse'),
    PlaceholderPage(label: 'Favorites'),
    PlaceholderPage(label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Browse'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String label;
  const PlaceholderPage({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      '$label — Coming in Sprint 2+',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  );
}
