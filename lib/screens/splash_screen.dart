
import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import 'intro_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  late final Animation<double> _logoScale;
  late final Animation<double> _textScale;
  late final Animation<Offset> _ballMove;
  late final Animation<double> _ballScale;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    /// Basketball movement
    _ballMove = Tween<Offset>(
      begin: const Offset(-0.7, -1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutQuad),
      ),
    );

    /// Basketball zoom
    _ballScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.8)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7),
      ),
    );

    /// Logo animation
    _logoScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOutBack),
      ),
    );

    /// Text animation
    _textScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.95, curve: Curves.elasticOut),
      ),
    );

    /// 🔥 Important: Start after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplash();
    });
  }

  Future<void> _startSplash() async {

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    /// Start animation
    await _controller.forward();

    /// Small delay after animation
    await Future.delayed(const Duration(milliseconds: 600));

    if (_navigated) return;

    bool loggedIn = await SessionManager.isLoggedIn();

    Widget nextScreen =
    loggedIn ? const MainScreen() : const IntroScreen();

    if (!mounted) return;

    _navigated = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double width = MediaQuery.of(context).size.width;

    double logoSize = width * 0.42;
    double ballSize = width * 0.42;
    double textSize = width * 0.045;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// Background
          Positioned.fill(
            child: Image.asset(
              'assets/splash_screen.jpg',
              fit: BoxFit.cover,
            ),
          ),

          /// Logo
          Align(
            alignment: const Alignment(0, -0.45),
            child: ScaleTransition(
              scale: _logoScale,
              child: Hero(
                tag: "app_logo",
                child: Image.asset(
                  'assets/logo.png',
                  width: logoSize,
                ),
              ),
            ),
          ),

          /// Text
          Align(
            alignment: const Alignment(0, 0.10),
            child: ScaleTransition(
              scale: _textScale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    children: const [
                      TextSpan(
                        text: "SERVING OUR KIDS AND\nCOMMUNITIES ",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: "SINCE 2016!",
                        style: TextStyle(color: Color(0xFF1A344A)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Basketball
          Align(
            alignment: const Alignment(0, 0.60),
            child: SlideTransition(
              position: _ballMove,
              child: ScaleTransition(
                scale: _ballScale,
                child: Image.asset(
                  'assets/basketball_animation.png', 
                  width: ballSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
