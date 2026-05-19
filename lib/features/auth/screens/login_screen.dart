import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'server_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String baseUrl;
  final String database;

  const LoginScreen({
    super.key,
    required this.baseUrl,
    required this.database,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginCtrl.text = prefs.getString('last_login') ?? '';
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login', _loginCtrl.text.trim());

    await ref.read(authProvider.notifier).login(
          baseUrl: widget.baseUrl,
          database: widget.database,
          login: _loginCtrl.text.trim(),
          password: _passCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Navigate when logged in
    ref.listen(authProvider, (_, next) {
      if (next.isLoggedIn && !next.isLoading) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      // ── Back button goes to Screen 1 ───────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF444B5A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo ──────────────────────────────────
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25A667),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Title ─────────────────────────────────
                  Text(
                    'School Attendance',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D23),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // ── Step indicator ────────────────────────
                  _StepIndicator(currentStep: 2),
                  const SizedBox(height: 24),

                  // ── Server info pill ──────────────────────
                  // Shows user which server they are connecting to
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.dns_outlined,
                              size: 16,
                              color: AppTheme.primaryColor.withOpacity(0.8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.baseUrl,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.database,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_outlined,
                              size: 14,
                              color: AppTheme.primaryColor.withOpacity(0.6)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Email ─────────────────────────────────
                  _buildLabel('Email / Username'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _loginCtrl,
                    hint: 'name@school.com',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your email' : null,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────────
                  _buildLabel('Password'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _passCtrl,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your password' : null,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Error ─────────────────────────────────
                  if (auth.error != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.errorColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ── Sign In Button ────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Step hint ─────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Step 2 of 2',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF444B5A),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
        suffixIcon: suffix,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────
// Same widget reused in both screens

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(
            number: 1,
            isActive: currentStep == 1,
            isDone: currentStep > 1),
        Expanded(
          child: Container(
            height: 2,
            color: currentStep > 1
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
          ),
        ),
        _StepDot(
            number: 2,
            isActive: currentStep == 2,
            isDone: false),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.number,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = (isActive || isDone)
        ? AppTheme.primaryColor
        : Colors.grey.shade300;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$number',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}