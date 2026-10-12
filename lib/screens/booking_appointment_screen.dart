
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../services/api_service.dart';
//import 'stripe_card_screen.dart';
import 'authorize_net_card_screen.dart';
import 'main_screen.dart';

class BookingAppointmentScreen extends StatefulWidget {
  final String entryId; 
  final String userId;
  final String productTitle;
  final String productId;
  final String formId;
  final Map<String, dynamic>? programData;

  const BookingAppointmentScreen({
    super.key,
    required this.entryId,
    required this.userId,
    required this.productTitle,
    required this.productId,
    required this.formId,
    required this.programData,
  });

  @override
  State<BookingAppointmentScreen> createState() => _BookingAppointmentScreenState();
}

class _BookingAppointmentScreenState extends State<BookingAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  // Added ScrollController to programmatically handle targeted viewport focus shifts
  final ScrollController _scrollController = ScrollController();
  
  bool _isProcessing = false;

  final List<String> _statesList = ["Alabama","Alaska", "Arizona", "Arkansas", "California", "Colorado", 
  "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia", 
  "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", 
  "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", 
  "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", 
  "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", 
  "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", 
  "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", 
  "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", 
  "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"];

  final _billingFNameController = TextEditingController();
  final _billingLNameController = TextEditingController();
  final _billingEmailController = TextEditingController();
  final _billingPhoneController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingZipController = TextEditingController();
  final _notesController = TextEditingController();
  
  final _billingStateController = TextEditingController();

  double get baseAmount => double.tryParse(widget.programData?['product_price']?.toString() ?? '25.0') ?? 25.0;
  //double get processingFee => 0.88; 

double get processingFeeRate {
  String feeStr = widget.programData?['processing_fee']?.toString().replaceAll('%', '').trim() ?? '';
  double? parsedFee = double.tryParse(feeStr);
  if (parsedFee != null && parsedFee > 0) {
    return parsedFee / 100.0;
  }
  return 0.035; // Default fallback to 3.5%
}

