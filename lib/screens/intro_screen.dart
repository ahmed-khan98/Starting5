
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideTween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFD7213),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFD7213), Color(0xFF2E201F)],
          ),
        ),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          // ✅ FIX: Removed root SafeArea wrapper so the glass container bleeds seamlessly to the device's absolute bottom edge
          child: Stack(
            children: [
              /// 1. BACKGROUND ARTWORK
              Positioned.fill(
                child: RepaintBoundary(
                  child: Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      "assets/intro_bg.png",
                      width: size.width,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  ),
                ),
              ),

              /// 2. LOGO
              // ✅ Wrapped explicitly in Positioned with an isolated SafeArea to guarantee hardware notch protection
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(top: size.height * 0.02),
                    child: Center(
                      child: Image.asset(
                        "assets/logo.png",
                        width: size.width * 0.22,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

              /// 3. BOTTOM GLASS PANEL (Anchored directly to superview base)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: ClipRect( 
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          size.width * 0.07,
                          25,
                          size.width * 0.07,
                          20 + bottomPadding, // ✅ Appends raw bottom padding dynamically to avoid safe area visual dead zones
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.20),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.1), 
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "STARTING 5 BASKETBALL is a youth basketball program, established in 2016, that aims to serve every child regardless of skill level or experience.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width * 0.040,
                                height: 1.6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: size.height * 0.03),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFD7213),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: () => _navigateTo(context, const LoginScreen()),
                                      child: const Text(
                                        "LOGIN",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: () => _navigateTo(context, const RegisterScreen()),
                                      child: const Text(
                                        "REGISTER",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          color: Color(0xFFFD7213),
                                        ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}