class SubscriptionModel {
  final String subscriptionId;
  final String transactionId;
  final String title;
  final String image;
  final String price;
  final String status;
  final String expires;
  final String paymentMethod;
  final String billingPeriod;
  final String billingInterval;
  final String next_payment;
  final String start_date;

  SubscriptionModel({
    required this.subscriptionId,
    required this.transactionId,
    required this.title,
    required this.image,
    required this.price,
    required this.status,
    required this.expires,
    required this.paymentMethod,
    required this.billingPeriod,
    required this.billingInterval,
    required this.next_payment,
    required this.start_date,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final products = json['products'] as List? ?? [];
    final firstProduct =
        products.isNotEmpty ? products.first : <String, dynamic>{};

    return SubscriptionModel(
      subscriptionId: json['subscription_id'].toString(),
      transactionId: json['transaction_id'].toString(),
      title: firstProduct['product_name'] ?? "Subscription",

      image: firstProduct['image'] ?? "",

      price: json['total'].toString(),

      status: json['status'] ?? "",

      expires: json['end_date'] == 0
          ? "Never"
          : json['end_date'].toString(),

      paymentMethod: json['payment_method'] ?? "N/A",

      billingPeriod: json['billing_period'] ?? "",

      billingInterval: json['billing_interval']?.toString() ?? "",

      next_payment: json['next_payment']?.toString() ?? "",
      start_date: json['start_date']?.toString() ?? "",
    );
  }
}