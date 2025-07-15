import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/enhanced_payment_service.dart';
import '../../core/theme/app_colors.dart';
import '../models/payment_model.dart';
import 'payment_method_selector.dart';

/// Comprehensive payment form widget
class PaymentFormWidget extends ConsumerStatefulWidget {
  final String userId;
  final String schoolId;
  final double? initialAmount;
  final String? description;
  final Function(PaymentResult)? onPaymentComplete;
  final Function(String)? onError;

  const PaymentFormWidget({
    super.key,
    required this.userId,
    required this.schoolId,
    this.initialAmount,
    this.description,
    this.onPaymentComplete,
    this.onError,
  });

  @override
  ConsumerState<PaymentFormWidget> createState() => _PaymentFormWidgetState();
}

class _PaymentFormWidgetState extends ConsumerState<PaymentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.description != null) {
      _descriptionController.text = widget.description!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount (\$)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Payment Method Selector
            PaymentMethodSelector(
              selectedMethod: _selectedMethod,
              onMethodSelected: (method) {
                setState(() {
                  _selectedMethod = method;
                  _errorMessage = null;
                });
              },
            ),

            // Phone Number Field (for M-Pesa)
            if (_selectedMethod == PaymentMethod.mpesa) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+254712345678',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
                validator: (value) {
                  if (_selectedMethod == PaymentMethod.mpesa) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^\+254\d{9}$').hasMatch(value)) {
                      return 'Please enter a valid Kenyan phone number (+254XXXXXXXXX)';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: AppConstants.paddingLarge),

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Process Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMethod == PaymentMethod.mpesa
                      ? Colors.green
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _getButtonText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            // Processing Message
            if (_isProcessing) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        _getProcessingMessage(),
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_selectedMethod == null) {
      return 'Select Payment Method';
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    final amountText = amount > 0 ? ' \$${amount.toStringAsFixed(2)}' : '';

    switch (_selectedMethod!) {
      case PaymentMethod.stripe:
        return 'Pay with Card$amountText';
      case PaymentMethod.mpesa:
        return 'Pay with M-Pesa$amountText';
      case PaymentMethod.bank:
        return 'Pay with Bank Transfer$amountText';
      case PaymentMethod.cash:
        return 'Pay with Cash$amountText';
    }
  }

  String _getProcessingMessage() {
    switch (_selectedMethod!) {
      case PaymentMethod.stripe:
        return 'Processing your card payment...';
      case PaymentMethod.mpesa:
        return 'Please check your phone and enter your M-Pesa PIN to complete the payment.';
      case PaymentMethod.bank:
        return 'Processing your bank transfer payment...';
      case PaymentMethod.cash:
        return 'Processing your cash payment...';
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMethod == null) {
      setState(() {
        _errorMessage = 'Please select a payment method';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;

      final request = PaymentRequest(
        userId: widget.userId,
        schoolId: widget.schoolId,
        amount: amount,
        currency: 'USD',
        description: description,
        paymentMethod: _selectedMethod!,
        phoneNumber: _selectedMethod == PaymentMethod.mpesa
            ? _phoneController.text.trim()
            : null,
      );

      final paymentService = ref.read(enhancedPaymentServiceProvider);
      final result = await paymentService.processPayment(request: request);

      if (result.success) {
        widget.onPaymentComplete?.call(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Payment of \$${amount.toStringAsFixed(2)} processed successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage =
              result.errorMessage ?? 'Payment failed. Please try again.';
        });
        widget.onError?.call(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      widget.onError?.call(_errorMessage!);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
