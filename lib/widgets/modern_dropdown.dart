import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';

/// Model for dropdown item with icon support
class ModernDropdownItem {
  final String label;
  final String value;
  final IconData icon;

  const ModernDropdownItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// Modern, premium dropdown component with modal bottom sheet
/// Inspired by Apple and Tesla design systems
class ModernDropdown extends StatefulWidget {
  final String? selectedValue;
  final List<ModernDropdownItem> items;
  final Function(String value) onChanged;
  final String hint;
  final String label;
  final bool isExpanded;

  const ModernDropdown({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    required this.hint,
    required this.label,
    this.isExpanded = true,
  });

  @override
  State<ModernDropdown> createState() => _ModernDropdownState();
}

class _ModernDropdownState extends State<ModernDropdown> {
  /// Get selected item label for display
  String get selectedLabel {
    final selected = widget.items.firstWhere(
      (item) => item.value == widget.selectedValue,
      orElse: () => ModernDropdownItem(
        label: widget.hint,
        value: '',
        icon: LucideIcons.square,
      ),
    );
    return selected.label;
  }

  /// Get selected item icon for display
  IconData get selectedIcon {
    final selected = widget.items.firstWhere(
      (item) => item.value == widget.selectedValue,
      orElse: () => ModernDropdownItem(
        label: widget.hint,
        value: '',
        icon: LucideIcons.square,
      ),
    );
    return selected.icon;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Dropdown trigger
        GestureDetector(
          onTap: () => _showDropdownModal(context),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.selectedValue != null
                      ? AppColors.accent.withOpacity(0.3)
                      : AppColors.separator,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Selected icon
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: widget.selectedValue != null
                        ? Icon(
                            selectedIcon,
                            size: 18,
                            color: AppColors.accent,
                            key: ValueKey(selectedIcon),
                          )
                        : Icon(
                            LucideIcons.chevronDown,
                            size: 18,
                            color: AppColors.tertiary,
                            key: const ValueKey('default_icon'),
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Selected text
                  Expanded(
                    child: Text(
                      widget.selectedValue != null
                          ? selectedLabel
                          : widget.hint,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.selectedValue != null
                            ? AppColors.primary
                            : AppColors.tertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Chevron icon
                  Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: widget.selectedValue != null
                        ? AppColors.accent
                        : AppColors.tertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show modern modal bottom sheet with items
  Future<void> _showDropdownModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.primary.withOpacity(0.3),
      elevation: 0,
      builder: (context) => _buildModalContent(context),
    );
  }

  /// Build modal content with modern design
  Widget _buildModalContent(BuildContext context) {
    return AnimatedBuilder(
      animation: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1),
          curve: Curves.easeOut,
        ),
      ),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - (ModalRoute.of(context)?.animation?.value ?? 1))),
          child: Opacity(
            opacity: ModalRoute.of(context)?.animation?.value ?? 1,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              color: AppColors.separator,
              thickness: 0.5,
              height: 1,
            ),

            // Items list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.items.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = item.value == widget.selectedValue;

                  return _buildItemTile(
                    context,
                    item,
                    isSelected,
                    index == widget.items.length - 1,
                  );
                },
              ),
            ),

            // Safe area bottom
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual dropdown item tile with animation
  Widget _buildItemTile(
    BuildContext context,
    ModernDropdownItem item,
    bool isSelected,
    bool isLast,
  ) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(item.value);
        Navigator.pop(context);
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Item icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.1)
                          : AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 18,
                      color: isSelected ? AppColors.accent : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Item label
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                  ),

                  // Selected checkmark
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 16,
                        color: AppColors.card,
                      ),
                    )
                  else
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.separator,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
            ),
            // Divider
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: AppColors.separator,
                  thickness: 0.5,
                  height: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
