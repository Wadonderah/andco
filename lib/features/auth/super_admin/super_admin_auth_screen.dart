import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/role_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/andco_logo.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../super_admin/super_admin_dashboard.dart';

class SuperAdminAuthScreen extends ConsumerStatefulWidget {
  const SuperAdminAuthScreen({super.key});

  @override
  ConsumerState<SuperAdminAuthScreen> createState() =>
      _SuperAdminAuthScreenState();
}

class _SuperAdminAuthScreenState extends ConsumerState<SuperAdminAuthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _organizationController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _departmentController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _superAdminExists = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkSuperAdminExists();
  }

  Future<void> _checkSuperAdminExists() async {
    try {
      final exists = await RoleNavigationService.superAdminExists();
      if (mounted) {
        setState(() {
          _superAdminExists = exists;
          _isCheckingAdmin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _superAdminExists = false;
          _isCheckingAdmin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _organizationController.dispose();
    _adminCodeController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: LoadingOverlay(
        isLoading: authState.isLoading,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.secondaryGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildAuthForms(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: AppColors.superAdminColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: AppConstants.iconSmall,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Super Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          const AndcoLogo(size: 50, showShadow: true)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Super Admin Portal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Manage the entire platform with advanced controls',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildAuthForms() {
    if (_isCheckingAdmin) {
      return Container(
        margin: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.paddingXLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppConstants.paddingMedium),
                Text('Checking admin status...'),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar - only show if admin doesn't exist or show login only if admin exists
          if (!_superAdminExists) ...[
            Container(
              margin: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.superAdminColor,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Sign Up'),
                ],
              ),
            ),
          ] else ...[
            // Admin exists - show login only header
            Container(
              margin: const EdgeInsets.all(AppConstants.paddingMedium),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.superAdminColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.white),
                  SizedBox(width: AppConstants.paddingSmall),
                  Text(
                    'Super Admin Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Tab Views
          Expanded(
            child: _superAdminExists
                ? _buildSignInForm() // Only show login if admin exists
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSignInForm(),
                      _buildSignUpForm(),
                    ],
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 800.ms).slideY(begin: 0.3);
  }

  Widget _buildSignInForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Security Notice
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: _superAdminExists
                    ? AppColors.info.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(
                    color: _superAdminExists
                        ? AppColors.info.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _superAdminExists ? Icons.info : Icons.security,
                    color:
                        _superAdminExists ? AppColors.info : AppColors.warning,
                    size: AppConstants.iconMedium,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      _superAdminExists
                          ? 'Admin account exists - Sign in with your credentials'
                          : 'Restricted Access: Super Admin credentials required',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _superAdminExists
                                ? AppColors.info
                                : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            CustomTextField(
              controller: _emailController,
              label: 'Admin Email Address',
              hint: 'Enter your admin email',
              prefixIcon: Icons.admin_panel_settings_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: _validatePassword,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppColors.superAdminColor),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            ElevatedButton(
              onPressed: _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.superAdminColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // First Admin Setup Notice
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.success,
                    size: AppConstants.iconMedium,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      'First-time Super Admin setup - Use admin@andco.com',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              validator: _validateName,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            CustomTextField(
              controller: _emailController,
              label: 'Admin Email Address',
              hint: 'Enter your admin email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter your phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            CustomTextField(
              controller: _organizationController,
              label: 'Organization',
              hint: 'Enter your organization name',
              prefixIcon: Icons.business_outlined,
              validator: _validateOrganization,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            CustomTextField(
              controller: _adminCodeController,
              label: 'Admin Authorization Code',
              hint: 'Enter super admin code',
              prefixIcon: Icons.vpn_key_outlined,
              validator: _validateAdminCode,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            CustomTextField(
              controller: _departmentController,
              label: 'Department',
              hint: 'e.g., IT, Operations, Management',
              prefixIcon: Icons.work_outline,
              validator: _validateDepartment,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Create a strong password',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: _validateStrongPassword,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm your password',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => setState(() =>
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
              validator: _validateConfirmPassword,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            _buildTermsCheckbox(),

            const SizedBox(height: AppConstants.paddingLarge),

            ElevatedButton(
              onPressed: _agreeToTerms ? _signUp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.superAdminColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
              ),
              child: const Text(
                'Request Super Admin Access',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          activeColor: AppColors.superAdminColor,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.superAdminColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.superAdminColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(
                      text:
                          ', and confirm I have authorization for super admin access'),
                ],
              ),
            ),
          ),
        ),
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

    // No additional email restrictions during validation
    // Dynamic validation will be handled during signup/signin
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  String? _validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
        .hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, number and special character';
    }
    return null;
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
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateOrganization(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your organization name';
    }
    if (value.length < 3) {
      return 'Organization name must be at least 3 characters';
    }
    return null;
  }

  String? _validateAdminCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the admin authorization code';
    }
    if (value.length < 8) {
      return 'Admin code must be at least 8 characters';
    }
    return null;
  }

  String? _validateDepartment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your department';
    }
    if (value.length < 2) {
      return 'Department must be at least 2 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Action methods
  void _signIn() async {
    if (_loginFormKey.currentState!.validate()) {
      final email = _emailController.text.trim();

      // Check if this email can access super admin
      final canAccess = await RoleNavigationService.canAccessSuperAdmin(email);
      if (!canAccess) {
        final existingAdminEmail =
            await RoleNavigationService.getSuperAdminEmail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(existingAdminEmail != null
                  ? 'Super Admin access is restricted to $existingAdminEmail'
                  : 'No Super Admin account exists. Please sign up first.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        await ref
            .read(authControllerProvider.notifier)
            .signInWithEmailAndPassword(
              email,
              _passwordController.text,
            );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const SuperAdminDashboard()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _signUp() async {
    if (_signupFormKey.currentState!.validate()) {
      final email = _emailController.text.trim();

      // Check if this email can access super admin
      final canAccess = await RoleNavigationService.canAccessSuperAdmin(email);
      if (!canAccess) {
        final existingAdminEmail =
            await RoleNavigationService.getSuperAdminEmail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(existingAdminEmail != null
                  ? 'Super Admin access is restricted to $existingAdminEmail'
                  : 'Super Admin access is restricted'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        await ref
            .read(authControllerProvider.notifier)
            .signUpWithEmailAndPassword(
              email: email,
              password: _passwordController.text,
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              role: UserRole.superAdmin,
            );

        if (mounted) {
          // First admin signup successful - navigate to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Super Admin account created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SuperAdminDashboard(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Super Admin Password Reset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'For security reasons, Super Admin password reset requires special handling.'),
            const SizedBox(height: 16),
            const Text(
                'Please contact the system administrator or use one of these options:'),
            const SizedBox(height: 16),
            const Text('• Email: support@andco.com'),
            const Text('• Phone: +1 (555) 123-4567'),
            const Text('• Emergency: admin-reset@andco.com'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Super Admin access is restricted for security',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open email client or copy email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact information copied to clipboard'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.superAdminColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}
