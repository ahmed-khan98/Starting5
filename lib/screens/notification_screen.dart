
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class NotificationModel {
  final String title;
  final String message;
  final String time;
  final String postType;

  NotificationModel({
    required this.title,
    required this.message,
    required this.time,
    required this.postType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title'] ?? "",
      message: json['description'] ?? "",
      time: json['published_date'] ?? "",
      postType: json['post_type'] ?? "",
    );
  }
}

class NotificationScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationScreen({super.key, this.onBack});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  String _errorMessage = "";
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final result = await ApiService.fetchNotificationList();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final List dynamicList = result['data'] ?? [];
          _notifications = dynamicList
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        } else {
          _errorMessage = "No Notifications Found.";
        }
      });
    }
  }

  // Parses raw datetime stamps into precise "X ago" strings
  String _convertToAgoFormat(String rawDateTimeString) {
    if (rawDateTimeString.isEmpty) return "";
    try {
      final DateTime publishedDate = DateTime.parse(rawDateTimeString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(publishedDate);

      if (difference.isNegative) {
        return "Just now";
      } else if (difference.inSeconds < 60) {
        return "${difference.inSeconds} seconds ago";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes} minutes ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours} hours ago";
      } else if (difference.inDays == 1) {
        return "Yesterday";
      } else if (difference.inDays < 30) {
        return "${difference.inDays} days ago";
      } else {
        final int months = (difference.inDays / 30).floor();
        return months == 1 ? "1 month ago" : "$months months ago";
      }
    } catch (e) {
      return rawDateTimeString; // Fallback directly to raw text on calculation anomalies
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: Colors.black),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          /// Background Layer
          Positioned.fill(
            child: Image.asset(
              "assets/images/dash_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Image Shading Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.15),
            ),
          ),

          /// Dynamic Display Branching
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFD7213)),
                )
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _notifications.isEmpty
                      ? const Center(
                          child: Text(
                            "No Notifications Found.",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: const Color(0xFFFD7213),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 15, 20, 150),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      /// Notification Avatar Icon
                                      Container(
                                        width: 55,
                                        height: 55,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.black12),
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            "assets/logo.png",
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      /// Text Layout Package
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notification.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              notification.message,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                _convertToAgoFormat(notification.time),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ],
      ),
    );
  }
}