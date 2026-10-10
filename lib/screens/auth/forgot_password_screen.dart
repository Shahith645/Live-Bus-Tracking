import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../db/db_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _newPassword = TextEditingController();
  bool _found = false;
  bool _loading = false;
  bool _done = false;
  String? _error;

  Future<void> _checkEmail() async {
    if (_email.text.isEmpty) return;
    setState(() => _loading = true);
    final exists = await DBHelper.instance.emailExists(_email.text.trim());
    setState(() {
      _loading = false;
      _found = exists;
      _error = exists ? null : 'No account found with this email';
    });
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final user = await DBHelper.instance.getUserByEmail(_email.text.trim());
    if (user != null) {
      await DBHelper.instance.updatePassword(user.id!, _newPassword.text);
    }
    setState(() {
      _loading = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _done
              ? EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Password updated',
                  subtitle: 'You can now sign in with your new password.',
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Forgot your password?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Enter your registered email to reset it.',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _email,
                        label: 'Email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
                      ),
                      const SizedBox(height: 12),
                      if (!_found)
                        GradientButton(label: 'Verify Email', icon: Icons.search_rounded, onTap: _checkEmail, loading: _loading),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                        ),
                      if (_found) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _newPassword,
                          label: 'New password',
                          icon: Icons.lock_reset_rounded,
                          obscure: true,
                          validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                        ),
                        const SizedBox(height: 20),
                        GradientButton(label: 'Update Password', icon: Icons.check_rounded, onTap: _reset, loading: _loading),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
