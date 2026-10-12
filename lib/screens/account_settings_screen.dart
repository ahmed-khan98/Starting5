import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'intro_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  /// =========================
  /// VARIABLES
  /// =========================

  bool push = false;
  bool sms = true;
  bool email = true;

  bool _isNotificationLoading = false;
  bool _isLoading = false;
  bool _isDeleting = false;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  /// =========================
  /// INIT
  /// =========================

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  /// =========================
  /// LOAD NOTIFICATION STATUS
  /// =========================

  Future<void> _loadNotificationStatus() async {
    if (!mounted) return;

    setState(() {
      _isNotificationLoading = true;
    });

    try {
      String? userId = await SessionManager.getUserId();

      if (userId == null || userId.isEmpty) {
        if (mounted) setState(() => _isNotificationLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
          "https://starting5.net/api/get-profile.php?user_id=$userId",
        ),
      );

      print("GET PROFILE RESPONSE:");
      print(response.body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['profile'] != null &&
            jsonData['profile']['isnotificationenable'] != null) {

          dynamic status = jsonData['profile']['isnotificationenable'];

          if (mounted) {
            setState(() {
              
              push = status.toString() == "1" || status.toString().toLowerCase() == "true";
            });
          }
          print("Notification Status loaded dynamically: $push");
        }
      }
    } catch (e) {
      print("Notification Load Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isNotificationLoading = false;
        });
      }
    }
  }

  /// =========================
  /// UPDATE NOTIFICATION
  /// =========================

  Future<void> _updateNotificationStatus(bool value) async {
    bool oldValue = push;

    setState(() {
      _isNotificationLoading = true;
      push = value; 
    });

    try {
      String? userId = await SessionManager.getUserId();

      if (userId == null || userId.isEmpty) {
        if (mounted) setState(() => push = oldValue);
        return;
      }

      final uri = Uri.parse("https://starting5.net/api/profile-update.php");
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        "Accept": "application/json",
      });

      request.fields['user_id'] = userId;
      request.fields['isnotificationenable'] = value ? "1" : "0";

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print("Notification Update Response: $responseData");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseData);

        if (jsonData['errcode'].toString() == "200") {

          dynamic profileData = jsonData['profile'] ?? jsonData['data'];

          if (profileData != null && profileData['isnotificationenable'] != null) {
            dynamic apiStatus = profileData['isnotificationenable'];
            if (mounted) {
              setState(() {
                push = apiStatus.toString() == "1" || apiStatus.toString().toLowerCase() == "true";
              });
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                push ? "Push Notification Enabled!" : "Push Notification Disabled!",
              ),
            ),
          );
        } else {
          if (mounted) setState(() => push = oldValue);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonData['errstr'] ?? "Update Failed"),
            ),
          );
        }
      } else {
        if (mounted) setState(() => push = oldValue);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server Error")),
        );
      }
    } catch (e) {
      print("Notification Error: $e");
      if (mounted) setState(() => push = oldValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isNotificationLoading = false;
        });
      }
    }
  }

  /// =========================
  /// STATUS DIALOG
  /// =========================

  void _showStatusDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 50,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE96225),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (isSuccess) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const IntroScreen()),
                          (route) => false,
                    );
                  }
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// =========================
  /// DELETE ACCOUNT
  /// =========================

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Delete Account!"),
              content: _isDeleting
                  ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE96225)),
                  SizedBox(height: 15),
                  Text("Deleting your account...", textAlign: TextAlign.center),
                ],
              )
                  : const Text("Are you sure you want to delete your account? This action is permanent."),
              actions: _isDeleting
                  ? []
                  : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    setDialogState(() => _isDeleting = true);
                    String? userId = await SessionManager.getUserId();

                    if (userId != null && userId.isNotEmpty) {
                      final response = await ApiService.deleteAccount(userId);

                      if (response['success'] == true) {
                        await SessionManager.clearSession();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const IntroScreen()),
                                (route) => false,
                          );
                        }
                      } else {
                        setDialogState(() => _isDeleting = false);
                        _showStatusDialog(
                          "Error",
                          response['message'] ?? "Failed",
                          false,
                        );
                      }
                    } else {
                      setDialogState(() => _isDeleting = false);
                    }
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// =========================
  /// PASSWORD UPDATE
  /// =========================

  Future<void> _handlePasswordUpdate() async {
    final String currentPasswordClean = _currentPassController.text.replaceAll(' ', '').trim();
    final String newPasswordClean = _newPassController.text.replaceAll(' ', '').trim();

    if (currentPasswordClean.isEmpty || newPasswordClean.isEmpty) {
      _showStatusDialog("Alert!", "Please enter both passwords.", false);
      return;
    }

    if (newPasswordClean.length < 6) {
      _showStatusDialog("Alert!", "New password must be at least 6 characters.", false);
      return;
    }

    if (currentPasswordClean == newPasswordClean) {
      _showStatusDialog("Alert!", "New password cannot be the same as your current password.", false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? userId = await SessionManager.getUserId();
      final String finalId = (userId != null && userId.isNotEmpty) ? userId : "";

      final response = await ApiService.changePassword(
        userId: finalId,
        currentPassword: currentPasswordClean,
        newPassword: newPasswordClean,
      );

      if (response['success'] == true) {
        _currentPassController.clear();
        _newPassController.clear();
        _showStatusDialog("Success!", "Password updated successfully.", true);
      } else {
        _showStatusDialog("Alert!", response['errstr'] ?? "Password update failed.", false);
      }
    } catch (e) {
      _showStatusDialog("Error", "Something went wrong", false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Account Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/dash_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE96225).withOpacity(0.45),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// CARD
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Account Settings",
                                      style: TextStyle(
                                        color: Color(0xFF1B264F),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Change Password",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _currentPassController,
                                      obscureText: !_isCurrentPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText: "Current Password",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    TextField(
                                      controller: _newPassController,
                                      obscureText: !_isNewPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText: "New Password",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isNewPasswordVisible = !_isNewPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE96225),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                        onPressed: _isLoading ? null : _handlePasswordUpdate,
                                        child: _isLoading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text(
                                          "UPDATE",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            const Text(
                              "Notification Preference",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 18),

                            _switchTile(
                              "Push Notification",
                              push,
                                  (val) {
                                _updateNotificationStatus(val);
                              },
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                ),
                                onPressed: _showDeleteConfirmation,
                                child: const Text(
                                  "DELETE ACCOUNT",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// SWITCH TILE (FIXED FLICKERING)
  /// =========================

  Widget _switchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400),
            ),
          ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isNotificationLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              Switch(
                value: value,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFFE96225),
                
                onChanged: _isNotificationLoading ? null : onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}