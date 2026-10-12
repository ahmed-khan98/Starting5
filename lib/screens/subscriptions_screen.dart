
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/subscription_model.dart';
import '../services/api_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  final String userId;

  const SubscriptionsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  bool isLoading = true;
  bool isCancelling = false;
  List<SubscriptionModel> subscriptions = [];

  @override
  void initState() {
    super.initState();
    loadSubscriptions(isInitialLoad: true);
  }

  Future<void> loadSubscriptions({bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      setState(() => isLoading = true);
    }
    
    final data = await ApiService.fetchUserSubscriptionsList(widget.userId);
    
    setState(() {
      subscriptions = data;
      isLoading = false;
    });
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat("MMM dd, yyyy").format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "trialing":
        return Colors.blue;
      case "canceled":
      case "cancelled":
        return Colors.red;
      case "completed":
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Future<void> _handleSubscriptionCancellation(
      String subId, String prodId, String price) async {
    final size = MediaQuery.of(context).size;
    final bool isSmall = size.width < 360;

    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.width * 0.04)),
        title: Text(
          "Cancel Subscription",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 16 : 18,
          ),
        ),
        content: Text(
          "Are you sure you want to cancel your subscription?",
          style: TextStyle(fontSize: isSmall ? 13 : 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "NO",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 12 : 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "YES, CANCEL",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 12 : 13,
              ),
            ),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirm) return;

    setState(() => isCancelling = true);

    try {
      /// OPTION A: UNIFIED BACKEND CANCELLATION
      /// Calls WooCommerce Subscriptions API to set status to 'cancelled'.
      /// This stops recurring billing across both the Website and Mobile App seamlessly.
      final backendResponse = await ApiService.cancelSubscription(
        userId: widget.userId,
        productId: prodId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backendResponse['success'] == true
                  ? "Subscription canceled successfully!"
                  : (backendResponse['message'] ??
                  "Local registry sync error occurred."),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Cancellation Failed: ${e.toString().replaceAll("Exception: ", "")}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isCancelling = false);
      await loadSubscriptions(isInitialLoad: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double sw = size.width;

    final double cardPadding = sw * 0.05;
    final double cardRadius = sw * 0.06;
    final double titleFontSize = sw * 0.050;
    final double priceFontSize = sw * 0.045;
    final double labelFontSize = sw * 0.038;
    final double valueFontSize = sw * 0.038;
    final double appBarFontSize = sw * 0.055;
    final double cancelBtnHeight = sw * 0.08;
    final double cancelBtnFontSize = sw * 0.030;
    final double listPadding = sw * 0.04;
    final double cardGap = sw * 0.05;
    final double rowGap = sw * 0.035;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Subscription",
          style: TextStyle(
            color: Colors.black,
            fontSize: appBarFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/dash_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFD7213)),
                  )
                : subscriptions.isEmpty
                    ? Center(
                        child: Text(
                          "No Subscriptions Found.",
                          style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => loadSubscriptions(isInitialLoad: false),
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                              listPadding,
                              listPadding,
                              listPadding,
                              listPadding +
                                  MediaQuery.of(context).padding.bottom +
                                  sw * 0.05),
                          itemCount: subscriptions.length,
                          itemBuilder: (context, index) {
                            final item = subscriptions[index];
                            final statusLower = item.status.toLowerCase();
                            final showCancelButton = statusLower == "active" ||
                                statusLower == "trialing";

                            return Container(
                              margin: EdgeInsets.only(bottom: cardGap),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(cardRadius),
                                image: item.image.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(item.image),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(cardRadius),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFFD7213), Color(0xFF2E201F)],
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: titleFontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (showCancelButton) ...[
                                            SizedBox(width: sw * 0.02),
                                            SizedBox(
                                              height: cancelBtnHeight,
                                              child: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: TextButton(
                                                  key: ValueKey("cancel_btn_${item.subscriptionId}_${item.status}"),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors.white
                                                        .withOpacity(0.2),
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal: sw * 0.035),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              cancelBtnHeight /
                                                                  2),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _handleSubscriptionCancellation(
                                                          item.transactionId,
                                                          item.subscriptionId,
                                                          item.price),
                                                  child: Text(
                                                    "CANCEL",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: cancelBtnFontSize,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      SizedBox(height: sw * 0.025),

                                      Text(
                                        "\$${item.price}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: priceFontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      SizedBox(height: sw * 0.075),

                                      _buildRow(
                                        "Subscription ID:",
                                        item.subscriptionId,
                                        labelSize: labelFontSize,
                                        valueSize: valueFontSize,
                                      ),
                                      SizedBox(height: rowGap),
                                      
                                      _buildRow(
                                          "Status:",
                                          "",
                                          labelSize: labelFontSize,
                                          valueSize: valueFontSize,
                                          customValueWidget: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 400),
                                            switchInCurve: Curves.easeIn,
                                            switchOutCurve: Curves.easeOut,
                                            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                                              return Stack(
                                                alignment: Alignment.centerLeft,
                                                children: <Widget>[
                                                  ...previousChildren,
                                                  if (currentChild != null) currentChild,
                                                ],
                                              );
                                            },
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                item.status.toUpperCase().replaceAll("CANCELLED", "CANCELED"),
                                                key: ValueKey("status_text_${item.subscriptionId}_${item.status}"),
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                  color: getStatusColor(item.status),
                                                  fontSize: valueFontSize,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: rowGap),
                                      _buildRow(
                                        "Started on:",
                                        formatDate(item.start_date),
                                        labelSize: labelFontSize,
                                        valueSize: valueFontSize,
                                      ),
                                      SizedBox(height: rowGap),
                                      _buildRow(
                                        "Expires on:",
                                        (statusLower != "active" &&
                                                statusLower != "on-hold" &&
                                                item.expires.isNotEmpty)
                                            ? formatDate(item.expires)
                                            : formatDate(item.next_payment),
                                        labelSize: labelFontSize,
                                        valueSize: valueFontSize,
                                      ),
                                      SizedBox(height: rowGap),
                                      _buildRow(
                                        "Billing:",
                                        "${item.billingInterval} ${item.billingPeriod}",
                                        labelSize: labelFontSize,
                                        valueSize: valueFontSize,
                                      ),
                                      SizedBox(height: rowGap),
                                      _buildRow(
                                        "Payment Method:",
                                        item.paymentMethod,
                                        labelSize: labelFontSize,
                                        valueSize: valueFontSize,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),

          if (isCancelling)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFD7213)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
      String title,
      String value, {
        Color valueColor = Colors.white,
        required double labelSize,
        required double valueSize,
        Widget? customValueWidget,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: labelSize,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: customValueWidget ?? Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: valueSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}