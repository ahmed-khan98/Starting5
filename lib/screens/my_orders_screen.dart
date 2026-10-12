import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ================= 1. UPDATED DYNAMIC MODEL =================
class OrderModel {
  final String orderId, date, status, total, subtotal, shipping, paymentMethod;
  final String name, address, phone, email;
  final String shippingName, shippingAddress, shippingPhone;
  final List<String> productNames;

  OrderModel({
    required this.orderId,
    required this.date,
    required this.status,
    required this.total,
    required this.subtotal,
    required this.shipping,
    required this.paymentMethod,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.shippingName,
    required this.shippingAddress,
    required this.productNames,
    required this.shippingPhone,
  });

  static String _formatPhoneIfNeeded(String phoneInput) {
    String cleanString = phoneInput.trim();
    if (cleanString.isEmpty) return "N/A";
    if (cleanString.contains('(') || cleanString.contains(')') || cleanString.contains('-')) {
      return cleanString;
    }
    String rawDigits = cleanString.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.length == 10) {
      return "(${rawDigits.substring(0, 3)}) ${rawDigits.substring(3, 6)} ${rawDigits.substring(6)}";
    }
    if (rawDigits.length == 11 && rawDigits.startsWith('1')) {
      return "(${rawDigits.substring(1, 4)}) ${rawDigits.substring(4, 7)} ${rawDigits.substring(7)}";
    }
    return cleanString;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var billing = json['billing_address'] ?? {};
    var shippingData = json['shipping_address'] ?? {};
    var products = json['products'] as List? ?? [];

    String formattedDate = "";
    try {
      String rawDate = json['order_date'] ?? "";
      if (rawDate.isNotEmpty) {
        List<String> dateTimeParts = rawDate.split(' ');
        List<String> dateParts = dateTimeParts[0].split('-');
        if (dateParts.length == 3) {
          formattedDate = "${dateParts[1]}-${dateParts[2]}-${dateParts[0]}";
        } else {
          formattedDate = dateTimeParts[0];
        }
      }
    } catch (_) {
      formattedDate = json['order_date'] ?? "";
    }

    String bAddress1 = (billing['address1'] ?? "").toString().trim();
    String bCity = (billing['city'] ?? "").toString().trim();
    String bState = (billing['state'] ?? "").toString().trim();
    List<String> billingParts = [
      if (bAddress1.isNotEmpty) bAddress1,
      if (bCity.isNotEmpty) bCity,
      if (bState.isNotEmpty) bState,
    ];
    String finalBillingAddress = billingParts.isNotEmpty ? billingParts.join(', ') : "N/A";

    String sAddress1 = (shippingData['address1'] ?? "").toString().trim();
    String sCity = (shippingData['city'] ?? "").toString().trim();
    String sState = (shippingData['state'] ?? "").toString().trim();
    String sPhone = (shippingData['phoneno'] ?? "").toString().trim();
    List<String> shippingParts = [
      if (sAddress1.isNotEmpty) sAddress1,
      if (sCity.isNotEmpty) sCity,
      if (sState.isNotEmpty) sState,
    ];
    String finalShippingAddress = shippingParts.isNotEmpty ? shippingParts.join(', ') : "";

    String rawBillingPhone = (billing['phone'] ?? "").toString().trim();
    String formattedBillingPhone = _formatPhoneIfNeeded(rawBillingPhone);
    String formattedShippingPhone = _formatPhoneIfNeeded(sPhone);

    return OrderModel(
      orderId: json['order_id'].toString(),
      date: formattedDate,
      status: json['status'] ?? "",
      total: json['total'].toString(),
      subtotal: json['subtotal'].toString(),
      shipping: json['shipping'].toString() == "0" ? "Free" : json['shipping'].toString(),
      paymentMethod: json['payment_method'] ?? "N/A",
      name: (billing['name'] ?? "").toString().trim().isNotEmpty ? billing['name'] : "N/A",
      email: (billing['email'] ?? "").toString().trim().isNotEmpty ? billing['email'] : "N/A",
      phone: formattedBillingPhone,
      address: finalBillingAddress,
      shippingName: (shippingData['name'] ?? "").toString().trim(),
      shippingAddress: finalShippingAddress,
      productNames: products.map((p) => "${p['product_name']} × ${p['qty']}").toList(),
      shippingPhone: formattedShippingPhone,
    );
  }
}

/// ================= 2. RESPONSIVE HELPER =================
class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double bottomPadding;
  static late double topPadding;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    bottomPadding = _mediaQueryData.padding.bottom; // home indicator / gesture bar
    topPadding = _mediaQueryData.padding.top;       // status bar / notch
  }

  static double w(double width) => (width / 375) * screenWidth;
  static double h(double height) => (height / 812) * screenHeight;
  static double sp(double size) => (size / 375) * screenWidth;
}

