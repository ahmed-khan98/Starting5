
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dynamic_registration_form.dart'; 
import '../services/api_service.dart';
import 'package:flutter_html/flutter_html.dart';
import '../widgets/full_bleed_image.dart';

class FormDetailScreen extends StatefulWidget {
  final String postId;
  final String userId;
  final bool isBack;

  const FormDetailScreen({
    super.key, 
    required this.postId, 
    required this.userId,
    required this.isBack,
  });

  @override
  State<FormDetailScreen> createState() => _FormDetailScreenState();
}

class _FormDetailScreenState extends State<FormDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _programData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProgramDetails();
  }

  Future<void> _fetchProgramDetails() async {
    Map<String, dynamic> result;
    try {
      result = await ApiService.fetchProgramSingle(widget.postId);
    } catch (e) {
      result = {'success': false, 'message': 'Could not load this program.'};
    }

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _programData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? "An error occurred.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE65100))),
      );
    }

    // ✅ FIXED: Evaluates if the widget is living inside a navigation context stack
    final bool canPop = widget.isBack;//ModalRoute.of(context)?.canPop ?? false;

    if (_errorMessage.isNotEmpty || _programData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          // ✅ FIXED: Conditionally shows/hides back arrow based on the menu route environment context
          leading: canPop 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _errorMessage, 
              style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    final String mainImage = _programData!['image'] ?? '';
    final String mainHeading = _programData!['heading'] ?? '';
    final String formName = _programData!['form_Name'] ?? '';
    final String programTitle = _programData!['acf_title'] ?? 'Program Details';
    final String description = _programData!['content'] ?? '';
    final String priceDetails = _programData!['price_message'] ?? '';
    final String formId = _programData!['form_id']?.toString() ?? widget.postId;
    final String productId = _programData!['product_id']?.toString() ?? widget.postId;
    final String buttonHeading = _programData!['button_heading'] ?? ''; 
    final String buttonDescription = _programData!['message'] ?? ''; 
    final List<dynamic> galleryImages = _programData!['gallery'] ?? [];
    final String buttonTitle = _programData!['button'] ?? 'REGISTER NOW';
    bool isOpen = _programData!['register_now'] != null && 
                 _programData!['register_now'].toString().toUpperCase().contains("OPEN");
    bool isOpenShooting = _programData!['form_Name'] != null && 
                 _programData!['form_Name'].toString().toUpperCase().contains("OPEN SHOOTING");

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        // Conditionally shows/hides back arrow based on navigation context framework
        leading: canPop 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── ORANGE HEADER HERO BANNER ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              color: const Color(0xFFE65100), 
              child: Center(
                child: Text(
                  programTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // ── MAIN HERO FEATURE IMAGE ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: FullBleedImage(url: mainImage),
              ),
            ),

            // ── WEBSITE DETAILED CONTENT SECTION ──
            Padding(
              padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, canPop ? 24.0 : 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    mainHeading,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w800, 
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  Html(
                    data: description, 
                    style: {
                      "body": Style(
                        color: Colors.black87,
                        fontSize: FontSize(15.0),
                        fontWeight: FontWeight.w400,
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        lineHeight: const LineHeight(1.55),
                      ),
                      "p": Style(
                        margin: Margins.only(top: 10, bottom: 12),
                        fontSize: FontSize(15.5),
                        color: Colors.black87,
                      ),
                      "strong": Style(
                        color: Colors.black,
                        fontWeight: FontWeight.w800, 
                        fontSize: FontSize(16.0),
                      ),
                      "ul": Style(
                        margin: Margins.only(top: 6, bottom: 14),
                        padding: HtmlPaddings.only(left: 18), 
                      ),
                      "li": Style(
                        color: Colors.black87,
                        fontSize: FontSize(15.0),
                        margin: Margins.only(bottom: 8), 
                        lineHeight: const LineHeight(1.45),
                        listStyleType: ListStyleType.disc,
                      ),
                    },
                  ),

                  const SizedBox(height: 30),
                  
                  // ── REGISTER BUTTON BOX ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9), 
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          buttonHeading.isNotEmpty ? buttonHeading : "Register for $programTitle",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w800, 
                            fontSize: 22,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          priceDetails,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black87, 
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (isOpen) ...[
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE65100),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final String registrationTitle =
                                  formName.isNotEmpty ? formName : programTitle;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DynamicRegistrationForm(
                                    productId: productId,
                                    title: registrationTitle,
                                    formId: formId.trim(),
                                    userId: widget.userId,
                                    programData: _programData,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              buttonTitle.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        ],
                        if (buttonDescription.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            buttonDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isOpenShooting ? Colors.black : Colors.grey.shade700, 
                              fontWeight: isOpenShooting ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 35),

                  // ── GALLERY IMAGES GRID ──
                  if (galleryImages.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: galleryImages.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            galleryImages[index]['url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}