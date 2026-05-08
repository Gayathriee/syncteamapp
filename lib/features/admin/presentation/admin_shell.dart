import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'admin_home_screen.dart';
import 'admin_live_list_screen.dart';
import 'admin_participants_screen.dart';
import 'admin_tasks_screen.dart';

/// Riverpod state for the currently selected admin tab.
/// Screens inside the shell (e.g. AdminHomeScreen) can read this provider
/// to switch tabs programmatically without needing a navigation callback.
final adminTabIndexProvider = StateProvider<int>((ref) => 0);

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell>
    with TickerProviderStateMixin {
  final _pages = const [
    AdminHomeScreen(),
    AdminLiveListScreen(),
    AdminTasksScreen(),
    AdminParticipantsScreen(),
  ];

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    ref.read(adminTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(adminTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AdminNavItem(
                  icon: Icons.home_rounded,
                  label: 'overview',
                  selected: currentIndex == 0,
                  color: AppColors.coral,
                  onTap: () => _onTabTapped(0),
                ),
                _AdminNavItem(
                  icon: Icons.sensors_rounded,
                  label: 'live',
                  selected: currentIndex == 1,
                  color: AppColors.teal,
                  onTap: () => _onTabTapped(1),
                ),
                _AdminNavItem(
                  icon: Icons.task_alt_rounded,
                  label: 'tasks',
                  selected: currentIndex == 2,
                  color: AppColors.mustard,
                  onTap: () => _onTabTapped(2),
                ),
                _AdminNavItem(
                  icon: Icons.people_rounded,
                  label: 'participants',
                  selected: currentIndex == 3,
                  color: AppColors.lavender,
                  onTap: () => _onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: selected ? color : AppColors.warm,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? color : AppColors.warm,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
