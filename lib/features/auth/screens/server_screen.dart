import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/theme/app_theme.dart';
import 'login_screen.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverCtrl = TextEditingController();
  final _dbCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _dbCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverCtrl.text = prefs.getString('server_url') ?? '';
      _dbCtrl.text = prefs.getString('database') ?? '';
    });
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverCtrl.text.trim());
    await prefs.setString('database', _dbCtrl.text.trim());

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          baseUrl: _serverCtrl.text.trim(),
          database: _dbCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                    'Education App',
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
                    'Enter your server details',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // ── Step indicator ────────────────────────
                  _StepIndicator(currentStep: 1),
                  const SizedBox(height: 32),

                  // ── Server URL ────────────────────────────
                  _buildLabel('Server URL'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _serverCtrl,
                    hint: 'http://192.168.1.15:8069',
                    icon: Icons.dns_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter server URL' : null,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),

                  // ── Database ──────────────────────────────
                  _buildLabel('Database'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _dbCtrl,
                    hint: 'school_db',
                    icon: Icons.storage_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter database name' : null,
                  ),
                  const SizedBox(height: 32),

                  // ── Next Button ───────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Hint ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Step 1 of 2',
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep; // 1 or 2

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(number: 1, isActive: currentStep == 1, isDone: currentStep > 1),
        Expanded(
          child: Container(
            height: 2,
            color: currentStep > 1
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
          ),
        ),
        _StepDot(number: 2, isActive: currentStep == 2, isDone: false),
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