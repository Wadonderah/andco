import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../models/payment_model.dart';

/// Widget for selecting payment method
class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod) onMethodSelected;
  final bool showMpesa;
  final bool showStripe;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
    this.showMpesa = true,
    this.showStripe = true,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  PaymentMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        if (widget.showStripe)
          _buildPaymentMethodCard(
            method: PaymentMethod.stripe,
            title: 'Credit or Debit Card',
            subtitle: 'Visa, Mastercard, American Express',
            icon: Icons.credit_card,
            color: AppColors.primary,
          ),
        if (widget.showStripe && widget.showMpesa)
          const SizedBox(height: AppConstants.paddingMedium),
        if (widget.showMpesa)
          _buildPaymentMethodCard(
            method: PaymentMethod.mpesa,
            title: 'M-Pesa',
            subtitle: 'Mobile money payment',
            icon: Icons.phone_android,
            color: Colors.green,
          ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
        widget.onMethodSelected(method);
      },
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying payment status
class PaymentStatusIndicator extends StatelessWidget {
  final PaymentStatus status;
  final double? size;

  const PaymentStatusIndicator({
    super.key,
    required this.status,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final text = _getStatusText(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size != null ? size! * 0.6 : 8,
        vertical: size != null ? size! * 0.3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size != null ? size! * 0.8 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: size ?? 16,
          ),
          SizedBox(width: size != null ? size! * 0.3 : 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: size != null ? size! * 0.8 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return AppColors.success;
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.failed:
        return AppColors.error;
      case PaymentStatus.cancelled:
        return AppColors.textSecondary;
      case PaymentStatus.refunded:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.access_time;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.refresh;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Widget for displaying payment amount
class PaymentAmountDisplay extends StatelessWidget {
  final double amount;
  final String currency;
  final TextStyle? style;
  final Color? color;

  const PaymentAmountDisplay({
    super.key,
    required this.amount,
    this.currency = 'USD',
    this.style,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = _getCurrencySymbol(currency);

    return Text(
      '$currencySymbol${amount.toStringAsFixed(2)}',
      style: style?.copyWith(color: color) ??
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'KES':
        return 'KSh ';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$currency ';
    }
  }
}

/// Widget for payment method icon
class PaymentMethodIcon extends StatelessWidget {
  final PaymentMethod method;
  final double? size;

  const PaymentMethodIcon({
    super.key,
    required this.method,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getMethodIcon(method);
    final color = _getMethodColor(method);

    return Icon(
      iconData,
      size: size ?? 24,
      color: color,
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return Icons.credit_card;
      case PaymentMethod.mpesa:
        return Icons.phone_android;
      case PaymentMethod.bank:
        return Icons.account_balance;
      case PaymentMethod.cash:
        return Icons.money;
    }
  }

  Color _getMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return AppColors.primary;
      case PaymentMethod.mpesa:
        return Colors.green;
      case PaymentMethod.bank:
        return Colors.blue;
      case PaymentMethod.cash:
        return Colors.orange;
    }
  }
}

/// Widget for loading payment state
class PaymentLoadingIndicator extends StatelessWidget {
  final String? message;

  const PaymentLoadingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
