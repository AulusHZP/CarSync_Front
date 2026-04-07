import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../services/auth_session.dart';
import '../../services/local_auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/carsync_logo_mark.dart';

enum _AuthMode { login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _isLoading = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
    _confirmPasswordController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final ready = _mode == _AuthMode.login
        ? _emailController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty
        : _nameController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty;

    if (ready != _isReady && mounted) {
      setState(() => _isReady = ready);
    }
  }

  void _changeMode(_AuthMode mode) {
    if (_mode == mode) {
      return;
    }

    setState(() {
      _mode = mode;
      _isReady = false;
    });
    _onChanged();
  }

  void _onForgotPassword() {
    AppFeedback.show(
      context,
      message: 'Recuperação de senha em breve.',
      tone: AppFeedbackTone.info,
    );
  }

  String? _validateName(String? value) {
    if (_mode != _AuthMode.register) return null;

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

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Informe sua senha';
    }
    if (_mode == _AuthMode.register && text.length < 6) {
      return 'Senha deve ter ao menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_mode != _AuthMode.register) {
      return null;
    }

    final text = value ?? '';
    if (text.isEmpty) {
      return 'Confirme sua senha';
    }
    if (text != _passwordController.text) {
      return 'As senhas nao coincidem';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isLoading || !_isReady) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      late final AuthUser user;

      if (_mode == _AuthMode.login) {
        user = await LocalAuthService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        user = await LocalAuthService.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      await UserProfileService.saveProfile(
        name: user.name,
        email: user.email,
      );

      await AuthSession.instance.login();

      if (!mounted) {
        return;
      }

      context.go('/');
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == _AuthMode.login;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CarSyncLogoMark(size: 52),
                    SizedBox(width: 12),
                    Text(
                      'CarSync',
                      style: TextStyle(
                        fontSize: 42,
                        height: 1,
                        letterSpacing: -1.35,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin
                      ? 'Entre para gerenciar gastos e manutencao do seu carro.'
                      : 'Crie sua conta para comecar a usar o CarSync.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.primary.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AuthModeButton(
                          active: isLogin,
                          label: 'Entrar',
                          onTap: () => _changeMode(_AuthMode.login),
                        ),
                      ),
                      Expanded(
                        child: _AuthModeButton(
                          active: !isLogin,
                          label: 'Cadastrar',
                          onTap: () => _changeMode(_AuthMode.register),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!isLogin) ...[
                  _AuthInput(
                    key: const ValueKey('auth_name_input'),
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
                  const SizedBox(height: 16),
                ],
                _AuthInput(
                  key: const ValueKey('auth_email_input'),
                  label: 'Email',
                  hint: 'Ex.: john@email.com',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _AuthInput(
                  key: const ValueKey('auth_password_input'),
                  label: 'Senha',
                  hint: 'Digite sua senha',
                  controller: _passwordController,
                  validator: _validatePassword,
                  obscureText: true,
                  textInputAction:
                      isLogin ? TextInputAction.done : TextInputAction.next,
                ),
                if (isLogin) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _onForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                ],
                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  _AuthInput(
                    key: const ValueKey('auth_confirm_password_input'),
                    label: 'Confirmar senha',
                    hint: 'Repita sua senha',
                    controller: _confirmPasswordController,
                    validator: _validateConfirmPassword,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_isReady ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: AppColors.bg,
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                      minimumSize: const Size(double.infinity, 56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.bg),
                            ),
                          )
                        : Text(
                            isLogin ? 'Entrar' : 'Criar conta',
                            style: const TextStyle(
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

class _AuthModeButton extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _AuthModeButton({
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _AuthInput extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;

  const _AuthInput({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  @override
  State<_AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<_AuthInput> {
  late final FocusNode _focusNode;
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _obscure = widget.obscureText;
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
  void didUpdateWidget(covariant _AuthInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
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
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  hasFocus ? const Color(0x66111111) : const Color(0x14111111),
              width: 1,
            ),
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
            obscureText: _obscure,
            cursorColor: const Color(0xFF111111),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA7ABB3),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.input,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x14111111)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x14111111)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0x66111111), width: 1.1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0x66EF4444), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0x99EF4444), width: 1),
              ),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      onPressed: () {
                        setState(() => _obscure = !_obscure);
                      },
                      icon: Icon(
                        _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 16,
                        color: const Color(0xFF6B7280),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
