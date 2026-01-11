import 'package:flutter/material.dart';

import '../theme.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'roommates_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int idx;

  @override
  void initState() {
    super.initState();
    idx = widget.initialIndex.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const RoommatesScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: pages[idx]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: idx,
          backgroundColor: Colors.transparent,
          onDestinationSelected: (i) => setState(() => idx = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _NavDestination(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'HOME',
              selected: idx == 0,
            ),
            _NavDestination(
              icon: Icons.apartment_outlined,
              selectedIcon: Icons.apartment,
              label: 'SPACES',
              selected: idx == 1,
            ),
            _NavDestination(
              icon: Icons.inbox_outlined,
              selectedIcon: Icons.inbox,
              label: 'REQUESTS',
              selected: idx == 2,
            ),
            _NavDestination(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'PROFILE',
              selected: idx == 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primary : AppTheme.textMuted;
    return NavigationDestination(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          if (selected)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
      selectedIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selectedIcon, color: color),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
      label: label,
    );
  }
}
