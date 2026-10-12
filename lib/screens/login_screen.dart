
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); 
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscure = true;
  bool isLoading = false;
  
  double? _stableBottomPadding; 

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleForgotPassword() async {
    String email = emailController.text.replaceAll(' ', '').trim();

    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email first!"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    final result = await ApiService.forgotPassword(email);
    setState(() => isLoading = false);

    if (!mounted) return;
    //_showSnackBar(result['message'] ?? "Reset link sent to your email");
    _showStatusForgotDialog(result['message'] ?? "Reset link sent to your email");

  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      final String cleanEmail = emailController.text.replaceAll(' ', '').trim();
      final String cleanPassword = passwordController.text.replaceAll(' ', '').trim();
      final String fcmToken = await SessionManager.getFcmToken() ?? "";
      try {
        final result = await ApiService.login(
          cleanEmail,
          cleanPassword,
          fcmToken
        );

        setState(() => isLoading = false);

        if (result['success'] == true) {
          var userModel = result['user'];
          var userId = userModel.userId;
          var firstName = userModel.firstName;
          var lastName = userModel.lastName;
          var userName = '$firstName $lastName';
          var email = userModel.email;

          if (userId != null) {
            String? sessionCookie = await SessionManager.getCookie();
            await SessionManager.clear();

            await SessionManager.setUserId(userId.toString());
            await SessionManager.setUserEmail(email.toString());
            await SessionManager.setUserFirstName(firstName.toString());
            await SessionManager.setUserLastName(lastName.toString());
            await SessionManager.setUserName(userName.toString());
            await SessionManager.setLogin(true);
            await SessionManager.saveCookie(sessionCookie.toString());
            await SessionManager.setFcmToken(fcmToken);

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        } else {
          String msg = result['message'] ?? "Login failed!";
          _showSnackBar(msg);
        }
      } catch (e) {
        setState(() => isLoading = false);
        _showSnackBar("Technical Error: Something went wrong!");
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2E201F), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [//Icon(Icons.check_circle, color: Colors.green, size: 50)
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 100,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF05A22), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

void _showStatusForgotDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2E201F), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 100,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF05A22), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// void _showStatusForgotDialog(String message, bool isSuccess) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           title: Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red, size: 50),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(message, textAlign: TextAlign.center),
//             ],
//           ),
//           actions: [
//             Center(
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE96225), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
//                 onPressed: () {
//                   Navigator.pop(context);
                  
//                 },
//                 child: const Text("OK", style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

// void _showSnackBar(String message) {
  //   if (!mounted) return;
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       backgroundColor: Colors.redAccent,
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }

  void goToRegister() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, animation, __) => const RegisterScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (_stableBottomPadding == null || (keyboardHeight == 0 && MediaQuery.of(context).padding.bottom > 0)) {
      _stableBottomPadding = MediaQuery.of(context).padding.bottom;
    }
    
    final double absoluteBottom = _stableBottomPadding ?? 0.0;
    // ✅ Check if the keyboard is actively occupying viewport space
    final bool isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 1. Background Gradient Layer
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFD7213), Color(0xFF2E201F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 2. Player Artwork Background
            Positioned.fill(
              child: Opacity(
                opacity: 0.9,
                child: Padding(
                  padding: EdgeInsets.only(top: size.height * .10),
                  child: Image.asset(
                    "assets/login_bg.png",
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),

            // 3. Scrollable Forms Layer (Locks down manual user drag interaction dynamically)
            Positioned.fill(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false), // Stops ambient iOS/Android elastic scroll bouncing
                child: SingleChildScrollView(
                  // ✅ FIX: Changes the scrolling engine mechanics based on keyboard presence
                  physics: isKeyboardOpen 
                      ? const NeverScrollableScrollPhysics() 
                      : const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: (size.height * .32) + absoluteBottom + keyboardHeight, 
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Toolbar
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Image.asset("assets/logo.png", width: size.width * .22),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),

                      // Log In Title Header Text
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                            left: 20,
                            top: size.height * 0.06,
                            bottom: size.height * 0.03
                        ),
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                            fontSize: 35,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Active Form Input Box
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey, 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Email address", style: TextStyle(color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 10),
                              _buildInputField(
                                controller: emailController,
                                hint: "Enter email",
                                isEmail: true,
                              ),
                              SizedBox(height: size.height * 0.02),
                              const Text("Password", style: TextStyle(color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 10),
                              _buildInputField(
                                controller: passwordController,
                                hint: "Enter password",
                                isPassword: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Fixed Static Bottom Glass Panel Layer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: (size.height * .32) + absoluteBottom,
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(30, 20, 30, 10 + absoluteBottom),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.20),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: isLoading ? null : _handleForgotPassword,
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: isLoading ? Colors.white54 : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          isLoading
                              ? const CircularProgressIndicator(color: Color(0xFFF05A22))
                              : _buildLoginButton(size),
                          const Spacer(),
                          _buildRegisterLink(),
                          const SizedBox(height: 15),
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
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, bool isPassword = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      obscureText: isPassword ? obscure : false,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      style: const TextStyle(color: Colors.black, fontSize: 18),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
        errorStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 2)),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => obscure = !obscure),
        ) : null,
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return "Required";
        if (isEmail && !val.contains("@")) return "Invalid email";
        //if (isPassword && val.length < 8) return "Min 8 characters";
        return null;
      },
    );
  }

  Widget _buildLoginButton(Size size) {
    return SizedBox(
      width: size.width * 0.65,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF05A22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        onPressed: _handleLogin,
        child: const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return InkWell(
      onTap: goToRegister,
      child: const Text.rich(
        TextSpan(
          text: "Not Registered? ",
          style: TextStyle(color: Colors.white70, fontSize: 20),
          children: [
            TextSpan(
              text: "Join Now",
              style: TextStyle(color: Color(0xFFF05A22), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}