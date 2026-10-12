import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

// --- SCREENS FOLDER IMPORTS ---
import '../services/session_manager.dart';
import 'intro_screen.dart';
import 'my_orders_screen.dart' hide ApiService;
import 'subscriptions_screen.dart';
import 'profile_screen.dart';
import 'all_announcements_screen.dart';
import 'account_settings_screen.dart';
import 'bookings_screen.dart';
import 'contact_us_footer_page.dart';

class MyAccountScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(int) onTabChange;

  static const Color customBlue = Color(0xFF142D43);

  const MyAccountScreen({
    super.key,
    required this.onBack,
    required this.onTabChange,
  });

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {

  String userName = "";
  String userId = "";

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  void loadUserName() async {
    String? name = await SessionManager.getUserName();
    String? userIdStr = await SessionManager.getUserId();

    setState(() {
      userName = "$name!";//name ?? "";
      userId = userIdStr ?? "";
    });
  }

  // ✅ NEW HELPER METHOD: Launches URLs in an optimized integrated web view layer
  Future<void> _launchSocialUrl(String urlString) async {
    String finalUrl = urlString;

    if (urlString.contains("facebook.com")) {
      finalUrl = Platform.isAndroid
          ? "fb://page/starting5clubbasketball"
          : "fb://profile/starting5clubbasketball";
    }

    final Uri appUri = Uri.parse(finalUrl);
    final Uri webUri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      }
      else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (fallbackError) {
        debugPrint("URL Launcher Error: $fallbackError");
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 10),
            child: FractionallySizedBox(
              widthFactor: 0.96,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.red.shade50,
                      child: const Icon(
                        Icons.power_settings_new,
                        color: Colors.redAccent,
                        size: 35,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Confirm Logout",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF142D43),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Are you sure you want to log out?\nYou will need to login again to access your account.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 35),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF142D43),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () async {
                              final String fcmToken = await SessionManager.getFcmToken() ?? "";
                              await SessionManager.logout();
                              await SessionManager.setFcmToken(fcmToken);
                              if (!context.mounted) return;

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const IntroScreen(),
                                ),
                                    (route) => false,
                              );
                            },
                            child: const Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: widget.onBack,
        ),

        title: const Text(
          "My Account",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/images/dash_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [

                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.88,

                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(45),
                          bottomRight: Radius.circular(45),
                        ),

                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 25,
                            sigmaY: 25,
                          ),

                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              30,
                              40,
                              15,
                              40,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.45),

                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(45),
                                bottomRight: Radius.circular(45),
                              ),

                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),

                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(scrollbars: false),

                              child: ListView(
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),

                                children: [

                                  const Text(
                                    "Hello",
                                    style: TextStyle(
                                      color: MyAccountScreen.customBlue,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),

                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: MyAccountScreen.customBlue,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  Text(
                                    "From your account dashboard you can view your recent orders, edit your password and account details.",//manage your shipping and billing addresses, 
                                    style: TextStyle(
                                      color: MyAccountScreen.customBlue
                                          .withOpacity(0.8),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                  ),

                                  const SizedBox(height: 35),

                                  _menuItem(
                                    context,
                                    Icons.inventory_2_outlined,
                                    "Orders",
                                        () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MyOrdersScreen(
                                            userId: userId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  _menuItem(
                                    context,
                                    Icons.calendar_month_outlined,
                                    "Subscription",
                                        () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SubscriptionsScreen(
                                                userId: userId,
                                              ),
                                        ),
                                      );
                                    },
                                  ),

                                  _menuItem(
                                    context,
                                    Icons.account_circle_outlined,
                                    "Profile",
                                        () async {

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ProfileScreen(),
                                        ),
                                      );

                                      loadUserName();
                                    },
                                  ),

                                  _menuItem(
                                    context,
                                    Icons.notifications_none_outlined,
                                    "Notifications",
                                        () {
                                      Navigator.pop(context);
                                      widget.onTabChange(2);
                                    },
                                  ),

                                  _menuItem(
                                    context,
                                    Icons.campaign_outlined,
                                    "Announcements",
                                        () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AllAnnouncementsScreen(
                                            announcements: [],
                                            isFromAccount: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  _menuItem(
                                    context,
                                    Icons.settings_outlined,
                                    "Settings",
                                        () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const AccountSettingsScreen(),
                                        ),
                                      );
                                    },
                                  ),

                                  _menuItem(
                                    context,
                                    Icons.calendar_today_outlined,
                                    "Bookings",
                                        () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BookingsScreen(
                                                  userId: userId
                                              ),
                                        ),
                                      );
                                    },
                                  ),

                                  // ✅ FIXED: Now safely opens the explicit UI full class layout page
                                  _menuItem(
                                    context,
                                    Icons.mail_outline,
                                    "Contact Us",
                                        () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ContactUsFooterPage(),
                                        ),
                                      );
                                    },
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

                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 20, 30, 20),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [
                      _logoutButton(context),
                      _socialIcons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Colors.white30,

        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),

          child: Row(
            children: [

              Icon(
                icon,
                color: MyAccountScreen.customBlue,
                size: 26,
              ),

              const SizedBox(width: 18),

              Text(
                title,
                style: const TextStyle(
                  color: MyAccountScreen.customBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {

    return Container(
      height: 65,
      width: 65,

      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),

      child: IconButton(
        icon: const Icon(
          Icons.power_settings_new,
          color: MyAccountScreen.customBlue,
          size: 32,
        ),

        onPressed: () {
          _showLogoutConfirmation(context);
        },
      ),
    );
  }

  Widget _socialIcons() {

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const FaIcon(
              FontAwesomeIcons.facebookF,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => _launchSocialUrl("https://www.facebook.com/starting5clubbasketball/"),
          ),

          const SizedBox(width: 25),

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const FaIcon(
              FontAwesomeIcons.xTwitter,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => _launchSocialUrl("https://x.com/Starting5Bball"),
          ),

          const SizedBox(width: 25),

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const FaIcon(
              FontAwesomeIcons.instagram,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => _launchSocialUrl("https://www.instagram.com/Starting5Basketball"),
          ),
        ],
      ),
    );
  }
}