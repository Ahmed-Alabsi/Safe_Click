import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/features/main/presentation/pages/home_screen.dart';
import 'package:safeclik/features/auth/presentation/providers/auth_controller.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 300; 

  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  void _startTimer() {
    setState(() => _secondsRemaining = 300);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackBar('الرجاء إدخال رمز صحيح مكون من 6 أرقام', true);
      return;
    }

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.verifyOtp(widget.email, otp);

    if (!mounted) return;

    if (success) {
      _showSnackBar('تم إنهاء التسجيل بنجاح', false);
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => const HomeScreen()), 
        (route) => false
      );
    } else {
      _showSnackBar(notifier.error ?? 'رمز غير صحيح', true);
    }
  }

  Future<void> _resendOtp() async {
    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.resendOtp(widget.email);

    if (!mounted) return;

    if (success) {
      _showSnackBar('تم إعادة إرسال الرمز', false);
      _startTimer();
    } else {
      _showSnackBar(notifier.error ?? 'فشل الإرسال', true);
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = ref.watch(authProvider).isLoading;
    
    final minutes = (_secondsRemaining / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحقق من البريد الإلكتروني'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
             begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
             colors: [
               Theme.of(context).colorScheme.surface,
               Theme.of(context).colorScheme.surfaceContainerHighest,
             ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(
                    Icons.mark_email_read_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'تم إرسال رمز التحقق إلى بريدك',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'صلاحية الرمز: $minutes:$seconds',
                    style: TextStyle(
                      color: _secondsRemaining > 60 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                         backgroundColor: Theme.of(context).colorScheme.primary,
                         foregroundColor: Theme.of(context).colorScheme.onPrimary,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                         ),
                      ),
                      child: isLoading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary,))
                          : const Text('تحقق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: (_secondsRemaining == 0 && !isLoading) ? _resendOtp : null,
                    child: Text('إعادة إرسال الرمز'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
