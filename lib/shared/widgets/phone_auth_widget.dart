import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/user_model.dart';
import 'custom_text_field.dart';

class PhoneAuthWidget extends ConsumerStatefulWidget {
  final UserRole userRole;
  final Color themeColor;
  final String? name;
  final String? schoolId;
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const PhoneAuthWidget({
    super.key,
    required this.userRole,
    required this.themeColor,
    this.name,
    this.schoolId,
    this.onSuccess,
    this.onError,
  });

  @override
  ConsumerState<PhoneAuthWidget> createState() => _PhoneAuthWidgetState();
}

class _PhoneAuthWidgetState extends ConsumerState<PhoneAuthWidget> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    if (widget.name != null) {
      _nameController.text = widget.name!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isOtpSent) _buildPhoneForm() else _buildOtpForm(),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.name == null) ...[
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              validator: _validateName,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
          ],
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+1 234 567 8900',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[+\d\s\-\(\)]')),
            ],
            validator: _validatePhone,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the 6-digit code sent to',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _phoneController.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.themeColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          CustomTextField(
            controller: _otpController,
            label: 'Verification Code',
            hint: '123456',
            prefixIcon: Icons.security_outlined,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: _validateOtp,
            onChanged: (value) {
              if (value.length == 6) {
                _verifyOtp();
              }
            },
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isOtpSent = false;
                    _otpController.clear();
                  });
                },
                child: Text(
                  'Change Number',
                  style: TextStyle(color: widget.themeColor),
                ),
              ),
              if (_canResend)
                TextButton(
                  onPressed: _resendOtp,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(color: widget.themeColor),
                  ),
                )
              else
                Text(
                  'Resend in ${_countdown}s',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Basic phone validation - should start with + and have at least 10 digits
    final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }
    if (!value.startsWith('+')) {
      return 'Phone number must include country code (e.g., +1)';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the verification code';
    }
    if (value.length != 6) {
      return 'Verification code must be 6 digits';
    }
    return null;
  }

  void _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          widget.onError?.call('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _isOtpSent = true;
            _verificationId = verificationId;
            _resendToken = resendToken;
          });
          _startCountdown();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      widget.onError?.call('Failed to send OTP: $e');
    }
  }

  void _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    if (_verificationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      await _signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      widget.onError?.call('Invalid verification code');
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithPhoneCredential(
        credential,
        name: widget.name ?? _nameController.text.trim(),
        role: widget.userRole,
        schoolId: widget.schoolId,
      );

      widget.onSuccess?.call();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      widget.onError?.call('Sign in failed: $e');
    }
  }

  void _resendOtp() {
    _sendOtp();
  }

  void _startCountdown() {
    _countdown = 60;
    _canResend = false;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) {
            _canResend = true;
          }
        });
      }
      return _countdown > 0 && mounted;
    });
  }
}
