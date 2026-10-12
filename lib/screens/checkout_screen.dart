
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
//import 'stripe_card_screen.dart';
import 'main_screen.dart';
import '../services/session_manager.dart';
import 'authorize_net_card_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String entryId;
  final String userId;
  final String productTitle;
  final String productId;
  final String formId;
  final String cityStr;
  final String stateStr;
  final String zipStr;
  final String phoneStr;
  final Map<String, dynamic>? programData;

  const CheckoutScreen({
    super.key,
    required this.entryId,
    required this.userId,
    required this.productTitle,
    required this.productId,
    required this.formId,
    required this.programData,
    required this.cityStr,
    required this.stateStr,
    required this.zipStr,
    required this.phoneStr,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  
  bool _isProcessing = false;
  bool _shipToDifferentAddress = false;

  // Coupon UI Control Hooks
  bool _showCouponField = false;
  bool _isValidatingCoupon = false;
  String? _couponErrorMessage;
  
  // Stacked active coupons tracker array list (Enforces max 2 cap natively)
  List<String> _appliedCoupons = []; 
  final _couponInputController = TextEditingController();

  final List<String> _statesList = 
  ["Alabama","Alaska", "Arizona", "Arkansas", "California", "Colorado", 
  "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia", 
  "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", 
  "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", 
  "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", 
  "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", 
  "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", 
  "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", 
  "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", 
  "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"];

  // Primary Billing Controllers
  final _emailController = TextEditingController();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _billingStateController = TextEditingController();

  // Alternative Shipping Controllers
  final _shipFNameController = TextEditingController();
  final _shipLNameController = TextEditingController();
  final _shipAddressController = TextEditingController();
  final _shipAddress2Controller = TextEditingController();
  final _shipCityController = TextEditingController();
  final _shipZipController = TextEditingController();
  final _shipPhoneController = TextEditingController();
  final _shippingStateController = TextEditingController();

  bool get isSubscription => widget.programData?['subscription']?.toString().toLowerCase() == 'yes';
  
  double get baseAmount {
    String pricingKey = isSubscription ? 'subscription_price' : 'product_price';
    return double.tryParse(widget.programData?[pricingKey]?.toString() ?? '') ?? 0.0;
  }

  double get signUpFee => double.tryParse(widget.programData?['sign_up_fee']?.toString() ?? '') ?? 0.0;
  
  //double get processingFeeRate => 0.035; 
  double get processingFeeRate {
  String feeStr = widget.programData?['processing_fee']?.toString().replaceAll('%', '').trim() ?? '';
  double? parsedFee = double.tryParse(feeStr);
  if (parsedFee != null && parsedFee > 0) {
    return parsedFee / 100.0;
  }
  return 0.035; // Default fallback to 3.5%
}

  // Multi-coupon stacking valuation engine helper
  double _getSingleCouponDeduction(String coupon) {
    String cleanCode = coupon.toLowerCase().trim();
    if (cleanCode == 'return40') {
      return signUpFee; 
    } else if (cleanCode == 'sibling25') {
      return 25.0;
    } else if (cleanCode == 'comp') {
      return baseAmount + signUpFee;
    }
    return 0.0;
  }

  double get couponDeduction {
    double totalDeduction = 0.0;
    for (var coupon in _appliedCoupons) {
      totalDeduction += _getSingleCouponDeduction(coupon);
    }
    return totalDeduction;
  }
  
  double get rawUpfrontSubtotal => baseAmount + signUpFee;

  // Initial checkout subtotal exactly after deducting applied coupons
  double get initialSubtotal {
    double total = rawUpfrontSubtotal - couponDeduction;
    return total < 0 ? 0.0 : total;
  }

  bool get hasCompCoupon => _appliedCoupons.any((c) => c.toLowerCase().trim() == 'comp');

  // Recalculated Processing Fee: Now dynamically hits the POST-COUPON subtotal balance
  double get calculatedProcessingFee {
    if (hasCompCoupon || initialSubtotal <= 0) return 0.00;
    return double.parse((initialSubtotal * processingFeeRate).toStringAsFixed(2));
  }

  // Day 1 Net Sign-Up Fee after potential return40 slash deductions
  double get netSignUpFee {
    if (hasCompCoupon) return 0.0;
    double deduction = 0.0;
    if (_appliedCoupons.any((c) => c.toLowerCase().trim() == 'return40')) {
      deduction += signUpFee;
    }
    double result = signUpFee - deduction;
    return result < 0 ? 0.0 : result;
  }

  double get signUpProcessingFee {
    if (hasCompCoupon || netSignUpFee <= 0) return 0.0;
    return double.parse((netSignUpFee * processingFeeRate).toStringAsFixed(2));
  }

  double get signUpFeeAmountWithFee {
    if (hasCompCoupon || netSignUpFee <= 0) return 0.0;
    return double.parse((netSignUpFee + signUpProcessingFee).toStringAsFixed(2));
  }

  // Total order checkout payment amount
  double get totalOrderAmount {
    //  "comp" coupon zeroes out upfront checkout amount entirely for both subscription & one-time items
    if (hasCompCoupon || initialSubtotal <= 0) return 0.00;
    double finalAmount = initialSubtotal + calculatedProcessingFee;
    return double.parse(finalAmount.toStringAsFixed(2));
  }

  // --- RECURRING SUBSCRIPTION PRICING CALCULATION LAYER ---
  double get recurringSubtotal {
    //  "comp" coupon forces recurring subscription values down to absolute zero 
    if (hasCompCoupon) return 0.00;
    double deduction = 0.0;
    if (_appliedCoupons.any((c) => c.toLowerCase().trim() == 'sibling25')) {
      deduction += 25.0;
    }
    double result = baseAmount - deduction;
    return result < 0 ? 0.0 : result;
  }

  // Recalculated Recurring Processing Fee: Derived strictly from post-coupon recurring subtotal
  double get recurringFee {
    if (recurringSubtotal <= 0) return 0.00;
    return double.parse((recurringSubtotal * processingFeeRate).toStringAsFixed(2));
  }

  double get recurringTotal {
    if (recurringSubtotal <= 0) return 0.00;
    double total = recurringSubtotal + recurringFee;
    return double.parse(total.toStringAsFixed(2));
  }

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  void loadUserName() async {
    String? firstName = await SessionManager.getUserFirstName();
    String? lastName = await SessionManager.getUserLastName();
    String? email = await SessionManager.getUserEmail();

    if (mounted) {
      setState(() {
        _fNameController.text = (firstName ?? "").replaceAll(' ', '').trim();
        _lNameController.text = (lastName ?? "").replaceAll(' ', '').trim();
        _emailController.text = (email ?? "").replaceAll(' ', '').trim();
        _cityController.text = widget.cityStr;
        _billingStateController.text = widget.stateStr;
        _zipController.text = widget.zipStr;
        _phoneController.text = widget.phoneStr;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); 
    _emailController.dispose();
    _fNameController.dispose();
    _lNameController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _billingStateController.dispose(); 
    _shipFNameController.dispose();
    _shipLNameController.dispose();
    _shipAddressController.dispose();
    _shipAddress2Controller.dispose();
    _shipCityController.dispose();
    _shippingStateController.dispose(); 
    _couponInputController.dispose();
    _shipPhoneController.dispose();
    super.dispose();
  }

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
              final offset = _scrollController.offset + position.dy - 140.0; 
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

  Future<void> _validateCouponCode() async {
    String enteredCode = _couponInputController.text.trim();
    if (enteredCode.isEmpty) return;

    if (_appliedCoupons.length >= 2) {
      setState(() {
        _couponErrorMessage = "Maximum of 2 coupons can be applied concurrently.";
      });
      return;
    }

    if (_appliedCoupons.any((c) => c.toLowerCase() == enteredCode.toLowerCase())) {
      setState(() {
        _couponErrorMessage = "This specific coupon code has already been applied.";
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isValidatingCoupon = true;
      _couponErrorMessage = null;
    });

    String lowerCode = enteredCode.toLowerCase();
    if (lowerCode == 'return40' && !isSubscription) {
      setState(() {
        _isValidatingCoupon = false;
        _couponErrorMessage = 'The coupon code "return40" is not applicable to the selected product.';
      });
      return;
    } else if (lowerCode == 'return40' && signUpFee == 0) {
      setState(() {
        _isValidatingCoupon = false;
        _couponErrorMessage = 'The coupon code "return40" is not applicable to the selected product.';
      });
      return;
    }

    if (lowerCode == 'sibling25' && !isSubscription) {
      setState(() {
        _isValidatingCoupon = false;
        _couponErrorMessage = 'The coupon code "sibling25" is not applicable to the selected product.';
      });
      return;
    } else if (lowerCode == 'sibling25' && signUpFee == 0) {
      setState(() {
        _isValidatingCoupon = false;
        _couponErrorMessage = 'The coupon code "sibling25" is not applicable to the selected product.';
      });
      return;
    }

    // if (lowerCode == 'comp' && isSubscription && signUpFee == 0) {
    //   setState(() {
    //     _isValidatingCoupon = false;
    //     _couponErrorMessage = 'The coupon code "comp" is not applicable to the selected product.';
    //   });
    //   return;
    // }
    final response = await ApiService.checkCouponCode(enteredCode);
    if (!mounted) return;
    
    setState(() {
      _isValidatingCoupon = false;
      if (response['success'] == true) {
        _appliedCoupons.add(enteredCode);
        _couponErrorMessage = null;
        _couponInputController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Coupon code applied successfully!")),
        );
      } else {
        if (lowerCode == 'return40' || lowerCode == 'comp' || lowerCode == 'sibling25') {
          _couponErrorMessage = 'The coupon code "$enteredCode" is not applicable to the selected product.';
        } else {
          _couponErrorMessage = 'The coupon code "$enteredCode" cannot be applied because it does not exist.';
        }
      }
    });
  }

  Future<void> _removeCouponCode(String code) async {
    setState(() => _isProcessing = true);
    try {
      final response = await http.get(
        Uri.parse("https://starting5.net/api/remove-coupan.php?coupon_code=${code.trim()}"),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _appliedCoupons.remove(code);
          _couponErrorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Coupon '$code' removed successfully.")),
        );
      } else {
        throw Exception("Server registry verification drop failed.");
      }
    } catch (e) {
      _showError("Failed to remove coupon code: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
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
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController, 
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCouponToggleBlock(),
                      const SizedBox(height: 20),

                      const Text("Billing details", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      
                      _buildField("Email address *", _emailController, "Email Address", keyboardType: TextInputType.emailAddress),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildField("First name *", _fNameController, "First Name")),
                          const SizedBox(width: 15),
                          Expanded(child: _buildField("Last name *", _lNameController, "Last Name")),
                        ],
                      ),
                      
                      _buildField("Street address *", _addressController, "House number and street name"),
                      _buildField("", _address2Controller, "Apartment, suite, unit, etc. (optional)", isRequired: false),
                      _buildField("Town / City *", _cityController, "City"),
                      _buildSearchableStateField("State *", _billingStateController, "Select State..."),
                      _buildField("ZIP Code *", _zipController, "ZIP Code", keyboardType: TextInputType.number),
                      _buildField("Phone *", _phoneController, "Phone Number", keyboardType: TextInputType.phone),
                      _buildField("Order notes *", _notesController, "PLEASE INDICATE YOUR CHILD'S NAME(S) HERE", maxLines: 3),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _shipToDifferentAddress,
                              onChanged: (val) => setState(() => _shipToDifferentAddress = val ?? false),
                              activeColor: const Color(0xFFFC790F),
                            ),
                            const Text("Ship to a different address?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                      
                      if (_shipToDifferentAddress) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 20),
                          child: Text("Shipping Details", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildField("First name *", _shipFNameController, "First Name")),
                            const SizedBox(width: 15),
                            Expanded(child: _buildField("Last name *", _shipLNameController, "Last Name")),
                          ],
                        ),
                        _buildField("Street address *", _shipAddressController, "House number and street name"),
                        _buildField("", _shipAddress2Controller, "Apartment, suite, unit, etc. (optional)", isRequired: false),
                        _buildField("Town / City *", _shipCityController, "City"),
                        _buildSearchableStateField("State *", _shippingStateController, "Select State..."),
                        _buildField("ZIP Code *", _shipZipController, "ZIP Code", keyboardType: TextInputType.number),
                        _buildField("Phone *", _shipPhoneController, "Phone Number", keyboardType: TextInputType.phone),
                      ],

                      const SizedBox(height: 15),
                      const Text("Your order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        child: CircularProgressIndicator(color: Color(0xFFFC790F)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponToggleBlock() {
    bool isAnyApplied = _appliedCoupons.isNotEmpty;

    return GestureDetector(
      onTap: () => setState(() => _showCouponField = !_showCouponField),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xffF4F3F7),
              border: Border(top: BorderSide(color: isAnyApplied ? Colors.green : Colors.blue.shade400, width: 3.5)),
            ),
            child: Row(
              children: [
                Icon(isAnyApplied ? Icons.bookmark : Icons.bookmark_outline, color: isAnyApplied ? Colors.green : Colors.blue.shade700, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text( 
                    isAnyApplied 
                        ? _appliedCoupons.length == 1 ? "Coupon Active: ${_appliedCoupons.join(', ').toUpperCase()}"  : "Coupons Active: ${_appliedCoupons.join(', ').toUpperCase()}"
                        : "Have a coupon? Click here to enter your code",
                    style: const TextStyle(fontSize: 14.5, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          if (_showCouponField) ...[
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {}, 
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: isAnyApplied ? Colors.green.shade300 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponInputController,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: "Coupon code",
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderSide: BorderSide(color: _couponErrorMessage != null ? Colors.red : Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _couponErrorMessage != null ? Colors.red : Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _couponErrorMessage != null ? Colors.red : Colors.blue)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffD0CDE1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            onPressed: _isValidatingCoupon ? null : _validateCouponCode,
                            child: _isValidatingCoupon
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                                : const Text("APPLY COUPON", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13.5)),
                          ),
                        ),
                      ],
                    ),
                    if (_couponErrorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(_couponErrorMessage!, style: const TextStyle(color: Color(0xffBA2B2B), fontSize: 13, height: 1.3)),
                    ],
                    
                    if (_appliedCoupons.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 5),
                      Text(
                        _appliedCoupons.length == 1 ? "Active Coupon:" : "Active Coupons:", 
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _appliedCoupons.map((coupon) {
                          return Chip(
                            backgroundColor: Colors.green.shade50,
                            side: BorderSide(color: Colors.green.shade200),
                            label: Text(coupon.toUpperCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                            deleteIcon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                            onDeleted: () => _removeCouponCode(coupon),
                          );
                        }).toList(),
                      )
                    ]
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool isRequired = true}) {
    bool isPhoneField = keyboardType == TextInputType.phone;
    bool isEmailField = keyboardType == TextInputType.emailAddress;
    bool isZipField = label.toLowerCase().contains("zip");
    bool isNameField = controller == _fNameController || controller == _lNameController || controller == _shipFNameController || controller == _shipLNameController;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
          ],
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isZipField ? TextInputType.number : keyboardType,
            textCapitalization: isNameField ? TextCapitalization.words : TextCapitalization.none,
            maxLength: isPhoneField ? null : (isZipField ? 9 : null),
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            style: const TextStyle(fontSize: 16),
            inputFormatters: [
              if (isPhoneField) ...[FilteringTextInputFormatter.digitsOnly, CustomPhoneTextInputFormatter()],
              if (isZipField) ...[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
              if (isNameField || isEmailField || isZipField) ...[FilteringTextInputFormatter.deny(RegExp(r'\s')),],
              if (!isNameField && !isEmailField && !isZipField && !isPhoneField) ...[
                TextInputFormatter.withFunction((oldValue, newValue) => newValue.text.contains('  ') ? oldValue : newValue),
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
              if (isRequired && (v == null || v.trim().isEmpty)) return 'Required';
              if (v != null && v.trim().isNotEmpty && isPhoneField) {
                if (v.replaceAll(RegExp(r'\D'), '').length != 10) return 'Must be exactly 10 digits.';
              }
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
          if (label.isNotEmpty) ...[
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
          ],
          TextFormField(
            controller: controller,
            readOnly: true, 
            style: const TextStyle(fontSize: 15),
            onTap: () async {
              final String? selectedState = await showSearch<String>(context: context, delegate: StateSearchDelegate(states: _statesList));
              if (selectedState != null && selectedState.isNotEmpty) {
                setState(() => controller.text = selectedState);
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
    String interval = widget.programData?['subscription_every']?.toString() ?? 'month';
    String processingFeeLabel = (processingFeeRate * 100).toStringAsFixed(1);
    
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          _buildRow("Product", "Subtotal", isHeader: true),
          
          _buildProductRow("${widget.productTitle} × 1", "\$${baseAmount.toStringAsFixed(2)}"),
          
          if (signUpFee > 0) _buildRow("Sign-Up Fee", "\$${signUpFee.toStringAsFixed(2)}"),
          _buildRow("Subtotal", "\$${rawUpfrontSubtotal.toStringAsFixed(2)}"),
          
          if (_appliedCoupons.isNotEmpty) ...[
            ..._appliedCoupons.map((coupon) {
              double deductionValue = _getSingleCouponDeduction(coupon);
              bool isComp = coupon.toLowerCase().trim() == 'comp';
              
              return _buildRowWithAction(
                "Coupon: ${coupon.toLowerCase()}", 
                "-\$${deductionValue.toStringAsFixed(2)}",
                isCompCouponWithSubscription: isComp && isSubscription,
                onAction: () => _removeCouponCode(coupon),
              );
            }),
          ],

          _buildRow("Card Processing Fee ($processingFeeLabel%)", "\$${calculatedProcessingFee.toStringAsFixed(2)}"),
          _buildRow("Total", "\$${totalOrderAmount.toStringAsFixed(2)}", isTotal: true),
          
          if (isSubscription) ...[
            const Divider(height: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.grey.shade50,
              child: const Text("Recurring total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            _buildRow("Subtotal", "\$${hasCompCoupon ? "0.00" : baseAmount.toStringAsFixed(2)} / $interval"),
            
            if (_appliedCoupons.any((c) => c.toLowerCase().trim() == 'sibling25')) ...[
              _buildRowWithAction(
                "Coupon: sibling25", 
                "-\$25.00",
                onAction: () => _removeCouponCode('sibling25'),
              ),
            ],

            _buildRow("Card Processing Fee ($processingFeeLabel%)", "\$${recurringFee.toStringAsFixed(2)}"),
            _buildRow("Recurring total", "\$${recurringTotal.toStringAsFixed(2)} / $interval", isTotal: true),
          ]
        ],
      ),
    );
  }

  Widget _buildProductRow(String productTitle, String subtotalPrice) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                productTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, height: 1.3),
              ),
            ),
          ),
          Text(
            subtotalPrice,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String left, String right, {bool isHeader = false, bool isTotal = false}) {
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

  Widget _buildRowWithAction(String left, String right, {bool isCompCouponWithSubscription = false, required VoidCallback onAction}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(left, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onAction,
                      child: const Text(
                        "[Remove]", 
                        style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                      ),
                    ),
                  ],
                ),
              ),
              Text(right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.black)),
            ],
          ),
          // if (isCompCouponWithSubscription) ...[
          //   const SizedBox(height: 4),
          //   const Text(
          //     "\$0.00 will be applicable to use this coupon", 
          //     style: TextStyle(fontSize: 12.5, color: Colors.red, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    // Bypasses Stripe completely and targets direct free checkout logic if the "comp" coupon is present
    bool isFreeBypass = hasCompCoupon;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFC790F), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
        ),
        onPressed: _isProcessing ? null : (isFreeBypass ? processFreeCheckout : openStripeScreen),
        child: const Text(
          "PLACE ORDER", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)
        ),
      ),
    );
  }

  Future<void> _handlePayment(Map<String, dynamic> paymentResponse) async {
    setState(() => _isProcessing = true);

    String transactionKey = isSubscription ? 'subscription_id' : 'transaction_id';
    final transactionId = paymentResponse[transactionKey] ?? "";
    final customerId = paymentResponse["stripe_credit_card_customer_id"] ?? "";
    final paymentToken = paymentResponse["stripe_credit_card_payment_token"] ?? "";
    final last4 = paymentResponse["stripe_credit_card_account_four"] ?? "";
    final expiryDate = paymentResponse["stripe_credit_card_card_expiry_date"] ?? "";
    final cardType = paymentResponse["stripe_credit_card_card_type"] ?? "";
    final orderCurrency = paymentResponse["order_currency"] ?? "USD";
    final paidDate = paymentResponse["paid_date"] ?? "";
    final completedDate = paymentResponse["completed_date"] ?? "";
    final cartHash = paymentResponse["cart_hash"] ?? "";
    
    String couponIdstr = _appliedCoupons.isNotEmpty ? _appliedCoupons.join(',').toLowerCase() : "";
    if (couponIdstr.contains("comp")) {
      couponIdstr = "comp";
    }
    try {
      final Map<String, String> submissionData = {
        "user_id": widget.userId,
        "post_id": widget.entryId,
        "product_id": widget.productId,
        "form_id": widget.formId,
        "order_note": _notesController.text,
        "subscription": isSubscription ? "Yes" : "No",
        "first_name": _fNameController.text,
        "last_name": _lNameController.text,
        "street_address": _addressController.text,
        "city": _cityController.text,
        "state": _billingStateController.text, 
        "zipcode": _zipController.text,
        "phone": _phoneController.text,
        "email": _emailController.text,
        "country": 'US',
        "fee_name": "Card Processing Fee (3.5%)",
        "qty": "1",
        "product_price": isSubscription ? "" : baseAmount.toStringAsFixed(2),
        "order_total": totalOrderAmount.toStringAsFixed(2),
        "fee_amount": calculatedProcessingFee.toStringAsFixed(2),
        "shipping_method": "Free shipping",
        "shipping_method_id": "free_shipping",
        "shipping_total": "0",
        "subscription_price": isSubscription ? (widget.programData?['subscription_price']?.toString() ?? '') : "",
        "subscription_every": isSubscription ? (widget.programData?['subscription_every']?.toString() ?? '') : "",
        "price_id": isSubscription ?  (widget.programData?['price_id']?.toString() ?? '') : "",
        "sign_up_fee": isSubscription ?  (widget.programData?['sign_up_fee']?.toString() ?? '') : "",
        "payment_method": hasCompCoupon ? "free_comp_bypass" : "authorize_net_cim_credit_card",
        "payment_method_title": hasCompCoupon ? "Complimentary Access" : "Credit Card",
        "order_currency": orderCurrency,
        "stripe_credit_card_customer_id" : customerId,
        "stripe_credit_card_payment_token" : paymentToken,
        "stripe_credit_card_account_four" : last4,
        "stripe_credit_card_card_expiry_date" : expiryDate,
        "stripe_credit_card_card_type" : cardType,
        "transaction_id" : transactionId,
        "paid_date" : paidDate,
        "completed_date" : completedDate,
        "cart_hash" : cartHash,
        "fee_percentage": "3.5",
        if (couponIdstr.isNotEmpty) "coupon_code": couponIdstr
      };

      if (_shipToDifferentAddress) {
        submissionData.addAll({
          "shipping_first_name": _shipFNameController.text,
          "shipping_last_name": _shipLNameController.text,
          "shipping_address_1": _shipAddressController.text,
          "shipping_address_2": _shipAddress2Controller.text,
          "shipping_city": _shipCityController.text,
          "shipping_state": _shippingStateController.text, 
          "shipping_zipcode": _shipZipController.text,
          "shipping_country": 'US',
          "shipping_company": '',
          "shipping_phone": _shipPhoneController.text
        });
      } else {
        submissionData.addAll({
          "shipping_first_name": '', "shipping_last_name": '', "shipping_address_1": '', "shipping_address_2": '',
          "shipping_city": '', "shipping_state": '', "shipping_zipcode": '', "shipping_country": '',
          "shipping_company": '', "shipping_phone": ''
        });
      }

      final result = await ApiService.checkoutForm(formData: submissionData, formType: isSubscription ? "Subscription" : "OneTime");
      if (result['success'] == true) {
        _showOrderConfirmation();
      } else {
        _showError(result['message'] ?? "Order API failed.");
      }
    } catch (e) {
      _showError("Payment processing exception error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> processFreeCheckout() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstValidationError();
      return;
    }
    FocusScope.of(context).unfocus();

    final String freeId = "free_comp_${DateTime.now().millisecondsSinceEpoch}";
    final mockFreePayload = {
      "status": "succeeded",
      "subscription_id": freeId,
      "transaction_id": freeId,
      "stripe_credit_card_customer_id": "free_customer_account",
      "stripe_credit_card_payment_token": "free_token_bypass",
      "stripe_credit_card_account_four": "0000",
      "stripe_credit_card_card_expiry_date": "00/00",
      "stripe_credit_card_card_type": "COMP_COUPON_FREE",
      "order_currency": "USD",
      "paid_date": DateTime.now().toIso8601String(),
      "completed_date": DateTime.now().toIso8601String(),
      "cart_hash": DateTime.now().millisecondsSinceEpoch.toString(),
    };

    _handlePayment(mockFreePayload);
  }

  Future<void> openStripeScreen() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstValidationError();
      return;
    }
    FocusScope.of(context).unfocus();

    String priceIdKey = isSubscription ? 'price_id' : 'product_price_id';
    String priceId = widget.programData?[priceIdKey] ?? '';
    
    double upfrontTotalAmount = totalOrderAmount; 
    double ongoingRecurringAmount = recurringTotal; 

    final paymentResponse = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorizeNetCardScreen(
          email: _emailController.text.trim(),
          name: "${_fNameController.text.trim()} ${_lNameController.text.trim()}",
          amount: upfrontTotalAmount.toStringAsFixed(2), 
          finalAmount: upfrontTotalAmount.toStringAsFixed(2), 
          address: _addressController.text.trim(),
          address2: _address2Controller.text.trim(),
          city: _cityController.text.trim(),
          state: _billingStateController.text.trim(), 
          zipCode: _zipController.text.trim(),
          isSubscription: isSubscription,
          stripePriceId: priceId,
          subscriptionEvery: isSubscription ? (widget.programData?['subscription_every']?.toString() ?? '') : "",
          signUpFeeAmountWithFee: signUpFeeAmountWithFee, 
          stripeCouponId: _appliedCoupons.isNotEmpty ? _appliedCoupons.join(',').toLowerCase() : "", 
          recurringSubtotalOverride: ongoingRecurringAmount.toStringAsFixed(2), 
          isOpenShooting: (widget.productTitle.contains("Open Shooting")) ? true : false,
          firstName: _fNameController.text,
          lastName: _lNameController.text,
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });

    if (paymentResponse != null && paymentResponse["status"] == "succeeded") {
      _handlePayment(paymentResponse);
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
            Text("Your registration for ${widget.productTitle} has been processed.", style: const TextStyle(fontSize: 15)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (route) => false),
            child: const Text("BACK TO HOME", style: TextStyle(color: Color(0xFFFC790F), fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 14)), backgroundColor: Colors.red));
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
    return [if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear, color: Colors.black54), onPressed: () => query = '')];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final filteredStates = states.where((state) => state.toLowerCase().contains(query.toLowerCase())).toList();
    if (filteredStates.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No states found.", style: TextStyle(color: Colors.grey, fontSize: 16))));
    }
    return ListView.builder(
      itemCount: filteredStates.length,
      itemBuilder: (context, index) {
        final item = filteredStates[index];
        return ListTile(title: Text(item, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)), onTap: () => close(context, item));
      },
    );
  }
}

class CustomPhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    String digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) return oldValue;

    if (newValue.text.length < oldValue.text.length) {
      if (digits.length <= 3) return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
      String masked = "";
      if (digits.isNotEmpty) masked += "(${digits.substring(0, 3)})";
      if (digits.length > 3) masked += " ${digits.substring(3, digits.length > 6 ? 6 : digits.length)}";
      if (digits.length > 6) masked += " ${digits.substring(6)}";
      return TextEditingValue(text: masked, selection: TextSelection.collapsed(offset: masked.length));
    }

    if (newValue.selection.baseOffset == 0) return newValue;
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
    return TextEditingValue(text: buffer.toString(), selection: TextSelection.collapsed(offset: selectionIndex));
  }
}