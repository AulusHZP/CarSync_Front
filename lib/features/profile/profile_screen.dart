import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../features/profile/add_car_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/add_car_button.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/dark_card.dart';
import '../../services/auth_session.dart';
import '../../services/vehicle_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Conta nova';
  String _userEmail = 'Nenhum email carregado';
  List<CarProfile> _cars = const <CarProfile>[];

  CarProfile _currentCar = const CarProfile(
    model: 'Sem carro cadastrado',
    year: '--',
    totalKm: '--',
    plate: '--',
  );

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
    _loadSavedCar();
  }

  Future<void> _loadSavedProfile() async {
    final saved = await UserProfileService.getProfile();
    if (!mounted) {
      return;
    }

    if (saved == null) {
      setState(() {
        _userName = 'Conta nova';
        _userEmail = 'Nenhum email carregado';
      });
      return;
    }

    setState(() {
      _userName = saved.name;
      _userEmail = saved.email;
    });
  }

  Future<void> _loadSavedCar() async {
    final saved = await VehicleProfileService.getProfile();
    final allCars = await VehicleProfileService.listProfiles();
    if (!mounted) {
      return;
    }

    if (saved == null) {
      setState(() {
        _cars = const <CarProfile>[];
        _currentCar = const CarProfile(
          model: 'Sem carro cadastrado',
          year: '--',
          totalKm: '--',
          plate: '--',
        );
      });
      return;
    }

    final mappedCars = allCars
        .map(
          (car) => CarProfile(
            model: car.model,
            year: car.year,
            totalKm: VehicleProfileService.formatKm(car.totalKm),
            plate: car.plate,
          ),
        )
        .toList();

    setState(() {
      _cars = mappedCars;
      _currentCar = CarProfile(
        model: saved.model,
        year: saved.year,
        totalKm: VehicleProfileService.formatKm(saved.totalKm),
        plate: saved.plate,
      );
    });
  }

  Future<void> _openAddCar() async {
    final newCar = await Navigator.push<CarProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCarScreen(),
      ),
    );

    if (!mounted || newCar == null) {
      return;
    }

    await _loadSavedCar();

    if (!mounted) {
      return;
    }

    AppFeedback.show(
      context,
      message: 'Carro atualizado com sucesso.',
      tone: AppFeedbackTone.success,
    );
  }

  Future<void> _openSwitchVehicle() async {
    if (_cars.length <= 1) {
      return;
    }

    final selectedPlate = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x16000000),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Trocar veículo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              ..._cars.map((car) {
                final isCurrent = car.plate == _currentCar.plate;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(sheetContext).pop(car.plate),
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0x0A000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.car,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    car.model,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  subtitle: Text(
                    car.plate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(
                          LucideIcons.circleCheck,
                          size: 16,
                          color: AppColors.accent,
                        )
                      : const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: AppColors.quarter,
                        ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selectedPlate == null || selectedPlate == _currentCar.plate) {
      return;
    }

    final switched =
        await VehicleProfileService.setActiveProfileByPlate(selectedPlate);
    if (!switched) {
      return;
    }

    await _loadSavedCar();
    if (!mounted) {
      return;
    }

    AppFeedback.show(
      context,
      message: 'Veículo alterado com sucesso.',
      tone: AppFeedbackTone.success,
    );
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<UserProfileData>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _userName,
          initialEmail: _userEmail,
        ),
      ),
    );

    if (!mounted || updated == null) {
      return;
    }

    setState(() {
      _userName = updated.name;
      _userEmail = updated.email;
    });

    AppFeedback.show(
      context,
      message: 'Perfil atualizado com sucesso.',
      tone: AppFeedbackTone.success,
    );
  }

  String _initialsFromName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) {
      return 'JD';
    }
    if (parts.length == 1) {
      final first = parts.first;
      return first.length >= 2
          ? first.substring(0, 2).toUpperCase()
          : first.toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _switchAccount() async {
    await AuthSession.instance.logout();

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final carDetails = [
      {'label': 'Marca e modelo', 'value': _currentCar.model},
      {'label': 'Ano', 'value': _currentCar.year},
      {'label': 'KM total', 'value': _currentCar.totalKm},
      {'label': 'Placa', 'value': _currentCar.plate},
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSavedProfile();
          await _loadSavedCar();
        },
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gerencie sua conta',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text('Perfil',
                      style: Theme.of(context).textTheme.displayLarge),
                ],
              ),
              const SizedBox(height: 24),

              // User Hero Card
              DarkCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _initialsFromName(_userName),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _userEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xB3FFFFFF)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _openEditProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0x17FFFFFF),
                        foregroundColor: Colors.white.withValues(alpha: 0.85),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: Color(0x1AFFFFFF), width: 0.5),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Editar perfil',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // My Car Section
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 12),
                child: Text('MEU CARRO', style: AppTheme.sectionLabelStyle),
              ),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0x0A000000),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(LucideIcons.car,
                                size: 15, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _currentCar.model,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                letterSpacing: -0.2),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0.5, indent: 20, endIndent: 20),
                    ...carDetails.asMap().entries.map((entry) {
                      final index = entry.key;
                      final d = entry.value;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(d['label']!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.secondary)),
                                Text(d['value']!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                        letterSpacing: -0.1)),
                              ],
                            ),
                          ),
                          if (index < carDetails.length - 1)
                            const Divider(
                                height: 0.5,
                                indent: 20,
                                endIndent: 20,
                                color: Color(0x0F3C3C43)),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AddCarButton(
                onTap: _openAddCar,
              ),
              if (_cars.length > 1) ...[
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _openSwitchVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.refreshCw, size: 15),
                      SizedBox(width: 8),
                      Text(
                        'Trocar veículo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _switchAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.user, size: 15),
                    SizedBox(width: 8),
                    Text(
                      'Trocar conta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Log Out Button
              ElevatedButton(
                onPressed: () async {
                  final confirmed = await AppFeedback.confirmLogout(
                    context,
                    title: 'Sair da conta?',
                    subtitle: 'Você realmente deseja sair?',
                    confirmLabel: 'Sair',
                    cancelLabel: 'Cancelar',
                  );

                  if (!context.mounted || !confirmed) {
                    return;
                  }

                  await AuthSession.instance.logout();

                  if (!context.mounted) {
                    return;
                  }

                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.red,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.logOut, size: 15),
                    SizedBox(width: 8),
                    Text('Sair',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Version
              const Center(
                child: Text(
                  'CarSync v1.0.0',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.quarter,
                      letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
