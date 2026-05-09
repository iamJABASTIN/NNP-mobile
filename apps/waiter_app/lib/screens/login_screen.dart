import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/brutal_text_field.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // If login success, trigger the splash flow again if requested
      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      }
      // Auth listener in main.dart will also handle navigation to AppShell
    } catch (e) {
      setState(() {
        _error = e.toString().contains('Invalid login credentials')
            ? 'Invalid email or password'
            : 'Login failed. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryYellow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo/Header Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  border: Border.all(color: AppColors.black, width: 4),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black, offset: Offset(6, 6)),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NNP',
                      style: TextStyle(
                        color: AppColors.primaryYellow,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      'WAITER POS',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              
              const Text(
                'LOG IN TO YOUR ACCOUNT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.4),
                    border: Border.all(color: AppColors.danger, width: 3),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              BrutalTextField(
                label: 'EMAIL ADDRESS',
                controller: _emailController,
                hintText: 'waiter@nnp.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              BrutalTextField(
                label: 'PASSWORD',
                controller: _passwordController,
                hintText: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 40),

              // Login Button
              GestureDetector(
                onTap: _loading ? null : _handleLogin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    border: Border.all(color: AppColors.black, width: 4),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(8, 8)),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryYellow,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'ENTER KITCHEN',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'SYSTEM v1.0.4 - SECURED BY SUPABASE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
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
