import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../models/payment_model.dart';
import 'payment_method_selector.dart';

/// Widget for displaying payment summary information
class PaymentSummaryCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onTap;
  final bool showActions;
  final Function(String)? onActionSelected;

  const PaymentSummaryCard({
    super.key,
    required this.payment,
    this.onTap,
    this.showActions = false,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Payment Method Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getMethodColor(payment.paymentMethod)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PaymentMethodIcon(
                      method: payment.paymentMethod,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: AppConstants.paddingMedium),

                  // Payment Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a')
                              .format(payment.createdAt),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PaymentAmountDisplay(
                        amount: payment.amount,
                        currency: payment.currency,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PaymentStatusIndicator(
                        status: payment.status,
                        size: 12,
                      ),
                    ],
                  ),

                  // Actions Menu
                  if (showActions)
                    PopupMenuButton<String>(
                      onSelected: onActionSelected,
                      itemBuilder: (context) => _buildActionMenuItems(),
                      child: const Icon(Icons.more_vert),
                    ),
                ],
              ),

              // Additional Details (if expanded)
              if (_shouldShowDetails()) ...[
                const SizedBox(height: AppConstants.paddingMedium),
                const Divider(),
                const SizedBox(height: AppConstants.paddingMedium),
                _buildDetailsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowDetails() {
    return payment.stripePaymentIntentId != null ||
        payment.mpesaReceiptNumber != null ||
        payment.failureReason != null;
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        _buildDetailRow('Transaction ID', payment.id),
        if (payment.stripePaymentIntentId != null)
          _buildDetailRow('Stripe Payment ID', payment.stripePaymentIntentId!),
        if (payment.mpesaReceiptNumber != null)
          _buildDetailRow('M-Pesa Receipt', payment.mpesaReceiptNumber!),
        if (payment.phoneNumber != null)
          _buildDetailRow('Phone Number', payment.phoneNumber!),
        if (payment.failureReason != null)
          _buildDetailRow('Failure Reason', payment.failureReason!,
              isError: true),
        _buildDetailRow(
            'Payment Method', _getMethodText(payment.paymentMethod)),
        _buildDetailRow('Currency', payment.currency.toUpperCase()),
        _buildDetailRow('Created',
            DateFormat('MMM dd, yyyy at hh:mm a').format(payment.createdAt)),
        if (payment.updatedAt != payment.createdAt)
          _buildDetailRow('Updated',
              DateFormat('MMM dd, yyyy at hh:mm a').format(payment.updatedAt)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? AppColors.error : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildActionMenuItems() {
    final items = <PopupMenuEntry<String>>[];

    items.add(const PopupMenuItem(
      value: 'view_details',
      child: Text('View Details'),
    ));

    if (payment.status == PaymentStatus.completed) {
      items.add(const PopupMenuItem(
        value: 'download_receipt',
        child: Text('Download Receipt'),
      ));

      items.add(const PopupMenuItem(
        value: 'refund',
        child: Text('Request Refund'),
      ));
    }

    if (payment.status == PaymentStatus.failed) {
      items.add(const PopupMenuItem(
        value: 'retry',
        child: Text('Retry Payment'),
      ));
    }

    items.add(const PopupMenuItem(
      value: 'copy_id',
      child: Text('Copy Transaction ID'),
    ));

    return items;
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

  String _getMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.stripe:
        return 'Credit Card';
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
}

/// Widget for displaying payment statistics
class PaymentStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? trend;

  const PaymentStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget for payment method breakdown chart
class PaymentMethodBreakdown extends StatelessWidget {
  final Map<PaymentMethod, double> data;
  final double total;

  const PaymentMethodBreakdown({
    super.key,
    required this.data,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Methods Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...data.entries.map((entry) {
            final method = entry.key;
            final amount = entry.value;
            final percentage = total > 0 ? (amount / total) * 100 : 0;

            return _buildBreakdownItem(
                method, amount.toDouble(), percentage.toDouble());
          }),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
      PaymentMethod method, double amount, double percentage) {
    final color =
        method == PaymentMethod.stripe ? AppColors.primary : Colors.green;
    final methodText =
        method == PaymentMethod.stripe ? 'Credit Cards' : 'M-Pesa';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PaymentMethodIcon(method: method, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    methodText,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              PaymentAmountDisplay(amount: amount),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
