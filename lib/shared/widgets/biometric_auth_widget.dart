import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/services/enhanced_auth_service.dart';
import '../../core/theme/app_colors.dart';

class BiometricAuthWidget extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;
  final String title;
  final String subtitle;
  final bool showToggle;

  const BiometricAuthWidget({
    super.key,
    this.onSuccess,
    this.onFailure,
    this.title = 'Biometric Authentication',
    this.subtitle = 'Use your fingerprint or face to authenticate',
    this.showToggle = true,
  });

  @override
  ConsumerState<BiometricAuthWidget> createState() => _BiometricAuthWidgetState();
}

class _BiometricAuthWidgetState extends ConsumerState<BiometricAuthWidget> {
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final authService = ref.read(enhancedAuthServiceProvider);
    
    setState(() => _isLoading = true);
    
    try {
      final isAvailable = await authService.isBiometricAvailable();
      final isEnabled = await authService.isBiometricEnabled();
      final availableBiometrics = await authService.getAvailableBiometrics();
      
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
        _availableBiometrics = availableBiometrics;
      });
    } catch (e) {
      debugPrint('Error checking biometric status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    final authService = ref.read(enhancedAuthServiceProvider);
    
    setState(() => _isLoading = true);
    
    try {
      if (enabled) {
        final success = await authService.enableBiometricAuth();
        if (success) {
          setState(() => _isBiometricEnabled = true);
          _showMessage('Biometric authentication enabled', AppColors.success);
        } else {
          _showMessage('Failed to enable biometric authentication', AppColors.error);
        }
      } else {
        await authService.disableBiometricAuth();
        setState(() => _isBiometricEnabled = false);
        _showMessage('Biometric authentication disabled', AppColors.warning);
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final authService = ref.read(enhancedAuthServiceProvider);
    
    setState(() => _isLoading = true);
    
    try {
      final success = await authService.authenticateWithBiometrics();
      if (success) {
        widget.onSuccess?.call();
        _showMessage('Authentication successful', AppColors.success);
      } else {
        widget.onFailure?.call();
        _showMessage('Authentication failed', AppColors.error);
      }
    } catch (e) {
      widget.onFailure?.call();
      _showMessage('Error: ${e.toString()}', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
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

    if (!_isBiometricAvailable) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.fingerprint_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Biometric Authentication Unavailable',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your device does not support biometric authentication or no biometrics are enrolled.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
                  _getBiometricIcon(),
                  color: _isBiometricEnabled ? AppColors.success : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showToggle)
                  Switch(
                    value: _isBiometricEnabled,
                    onChanged: _toggleBiometric,
                    activeColor: AppColors.success,
                  ),
              ],
            ),
            
            if (_isBiometricEnabled) ...[
              const SizedBox(height: 16),
              _buildBiometricInfo(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _authenticateWithBiometric,
                  icon: Icon(_getBiometricIcon()),
                  label: Text(_getAuthButtonText()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricInfo() {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric authentication is enabled',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'Available: ${_getAvailableBiometricsText()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    }
    return Icons.security;
  }

  String _getAuthButtonText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Authenticate with Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Authenticate with Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Authenticate with Iris';
    }
    return 'Authenticate with Biometrics';
  }

  String _getAvailableBiometricsText() {
    if (_availableBiometrics.isEmpty) return 'None';
    
    final types = _availableBiometrics.map((type) {
      switch (type) {
        case BiometricType.face:
          return 'Face ID';
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.iris:
          return 'Iris';
        case BiometricType.strong:
          return 'Strong Biometric';
        case BiometricType.weak:
          return 'Weak Biometric';
      }
    }).toList();
    
    return types.join(', ');
  }
}

/// Biometric authentication dialog
class BiometricAuthDialog extends ConsumerWidget {
  final String title;
  final String message;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const BiometricAuthDialog({
    super.key,
    this.title = 'Biometric Authentication',
    this.message = 'Please authenticate to continue',
    this.onSuccess,
    this.onFailure,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fingerprint,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onFailure?.call();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final authService = ref.read(enhancedAuthServiceProvider);
            final success = await authService.authenticateWithBiometrics();
            
            Navigator.of(context).pop();
            
            if (success) {
              onSuccess?.call();
            } else {
              onFailure?.call();
            }
          },
          child: const Text('Authenticate'),
        ),
      ],
    );
  }

  /// Show biometric authentication dialog
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    bool result = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BiometricAuthDialog(
        title: title ?? 'Biometric Authentication',
        message: message ?? 'Please authenticate to continue',
        onSuccess: () => result = true,
        onFailure: () => result = false,
      ),
    );
    
    return result;
  }
}
