import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../services/user_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);

    _nameController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
    _onChanged();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final ready = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty;

    if (ready != _isReady && mounted) {
      setState(() => _isReady = ready);
    }
  }

  String? _validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Informe seu nome';
    }
    if (text.length < 3) {
      return 'Nome muito curto';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Informe seu email';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'Email invalido';
    }
    return null;
  }

  Future<void> _save() async {
    if (_isSaving || !_isReady) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final updated = UserProfileData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    await UserProfileService.saveProfile(
      name: updated.name,
      email: updated.email,
    );
    await HapticFeedback.lightImpact();

    if (!mounted) {
      return;
    }

    context.pop(updated);
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
        title: const Text('Editar perfil'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seus dados',
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
                  'Atualize nome e email para manter sua conta em dia.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileInput(
                  label: 'Nome completo',
                  hint: 'Ex.: John Doe',
                  controller: _nameController,
                  validator: _validateName,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  autocorrect: true,
                  enableSuggestions: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),
                _ProfileInput(
                  label: 'Email',
                  hint: 'Ex.: john@email.com',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving || !_isReady ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFB6BBC5),
                      elevation: _isSaving || !_isReady ? 0 : 3,
                      shadowColor: const Color(0x2A000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Salvar alteracoes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInput extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
   final TextCapitalization textCapitalization;
   final bool autocorrect;
   final bool enableSuggestions;

  const _ProfileInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
     this.textCapitalization = TextCapitalization.none,
     this.autocorrect = true,
     this.enableSuggestions = true,
  });

  @override
  State<_ProfileInput> createState() => _ProfileInputState();
}

class _ProfileInputState extends State<_ProfileInput> {
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
              color: hasFocus ? const Color(0x553B82F6) : const Color(0x1F1C1C1E),
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
            autocorrect: widget.autocorrect,
            enableSuggestions: widget.enableSuggestions,
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