/// ================= 3. API SERVICE =================
class ApiService {
  static const String baseUrl = "https://starting5.net/api";
  static const String authUser = "46r4-5ri242Ome3-starting5";
  static const String authPass = "starting5-NEm4wE287p-46r4";

  static String get _basicAuth =>
      'Basic ${base64Encode(utf8.encode('$authUser:$authPass'))}';

  static Future<List<OrderModel>> fetchUserOrders(String userId) async {
    try {
      final String url =
          "$baseUrl/all-order-displayuser.php?user_id=$userId&output=json";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['errcode'] == 200) {
          List ordersJson = data['orders'] ?? [];
          return ordersJson.map((json) => OrderModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Fetch Orders Error: $e");
      return [];
    }
  }
}

/// ================= 4. MAIN SCREEN =================
class MyOrdersScreen extends StatefulWidget {
  final String userId;
  const MyOrdersScreen({super.key, required this.userId});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.fetchUserOrders(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Orders",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: SizeConfig.sp(18),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/dash_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF2D3E50)),
            ),
          ),

          FutureBuilder<List<OrderModel>>(
            future: _ordersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFD7213)));
              } else if (snapshot.hasError) {
                return const Center(child: Text("An error occurred"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No Orders Found."));
              }

              final ordersList = snapshot.data!;
              return ListView.builder(
                // ✅ FIX: bottom mein safe area + extra breathing room
                padding: EdgeInsets.only(
                  left: SizeConfig.w(15),
                  right: SizeConfig.w(15),
                  top: SizeConfig.h(20),
                  bottom: SizeConfig.h(20) + SizeConfig.bottomPadding + 20,
                ),
                itemCount: ordersList.length,
                itemBuilder: (context, index) =>
                    OrderCard(order: ordersList[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ================= 5. ORDER CARD WIDGET =================
class OrderCard extends StatelessWidget {
  final OrderModel order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    bool hasValidShipping =
        order.shippingName.isNotEmpty || order.shippingAddress.isNotEmpty;
    bool isAppointmentOrder = order.productNames
        .any((name) => name.toLowerCase().contains("appointment"));

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.h(20)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SizeConfig.w(18)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFD7213), Color(0xFF2E201F)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.w(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// STATUS BOX
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(SizeConfig.w(12)),
              decoration: BoxDecoration(
                color: const Color(0xFF173B5C).withOpacity(0.9),
                borderRadius: BorderRadius.circular(SizeConfig.w(10)),
              ),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                      fontSize: SizeConfig.sp(12), color: Colors.white),
                  children: [
                    const TextSpan(
                        text: "Order ",
                        style: TextStyle(color: Color(0xFFE96225))),
                    TextSpan(
                        text: "#${order.orderId}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(
                        text: " placed on ",
                        style: TextStyle(color: Color(0xFFE96225))),
                    TextSpan(text: order.date),
                    const TextSpan(
                        text: " is ",
                        style: TextStyle(color: Color(0xFFE96225))),
                    TextSpan(
                        text: order.status.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.h(20)),

            Text(
              "Order Details",
              style: TextStyle(
                  fontSize: SizeConfig.sp(15),
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: SizeConfig.h(10)),

            /// WHITE DETAILS BOX
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(SizeConfig.w(12))),
              child: Column(
                children: [
                  ...order.productNames.map((name) => _OrderRow(name, "")),
                  const Divider(height: 1),
                  _OrderRow("Subtotal:", "\$${order.subtotal}"),
                  if (!isAppointmentOrder) _OrderRow("Shipping:", order.shipping),
                  _OrderRow("Payment:", order.paymentMethod),
                  _OrderRow("Total:", "\$${order.total}", bold: true),
                ],
              ),
            ),

            SizedBox(height: SizeConfig.h(20)),
            Text(
              "Billing Address",
              style: TextStyle(
                  fontSize: SizeConfig.sp(15),
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: SizeConfig.h(8)),
            Text(
              "${order.name}\n${order.address}\nPhone: ${order.phone}\nEmail: ${order.email}",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: SizeConfig.sp(12),
                  height: 1.4),
            ),

            if (hasValidShipping) ...[
              SizedBox(height: SizeConfig.h(20)),
              Text(
                "Shipping Address",
                style: TextStyle(
                    fontSize: SizeConfig.sp(15),
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: SizeConfig.h(8)),
              Text(
                "${order.shippingName.isNotEmpty ? order.shippingName : 'N/A'}\n${order.shippingAddress.isNotEmpty ? order.shippingAddress : 'N/A'}\nPhone: ${order.shippingPhone}",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: SizeConfig.sp(12),
                    height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String title, value;
  final bool bold;
  const _OrderRow(this.title, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.w(12), vertical: SizeConfig.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: SizeConfig.sp(12),
                      fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal))),
          Text(value,
              style: TextStyle(
                  fontSize: SizeConfig.sp(12),
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}