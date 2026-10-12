
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeCardScreen extends StatefulWidget {
  final String email;
  final String name;
  final String amount; 
  final String finalAmount; 
  final String address;
  final String address2;
  final String city;
  final String state;
  final String zipCode;
  final bool isSubscription;
  final String stripePriceId; 
  final String subscriptionEvery;
  final double signUpFeeAmountWithFee; 
  final String? stripeCouponId; 
  final String? recurringSubtotalOverride; 
  final bool isOpenShooting;

  const StripeCardScreen({
    super.key,
    required this.email,
    required this.name,
    required this.amount,
    required this.finalAmount,
    required this.address,
    required this.address2,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.isSubscription,
    required this.stripePriceId,
    required this.subscriptionEvery,
    required this.signUpFeeAmountWithFee, 
    this.stripeCouponId,
    this.recurringSubtotalOverride,
    required this.isOpenShooting,
  });

  @override
  State<StripeCardScreen> createState() => _StripeCardScreenState();
}

class _StripeCardScreenState extends State<StripeCardScreen> {
  CardFieldInputDetails? _card;
  bool _loading = false;
//sk_live_"""
//D4XhNdWFgi40NjNOjiT1XOE3
  final String secretKey = "";
      //51JMWebSIh5ESgj82s9vIFnNCGUv5WBcfmJIlq1VwAYcaXs8WGoQ5XFJs0AuvI4BMhLQDPGlkP2x15BbtpBTBywTv00duBrPLpJ";
//"sk_test_"""
  Future<void> makePayment() async {
    if (_card == null || !(_card?.complete ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter complete card details"),
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _loading = true;
      });

      /// STEP 1: CREATE PAYMENT METHOD
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email: widget.email,
              name: widget.name,
              address: Address(
                city: widget.city,
                country: "US",
                line1: widget.address,
                line2: widget.address2,
                postalCode: widget.zipCode,
                state: widget.state,
              ),
            ),
          ),
        ),
      );

      if (!mounted) return;

      /// STEP 2: CREATE CUSTOMER
      final customerData = await createCustomer(
        paymentMethodId: paymentMethod.id,
        address: widget.address,
        address2: widget.address2,
        city: widget.city,
        state: widget.state,
        zipCode: widget.zipCode,
      );

      if (!mounted) return;

      final customerId = customerData["id"];
      String transactionId = "";
      String finalStatus = "";
      String extractedSubscriptionId = "";
      Map<String, dynamic>? subscriptionResponse;

      if (widget.isSubscription) {
        print("Executing createSubscription lifecycle routing immediately...");
        subscriptionResponse = await createSubscription(
          customerId: customerId,
          paymentMethodId: paymentMethod.id,
          trialEnd: "", 
        );

        if (!mounted) return;

        extractedSubscriptionId = subscriptionResponse["id"]?.toString() ?? "";
        finalStatus = subscriptionResponse["status"]?.toString() ?? "";
        transactionId = extractedSubscriptionId;

        if (finalStatus == "incomplete" || finalStatus == "incomplete_expired" || extractedSubscriptionId.isEmpty) {
          throw Exception("Subscription registration status is incomplete. Requires additional authentication or different card.");
        }
      } else {
        print("Executing createPaymentIntent direct transaction routing...");
        final paymentIntent = await createPaymentIntent(
          customerId: customerId,
          paymentMethodId: paymentMethod.id,
        );

        if (!mounted) return;

        finalStatus = paymentIntent["status"] ?? "";
        transactionId = paymentIntent["id"] ?? "";

        if (finalStatus != "succeeded") {
          throw Exception("Direct payment process failed with status: $finalStatus");
        }
      }

      final card = paymentMethod.card;
      final now = DateTime.now();

      final paymentData = {
        "payment_method": "stripe",
        "payment_method_title": widget.isSubscription
            ? "Stripe Subscription"
            : "Credit Card (Stripe)",
        "order_currency": "USD",
        "order_total": widget.amount,
        "stripe_credit_card_customer_id": customerId,
        "stripe_credit_card_payment_token": paymentMethod.id,
        "stripe_credit_card_account_four": card.last4,
        "stripe_credit_card_card_expiry_date":
            "${card.expMonth.toString().padLeft(2, '0')}/${card.expYear}",
        "stripe_credit_card_card_type": card.brand ?? "",
        "transaction_id": transactionId,
        "paid_date": now.toIso8601String(),
        "completed_date": now.toIso8601String(),
        "cart_hash": generateCartHash(),
        "status": "succeeded", 
        "is_subscription": widget.isSubscription ? "1" : "0",
        "subscription_id": extractedSubscriptionId, 
        "subscription_status": widget.isSubscription ? finalStatus : "",
      };

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isSubscription
                ? "Subscription Successful!"
                : "Payment Successful!",
          ),
        ),
      );

      navigator.pop(paymentData);

    } catch (e) {
      debugPrint("PAYMENT RUNTIME FAULT: ${e.toString()}");
      if (mounted) {
        _showFailureDialog(e.toString().replaceAll("Exception: ", ""));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // void _showFailureDialog(String errorMessage) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (BuildContext ctx) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //         title: Row(
  //           children: [
  //             Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
  //             const SizedBox(width: 10),
  //             const Text(
  //               "Transaction Failed",
  //               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //             ),
  //           ],
  //         ),
  //         content: Text(
  //           "Card Declined!",
  //           style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(ctx),
  //             child: Text(
  //               "TRY AGAIN",
  //               style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 14),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

void _showFailureDialog(String errorMessage) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext ctx) {
      final screenWidth = MediaQuery.of(ctx).size.width;
      final isSmallScreen = screenWidth < 360;

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: isSmallScreen ? 24 : 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Transaction Failed",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "Card Declined!",
          // errorMessage,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "TRY AGAIN",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
          ),
        ],
      );
    },
  );
}

  Future<Map<String, dynamic>> createInvoiceItem({
    required String customerId,
    required String amount,
    required String description,
  }) async {
    final amountInCents = (double.parse(amount) * 100).toInt().toString();

    final response = await http.post(
      Uri.parse("https://api.stripe.com/v1/invoiceitems"),
      headers: {
        "Authorization": "Bearer $secretKey",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "customer": customerId,
        "amount": amountInCents,
        "currency": "usd",
        "description": description,
      },
    );

    final decoded = jsonDecode(response.body);
    if (decoded["error"] != null) {
      throw Exception(decoded["error"]["message"] ?? "Failed to register up-front sign-up fee.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createCustomer({
    required String paymentMethodId,
    required String address,
    required String address2,
    required String city,
    required String state,
    required String zipCode,
  }) async {
    final response = await http.post(
      Uri.parse("https://api.stripe.com/v1/customers"),
      headers: {
        "Authorization": "Bearer $secretKey",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "email": widget.email,
        "name": widget.name,
        "payment_method": paymentMethodId,
        "address[line1]": address,
        "address[line2]": address2,
        "address[city]": city,
        "address[state]": state,
        "address[country]": "US",
        "address[postal_code]": zipCode,
      },
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String customerId,
    required String paymentMethodId,
  }) async {
    final amountInCents =
        (double.parse(widget.amount) * 100).toInt().toString();

    final response = await http.post(
      Uri.parse("https://api.stripe.com/v1/payment_intents"),
      headers: {
        "Authorization": "Bearer $secretKey",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "amount": amountInCents,
        "currency": "usd",
        "customer": customerId,
        "payment_method": paymentMethodId,
        "confirm": "true",
        "off_session": "true",
        "description": "Payment for ${widget.name}",
        "shipping[name]": widget.name,
        "shipping[address][line1]": widget.address,
        "shipping[address][city]": widget.city,
        "shipping[address][state]": widget.state,
        "shipping[address][postal_code]": widget.zipCode,
        "shipping[address][country]": "US",
      },
    );

    final decoded = jsonDecode(response.body);
    if (decoded["error"] != null) {
      throw Exception(decoded["error"]["message"] ?? "Payment Intent failed.");
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required String paymentMethodId,
    required String trialEnd,
  }) async {
    final Map<String, String> requestBody = {
      "customer": customerId,
      "default_payment_method": paymentMethodId,
      "expand[]": "latest_invoice.payment_intent",
      "description": "Subscription for ${widget.name}",
    };

    if (widget.recurringSubtotalOverride != null) {
      int ongoingCents = (double.parse(widget.recurringSubtotalOverride!) * 100).round();
      
      requestBody["items[0][price_data][unit_amount]"] = ongoingCents.toString();
      requestBody["items[0][price_data][currency]"] = "usd";
      
      String cleanInterval = widget.subscriptionEvery.toLowerCase().trim();
      if (cleanInterval.contains("day")) cleanInterval = "day";
      if (cleanInterval.contains("week")) cleanInterval = "week";
      if (cleanInterval.contains("month")) cleanInterval = "month";
      if (cleanInterval.contains("year")) cleanInterval = "year";
      
      requestBody["items[0][price_data][recurring][interval]"] = cleanInterval;
      requestBody["items[0][price_data][product]"] = widget.isOpenShooting ? "prod_UnBkOKLpwLYz7X" : "prod_UnBncOm5SUSjem";//"prod_Ugp8kGW3q5fF2w" : "prod_Ua7ijkH8N52LcJ"; 

      bool hasReturn40 = widget.stripeCouponId?.toLowerCase().contains("return40") ?? false;

      // Note: "comp" checks inside createSubscription are kept as fallback logic.
      // Since "comp" coupon checkouts now bypass this entire card payment execution screen entirely,
      // it handles regular coupon options safely.
      if (widget.signUpFeeAmountWithFee > 0.01 && !hasReturn40) {
        print("Adding sign-up fee natively to first invoice: \$${widget.signUpFeeAmountWithFee}");
        await createInvoiceItem(
          customerId: customerId,
          amount: widget.signUpFeeAmountWithFee.toStringAsFixed(2),
          description: "One-Time Sign-Up Fee (with processing fee configurations)",
        );
      }
    } else {
      requestBody["items[0][price]"] = widget.stripePriceId;
    }

    final response = await http.post(
      Uri.parse("https://api.stripe.com/v1/subscriptions"),
      headers: {
        "Authorization": "Bearer $secretKey",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: requestBody,
    );

    final decoded = jsonDecode(response.body);
    if (decoded["error"] != null) {
      throw Exception(decoded["error"]["message"] ?? "Subscription creation failed.");
    }
    return decoded;
  }

  String generateCartHash() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Add Card",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Card Details",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your payment information securely",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 25),

                  /// STRIPE CARD FIELD CONTAINER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Credit / Debit Card",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        CardField(
                          autofocus: false,
                          enablePostalCode: false,
                          dangerouslyGetFullCardDetails: true,
                          decoration: InputDecoration(
                            hintText: "4242 4242 4242 4242",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          onCardChanged: (card) {
                            setState(() {
                              _card = card;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  /// ACTION PAYMENT CONTEXT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: size.height * 0.065,
                    child: ElevatedButton(
                      onPressed: _loading ? null : makePayment,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.isSubscription
                            ? "SUBSCRIBE \$${widget.finalAmount}"
                            : "PAY \$${widget.finalAmount}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          /// LOADING STATUS INTERCEPTION SHIELD
          if (_loading)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}