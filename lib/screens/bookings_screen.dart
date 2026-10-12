
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; 
import 'package:startingfive/screens/my_orders_screen.dart' hide ApiService;

import '../models/BookingModel.dart';
import '../services/api_service.dart';

class BookingsScreen extends StatefulWidget {
  final String userId;

  const BookingsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool isLoading = true;
  List<Booking> bookingList = [];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      bookingList = await ApiService.fetchUserBookings(widget.userId);
    } catch (e) {
      debugPrint("Booking Error : $e");
    }
    if (mounted) {
      setState(() {
        isLoading = false; 
      });
    }
  }

  // HELPER METHOD: Converts "yyyy-MM-dd HH:mm:ss" safely into "MM-dd-yyyy hh:mm a" (e.g., 06-19-2026 02:10 PM)
  String _formatBookingDateTime(String rawDateString) {
    if (rawDateString.isEmpty) return "";
    try {
      // Step 1: Handle space anomalies or partial stamps safely
      DateTime parsedDateTime = DateTime.parse(rawDateString.trim());
      
      // Step 2: Format to display date followed by 12-hour clock time with AM/PM markers
      return DateFormat('MM-dd-yyyy hh:mm a').format(parsedDateTime);
    } catch (e) {
      // Fallback: If parsing fails, return original raw string value safely
      return rawDateString; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      //final isSmallScreen = constraints.maxWidth < 600;

      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/dash_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2D3E50)), 
            ),
          ),

          Scaffold(
            backgroundColor:  Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              title: const Text(
                "Bookings",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : bookingList.isEmpty
                  ? const Center(
                child: Text("No Bookings Found.", style: TextStyle(color: Colors.white)),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(constraints.maxWidth * 0.05),
                itemCount: bookingList.length,
                itemBuilder: (context, index) {
                  final booking = bookingList[index];
                  return _buildBookingCard(booking, constraints.maxWidth);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

  Widget _buildBookingCard(Booking booking, double maxWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: maxWidth * 0.05),
      padding: EdgeInsets.all(maxWidth * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE67E22).withOpacity(0.9),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.serviceName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: maxWidth * 0.05,
            ),
          ),
          SizedBox(height: maxWidth * 0.03),
          Text("\$${booking.bookingPrice}", style: const TextStyle(color: Colors.white)),
          const Divider(color: Colors.white24),
          _buildRow("Booking ID", booking.appointmentId, maxWidth),
          _buildRow("Status", capitalize(booking.bookingStatus), maxWidth),
          
          // Passing values inside the new date + time string converter hook method
          _buildRow("Start Date", _formatBookingDateTime(booking.startDate), maxWidth),
          _buildRow("End Date", _formatBookingDateTime(booking.endDate), maxWidth),
          
          _buildRow("Coach", booking.coachName, maxWidth),
          SizedBox(height: maxWidth * 0.04),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyOrdersScreen(userId: widget.userId)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF27133),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("View Order", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, double maxWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}