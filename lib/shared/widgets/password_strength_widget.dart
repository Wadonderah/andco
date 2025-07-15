import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/enhanced_auth_service.dart';
import '../../core/theme/app_colors.dart';

class PasswordStrengthWidget extends ConsumerWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthWidget({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(enhancedAuthServiceProvider);
    final strength = authService.checkPasswordStrength(password);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength Indicator
        _buildStrengthIndicator(context, strength),
        
        if (showRequirements) ...[
          const SizedBox(height: 12),
          _buildRequirements(context),
        ],
      ],
    );
  }

  Widget _buildStrengthIndicator(BuildContext context, PasswordStrength strength) {
    Color strengthColor;
    String strengthText;
    double strengthValue;

    switch (strength) {
      case PasswordStrength.weak:
        strengthColor = AppColors.error;
        strengthText = 'Weak';
        strengthValue = 0.33;
        break;
      case PasswordStrength.medium:
        strengthColor = AppColors.warning;
        strengthText = 'Medium';
        strengthValue = 0.66;
        break;
      case PasswordStrength.strong:
        strengthColor = AppColors.success;
        strengthText = 'Strong';
        strengthValue = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Password Strength: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              strengthText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: strengthValue,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildRequirements(BuildContext context) {
    final requirements = [
      _PasswordRequirement(
        text: 'At least 8 characters',
        isMet: password.length >= 8,
      ),
      _PasswordRequirement(
        text: 'At least 12 characters (recommended)',
        isMet: password.length >= 12,
        isOptional: true,
      ),
      _PasswordRequirement(
        text: 'Contains uppercase letter (A-Z)',
        isMet: password.contains(RegExp(r'[A-Z]')),
      ),
      _PasswordRequirement(
        text: 'Contains lowercase letter (a-z)',
        isMet: password.contains(RegExp(r'[a-z]')),
      ),
      _PasswordRequirement(
        text: 'Contains number (0-9)',
        isMet: password.contains(RegExp(r'[0-9]')),
      ),
      _PasswordRequirement(
        text: 'Contains special character (!@#\$%^&*)',
        isMet: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((requirement) => _buildRequirementItem(context, requirement)),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(BuildContext context, _PasswordRequirement requirement) {
    final color = requirement.isMet 
        ? AppColors.success 
        : requirement.isOptional 
            ? AppColors.textSecondary 
            : AppColors.error;
    
    final icon = requirement.isMet 
        ? Icons.check_circle 
        : requirement.isOptional 
            ? Icons.radio_button_unchecked 
            : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                decoration: requirement.isMet ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRequirement {
  final String text;
  final bool isMet;
  final bool isOptional;

  _PasswordRequirement({
    required this.text,
    required this.isMet,
    this.isOptional = false,
  });
}

/// Enhanced password field with strength indicator
class PasswordFieldWithStrength extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool showStrengthIndicator;
  final bool showRequirements;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const PasswordFieldWithStrength({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.hintText,
    this.showStrengthIndicator = true,
    this.showRequirements = true,
    this.onChanged,
    this.validator,
  });

  @override
  ConsumerState<PasswordFieldWithStrength> createState() => _PasswordFieldWithStrengthState();
}

class _PasswordFieldWithStrengthState extends ConsumerState<PasswordFieldWithStrength> {
  bool _obscureText = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _password = widget.controller.text;
    widget.controller.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _password = widget.controller.text;
    });
    widget.onChanged?.call(_password);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          validator: widget.validator,
        ),
        
        if (widget.showStrengthIndicator && _password.isNotEmpty) ...[
          const SizedBox(height: 12),
          PasswordStrengthWidget(
            password: _password,
            showRequirements: widget.showRequirements,
          ),
        ],
      ],
    );
  }
}

/// Password history checker widget
class PasswordHistoryChecker extends ConsumerWidget {
  final String userId;
  final String newPassword;
  final Widget child;

  const PasswordHistoryChecker({
    super.key,
    required this.userId,
    required this.newPassword,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(enhancedAuthServiceProvider).isPasswordInHistory(userId, newPassword),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return child;
        }

        final isInHistory = snapshot.data ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            if (isInHistory && newPassword.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This password was used recently. Please choose a different password.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
