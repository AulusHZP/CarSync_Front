import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../features/profile/add_car_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../services/user_profile_service.dart';
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
  bool _isDeletingCar = false;

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

  Future<void> _deleteCurrentCar() async {
    if (_isDeletingCar || _cars.isEmpty) {
      return;
    }

    final plate = _currentCar.plate.trim();
    if (plate.isEmpty || plate == '--') {
      return;
    }

    final confirmed = await AppFeedback.confirmDestructive(
      context,
      title: 'Excluir veículo?',
      message: 'O veículo $plate será removido permanentemente.',
      highlightedText: plate,
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isDeletingCar = true);

    try {
      final deleted = await VehicleProfileService.deleteProfileByPlate(plate);

      if (!deleted) {
        if (!mounted) {
          return;
        }
        AppFeedback.show(
          context,
          message: 'Veículo não encontrado para exclusão.',
          tone: AppFeedbackTone.warning,
        );
        return;
      }

      await _loadSavedCar();
      if (!mounted) {
        return;
      }

      AppFeedback.show(
        context,
        message: 'Veículo excluído com sucesso.',
        tone: AppFeedbackTone.success,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppFeedback.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        tone: AppFeedbackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingCar = false);
      }
    }
  }

  String _carMetaLine() {
    final parts = <String>[];

    final year = _currentCar.year.trim();
    if (year.isNotEmpty && year != '--') {
      parts.add(year);
    }

    final plate = _currentCar.plate.trim();
    if (plate.isNotEmpty && plate != '--') {
      parts.add(plate);
    }

    if (parts.isEmpty) {
      return 'Sem dados do veículo';
    }

    return parts.join(' • ');
  }

  String _carKmHighlight() {
    final km = _currentCar.totalKm.trim();
    if (km.isEmpty || km == '--') {
      return '—';
    }
    return km;
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 2,
                      decoration: BoxDecoration(
                        color: const Color(0x331C1C1E),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentCar.model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _carMetaLine(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.08,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'KM atual',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _carKmHighlight(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _openAddCar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plus, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Adicionar carro',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (_cars.length > 1 || _cars.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_cars.length > 1)
                      TextButton.icon(
                        onPressed: _openSwitchVehicle,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(LucideIcons.refreshCw, size: 15),
                        label: const Text(
                          'Trocar veículo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    if (_cars.length > 1 && _cars.isNotEmpty)
                      const SizedBox(width: 8),
                    if (_cars.isNotEmpty)
                      TextButton.icon(
                        onPressed: _isDeletingCar ? null : _deleteCurrentCar,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF3B30),
                          disabledForegroundColor: const Color(0x99FF3B30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                        ),
                        icon: _isDeletingCar
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF3B30),
                                  ),
                                ),
                              )
                            : const Icon(LucideIcons.trash2, size: 15),
                        label: const Text(
                          'Excluir carro',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                  ],
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
