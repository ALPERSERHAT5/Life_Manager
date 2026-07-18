import 'package:flutter/material.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/tasks/tasks_screen.dart';
import '../../screens/finance/finance_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../widgets/main_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    TasksScreen(),
    FinanceScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
