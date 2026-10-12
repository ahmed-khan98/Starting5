class OrderModel {
  final String orderId;
  final String date;
  final String status;
  final String total;
  final String subtotal;
  final String shipping;
  final String paymentMethod;
  final String name;
  final String address;
  final String phone;
  final String email;
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
    required this.productNames,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var billing = json['billing_address'];
    var products = json['products'] as List;

    return OrderModel(
      orderId: json['order_id'].toString(),
      date: json['order_date'] ?? "",
      status: json['status'] ?? "",
      total: json['total'].toString(),
      subtotal: json['subtotal'].toString(),
      shipping: json['shipping'].toString() == "0" ? "Free" : json['shipping'].toString(),
      paymentMethod: json['payment_method'] ?? "N/A",
      name: billing['name'] ?? "",
      email: billing['email'] ?? "",
      phone: billing['phone'] ?? "",
      address: "${billing['address1']}, ${billing['city']}, ${billing['state']} ${billing['postcode']}",
      productNames: products.map((p) => "${p['product_name']} × ${p['qty']}").toList(),
    );
  }
}