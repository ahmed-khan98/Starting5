import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsFooterPage extends StatelessWidget {
  const ContactUsFooterPage({super.key});

  Future<void> _launchEmail(String email) async {
    
    final String subject = Uri.encodeComponent('Inquiry regarding STARTING 5 BASKETBALL');
    
    final Uri emailLaunchUri = Uri.parse('mailto:$email?subject=$subject');

    try {
      await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching email client: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeAccent = Color(0xFFE05A2B);
    const textColor = Color(0xFF374151); 
    const darkHeadingColor = Colors.black;

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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Contact Us",
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
          // 1. BACKGROUND IMAGE LAYER
          Positioned.fill(
            child: Image.asset(
              "assets/images/dash_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // 2. BLUR & CONTENT LAYER
          SafeArea(
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
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(30, 45, 24, 45),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6), 
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(45),
                          bottomRight: Radius.circular(45),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CONTACT US HEADER
                            const Text(
                              'CONTACT US',
                              style: TextStyle(
                                color: darkHeadingColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 35),

                            // FACILITY ADDRESS SECTION
                            const Text(
                              'Training Facility Address',
                              style: TextStyle(
                                color: darkHeadingColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '24525 Town Center Drive\nValencia, CA 91355',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 40), 

                            // EMAIL SECTION 1: BASKETBALL PROGRAM
                            RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(text: 'For basketball program questions, email us at '),
                                  TextSpan(
                                    text: 'starting5staff@gmail.com',
                                    style: const TextStyle(
                                      color: orangeAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _launchEmail('starting5staff@gmail.com'),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20), 

                            // EMAIL SECTION 2: BILLING
                            RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(text: 'For billing questions, email us at '),
                                  TextSpan(
                                    text: 'starting5billing@gmail.com',
                                    style: const TextStyle(
                                      color: orangeAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _launchEmail('starting5billing@gmail.com'),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            // COMMON SUBTEXT
                            /*const Text(
                              '(Same day response. We\'ll call/text you if needed.)',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),*/
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
}