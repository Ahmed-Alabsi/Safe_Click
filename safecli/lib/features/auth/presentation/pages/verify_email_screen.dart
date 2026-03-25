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

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  
  Timer? _timer;
  int _secondsRemaining = 300; // 5 دقائق

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
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
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String _getCombinedOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: isError 
                ? Theme.of(context).colorScheme.onError 
                : Theme.of(context).colorScheme.onSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error 
            : Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _getCombinedOtp();
    
    if (otp.length != 6) {
      _showSnackBar('الرجاء إدخال رمز صحيح مكون من 6 أرقام', true);
      return;
    }

    FocusScope.of(context).unfocus();

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.verifyOtp(widget.email, otp);

    if (!mounted) return;

    if (success) {
      _showSnackBar('تم إنهاء التسجيل بنجاح', false);
      
      // تأخير بسيط قبل الانتقال
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
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
      
      // مسح الحقول
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();
    } else {
      _showSnackBar(notifier.error ?? 'فشل الإرسال', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = ref.watch(authProvider).isLoading;
    final isSmallScreen = size.width < 360;
    
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final bool isExpired = _secondsRemaining == 0;

    return Scaffold(
      body: Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,    // يبدأ من الأعلى
          end: Alignment.bottomCenter,    // ينتهي في الأسفل
          colors: [
            Theme.of(context).colorScheme.tertiaryContainer,  // فاتح في الأعلى
            Theme.of(context).colorScheme.tertiary,          // غامق في الأسفل
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildHeader(),
                  ),
                  const SizedBox(height: 40),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildOtpCard(context, isSmallScreen, isLoading, isExpired, minutes, seconds),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildResendLink(context, isExpired, isLoading),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.mark_email_read_rounded,
            size: 45,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'تحقق من البريد الإلكتروني',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'تم إرسال رمز التحقق إلى:\n',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.7),
              ),
              children: [
                TextSpan(
                  text: widget.email,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpCard(BuildContext context, bool isSmallScreen, bool isLoading, bool isExpired, String minutes, String seconds) {
    return Container(
      width: isSmallScreen ? double.infinity : 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, 'أدخل رمز التحقق'),
            const SizedBox(height: 24),
            _buildOtpFields(context),
            const SizedBox(height: 20),
            _buildTimer(context, isExpired, minutes, seconds),
            const SizedBox(height: 24),
            _buildVerifyButton(context, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpFields(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          height: 60,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) => _onOtpChanged(index, value),
          ),
        );
      }),
    );
  }

  Widget _buildTimer(BuildContext context, bool isExpired, String minutes, String seconds) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: (isExpired ? Colors.red : Colors.green).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExpired ? Icons.timer_off_rounded : Icons.timer_rounded,
            size: 18,
            color: isExpired ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            isExpired ? 'انتهت صلاحية الرمز' : 'صلاحية الرمز: $minutes:$seconds',
            style: TextStyle(
              color: isExpired ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(BuildContext context, bool isLoading) {
    return SizedBox(
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isLoading ? 0 : 4,
            shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'جاري التحقق...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'تحقق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.verified_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResendLink(BuildContext context, bool isExpired, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: InkWell(
        onTap: (isExpired && !isLoading) ? _resendOtp : null,
        borderRadius: BorderRadius.circular(30),
        child: Opacity(
          opacity: (isExpired && !isLoading) ? 1.0 : 0.5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 18,
                color: (isExpired && !isLoading)
                    ? Theme.of(context).colorScheme.onTertiary
                    : Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'إعادة إرسال الرمز',
                style: TextStyle(
                  color: (isExpired && !isLoading)
                      ? Theme.of(context).colorScheme.onTertiary
                      : Theme.of(context).colorScheme.onTertiary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}