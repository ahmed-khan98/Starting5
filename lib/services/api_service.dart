import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:startingfive/models/BookingModel.dart';
import '../models/OrderModel.dart';
import '../models/user_model.dart';
import '../services/session_manager.dart';
import '../models/subscription_model.dart';

class ApiService {
  static const String baseUrl = "https://starting5.net/api";

  // Basic Auth Credentials
  static const String authUser = "46r4-5ri242Ome3-starting5";
  static const String authPass = "starting5-NEm4wE287p-46r4";

  static String get _basicAuth =>
      'Basic ${base64Encode(utf8.encode('$authUser:$authPass'))}';

  static Future<Map<String, dynamic>> login(String email,
      String password,
      String fcmToken) async {
    try {
      final String url = "$baseUrl/login-page.php";

      print("Request URL: $url");
      print("Email: $email");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "user_email": email.trim(),
          "user_pass": password.trim(),
          'fcmToken': fcmToken
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode != 200) {
        return {
          "success": false,
          "message": "Server error: ${response.statusCode}",
        };
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      print("Decoded Data: $data");

      /// SUCCESS CHECK
      final bool isSuccess =
          data["code"] == 200 &&
              (data["success"] == true ||
                  data["success"].toString().toLowerCase() == "true");

      if (isSuccess) {
        /// SAVE COOKIE
        try {
          String? rawCookie = response.headers['set-cookie'];

          print("Raw Cookie: $rawCookie");

          if (rawCookie != null && rawCookie.isNotEmpty) {
            String sessionCookie = rawCookie
                .split(';')
                .first;

            print("Session Cookie: $sessionCookie");

            await SessionManager.saveCookie(sessionCookie);
          }
        } catch (e) {
          print("Cookie Save Error: $e");
        }

        /// USER PARSE
        final user = UserModel.fromJson(data["data"]);

        print("Parsed User ID: ${user.userId}");

        return {
          "success": true,
          "user": user,
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Login failed",
        };
      }
    } catch (e, stack) {
      print("LOGIN ERROR: $e");
      print(stack);

      return {
        "success": false,
        "message": "Network error: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fName,
    required String lName,
    required String fcmToken
  }) async {
    try {
      final String url = "$baseUrl/user-registation.php";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'user_email': email.trim(),
          'user_pass': password.trim(),
          'first_name': fName.trim(),
          'last_name': lName.trim(),
          'fcmToken': fcmToken
        },
      );

      var data = jsonDecode(response.body);

      if (data['code'].toString() == "200") {
        
        return {
          "success": true,
          "message": data['message'],
          "user_id": data['data']['user_id'] 
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Registration failed"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // --- FORGOT PASSWORD API ---
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final String url = "$baseUrl/forget-password.php";

      print("Requesting Password Reset for: $email");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth, // ✅ Basic Auth Header
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'user_email': email.trim(),
          
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      var data = jsonDecode(response.body);

      
      if (data['code'].toString() == "200" || data['success'] == true) {
        return {
          "success": true,
          "message": data['message'] ?? "Password reset email sent."
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Email not found or failed."
        };
      }
    } catch (e) {
      print("Forgot Password Error: $e");
      return {"success": false, "message": "Network error: Connection failed."};
    }
  }


  // Profile fetch
  static Future<Map<String, dynamic>> fetchProfile(String userId) async {
    try {
      final String url = "$baseUrl/profile.php?output=json";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/x-www-form-urlencoded",
          
        },
        body: {
          'user_id': userId, 
        },
      );

      var data = jsonDecode(response.body);

      if (data['code'].toString() == "200") {
        return {"success": true, "data": data['data']};
      } else {
        return {
          "success": false,
          "message": data['message'] ?? "Failed to load profile"
        };
      }
    } catch (e) {
      print("Fetch Profile Error: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  static Future<Map<String, dynamic>> fetchAnnouncements() async {
    try {
      String? userId = await SessionManager.getUserId();
      final String url = "$baseUrl/announcement-page.php?userid=$userId?output=json";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );

      print("Annousement response....: ${response.body}");
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['errcode'].toString() == "200") {
          return {"success": true, "data": data};
        }
      }
      return {"success": false, "message": "Failed to load announcements"};
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  static Future<Map<String, dynamic>> fetchOurPrograms() async {
    try {
      final String url = "$baseUrl/our-program.php?output=json";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['errcode'].toString() == "200") {
          return {"success": true, "data": data['data']};
        }
      }
      return {"success": false, "message": "Failed to load programs"};
    } catch (e) {
      print("Fetch Programs Error: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // --- FETCH TEAM ROSTER API ---
  static Future<Map<String, dynamic>> fetchTeamRoster() async {
    try {
      
      final String url = "$baseUrl/team-roster.php?output=json";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );

      print("Roster Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['errcode'].toString() == "200") {
          return {
            "success": true,
            "data": data['data'] // This returns the list of teams
          };
        }
      }
      return {"success": false, "message": "Failed to load roster"};
    } catch (e) {
      print("Fetch Roster Error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final Uri url = Uri.parse("$baseUrl/change-password.php").replace(
        queryParameters: {
          'user_id': userId,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      final response = await http.get(url, headers: {
        "Authorization": _basicAuth,
        "Cookie": "_sfs_id=48be56b6d4c7656e9e822783d537d1911777637996",
      });

      var data = jsonDecode(response.body);

      if (data['errcode'].toString() == "200") {
        return {
          "success": true,
          "errstr": data['errstr']
          
        };
      } else {
        return {
          "success": false,
          "errstr": data['errstr'] ?? "Failed" 
        };
      }
    } catch (e) {
      return {"success": false, "errstr": "Network error: $e"};
    }
  }

  static Future<List<OrderModel>> fetchUserOrders(String userId) async {
    try {
      final String url = "$baseUrl/all-order-displayuser.php?user_id=$userId&output=json";
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": _basicAuth},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['errcode'] == 200) {
          List ordersJson = data['orders'];
          return ordersJson.map((json) => OrderModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Error fetching orders: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchTrainingSchedule() async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/training_schedule.php?output=json",
        ),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );

      print("Training Schedule Status : ${response.statusCode}");
      print("Training Schedule Response : ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['errcode'].toString() == "200") {
          return {
            "success": true,
            "data": data['data'],
          };
        } else {
          return {
            "success": false,
            "message": data['errstr'] ?? "Failed",
          };
        }
      }

      return {
        "success": false,
        "message": "Server Error",
      };
    } catch (e) {
      print("Training Schedule Error : $e");

      return {
        "success": false,
        "message": "Network Error",
      };
    }
  }

  // NEW: Function to save forms dynamically
  static Future<Map<String, dynamic>> saveRegistrationForm({
    required Map<String, String> formData,
    required String formType,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/all-form.php");

      var request = http.MultipartRequest('POST', uri);
      String? sessionCookie = await SessionManager.getCookie();
      // Add common headers
      request.headers.addAll({
        "Authorization": _basicAuth,
        "Accept": "application/x-www-form-urlencoded",
        if (sessionCookie != null) "Cookie": sessionCookie,
      });

      // Add all form fields from the map
      request.fields.addAll(formData);

      // Send the request
      http.StreamedResponse response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseData);
        if (data['errcode'].toString() == "200") {
          return {
            "success": true,
            "data": data
          };
        } else {
          return {
            "success": false,
            "message": data['errstr'] ?? "Failed to parse program data."
          };
        }
      } else {
        return {
          "success": false,
          "message": "Server Error: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Connection Error: $e"
      };
    }
  }

  // --- FETCH SINGLE PROGRAM DETAILS ---
  static Future<Map<String, dynamic>> fetchProgramSingle(String postId) async {
    try {
      final String url = "$baseUrl/our-program-single.php?post_id=$postId&output=json";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['errcode'].toString() == "200") {
          return {
            "success": true,
            "data": data['data']
          };
        } else {
          return {
            "success": false,
            "message": data['errstr'] ?? "Failed to parse program data."
          };
        }
      }
      return {
        "success": false,
        "message": "Server Error: ${response.statusCode}"
      };
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  /// Loads Super Form fields from get-form.php.
  /// Returns the `fields` list when errcode is 200.
  static Future<List<dynamic>> fetchFormFields(dynamic formId) async {
    try {
      final uri = Uri.parse("$baseUrl/get-form.php").replace(
        queryParameters: {
          "form_id": formId.toString(),
          "output": "json",
        },
      );

      final response = await http.get(
        uri,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Server Error: ${response.statusCode}");
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw Exception("Failed to load form.");
      }
      if (decoded['errcode'].toString() != "200") {
        throw Exception(decoded['errstr']?.toString().trim().isNotEmpty == true
            ? decoded['errstr'].toString()
            : "Failed to load form.");
      }

      final data = decoded['data'];
      if (data is Map && data['fields'] is List) {
        return data['fields'] as List;
      }
      if (data is List) {
        return data;
      }
      throw Exception("Form fields were not returned.");
    } catch (e) {
      final raw = e.toString().replaceFirst(RegExp(r'^[A-Za-z0-9_]*Exception:\s*'), '').trim();
      throw Exception(raw.isEmpty ? "Failed to load form." : raw);
    }
  }

  // NEW: Function to checkout forms dynamically
  static Future<Map<String, dynamic>> checkoutForm({
    required Map<String, String> formData,
    required String formType,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/checkout.php");

      var request = http.MultipartRequest('POST', uri);
      String? sessionCookie = await SessionManager.getCookie();
      // Add common headers
      request.headers.addAll({
        "Authorization": _basicAuth,
        "Accept": "application/x-www-form-urlencoded",
        if (sessionCookie != null) "Cookie": sessionCookie,
      });

      // Add all form fields from the map
      request.fields.addAll(formData);

      // Send the request
      http.StreamedResponse response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseData);
        if (data['errcode'].toString() == "200") {
          return {
            "success": true,
            "data": data
          };
        } else {
          return {
            "success": false,
            "message": data['errstr'] ?? "Failed to parse program data."
          };
        }
      } else {
        return {
          "success": false,
          "message": "Server Error: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Connection Error: $e"
      };
    }
  }

