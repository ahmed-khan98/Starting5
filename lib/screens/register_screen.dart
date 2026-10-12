
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscure = true;
  bool isLoading = false;

  double? _stableBottomPadding;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      final String cleanEmail = emailController.text.replaceAll(' ', '').trim();
      final String cleanPassword = passwordController.text.replaceAll(' ', '').trim();
      final String cleanFName = firstNameController.text.replaceAll(' ', '').trim();
      final String cleanLName = lastNameController.text.replaceAll(' ', '').trim();
      final String fcmToken = await SessionManager.getFcmToken() ?? "";

      final result = await ApiService.register(
        email: cleanEmail,
        password: cleanPassword,
        fName: cleanFName,
        lName: cleanLName,
        fcmToken: fcmToken
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        String? sessionCookie = await SessionManager.getCookie();
        await SessionManager.clear();

        if (result['user_id'] != null) {
          var firstName = cleanFName;
          var lastName = cleanLName;
          var userName = '$firstName $lastName';
          var email = cleanEmail;

          await SessionManager.setUserId(result['user_id'].toString());
          await SessionManager.setUserEmail(email.toString());
          await SessionManager.setUserFirstName(firstName.toString());
          await SessionManager.setUserLastName(lastName.toString());
          await SessionManager.setUserName(userName.toString());
        }
        await SessionManager.saveCookie(sessionCookie.toString());
        await SessionManager.setFcmToken(fcmToken);

        await SessionManager.setLogin(true);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Registration failed!"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, animation, __) => const LoginScreen(),
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 1. BACKGROUND GRADIENT
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFD7213), Color(0xFF2E201F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 2. PLAYER IMAGE
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

            // 3. CONTENT LAYER
            Positioned.fill(
              child: SingleChildScrollView(
                // ✅ FIX: Disables all user scrolling physics dynamically when the keyboard is open[cite: 6]
                physics: keyboardHeight > 0 
                    ? const NeverScrollableScrollPhysics() 
                    : const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: (size.height * .25) + absoluteBottom + keyboardHeight, 
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
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

                    // TITLE
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                          left: 20,
                          top: size.height * 0.04,
                          bottom: size.height * 0.02
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // FORM SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildInputSection("First Name", firstNameController, "First name")),
                                const SizedBox(width: 15),
                                Expanded(child: _buildInputSection("Last Name", lastNameController, "Last name")),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildInputSection("Email", emailController, "Enter email", isEmail: true),
                            const SizedBox(height: 15),
                            _buildInputSection("Password", passwordController, "Enter password", isPassword: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. FIXED BOTTOM GLASS PANEL LAYER
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: (size.height * .25) + absoluteBottom,
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(30, 20, 30, 10 + absoluteBottom),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.20),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {},
                            child: const Text(
                              "",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
                            ),
                          ),
                          const SizedBox(height: 25),
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

  Widget _buildInputSection(String label, TextEditingController controller, String hint, {bool isEmail = false, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        _buildInputField(controller: controller, hint: hint, isEmail: isEmail, isPassword: isPassword),
      ],
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, bool isPassword = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      textCapitalization: isEmail || isPassword ? TextCapitalization.none : TextCapitalization.words,
      obscureText: isPassword ? obscure : false,
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
        if (isPassword && val.length < 8) return "Min 8 characters long";
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
        onPressed: _handleRegister,
        child: const Text("REGISTER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return InkWell(
      onTap: goToLogin,
      child: const Text.rich(
        TextSpan(
          text: "Have an account? ",
          style: TextStyle(color: Colors.white70, fontSize: 20),
          children: [
            TextSpan(
              text: "Log In",
              style: TextStyle(color: Color(0xFFF05A22), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}