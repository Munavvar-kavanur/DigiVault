import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/modern_navbar.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'category_screen.dart';
import 'settings_screen.dart';
import 'add_edit_password_screen.dart';
import '../widgets/animated_neon_background.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const SizedBox(), // Placeholder for Add button
    const CategoryScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // "Add" button tapped
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddEditPasswordScreen(),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedNeonBackground(
        currentIndex: _currentIndex,
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: ModernNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          NavBarItem(icon: LucideIcons.home, label: 'Home'),
          NavBarItem(icon: LucideIcons.search, label: 'Search'),
          NavBarItem(icon: LucideIcons.plus, label: 'Add'),
          NavBarItem(icon: LucideIcons.folder, label: 'Category'),
          NavBarItem(icon: LucideIcons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
