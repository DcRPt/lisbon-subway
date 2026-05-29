import 'package:cmproject/data/app_colors.dart';
import 'package:flutter/material.dart';
import 'pages.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_selectedIndex].widget,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        // transparent indicator removes the default pill shape
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(
          AppColors.kNavyBlue.withValues(alpha: 0.06),
        ),
        destinations: screens.asMap().entries.map((e) {
          return NavigationDestination(
            key: e.value.navKey,
            icon:         Icon(e.value.icon,
                color: AppColors.kGrey,
                size: 24),
            selectedIcon: Icon(e.value.icon,
                color: AppColors.kNavyBlue,
                size: 24),
            label: e.value.title,
          );
        }).toList(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}