double get processingFee {
  double rawFee = baseAmount * processingFeeRate;
  return double.parse(rawFee.toStringAsFixed(2));
}

  double get totalOrderAmount => baseAmount + processingFee;

  @override
  void initState() {
    super.initState();
    _loadInitialPassedData();
  }

  void _loadInitialPassedData() {
    if (widget.programData != null) {
      setState(() {
        _billingFNameController.text = widget.programData!['parent_first_name'] ?? "";
        _billingLNameController.text = widget.programData!['parent_last_name'] ?? "";
        _billingEmailController.text = widget.programData!['parent_email'] ?? "";
        
        String rawPhone = widget.programData!['parent_phone'] ?? "";
        if (rawPhone.length == 10) {
          _billingPhoneController.text = "(${rawPhone.substring(0, 3)}) ${rawPhone.substring(3, 6)}-${rawPhone.substring(6)}";
        } else {
          _billingPhoneController.text = rawPhone;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅ Clean hook allocation release
    _billingFNameController.dispose();
    _billingLNameController.dispose();
    _billingEmailController.dispose();
    _billingPhoneController.dispose();
    _billingAddressController.dispose();
    _billingCityController.dispose();
    _billingZipController.dispose();
    _billingStateController.dispose(); 
    _notesController.dispose();
    super.dispose();
  }

  // ✅ NEW METHOD: Breaks recursive tree parsing immediately upon discovering the first validation error node
  void _scrollToFirstValidationError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      bool foundFirstError = false;

      void scrollElement(Element element) {
        if (foundFirstError) return; 

        if (element.widget is FormField) {
          final FormFieldState state = (element as StatefulElement).state as FormFieldState;
          if (state.hasError) {
            foundFirstError = true; 
            
            final renderBox = element.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
              final offset = _scrollController.offset + position.dy - 140.0; // Comfort margin top padding room
              
              _scrollController.animateTo(
                offset < 0 ? 0 : offset,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
            return; 
          }
        }
        element.visitChildren(scrollElement);
      }
      context.visitChildElements(scrollElement);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            "Checkout",
            
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController, // ✅ Linked to active ScrollController layer instance
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    const Text("Billing details", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    _buildField("Email address *", _billingEmailController, "Email Address", keyboardType: TextInputType.emailAddress),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildField("First name *", _billingFNameController, "First Name")),
                        const SizedBox(width: 15),
                        Expanded(child: _buildField("Last name *", _billingLNameController, "Last Name")),
                      ],
                    ),
                    
                    _buildField("Street address *", _billingAddressController, "House number and street name"),
                    _buildField("Town / City *", _billingCityController, "City"),
                    _buildSearchableStateField("State *", _billingStateController, "Select State..."),
                    _buildField("ZIP Code *", _billingZipController, "ZIP Code", keyboardType: TextInputType.number),
                    _buildField("Phone *", _billingPhoneController, "Phone Number", keyboardType: TextInputType.phone),
                    _buildField("Order notes *", _notesController, "PLEASE INDICATE YOUR CHILD'S NAME(S) HERE", isMultiLine: true),
                    
                    const SizedBox(height: 15),
                    
                    const Text("Your order", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildOrderTable(),
                    
                    const SizedBox(height: 30),
                    _buildPlaceOrderButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            if (_isProcessing)
              Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: Colors.black.withOpacity(0.55), 
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFC790F),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFC790F)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label, 
    TextEditingController controller, 
    String hint, {
    TextInputType keyboardType = TextInputType.text, 
    bool isMultiLine = false,
  }) {
    bool isPhoneField = keyboardType == TextInputType.phone;
    bool isEmailField = keyboardType == TextInputType.emailAddress;
    bool isZipField = label.toLowerCase().contains("zip");
    
    bool isNameField = controller == _billingFNameController || controller == _billingLNameController;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            //keyboardType: isZipField ? TextInputType.number : keyboardType,
            keyboardType: isMultiLine ? TextInputType.multiline : (isZipField ? TextInputType.number : keyboardType),
            textCapitalization: isNameField ? TextCapitalization.words : TextCapitalization.none,
            maxLength: isZipField ? 9 : null, 
            maxLines: isMultiLine ? 3 : 1,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            
            style: const TextStyle(fontSize: 16),
            inputFormatters: [
              if (isPhoneField) ...[
                FilteringTextInputFormatter.digitsOnly,
                CustomPhoneTextInputFormatter(), 
              ],
              if (isZipField) ...[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              if (isEmailField || isNameField) ...[
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              if (!isNameField && !isEmailField && !isZipField && !isPhoneField) ...[
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.contains('  ')) {
                    return oldValue; 
                  }
                  return newValue; 
                }),
              ],
            ],
            decoration: InputDecoration(
              hintText: hint,
              
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (isPhoneField && _getRawDigits(v).length != 10) {
                return 'Must be exactly 10 digits';
              }
              // if (isZipField) {
              //   int len = v.trim().length;
              //   if (len != 5 && len != 9) {
              //     return 'US ZIP code must be 5 or 9 digits';
              //   }
              // }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableStateField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true, 
            
            style: const TextStyle(fontSize: 15),
            onTap: () async {
              final String? selectedState = await showSearch<String>(
                context: context,
                delegate: StateSearchDelegate(states: _statesList),
              );
              if (selectedState != null && selectedState.isNotEmpty) {
                setState(() {
                  controller.text = selectedState;
                });
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTable() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          _buildRow("Product", "Subtotal", isHeader: true),
          _buildRow("${widget.productTitle} × 1", "\$${baseAmount.toStringAsFixed(2)}"),
          _buildRow("Card Processing Fee (3.5%)", "\$${processingFee.toStringAsFixed(2)}"),
          _buildRow("Total", "\$${totalOrderAmount.toStringAsFixed(2)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildRow(String left, String right, {bool isHeader = false, bool isTotal = false}) {
    // Calculated row font size values dynamically
    double calculatedSize = isHeader || isTotal ? 16.0 : 15.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(left, style: TextStyle(fontSize: calculatedSize, fontWeight: isHeader || isTotal ? FontWeight.bold : FontWeight.normal))),
          Text(right, style: TextStyle(fontSize: calculatedSize, fontWeight: isHeader || isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? const Color(0xFFFC790F) : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFC790F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        onPressed: _isProcessing ? null : openStripeScreen,
        
        child: const Text("PLACE ORDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
      ),
    );
  }

  Future<void> _handlePayment(Map<String, dynamic> paymentResponse) async {
    setState(() => _isProcessing = true);

    final transactionId = paymentResponse["transaction_id"] ?? "";
    final customerId = paymentResponse["stripe_credit_card_customer_id"] ?? "";
    final paymentToken = paymentResponse["stripe_credit_card_payment_token"] ?? "";
    final last4 = paymentResponse["stripe_credit_card_account_four"] ?? "";
    final expiryDate = paymentResponse["stripe_credit_card_card_expiry_date"] ?? "";
    final cardType = paymentResponse["stripe_credit_card_card_type"] ?? "";
    final orderCurrency = paymentResponse["order_currency"] ?? "USD";
    final paidDate = paymentResponse["paid_date"] ?? "";
    final completedDate = paymentResponse["completed_date"] ?? "";
    final cartHash = paymentResponse["cart_hash"] ?? "";

    try {
      final Map<String, dynamic> bookingPayload = {
        "service_id": int.tryParse(widget.entryId) ?? 3,
        "service_name": widget.programData?['service_name'] ?? "",
        "service_price": baseAmount,
        "service_duration": widget.programData?['duration'] ?? "",
        "user_id": int.tryParse(widget.userId) ?? 0,
        "product_id": 39602,
        "fee_name": "Card Processing Fee (3.5%)",
        "Fees": processingFee,
        "role": "Amelia Customer",

        "appointment": {
          "booking_date": widget.programData?['workout_date'] ?? "",
          "booking_time": widget.programData!['workout_time'] ?? "",
          "booking_datetime": widget.programData!['workout_date'] ?? "",
          "timezone": "America/Los_Angeles",
          "location_id": 1
        },

        "customer": {
          "first_name": widget.programData?['parent_first_name'] ?? "",
          "last_name": widget.programData?['parent_last_name'] ?? "",
          "email": widget.programData?['parent_email'] ?? "",
          "phone": widget.programData?['parent_phone'] ?? "",
          "player_name": widget.programData?['player_name'] ?? "",
          "hear_about_us": widget.programData?['referral'] ?? "Other",
        },  
        "order_note": _notesController.text,
        "first_name": _billingFNameController.text,
        "last_name": _billingLNameController.text,
        "email": _billingEmailController.text,
        "phone": _billingPhoneController.text,//_getRawDigits(_billingPhoneController.text),
        "street_address": _billingAddressController.text,
        "city": _billingCityController.text,
        "state": _billingStateController.text, 
        "zipcode": _billingZipController.text,
        "country": "US",

        "payment_method": "authorize_net_cim_credit_card",
        "payment_method_title": "Credit Card",
        "wc_authorize_net_cim_credit_card_card_type": cardType,
        "order_currency": orderCurrency,
        "order_total": totalOrderAmount.toStringAsFixed(2),
        "stripe_credit_card_customer_id": customerId,
        "stripe_credit_card_payment_token": paymentToken,
        "stripe_credit_card_account_four": last4,
        "stripe_credit_card_card_expiry_date": expiryDate,
        "stripe_credit_card_card_type": cardType.toLowerCase(),
        "transaction_id": transactionId,
        "paid_date": paidDate,
        "completed_date": completedDate,
        "cart_hash": cartHash,
        "payment_status": "Active"
      };

      final result = await ApiService.bookingAppointment(
        formData: bookingPayload, 
        formType: "SinglePass",
      );

      if (result['success'] == true) {
        _showOrderConfirmation();
      } else {
        _showError(result['message'] ?? "Order API submission failed.");
      }
    } catch (e) {
      _showError("Payment processing exception error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showOrderConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            const Text("Order Confirmed!", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            Text("Your pass reservation for ${widget.productTitle} has been successfully configured.", style: const TextStyle(fontSize: 15)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
            
            child: const Text("BACK TO HOME", style: TextStyle(color: Color(0xFFFC790F), fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 14)), backgroundColor: Colors.red));
  }

  Future<void> openStripeScreen() async {
    if (!_formKey.currentState!.validate()) {
      //TRIGGERED ON ERROR: Traverses context layout structure to focus viewport scroll directly over the first required field failure
      _scrollToFirstValidationError();
      return;
    }

    FocusScope.of(context).unfocus();

    final paymentResponse = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorizeNetCardScreen(
          email: _billingEmailController.text,
          name: "${_billingFNameController.text} ${_billingLNameController.text}",
          amount: totalOrderAmount.toStringAsFixed(2),
          finalAmount: totalOrderAmount.toStringAsFixed(2),
          address: _billingAddressController.text,
          address2: "",
          city: _billingCityController.text,
          state: _billingStateController.text, 
          zipCode: _billingZipController.text,
          isSubscription: false,
          stripePriceId: "",
          subscriptionEvery: "",
          signUpFeeAmountWithFee: 0,
          stripeCouponId: "",
          isOpenShooting: false,
          firstName: _billingFNameController.text,
          lastName: _billingLNameController.text,
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });

    if (paymentResponse != null) {
      final status = paymentResponse["status"];
      if (status == "succeeded") {
        _handlePayment(paymentResponse);
      }
    }
  }

  String _getRawDigits(String text) {
    return text.replaceAll(RegExp(r'\D'), '');
  }
}

class StateSearchDelegate extends SearchDelegate<String> {
  final List<String> states;

  StateSearchDelegate({required this.states});

  @override
  String get searchFieldLabel => 'Search State...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0.5),
      inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.black54),
          onPressed: () => query = '',
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final filteredStates = states
        .where((state) => state.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filteredStates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          
          child: Text("No states found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStates.length,
      itemBuilder: (context, index) {
        final item = filteredStates[index];
        return ListTile(
          
          title: Text(item, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          onTap: () => close(context, item),
        );
      },
    );
  }
}

class CustomPhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    String digits = text.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 10) {
      return oldValue;
    }

    if (newValue.text.length < oldValue.text.length) {
      if (digits.length <= 3) {
        return TextEditingValue(
          text: digits,
          selection: TextSelection.collapsed(offset: digits.length),
        );
      }
      
      String masked = "";
      if (digits.isNotEmpty) {
        masked += "(${digits.substring(0, 3)})";
      }
      if (digits.length > 3) {
        masked += " ${digits.substring(3, digits.length > 6 ? 6 : digits.length)}";
      }
      if (digits.length > 6) {
        masked += " ${digits.substring(6)}";
      }
      return TextEditingValue(
        text: masked,
        selection: TextSelection.collapsed(offset: masked.length),
      );
    }

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;

    for (int i = 0; i < text.length; i++) {
      if (i == 0) {
        buffer.write('(${text[i]}');
        if (selectionIndex >= 1) selectionIndex++;
      } else if (i == 2) {
        buffer.write('${text[i]}) ');
        if (selectionIndex >= 3) selectionIndex += 2;
      } else if (i == 5) {
        buffer.write('${text[i]} ');
        if (selectionIndex >= 6) selectionIndex++;
      } else {
        buffer.write(text[i]);
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
