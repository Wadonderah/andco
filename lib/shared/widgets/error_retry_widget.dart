import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// A reusable error widget with retry functionality
class ErrorRetryWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final String retryButtonText;
  final IconData icon;
  final Color? iconColor;
  final bool showDetails;
  final Widget? customAction;

  const ErrorRetryWidget({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
    this.retryButtonText = 'Retry',
    this.icon = Icons.error_outline,
    this.iconColor,
    this.showDetails = false,
    this.customAction,
  });

  /// Factory constructor for network errors
  factory ErrorRetryWidget.network({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorRetryWidget(
      title: 'Connection Error',
      message: 'Please check your internet connection and try again.',
      details: details,
      onRetry: onRetry,
      icon: Icons.wifi_off,
      iconColor: AppColors.error,
    );
  }

  /// Factory constructor for initialization errors
  factory ErrorRetryWidget.initialization({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorRetryWidget(
      title: 'Initialization Failed',
      message: 'Something went wrong while starting the app.',
      details: details,
      onRetry: onRetry,
      icon: Icons.refresh,
      iconColor: AppColors.error,
    );
  }

  /// Factory constructor for permission errors
  factory ErrorRetryWidget.permission({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorRetryWidget(
      title: 'Permission Required',
      message: 'This feature requires additional permissions to work properly.',
      details: details,
      onRetry: onRetry,
      retryButtonText: 'Grant Permission',
      icon: Icons.security,
      iconColor: AppColors.warning,
    );
  }

  /// Factory constructor for authentication errors
  factory ErrorRetryWidget.authentication({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorRetryWidget(
      title: 'Authentication Error',
      message: 'There was a problem with your login. Please try again.',
      details: details,
      onRetry: onRetry,
      retryButtonText: 'Try Again',
      icon: Icons.lock_outline,
      iconColor: AppColors.error,
    );
  }

  /// Factory constructor for data loading errors
  factory ErrorRetryWidget.dataLoading({
    VoidCallback? onRetry,
    String? details,
  }) {
    return ErrorRetryWidget(
      title: 'Loading Failed',
      message: 'Unable to load data. Please try again.',
      details: details,
      onRetry: onRetry,
      icon: Icons.cloud_off,
      iconColor: AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.error).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: iconColor ?? AppColors.error,
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Error title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Error message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Error details (expandable)
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              _buildDetailsSection(context),
            ],
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Error Details',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            details!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Retry button
        if (onRetry != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryButtonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor ?? AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
              ),
            ),
          ),
        
        // Custom action
        if (customAction != null) ...[
          const SizedBox(height: AppConstants.paddingMedium),
          customAction!,
        ],
      ],
    );
  }
}

/// A loading widget with customizable message and progress
class LoadingStateWidget extends StatefulWidget {
  final String message;
  final String? subMessage;
  final double? progress;
  final bool showProgress;
  final Color? color;
  final Widget? customIndicator;

  const LoadingStateWidget({
    super.key,
    this.message = 'Loading...',
    this.subMessage,
    this.progress,
    this.showProgress = false,
    this.color,
    this.customIndicator,
  });

  @override
  State<LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<LoadingStateWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading indicator
              widget.customIndicator ??
                  CircularProgressIndicator(
                    color: widget.color ?? AppColors.primary,
                    strokeWidth: 3,
                  ),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Loading message
              Text(
                widget.message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Sub message
              if (widget.subMessage != null) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  widget.subMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              // Progress bar
              if (widget.showProgress && widget.progress != null) ...[
                const SizedBox(height: AppConstants.paddingLarge),
                _buildProgressBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200 * (widget.progress ?? 0),
                height: 6,
                decoration: BoxDecoration(
                  color: widget.color ?? AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Text(
          '${((widget.progress ?? 0) * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Empty state widget for when there's no data
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;
  final Widget? customAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Empty state title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // Empty state message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action button
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
            
            // Custom action
            if (customAction != null) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              customAction!,
            ],
          ],
        ),
      ),
    );
  }
}
