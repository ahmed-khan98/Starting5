
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class AuthorizeNetCardScreen extends StatefulWidget {
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
  final String firstName;
  final String lastName;

  const AuthorizeNetCardScreen({
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
    required this.firstName,
    required this.lastName,
  });

  @override
  State<AuthorizeNetCardScreen> createState() => _AuthorizeNetCardScreenState();
}

class _AuthorizeNetCardScreenState extends State<AuthorizeNetCardScreen> {
  // Live Keys
  final String apiLoginId = "4AB4DgXcc2Nh";
  final String clientKey = "28p528bq2533C84d8PSDSYEtsJcqd9Pd44Nu6zLy3YbTQ3y6qkLFhjy6ACHTx3x6";
  final String apiTransactionKey = "732v69W67f3GLwb7";
  final bool isSandbox = false;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  late WebViewController _webViewController;
  Completer<Map<String, String>>? _tokenCompleter;
  bool _loading = false;
  bool _isWebViewReady = false;

  String get apiUrl => isSandbox
      ? "https://apitest.authorize.net/xml/v1/request.api"
      : "https://api.authorize.net/xml/v1/request.api";

  String get acceptJsUrl => isSandbox
      ? "https://jstest.authorize.net/v1/Accept.js"
      : "https://js.authorize.net/v1/Accept.js";

  @override
  void initState() {
    super.initState();
    _initAcceptJsWebView();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _getStateCode(String inputState) {
    const Map<String, String> usStates = {
      "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
      "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
      "District of Columbia": "DC", "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
      "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
      "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
      "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
      "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
      "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
      "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
      "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
      "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
      "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
      "Wisconsin": "WI", "Wyoming": "WY"
    };

    final clean = inputState.trim();
    if (clean.length == 2) return clean.toUpperCase();
    return usStates[clean] ?? "CA";
  }

  void _initAcceptJsWebView() {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <script type="text/javascript" src="$acceptJsUrl" charset="utf-8"></script>
      <script type="text/javascript">
        function tokenizeCard(cardNumber, expMonth, expYear, cardCode) {
          var secureData = {};
          var cardData = {};
          
          cardData.cardNumber = cardNumber;
          cardData.month = expMonth;
          cardData.year = expYear;
          cardData.cardCode = cardCode;
          secureData.cardData = cardData;
          secureData.authData = {
            clientKey: "$clientKey",
            apiLoginID: "$apiLoginId"
          };

          Accept.dispatchData(secureData, responseHandler);
        }

        function responseHandler(response) {
          if (response.messages.resultCode === "Error") {
            var i = 0;
            var errorMsg = "";
            while (i < response.messages.message.length) {
              errorMsg += response.messages.message[i].text + " ";
              i = i + 1;
            }
            TokenChannel.postMessage(JSON.stringify({ "status": "error", "message": errorMsg }));
          } else {
            TokenChannel.postMessage(JSON.stringify({
              "status": "success",
              "dataDescriptor": response.opaqueData.dataDescriptor,
              "dataValue": response.opaqueData.dataValue
            }));
          }
        }
      </script>
    </head>
    <body></body>
    </html>
    ''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TokenChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (_tokenCompleter != null && !_tokenCompleter!.isCompleted) {
            final res = jsonDecode(message.message);
            if (res["status"] == "success") {
              _tokenCompleter!.complete({
                "dataDescriptor": res["dataDescriptor"],
                "dataValue": res["dataValue"],
              });
            } else {
              _tokenCompleter!.completeError(
                Exception(res["message"] ?? "Failed to tokenize card."),
              );
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              _isWebViewReady = true;
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent, baseUrl: 'https://localhost');
  }

  Future<void> makePayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete card details")),
      );
      return;
    }

