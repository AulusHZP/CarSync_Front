import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/modern_dropdown.dart';

/// Demo screen showcasing the ModernDropdown component
/// This demonstrates best practices and multiple use cases
class ModernDropdownDemo extends StatefulWidget {
  const ModernDropdownDemo({super.key});

  @override
  State<ModernDropdownDemo> createState() => _ModernDropdownDemoState();
}

class _ModernDropdownDemoState extends State<ModernDropdownDemo> {
  // Example 1: Expense categories (used in AddExpenseScreen)
  late final List<ModernDropdownItem> expenseCategories = [
    ModernDropdownItem(
      label: 'Combustível',
      value: 'Combustível',
      icon: LucideIcons.droplets,
    ),
    ModernDropdownItem(
      label: 'Manutenção',
      value: 'Manutenção',
      icon: LucideIcons.wrench,
    ),
    ModernDropdownItem(
      label: 'Seguro',
      value: 'Seguro',
      icon: LucideIcons.shield,
    ),
    ModernDropdownItem(
      label: 'Lava-rápido',
      value: 'Lava-rápido',
      icon: LucideIcons.sun,
    ),
    ModernDropdownItem(
      label: 'Estacionamento',
      value: 'Estacionamento',
      icon: LucideIcons.squareParking,
    ),
    ModernDropdownItem(
      label: 'Pedágio',
      value: 'Pedágio',
      icon: LucideIcons.ticketSlash,
    ),
    ModernDropdownItem(
      label: 'Outro',
      value: 'Outro',
      icon: LucideIcons.ellipsis,
    ),
  ];

  // Example 2: Vehicle types
  late final List<ModernDropdownItem> vehicleTypes = [
    ModernDropdownItem(
      label: 'Sedan',
      value: 'sedan',
      icon: LucideIcons.car,
    ),
    ModernDropdownItem(
      label: 'SUV',
      value: 'suv',
      icon: LucideIcons.car,
    ),
    ModernDropdownItem(
      label: 'Hatchback',
      value: 'hatchback',
      icon: LucideIcons.car,
    ),
    ModernDropdownItem(
      label: 'Pickup',
      value: 'pickup',
      icon: LucideIcons.truck,
    ),
  ];

  // Example 3: Maintenance types
  late final List<ModernDropdownItem> maintenanceTypes = [
    ModernDropdownItem(
      label: 'Óleo',
      value: 'oil',
      icon: LucideIcons.droplet,
    ),
    ModernDropdownItem(
      label: 'Pneus',
      value: 'tires',
      icon: LucideIcons.circle,
    ),
    ModernDropdownItem(
      label: 'Freios',
      value: 'brakes',
      icon: LucideIcons.square,
    ),
    ModernDropdownItem(
      label: 'Bateria',
      value: 'battery',
      icon: LucideIcons.zap,
    ),
    ModernDropdownItem(
      label: 'Filtro',
      value: 'filter',
      icon: LucideIcons.settings,
    ),
  ];

  String? selectedExpenseCategory;
  String? selectedVehicleType;
  String? selectedMaintenanceType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: AppColors.card,
            floating: true,
            pinned: true,
            elevation: 0,
            title: Text(
              'ModernDropdown Demo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Expense Categories Demo
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Categories',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Example of dropdown with expense icons',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ModernDropdown(
                        selectedValue: selectedExpenseCategory,
                        items: expenseCategories,
                        hint: 'Selecione uma categoria',
                        label: 'Categoria de Gasto',
                        onChanged: (value) {
                          setState(() {
                            selectedExpenseCategory = value;
                          });
                        },
                      ),
                      if (selectedExpenseCategory != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.check,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Selecionado: $selectedExpenseCategory',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Vehicle Types Demo
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Types',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Example with vehicle options',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ModernDropdown(
                        selectedValue: selectedVehicleType,
                        items: vehicleTypes,
                        hint: 'Selecione um tipo de veículo',
                        label: 'Tipo de Veículo',
                        onChanged: (value) {
                          setState(() {
                            selectedVehicleType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Maintenance Types Demo
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maintenance Types',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Example with maintenance options',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ModernDropdown(
                        selectedValue: selectedMaintenanceType,
                        items: maintenanceTypes,
                        hint: 'Selecione um tipo de manutenção',
                        label: 'Tipo de Manutenção',
                        onChanged: (value) {
                          setState(() {
                            selectedMaintenanceType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Design Features
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Key Design Features',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        '✨ Modern Modal Design',
                        'Uses showModalBottomSheet for a premium feel',
                      ),
                      _buildFeatureItem(
                        '🎨 Custom Styling',
                        'Soft shadows, rounded corners, subtle colors',
                      ),
                      _buildFeatureItem(
                        '⚡ Smooth Animations',
                        'Entry/exit animations with Tween & CurvedAnimation',
                      ),
                      _buildFeatureItem(
                        '✅ Selected Checkmark',
                        'Visual confirmation with icon in modal',
                      ),
                      _buildFeatureItem(
                        '🎯 Icons for Items',
                        'Each item has a relevant icon for quick identification',
                      ),
                      _buildFeatureItem(
                        '📱 Mobile Optimized',
                        'Perfect spacing and tap targets for mobile devices',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
