import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _otpSent = false;
  bool _isRequesting = false;
  String? _errorText;
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
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_phoneController.text.trim().length != 10) {
      setState(() => _errorText = 'Enter a valid 10-digit phone number');
      return;
    }
    setState(() {
      _isRequesting = true;
      _errorText = null;
    });
    try {
      await _authService.requestOtp(_phoneController.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  Future<void> _verifyOtp() async {
    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.verifyOtp(_phoneController.text.trim(), _otpController.text.trim());
    if (success && mounted) {
      final user = ref.read(authProvider).user!;
      context.go(user.isAdmin ? '/admin/dashboard' : '/customer/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar on gradient background
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'Log in with OTP',
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
                          // Icon header
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
                              child: const Icon(Icons.phone_android_outlined,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'OTP Verification',
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
                                ? 'Enter the OTP sent to your phone'
                                : 'We\'ll send a one-time password to your phone',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Glass card
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
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  enabled: !_otpSent,
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
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
                                    ),
                                  ),
                                ),
                                if (_errorText != null) ...[
                                  const SizedBox(height: 8),
                                  Text(_errorText!,
                                      style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                                ],
                                if (authState.error != null) ...[
                                  const SizedBox(height: 8),
                                  Text(authState.error!,
                                      style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                                ],
                                if (!_otpSent) ...[
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 52,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.accentGradient,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isRequesting ? null : _requestOtp,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: _isRequesting
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text(
                                                'Send OTP',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15),
                                              ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
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
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                                        borderSide:
                                            const BorderSide(color: AppTheme.primaryLight, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 52,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.accentGradient,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: authState.isLoading ? null : _verifyOtp,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14)),
                                        ),
                                        child: authState.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text(
                                                'Verify & Log In',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15),
                                              ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() => _otpSent = false),
                                    child: Text(
                                      'Change phone number',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
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
