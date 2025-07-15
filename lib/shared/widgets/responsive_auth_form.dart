import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../shared/models/user_model.dart';
import 'responsive_auth_button.dart';

enum AuthFormMode {
  login,
  register,
  logout,
}

class ResponsiveAuthForm extends ConsumerStatefulWidget {
  final AuthFormMode mode;
  final UserRole? userRole;
  final Color? themeColor;
  final VoidCallback? onSuccess;
  final VoidCallback? onModeChange;
  final bool showModeToggle;
  final bool showSocialAuth;

  const ResponsiveAuthForm({
    super.key,
    required this.mode,
    this.userRole,
    this.themeColor,
    this.onSuccess,
    this.onModeChange,
    this.showModeToggle = true,
    this.showSocialAuth = true,
  });

  @override
  ConsumerState<ResponsiveAuthForm> createState() => _ResponsiveAuthFormState();
}

class _ResponsiveAuthFormState extends ConsumerState<ResponsiveAuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  AuthFormMode _currentMode = AuthFormMode.login;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (_currentMode == AuthFormMode.logout) {
      return _buildLogoutForm(isLoading, isSmallScreen);
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showModeToggle) _buildModeToggle(isSmallScreen),
            if (widget.showModeToggle)
              SizedBox(height: isSmallScreen ? 16 : 24),
            ..._buildFormFields(isSmallScreen),
            SizedBox(height: isSmallScreen ? 20 : 24),
            _buildPrimaryButton(isLoading, isSmallScreen),
            if (widget.showSocialAuth) ...[
              SizedBox(height: isSmallScreen ? 16 : 20),
              _buildDivider(),
              SizedBox(height: isSmallScreen ? 16 : 20),
              _buildSocialButtons(isLoading, isSmallScreen),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: ResponsiveAuthButton(
            text: 'Login',
            type: _currentMode == AuthFormMode.login
                ? AuthButtonType.primary
                : AuthButtonType.secondary,
            size: isSmallScreen ? AuthButtonSize.small : AuthButtonSize.medium,
            customColor: widget.themeColor,
            onPressed: () {
              setState(() {
                _currentMode = AuthFormMode.login;
              });
              widget.onModeChange?.call();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ResponsiveAuthButton(
            text: 'Register',
            type: _currentMode == AuthFormMode.register
                ? AuthButtonType.primary
                : AuthButtonType.secondary,
            size: isSmallScreen ? AuthButtonSize.small : AuthButtonSize.medium,
            customColor: widget.themeColor,
            onPressed: () {
              setState(() {
                _currentMode = AuthFormMode.register;
              });
              widget.onModeChange?.call();
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields(bool isSmallScreen) {
    List<Widget> fields = [];

    if (_currentMode == AuthFormMode.register) {
      fields.add(_buildTextField(
        controller: _nameController,
        label: 'Full Name',
        icon: Icons.person_outline,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your full name';
          }
          return null;
        },
      ));
      fields.add(SizedBox(height: isSmallScreen ? 12 : 16));
    }

    fields.add(_buildTextField(
      controller: _emailController,
      label: 'Email',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
    ));
    fields.add(SizedBox(height: isSmallScreen ? 12 : 16));

    fields.add(_buildTextField(
      controller: _passwordController,
      label: 'Password',
      icon: Icons.lock_outline,
      isPassword: true,
      isPasswordVisible: _isPasswordVisible,
      onTogglePassword: () {
        setState(() {
          _isPasswordVisible = !_isPasswordVisible;
        });
      },
      validator: _validatePassword,
    ));

    if (_currentMode == AuthFormMode.register) {
      fields.add(SizedBox(height: isSmallScreen ? 12 : 16));
      fields.add(_buildTextField(
        controller: _confirmPasswordController,
        label: 'Confirm Password',
        icon: Icons.lock_outline,
        isPassword: true,
        isPasswordVisible: _isConfirmPasswordVisible,
        onTogglePassword: () {
          setState(() {
            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
          });
        },
        validator: (value) {
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ));
    }

    return fields;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[400],
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.themeColor ?? Colors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isLoading, bool isSmallScreen) {
    return ResponsiveAuthButton(
      text: _currentMode == AuthFormMode.login ? 'Login' : 'Register',
      type: AuthButtonType.primary,
      size: isSmallScreen ? AuthButtonSize.medium : AuthButtonSize.large,
      isLoading: isLoading,
      customColor: widget.themeColor,
      onPressed: _handlePrimaryAction,
    );
  }

  Widget _buildSocialButtons(bool isLoading, bool isSmallScreen) {
    return Column(
      children: [
        ResponsiveAuthButton(
          text: _currentMode == AuthFormMode.login
              ? 'Sign in with Google'
              : 'Register with Google',
          type: AuthButtonType.google,
          size: isSmallScreen ? AuthButtonSize.medium : AuthButtonSize.large,
          isLoading: isLoading,
          onPressed: _handleGoogleAuth,
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        ResponsiveAuthButton(
          text: _currentMode == AuthFormMode.login
              ? 'Sign in with Phone'
              : 'Register with Phone',
          type: AuthButtonType.phone,
          size: isSmallScreen ? AuthButtonSize.medium : AuthButtonSize.large,
          icon: Icons.phone,
          isLoading: isLoading,
          onPressed: _handlePhoneAuth,
        ),
      ],
    );
  }

  Widget _buildLogoutForm(bool isLoading, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.logout,
            size: isSmallScreen ? 48 : 64,
            color: Colors.red,
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            'Sign Out',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            'Are you sure you want to sign out?',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          Row(
            children: [
              Expanded(
                child: ResponsiveAuthButton(
                  text: 'Cancel',
                  type: AuthButtonType.outlined,
                  size: isSmallScreen
                      ? AuthButtonSize.medium
                      : AuthButtonSize.large,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResponsiveAuthButton(
                  text: 'Sign Out',
                  type: AuthButtonType.logout,
                  size: isSmallScreen
                      ? AuthButtonSize.medium
                      : AuthButtonSize.large,
                  isLoading: isLoading,
                  onPressed: _handleLogout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[700])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[700])),
      ],
    );
  }

  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (_currentMode == AuthFormMode.register && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Action handlers
  Future<void> _handlePrimaryAction() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_currentMode == AuthFormMode.login) {
        await ref
            .read(authControllerProvider.notifier)
            .signInWithEmailAndPassword(
              _emailController.text.trim(),
              _passwordController.text,
            );
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .signUpWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim(),
              phoneNumber: '',
              role: widget.userRole ?? UserRole.parent,
            );
      }
      widget.onSuccess?.call();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _handleGoogleAuth() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle(
            role: widget.userRole ?? UserRole.parent,
          );
      widget.onSuccess?.call();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _handlePhoneAuth() async {
    // Show phone auth dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone Authentication'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your phone number to receive a verification code.'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '+1 234 567 8900',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showInfoSnackBar('Phone verification code sent!');
            },
            child: const Text('Send Code'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      widget.onSuccess?.call();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
