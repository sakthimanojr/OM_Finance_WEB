import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;

  bool _otpSent = false;
  bool _isLoading = false;
  String? _error;
  String? _success;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _authService.forgotPassword(_phoneController.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _authService.resetPassword(
        _phoneController.text.trim(),
        _otpController.text.trim(),
        _newPasswordController.text,
      );
      setState(() => _success = 'Password reset successfully. You can now log in.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? LinearGradient(colors: [
                  AppTheme.primaryColor.withOpacity(0.4),
                  AppTheme.primaryLight.withOpacity(0.4),
                ])
              : AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(icon, color: Colors.white, size: 18),
          label: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          // Header icon
                          Center(
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.lock_reset_outlined,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Forgot Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _otpSent
                                ? 'Enter the OTP and your new password'
                                : 'Enter your phone number to receive a reset OTP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Glass form card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Phone field
                                TextField(
                                  controller: _phoneController,
                                  enabled: !_otpSent,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Phone number',
                                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    prefixIcon: Icon(Icons.phone_outlined,
                                        color: Colors.white.withOpacity(0.7)),
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.06),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                          BorderSide(color: Colors.white.withOpacity(0.15)),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide:
                                          BorderSide(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppTheme.primaryLight, width: 1.5),
                                    ),
                                  ),
                                ),

                                if (_otpSent) ...[
                                  const SizedBox(height: 16),
                                  // OTP field
                                  TextField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    style: const TextStyle(
                                        color: Colors.white, letterSpacing: 6, fontSize: 18),
                                    decoration: InputDecoration(
                                      labelText: '6-digit OTP',
                                      labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.7)),
                                      prefixIcon: Icon(Icons.pin_outlined,
                                          color: Colors.white.withOpacity(0.7)),
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.06),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide:
                                            BorderSide(color: Colors.white.withOpacity(0.15)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                            color: AppTheme.primaryLight, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // New password field
                                  TextField(
                                    controller: _newPasswordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'New password',
                                      labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.7)),
                                      prefixIcon: Icon(Icons.lock_outline,
                                          color: Colors.white.withOpacity(0.7)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        onPressed: () => setState(
                                            () => _obscurePassword = !_obscurePassword),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.06),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide:
                                            BorderSide(color: Colors.white.withOpacity(0.15)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                            color: AppTheme.primaryLight, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],

                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppTheme.errorColor.withOpacity(0.4)),
                                    ),
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            color: AppTheme.errorColor, fontSize: 13)),
                                  ),
                                ],
                                if (_success != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppTheme.successColor.withOpacity(0.4)),
                                    ),
                                    child: Text(_success!,
                                        style: const TextStyle(
                                            color: AppTheme.successColor, fontSize: 13)),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                if (_success == null)
                                  _buildGradientButton(
                                    onPressed: _isLoading
                                        ? null
                                        : (_otpSent ? _resetPassword : _requestOtp),
                                    label: _otpSent ? 'Reset Password' : 'Send OTP',
                                    icon: _otpSent
                                        ? Icons.lock_reset_outlined
                                        : Icons.send_outlined,
                                    isLoading: _isLoading,
                                  )
                                else
                                  _buildGradientButton(
                                    onPressed: () => context.go('/login'),
                                    label: 'Back to Login',
                                    icon: Icons.login_outlined,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