//Booking Appointment Service API
  static Future<Map<String, dynamic>> bookingAppointment({
    required Map<String, dynamic> formData,
    required String formType,
  }) async {
    try {
      final uri = Uri.parse(
          "https://starting5.net/wp-json/mobile/v1/book-appointment");

      String? sessionCookie = await SessionManager.getCookie();

      
      final response = await http.post(
        uri,
        headers: {
          "Authorization": _basicAuth,
          
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (sessionCookie != null) "Cookie": sessionCookie,
        },
        
        body: jsonEncode(formData),
      );

      // Log server text directly if character 1 errors emerge during testing
      print("BOOKING API RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Match stringified verification conditions used by your other screens
        if (data['success'] == true || data['errcode'].toString() == "200") {
          return {
            "success": true,
            "data": data
          };
        } else {
          return {
            "success": false,
            // Fallback checking to capture whatever error key string is sent back
            "message": data['errstr'] ?? data['message'] ??
                "Failed to finalize pass booking setup."
          };
        }
      } else {
        return {
          "success": false,
          "message": "Server Error Code: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Connection Parse Error: $e"
      };
    }
  }

//Get User Subscriptions List
  static Future<List<SubscriptionModel>> fetchUserSubscriptionsList(
      String userId) async {
    try {
      final String url =
          "$baseUrl/user-subscription-orders.php?user_id=$userId&output=json";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['errcode'] == 200) {
          List subscriptionsJson = data['subscriptions'] ?? [];

          return subscriptionsJson
              .map((json) => SubscriptionModel.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print("Subscription API Error: $e");
      return [];
    }
  }

// Fetch User Bookings
  static Future<List<Booking>> fetchUserBookings(
      String userId) async {

    try {

      final String url =
          "$baseUrl/all-bookings.php?user_id=$userId";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );

      print("Bookings Response : ${response.body}");

      if (response.statusCode == 200) {

        var data = jsonDecode(response.body);

        if (data["success"] == true) {

          List bookingsJson = data["data"] ?? [];

          return bookingsJson
              .map((json) => Booking.fromJson(json))
              .toList();
        }
      }

      return [];

    } catch (e) {

      print("Booking API Error : $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> deleteAccount(String userId) async {
  try {
    // 1. API URL
    final Uri url = Uri.parse("https://starting5.net/api/deactive-user.php?output=json");

    // 2.
    String username = '46r4-5ri242Ome3-starting5';
    String password = 'starting5-NEm4wE287p-46r4';
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));

    // 3. Multipart Request (curl --form ke liye)
    var request = http.MultipartRequest('POST', url);

    
    request.headers.addAll({
      "Authorization": basicAuth,
    });
  
    request.fields['user_id'] = userId;

    var response = await request.send();
    
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);

      if (data['success'] == true) {
        return {"success": true, "message": data['message'] ?? "Account deleted"};
      } else {
        return {"success": false, "message": data['message'] ?? "Failed to deactivate"};
      }
    } else {
      return {"success": false, "message": "Server Error: ${response.statusCode}"};
    }
  } catch (e) {
    print("Delete Account Error: $e");
    return {"success": false, "message": "Network error: $e"};
  }
}

