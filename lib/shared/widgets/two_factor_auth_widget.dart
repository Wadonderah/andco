import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/services/enhanced_auth_service.dart';
import '../../core/theme/app_colors.dart';

class TwoFactorAuthWidget extends ConsumerStatefulWidget {
  final String userEmail;
  final VoidCallback? onEnabled;
  final VoidCallback? onDisabled;

  const TwoFactorAuthWidget({
    super.key,
    required this.userEmail,
    this.onEnabled,
    this.onDisabled,
  });

  @override
  ConsumerState<TwoFactorAuthWidget> createState() => _TwoFactorAuthWidgetState();
}

class _TwoFactorAuthWidgetState extends ConsumerState<TwoFactorAuthWidget> {
  bool _isLoading = false;
  bool _is2FAEnabled = false;
  String? _secret;
  String? _qrCodeData;
  final _codeController = TextEditingController();
  bool _showSetup = false;

  @override
  void initState() {
    super.initState();
    _check2FAStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _check2FAStatus() async {
    final authService = ref.read(enhancedAuthServiceProvider);
    
    setState(() => _isLoading = true);
    
    try {
      final isEnabled = await authService.is2FAEnabled();
      setState(() => _is2FAEnabled = isEnabled);
    } catch (e) {
      debugPrint('Error checking 2FA status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setup2FA() async {
    final authService = ref.read(enhancedAuthServiceProvider);
    
    setState(() => _isLoading = true);
    
    try {
      final secret = authService.generate2FASecret();
      final qrCodeData = authService.generate2FAQRCode(widget.userEmail, secret);
      
      setState(() {
        _secret = secret;
        _qrCodeData = qrCodeData;
        _showSetup = true;
      });
    } catch (e) {
      _showMessage('Error setting up 2FA: ${e.toString()}', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enable2FA() async {
    if (_secret == null || _codeController.text.isEmpty) {
      _showMessage('Please enter the verification code', AppColors.warning);
      return;
    }

    final authService = ref.read(enhancedAuthServiceProvider);
    
    setState(() => _isLoading = true);
    
    try {
      final success = await authService.enable2FA(_secret!, _codeController.text);
      if (success) {
        setState(() {
          _is2FAEnabled = true;
          _showSetup = false;
        });
        _showMessage('Two-factor authentication enabled successfully', AppColors.success);
        widget.onEnabled?.call();
      } else {
        _showMessage('Invalid verification code. Please try again.', AppColors.error);
      }
    } catch (e) {
      _showMessage('Error enabling 2FA: ${e.toString()}', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disable2FA() async {
    final confirmed = await _showConfirmationDialog(
      'Disable Two-Factor Authentication',
      'Are you sure you want to disable two-factor authentication? This will make your account less secure.',
    );

    if (!confirmed) return;

    final authService = ref.read(enhancedAuthServiceProvider);
    
    setState(() => _isLoading = true);
    
    try {
      await authService.disable2FA();
      setState(() => _is2FAEnabled = false);
      _showMessage('Two-factor authentication disabled', AppColors.warning);
      widget.onDisabled?.call();
    } catch (e) {
      _showMessage('Error disabling 2FA: ${e.toString()}', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: _is2FAEnabled ? AppColors.success : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Add an extra layer of security to your account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _is2FAEnabled,
                  onChanged: (enabled) {
                    if (enabled) {
                      _setup2FA();
                    } else {
                      _disable2FA();
                    }
                  },
                  activeColor: AppColors.success,
                ),
              ],
            ),
            
            if (_is2FAEnabled) ...[
              const SizedBox(height: 16),
              _build2FAEnabledInfo(),
            ],
            
            if (_showSetup) ...[
              const SizedBox(height: 16),
              _build2FASetup(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _build2FAEnabledInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Two-factor authentication is enabled and protecting your account',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build2FASetup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Setup Two-Factor Authentication',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Install an authenticator app (Google Authenticator, Authy, etc.)\n'
                '2. Scan the QR code below or enter the secret key manually\n'
                '3. Enter the 6-digit code from your authenticator app',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // QR Code
        if (_qrCodeData != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: _qrCodeData!,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Secret Key
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secret Key:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _secret ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _secret ?? ''));
                    _showMessage('Secret key copied to clipboard', AppColors.success);
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy secret key',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Verification Code Input
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              hintText: 'Enter 6-digit code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.security),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _showSetup = false);
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _enable2FA,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enable 2FA'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