    if (!_isWebViewReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Initializing secure payment channel. Please retry.")),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() {
        _loading = true;
      });

      final expParts = _expiryController.text.trim().split('/');
      final expMonth = expParts[0];
      final expYear = "20${expParts[1]}";
      final cleanCardNum = _cardNumberController.text.replaceAll(' ', '');

      _tokenCompleter = Completer<Map<String, String>>();
      
      final script = "tokenizeCard('$cleanCardNum', '$expMonth', '$expYear', '${_cvvController.text.trim()}')";
      await _webViewController.runJavaScript(script);

      final tokenData = await _tokenCompleter!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Payment Gateway timeout. Please try again."),
      );

      if (!mounted) return;

      /// STEP 1: CREATE CUSTOMER & PAYMENT PROFILE (CIM)
      final customerData = await createCustomerProfile(
        dataDescriptor: tokenData["dataDescriptor"]!,
        dataValue: tokenData["dataValue"]!,
      );

      final customerProfileId = customerData["customerProfileId"] ?? "";
      final paymentProfileId = customerData["customerPaymentProfileId"] ?? "";

      if (customerProfileId.isEmpty || paymentProfileId.isEmpty) {
        throw Exception("Invalid profile details received from payment gateway.");
      }

      /// STEP 2: OPTION A - DIRECT AUTHORIZE.NET TRANSACTION VIA CUSTOMER PROFILE
      /// Both One-Time items and Subscriptions process direct charges; WooCommerce Subscriptions
      /// handles future recurring cycles using the saved CIM tokens.
      debugPrint("Executing Direct Authorize.Net CIM Transaction via Customer Profile...");
      
      final paymentIntent = await createOneTimeTransaction(
        customerProfileId: customerProfileId,
        paymentProfileId: paymentProfileId,
      );

      final finalStatus = paymentIntent["status"] ?? "";
      final transactionId = paymentIntent["transactionId"] ?? "";

      if (finalStatus != "succeeded") {
        throw Exception("Payment process failed: ${paymentIntent["errorMessage"]}");
      }

      final last4 = cleanCardNum.substring(cleanCardNum.length - 4);
      final now = DateTime.now();

      final paymentData = {
        "payment_method": "authorize_net_cim_credit_card",
        "payment_method_title": "Credit Card (Authorize.Net)",
        "order_currency": "USD",
        "order_total": widget.amount,
        "stripe_credit_card_customer_id": customerProfileId,
        "stripe_credit_card_payment_token": paymentProfileId,
        "stripe_credit_card_account_four": last4,
        "stripe_credit_card_card_expiry_date": "$expMonth/$expYear",
        "stripe_credit_card_card_type": _getCardType(cleanCardNum),
        "transaction_id": transactionId,
        "paid_date": now.toIso8601String(),
        "completed_date": now.toIso8601String(),
        "cart_hash": generateCartHash(),
        "status": "succeeded",
        "is_subscription": widget.isSubscription ? "1" : "0",
        "subscription_id": transactionId, // WooCommerce links transaction to sub
        "subscription_status": "active",
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

  Future<Map<String, String>> createCustomerProfile({
    required String dataDescriptor,
    required String dataValue,
  }) async {
    final requestBody = {
      "createCustomerProfileRequest": {
        "merchantAuthentication": {
          "name": apiLoginId,
          "transactionKey": apiTransactionKey,
        },
        "profile": {
          "merchantCustomerId": "CUST_${DateTime.now().millisecondsSinceEpoch}",
          "description": "App User: ${widget.name}",
          "email": widget.email.isNotEmpty ? widget.email : "user@example.com",
          "paymentProfiles": {
            "customerType": "individual",
            "billTo": {
              "firstName": widget.firstName.isNotEmpty ? widget.firstName : "Customer",
              "lastName": widget.lastName.isNotEmpty ? widget.lastName : "User",
              "address": widget.address.isNotEmpty ? widget.address : "123 Main St",
              "city": widget.city.isNotEmpty ? widget.city : "City",
              "state": _getStateCode(widget.state),
              "zip": widget.zipCode.isNotEmpty ? widget.zipCode : "90210",
              "country": "US"
            },
            "payment": {
              "opaqueData": {
                "dataDescriptor": dataDescriptor,
                "dataValue": dataValue,
              }
            }
          }
        },
        "validationMode": isSandbox ? "testMode" : "liveMode"
      }
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    final decoded = jsonDecode(response.body);
    final messages = decoded["messages"];

    if (messages != null && messages["resultCode"] == "Ok") {
      final profileId = decoded["customerProfileId"]?.toString() ?? "";
      String paymentProfileId = "";
      
      if (decoded["customerPaymentProfileIdList"] != null &&
          (decoded["customerPaymentProfileIdList"] as List).isNotEmpty) {
        paymentProfileId = decoded["customerPaymentProfileIdList"][0].toString();
      }

      if (profileId.isEmpty || paymentProfileId.isEmpty) {
        throw Exception("Failed to generate valid Customer Profile record.");
      }

      return {
        "customerProfileId": profileId,
        "customerPaymentProfileId": paymentProfileId,
      };
    } else {
      final errorText = messages?["message"]?[0]?["text"] ?? "Could not create Customer Profile.";
      final errorCode = messages?["message"]?[0]?["code"] ?? "";
      throw Exception("[$errorCode] $errorText");
    }
  }

  Future<Map<String, dynamic>> createOneTimeTransaction({
    required String customerProfileId,
    required String paymentProfileId,
  }) async {
    final requestBody = {
      "createTransactionRequest": {
        "merchantAuthentication": {
          "name": apiLoginId,
          "transactionKey": apiTransactionKey,
        },
        "transactionRequest": {
          "transactionType": "authCaptureTransaction",
          "amount": double.parse(widget.finalAmount).toStringAsFixed(2),
          "profile": {
            "customerProfileId": customerProfileId,
            "paymentProfile": {
              "paymentProfileId": paymentProfileId,
            }
          }
        }
      }
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    final decoded = jsonDecode(response.body);
    final transactionResponse = decoded["transactionResponse"];

    if (transactionResponse != null && transactionResponse["responseCode"] == "1") {
      return {
        "status": "succeeded",
        "transactionId": transactionResponse["transId"]?.toString() ?? "",
      };
    } else {
      String err = "Transaction failed.";
      if (transactionResponse != null && transactionResponse["errors"] != null) {
        final e = transactionResponse["errors"][0];
        err = "Code ${e['errorCode']}: ${e['errorText']}";
      } else if (decoded["messages"] != null && decoded["messages"]["message"] != null) {
        final m = decoded["messages"]["message"][0];
        err = "Code ${m['code']}: ${m['text']}";
      }
      return {
        "status": "failed",
        "errorMessage": err,
      };
    }
  }

  void _showFailureDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 10),
              const Text(
                "Transaction Failed",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            errorMessage.isEmpty ? "Card Declined!" : errorMessage,
            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "TRY AGAIN",
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'Visa';
    if (cardNumber.startsWith(RegExp(r'^(5[1-5]|2[2-7])'))) return 'MasterCard';
    if (cardNumber.startsWith(RegExp(r'^3[47]'))) return 'American Express';
    if (cardNumber.startsWith('6011')) return 'Discover';
    return 'Unknown';
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
          SizedBox(
            height: 1,
            width: 1,
            child: WebViewWidget(controller: _webViewController),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
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
                          
                          TextFormField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                            ],
                            validator: (val) {
                              if (val == null || val.length < 13) {
                                return "Enter a valid card number";
                              }
                              return null;
                            },
                            decoration: _inputDecoration("Card Number"),
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                    _ExpiryInputFormatter(),
                                  ],
                                  validator: (val) {
                                    if (val == null || val.length < 5) {
                                      return "MM/YY required";
                                    }
                                    return null;
                                  },
                                  decoration: _inputDecoration("MM/YY"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _cvvController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: (val) {
                                    if (val == null || val.length < 3) {
                                      return "Invalid CVV";
                                    }
                                    return null;
                                  },
                                  decoration: _inputDecoration("CVV"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

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
          ),

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

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }
}

class _ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}