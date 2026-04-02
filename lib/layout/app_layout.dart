import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';

class AppLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;
    
    return Scaffold(
      backgroundColor: isMobile ? AppColors.bg : const Color(0xFFE5E5EA),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            constraints: isMobile ? const BoxConstraints.expand() : const BoxConstraints(maxWidth: 390),
            decoration: isMobile 
              ? null
              : const BoxDecoration(
                  color: AppColors.bg,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
            child: Column(
              children: [
                // Main content area - takes remaining space
                Expanded(
                  child: navigationShell,
                ),
                // Bottom Navigation Bar
                _buildBottomNavBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomSpacing = bottomInset > 0 ? 10.0 : 8.0;

    return Stack(
      children: [
        // Background container extending to safe area
        Positioned.fill(
          child: Container(
            color: AppColors.bg,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 12, bottomSpacing),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.80),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(context, 0, LucideIcons.house, 'Início'),
                      _buildNavItem(context, 1, LucideIcons.receipt, 'Gastos'),
                      _buildNavItem(context, 2, LucideIcons.wrench, 'Serviço'),
                      _buildNavItem(context, 3, LucideIcons.bell, 'Alertas'),
                      _buildNavItem(context, 4, LucideIcons.user, 'Perfil'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isActive = navigationShell.currentIndex == index;

    return GestureDetector(
      onTap: () => navigationShell.goBranch(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 12 : 6,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isActive ? 20 : 18,
              color: isActive
                  ? AppColors.primary
                  : const Color(0xFFA0A0A0),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : const Color(0xFF888888),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
