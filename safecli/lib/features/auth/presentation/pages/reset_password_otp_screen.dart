import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';
import 'package:safeclik/features/auth/presentation/pages/new_password_screen.dart';

class ResetPasswordOTPScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordOTPScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordOTPScreen> createState() => _ResetPasswordOTPScreenState();
}

class _ResetPasswordOTPScreenState extends ConsumerState<ResetPasswordOTPScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال 6 أرقام')),
      );
      return;
    }

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.verifyResetOtp(widget.email, otp);

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordScreen(email: widget.email, otp: otp),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'الرمز غير صحيح'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('التحقق من الرمز')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تم إرسال رمز التحقق إلى:\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('تحقق', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
