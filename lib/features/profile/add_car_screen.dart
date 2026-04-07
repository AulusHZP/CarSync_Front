import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../services/vehicle_profile_service.dart';
import '../../widgets/app_feedback.dart';

class CarProfile {
  final String model;
  final String year;
  final String totalKm;
  final String plate;

  const CarProfile({
    required this.model,
    required this.year,
    required this.totalKm,
    required this.plate,
  });
}

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _kmController = TextEditingController();
  final _plateController = TextEditingController();
  bool _isSubmitting = false;
  bool _isFormReady = false;
  bool _contentVisible = false;

  @override
  void initState() {
    super.initState();
    _modelController.addListener(_onFieldChanged);
    _yearController.addListener(_onFieldChanged);
    _kmController.addListener(_onFieldChanged);
    _plateController.addListener(_onFieldChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _contentVisible = true);
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _kmController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final ready = _modelController.text.trim().isNotEmpty &&
        _yearController.text.trim().isNotEmpty &&
        _kmController.text.trim().isNotEmpty &&
        _plateController.text.trim().isNotEmpty;
    if (ready == _isFormReady) {
      return;
    }
    setState(() => _isFormReady = ready);
  }

  String? _validateModel(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Informe a marca e modelo';
    }
    if (text.length < 3) {
      return 'Digite um nome válido';
    }
    return null;
  }

  String? _validateYear(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Informe o ano';
    }
    final year = int.tryParse(text);
    final current = DateTime.now().year;
    if (year == null || year < 1980 || year > current + 1) {
      return 'Ano inválido';
    }
    return null;
  }

  String? _validatePlate(String? value) {
    final text = _normalizePlate(value ?? '');
    if (text.isEmpty) {
      return 'Informe a placa';
    }

    final oldPattern = RegExp(r'^[A-Z]{3}-[0-9]{4}$');
    final mercosulPattern = RegExp(r'^[A-Z]{3}[0-9][A-Z][0-9]{2}$');
    if (!oldPattern.hasMatch(text) && !mercosulPattern.hasMatch(text)) {
      return 'Placa inválida';
    }
    return null;
  }

  String? _validateTotalKm(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return 'Informe a KM total';
    }

    final km = int.tryParse(digits);
    if (km == null || km < 0) {
      return 'KM inválida';
    }
    if (km > 3000000) {
      return 'KM fora do esperado';
    }
    return null;
  }

  String _normalizePlate(String value) {
    final raw = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (raw.length == 7 && RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(raw)) {
      return '${raw.substring(0, 3)}-${raw.substring(3)}';
    }
    return raw;
  }

  String _normalizeKm(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final kmValue = int.tryParse(digits) ?? 0;
    return VehicleProfileService.formatKm(kmValue);
  }

  int _parseKmNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final normalizedPlate = _normalizePlate(_plateController.text.trim());
    final kmNumber = _parseKmNumber(_kmController.text.trim());
    final normalizedKm = _normalizeKm(_kmController.text.trim());

    await HapticFeedback.lightImpact();

    try {
      await VehicleProfileService.saveProfile(
        model: _modelController.text.trim(),
        year: _yearController.text.trim(),
        plate: normalizedPlate,
        totalKm: kmNumber,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      AppFeedback.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        tone: AppFeedbackTone.error,
      );
      return;
    }

    final car = CarProfile(
      model: _modelController.text.trim(),
      year: _yearController.text.trim(),
      totalKm: normalizedKm,
      plate: normalizedPlate,
    );

    if (!mounted) {
      return;
    }

    context.pop(car);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Adicionar carro'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            offset: _contentVisible ? Offset.zero : const Offset(0, 0.03),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 260),
              opacity: _contentVisible ? 1 : 0,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo veículo',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.9,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Adicione seu veículo para continuar.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                        height: 1.5,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PremiumInput(
                      label: 'Marca e modelo',
                      hint: 'Ex.: Tesla Model 3',
                      controller: _modelController,
                      validator: _validateModel,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),
                    _PremiumInput(
                      label: 'Ano',
                      hint: 'Ex.: 2024',
                      controller: _yearController,
                      validator: _validateYear,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _PremiumInput(
                      label: 'KM total',
                      hint: 'Ex.: 45000',
                      controller: _kmController,
                      validator: _validateTotalKm,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _PremiumInput(
                      label: 'Placa',
                      hint: 'Ex.: ABC-1234 ou BRA1A23',
                      controller: _plateController,
                      validator: _validatePlate,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        _UpperCasePlateFormatter(),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _PrimarySubmitButton(
                      label: 'Salvar carro',
                      loading: _isSubmitting,
                      enabled: _isFormReady,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumInput extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _PremiumInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  State<_PremiumInput> createState() => _PremiumInputState();
}

class _PremiumInputState extends State<_PremiumInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: hasFocus ? const Color(0xFFFFFFFF) : const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  hasFocus ? const Color(0x553B82F6) : const Color(0x1F1C1C1E),
              width: 1,
            ),
            boxShadow: hasFocus
                ? const [
                    BoxShadow(
                      color: Color(0x1A3B82F6),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: TextFormField(
            focusNode: _focusNode,
            controller: widget.controller,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA7ABB3),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0x33EF4444), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0x66EF4444), width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimarySubmitButton extends StatefulWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const _PrimarySubmitButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_PrimarySubmitButton> createState() => _PrimarySubmitButtonState();
}

class _PrimarySubmitButtonState extends State<_PrimarySubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.loading;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.985 : 1,
      child: Material(
        color: active ? AppColors.primary : const Color(0xFFB6BBC5),
        borderRadius: BorderRadius.circular(26),
        elevation: active ? 3 : 0,
        shadowColor: const Color(0x2A000000),
        child: InkWell(
          onTap: active ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(26),
          onHighlightChanged: (isPressed) {
            if (!active) {
              return;
            }
            if (mounted) {
              setState(() => _pressed = isPressed);
            }
          },
          splashColor: Colors.white.withValues(alpha: 0.10),
          highlightColor: Colors.transparent,
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCasePlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw =
        newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');

    return newValue.copyWith(
      text: raw,
      selection: TextSelection.collapsed(offset: raw.length),
    );
  }
}
