import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  late Razorpay _razorpay;

  Function(String)? onPaymentSuccess;
  Function(String)? onPaymentError;

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment Success: ${response.paymentId}");
    if (onPaymentSuccess != null) {
      onPaymentSuccess!(response.paymentId ?? "unknown");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment Error: ${response.code} - ${response.message}");
    if (onPaymentError != null) {
      onPaymentError!(response.message ?? "Payment failed");
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
  }

  Future<void> openCheckout(String planId, String email, String contact) async {
    try {
      // Call our secure Cloud Function to create an order
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createRazorpayOrder');
      final result = await callable.call(<String, dynamic>{
        'planId': planId,
      });

      final orderId = result.data['orderId'];
      final amount = result.data['amount'];
      final currency = result.data['currency'];

      var options = {
        'key': 'YOUR_KEY_ID', // Replaced by server ideally or just use public key here
        'amount': amount,
        'currency': currency,
        'name': 'BondNex Premium',
        'order_id': orderId,
        'description': 'Unlock Premium Features',
        'timeout': 300,
        'prefill': {
          'contact': contact,
          'email': email
        }
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint("Checkout Error: $e");
      if (onPaymentError != null) {
        onPaymentError!(e.toString());
      }
    }
  }
}
