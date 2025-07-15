import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/mpesa_service.dart';
import '../../core/theme/app_colors.dart';

/// Widget for handling M-Pesa payments
class MPesaPaymentWidget extends ConsumerStatefulWidget {
  final double amount;
  final String accountReference;
  final String transactionDescription;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final VoidCallback? onCancel;

  const MPesaPaymentWidget({
    super.key,
    required this.amount,
    required this.accountReference,
    required this.transactionDescription,
    this.onSuccess,
    this.onError,
    this.onCancel,
  });

  @override
  ConsumerState<MPesaPaymentWidget> createState() => _MPesaPaymentWidgetState();
}

class _MPesaPaymentWidgetState extends ConsumerState<MPesaPaymentWidget> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isProcessing = false;
  String? _errorMessage;
  String? _checkoutRequestId;
  Timer? _statusTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Image.asset(
                  'assets/images/mpesa_logo.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.phone_android, color: Colors.green),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                const Text(
                  'M-Pesa Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Amount display
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.transactionDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'KSh ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Phone number input
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: '0712345678 or 254712345678',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                enabled: !_isProcessing,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your M-Pesa phone number';
                }
                if (!MPesaService.instance.isValidPhoneNumber(value)) {
                  return 'Please enter a valid Kenyan phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Payment status
            if (_isProcessing && _checkoutRequestId != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: AppConstants.paddingSmall),
                        Expanded(
                          child: Text(
                            'Check your phone for M-Pesa PIN prompt',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    const LinearProgressIndicator(),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      'Waiting for payment confirmation...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            // Payment button
            ElevatedButton(
              onPressed: _isProcessing ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: AppConstants.paddingSmall),
                        Text('Processing...'),
                      ],
                    )
                  : const Text(
                      'Pay with M-Pesa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),

            // Cancel button
            TextButton(
              onPressed: _isProcessing ? null : () => widget.onCancel?.call(),
              child: const Text('Cancel'),
            ),

            const SizedBox(height: AppConstants.paddingSmall),

            // Info text
            Text(
              'You will receive an M-Pesa PIN prompt on your phone. Enter your PIN to complete the payment.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final response = await MPesaService.instance.stkPush(
        phoneNumber: _phoneController.text.trim(),
        amount: widget.amount,
        accountReference: widget.accountReference,
        transactionDesc: widget.transactionDescription,
      );

      if (response['ResponseCode'] == '0') {
        _checkoutRequestId = response['CheckoutRequestID'];
        _startStatusPolling();
      } else {
        setState(() {
          _errorMessage = response['CustomerMessage'] ?? 'Payment initiation failed';
        });
        widget.onError?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
      widget.onError?.call();
    } finally {
      if (mounted && _checkoutRequestId == null) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_checkoutRequestId == null) {
        timer.cancel();
        return;
      }

      try {
        final status = await MPesaService.instance.queryStkPushStatus(
          checkoutRequestId: _checkoutRequestId!,
        );

        if (status['ResultCode'] == '0') {
          // Payment successful
          timer.cancel();
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
          widget.onSuccess?.call();
        } else if (status['ResultCode'] != null && status['ResultCode'] != '1032') {
          // Payment failed (1032 means still pending)
          timer.cancel();
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _errorMessage = status['ResultDesc'] ?? 'Payment failed';
            });
          }
          widget.onError?.call();
        }
      } catch (e) {
        // Continue polling on error, but stop after 2 minutes
        if (timer.tick > 40) { // 40 * 3 seconds = 2 minutes
          timer.cancel();
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _errorMessage = 'Payment timeout. Please try again.';
            });
          }
          widget.onError?.call();
        }
      }
    });
  }

  String _getErrorMessage(dynamic error) {
    if (error is MPesaException) {
      return error.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