// Check Coupon Code
  static Future<Map<String, dynamic>> checkCouponCode(
      String couponCode) async {

    try {

      final String url =
          "$baseUrl/coupon.php?coupan=$couponCode";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['errcode'].toString() == "200") {
          return {"success": true, "message": data['errstr'] ?? "Coupon code applied successfully!"};
        } else {
          return {"success": false, "message": data['errstr'] ?? "Failed!"};
        }
      }

      return {"success": false, "message": "Server Error: ${response.statusCode}"};

    } catch (e) {

      return {"success": false, "message": "Network error: $e"};
    }
  }

  //Cancel Subscription
   static Future<Map<String, dynamic>> cancelSubscription({
    required String userId,
    required String productId
  }) async {
    try {
      final uri = Uri.parse(
          "$baseUrl/cancelled_subscriptions.php");

      final response = await http.post(
        uri,
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/x-www-form-urlencoded",
        },
       body: {
          'user_id': userId,
          "subscription_id": productId
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Match stringified verification conditions used by your other screens
        if (data['success'] == true || data['errcode'].toString() == "200") {
          return {
            "success": true,
            "data": data
          };
        } else {
          return {
            "success": false,
            // Fallback checking to capture whatever error key string is sent back
            "message": data['errstr'] ?? data['message'] ??
                "Failed!"
          };
        }
      } else {
        return {
          "success": false,
          "message": "Server Error Code: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Connection Parse Error: $e"
      };
    }
  }

// NEW: Fetch Dynamic Notifications List
  static Future<Map<String, dynamic>> fetchNotificationList() async {
    try {
      final String url = "$baseUrl/notification-list.php";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": _basicAuth,
          "Content-Type": "application/json",
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errcode'].toString() == "200") {
          return {
            "success": true,
            "data": data['data'] ?? []
          };
        }
      }
      return {"success": false, "message": "Failed to load notifications"};
    } catch (e) {
      
      return {"success": false, "message": "Network error: $e"};
    }
  }

}