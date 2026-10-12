
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'form_detail.dart'; 
//import 'my_roster_screen.dart';
import 'notification_screen.dart';
import 'my_account_screen.dart';
import '../services/session_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  String _currentUserId = ""; // ✅ ADDED: Variable to store session userId

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  // ✅ ADDED: Session loader to safely pass actual current active users down to form_detail tab context
  Future<void> _loadUserSession() async {
    String? userId = await SessionManager.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId ?? "";
      });
    }
  }

  void goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  void goToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    _lastBackPressTime = null;
  }

  void _openMyAccountFullScreen() {
    _lastBackPressTime = null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyAccountScreen(
          onBack: () {
            Navigator.pop(context);
            goToHome();
          },
          onTabChange: goToTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final screens = [
      const HomeScreen(),
      //MyRosterScreen(onBack: goToHome),
      FormDetailScreen(
        postId: "46522", // Default developmental training / club team post package ID 
        userId: _currentUserId,
        isBack: false
      ),
      NotificationScreen(onBack: goToHome),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }

        final now = DateTime.now();

        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) >
                const Duration(seconds: 2)) {
          _lastBackPressTime = now;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Press back again to exit"),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 2),
            ),
          );

          return false;
        }

        await SystemNavigator.pop();
        return false; 
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            screens[_currentIndex],
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 10, 
              left: width * 0.05,
              right: width * 0.05,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: height * 0.075, 
                    padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _navItem("assets/icons/home.png", "Home", 0),
                        //_navItem("assets/icons/roster.png", "Roster", 1),
                        _navItem("assets/icons/register.png", "Register", 1),
                        _navItem("assets/icons/bell.png", "Notifications", 2),
                        _navItem("assets/icons/account.png", "My Account", 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String icon, String label, int index) {
    final size = MediaQuery.of(context).size;
    final isActive = _currentIndex == index;

    return Expanded( 
      child: GestureDetector(
        onTap: () {
          if (index == 3) {
            _openMyAccountFullScreen();
          } else {
            goToTab(index);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              height: size.width * 0.055, 
              color: isActive ? Colors.orange : Colors.black87,
            ),
            SizedBox(height: size.height * 0.004),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: size.width * 0.028, 
                color: isActive ? Colors.orange : Colors.black87,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            )
          ],
        ),
      ),
    );
  }
}