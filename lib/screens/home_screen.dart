import 'dart:async';
import 'package:flutter/material.dart';
import 'package:startingfive/screens/form_detail.dart';
import 'package:startingfive/screens/training_schedule.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'all_announcements_screen.dart';
import 'announcements_screen.dart';
import 'single_workout_pass.dart';
import 'package:html_unescape/html_unescape.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final unescape = HtmlUnescape();
  List<dynamic> _announcements = [];
  List<dynamic> _apiPrograms = [];
  Map<String, dynamic> _bannerInfo = {};

  bool _isLoading = true;

  final double _sliderViewportFraction = 0.92;
  final Color brandOrange = const Color(0xFFE96225);
  final Color darkHeaderBlue = const Color(0xFF1B3147);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _sliderViewportFraction);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchAnnouncements(),
        ApiService.fetchOurPrograms(),
      ]);
      if (mounted) {
        setState(() {
          if (results[0]['success']) {
            _bannerInfo = results[0]['data'];
            _announcements = _bannerInfo['data'];
          }
          if (results[1]['success']) _apiPrograms = results[1]['data'];
          _isLoading = false;
        });
        _startAutoSlider();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startAutoSlider() {
    final items = _getAnnouncementsList().take(4).toList();
    if (items.isEmpty) return;

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) async {
      if (!_pageController.hasClients) return;

      int nextPage = _currentPage + 1;
      if (nextPage >= items.length) {
        nextPage = 0;
      }

      _currentPage = nextPage;

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoSlider() {
    _timer?.cancel();
    _timer = null;
  }

  List<dynamic> _getAnnouncementsList() {
    return _announcements;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double alignmentPadding =
        screenSize.width * ((1 - _sliderViewportFraction) / 2) + 5;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/dash_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          RefreshIndicator(
            onRefresh: _loadData,
            color: brandOrange,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(screenSize, alignmentPadding),
                  const SizedBox(height: 22),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: alignmentPadding),
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_getAnnouncementsList().isNotEmpty)
                  _buildSectionHeader(
                    "Announcements",
                    hasViewAll: true,
                    padding: alignmentPadding,
                  ),
                  _isLoading
                      ? const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : _buildAnnouncementSlider(),
                  if (!_isLoading && _getAnnouncementsList().isNotEmpty)
                    _buildDotIndicator(),
                  const SizedBox(height: 30),
                  _buildTrainingScheduleCard(alignmentPadding),
                  const SizedBox(height: 35),
                  _buildProgramIntro(alignmentPadding),
                  _isLoading
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: alignmentPadding,
                    ),
                    child: Column(
                      children: _apiPrograms
                          .map((data) => _buildDynamicProgramCard(data))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

/*
Widget _buildHeroBanner(Size size, double padding) {
    final dynamic rawBanner = _bannerInfo.isNotEmpty
        ? _bannerInfo['bannerimage']
        : null;
    final String bannerUrl = (rawBanner is String) ? rawBanner : "";

    final dynamic rawTitle = _bannerInfo.isNotEmpty
        ? _bannerInfo['bannertitle']
        : null;
    final String title = (rawTitle is String && rawTitle.isNotEmpty)
        ? rawTitle
        : "Welcome to STARTING 5 BASKETBALL!";

    final dynamic rawDescription = _bannerInfo.isNotEmpty
        ? _bannerInfo['bannerdesc']
        : null;
    final String description = (rawDescription is String) ? rawDescription : "Development, Training, Club Teams & Leagues for Kids and Teens Grades K Through 12";

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: SizedBox(
        height: size.height * 0.38,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: bannerUrl.isNotEmpty
                  ? Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                frameBuilder:
                    (context, child, frame, wasSynchronouslyLoaded) =>
                wasSynchronouslyLoaded
                    ? child
                    : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 500),
                  child: child,
                ),
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  "assets/images/banner.png",
                  fit: BoxFit.cover,
                ),
              )
                  : Image.asset("assets/images/banner.png", fit: BoxFit.cover),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(padding, 50, padding, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // LOGO & SLOGAN HEADER ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', height: 55),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'SFPro',
                              height: 1.15,
                              letterSpacing: 0.8,
                            ),
                            children: [
                              const TextSpan(
                                text: "SERVING OUR KIDS\nAND COMMUNITIES\n",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: "SINCE  2016!",
                                style: TextStyle(
                                  color: brandOrange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
*/

Widget _buildHeroBanner(Size size, double padding) {
    final dynamic rawBanner = _bannerInfo.isNotEmpty
        ? _bannerInfo['bannerimage']
        : null;
    final String bannerUrl = (rawBanner is String) ? rawBanner : "";

    final dynamic rawTitle = _bannerInfo.isNotEmpty
        ? _bannerInfo['bannertitle']
        : null;
    final String title = (rawTitle is String && rawTitle.isNotEmpty)
        ? rawTitle
        : "Welcome to STARTING 5 BASKETBALL!";

    final dynamic rawDescription = _bannerInfo.isNotEmpty
        ? _bannerInfo['bannerdesc']
        : null;
    final String description = (rawDescription is String) ? rawDescription : "Development, Training, Club Teams & Leagues for Kids and Teens Grades K Through 12";

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: SizedBox(
        height: size.height * 0.38,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: bannerUrl.isNotEmpty
                  ? Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                frameBuilder:
                    (context, child, frame, wasSynchronouslyLoaded) =>
                wasSynchronouslyLoaded
                    ? child
                    : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 500),
                  child: child,
                ),
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  "assets/images/banner.png",
                  fit: BoxFit.cover,
                ),
              )
                  : Image.asset("assets/images/banner.png", fit: BoxFit.cover),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(padding, 50, padding, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.3, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // LOGO & SLOGAN HEADER ROW WITH FOCUSED DARK BACKDROP LAYER
                  // LOGO & SLOGAN HEADER ROW WITH FOCUSED DARK BACKDROP LAYER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', height: 55),
                      const SizedBox(width: 10),
                      
                      Transform.translate(
                        offset: const Offset(0, -2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55), // Dark protective layer
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.02),
                              width: 1,
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                height: 1.05,
                                letterSpacing: 0.6,
                              ),
                              children: [
                                const TextSpan(
                                  text: "SERVING OUR KIDS\nAND COMMUNITIES\n",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: "SINCE 2016!",
                                  style: TextStyle(
                                    color: brandOrange, // Preserved exact brand orange
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingScheduleCard(double padding) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TrainingScheduleScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: darkHeaderBlue,
              child: const Text(
                "TRAINING SCHEDULE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementSlider() {
    final announcements = _announcements.take(4).toList();

    if (announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ FIXED GESTURE ARENA: Pauses slider tracking safely on pointer down events
    return Listener(
      onPointerDown: (_) => _pauseAutoSlider(),
      onPointerUp: (_) => _startAutoSlider(),
      child: SizedBox(
        height: 260,
        child: PageView.builder(
          controller: _pageController,
          itemCount: announcements.length,
          onPageChanged: (int index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            final item = announcements[index];

            final String bannerImage = item['home_banner'] is String
                ? item['home_banner']
                : "";

            // ✅ FIXED METHOD: Swapped InkWell for GestureDetector using strictly onTap to resolve lift-to-register swipe click errors
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnouncementsScreen(
                      announcements: item['announcement'] ?? [],
                      bannerImage: item['home_banner'] is String
                          ? item['home_banner']
                          : '',
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // IMAGE
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: bannerImage.isNotEmpty
                          ? Image.network(bannerImage, fit: BoxFit.cover)
                          : Image.asset(
                        "assets/images/banner.png",
                        fit: BoxFit.cover,
                      ),
                    ),

                    // TITLE
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            HtmlUnescape().convert(
                              item['title']?.toString() ?? '',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: brandOrange,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

//Use this function if we have to stop click on button if registration closed.(Previous function)
  // Widget _buildDynamicProgramCard(dynamic data) {
  //   bool isEnabled =
  //       data['register_now'] != null &&
  //           data['register_now'].toString().toUpperCase().contains("OPEN");

  //   final String imageUrl = (data['image'] ?? "").toString().trim();
  //   bool hasImage = imageUrl.isNotEmpty;

  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 15),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(25),
  //     ),
  //     clipBehavior: Clip.antiAlias,
  //     child: Column(
  //       children: [
  //         if (hasImage)
  //           Image.network(
  //             imageUrl,
  //             height: 220,
  //             width: double.infinity,
  //             fit: BoxFit.cover,
  //             frameBuilder: (context, child, frame, _) => frame == null
  //                 ? Container(height: 220, color: Colors.grey[200])
  //                 : child,
  //             errorBuilder: (c, e, s) =>
  //                 Container(height: 220, color: Colors.grey[200]),
  //           )
  //         else
  //           const SizedBox(height: 0),

  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
  //           child: Column(
  //             children: [
  //               Text(
  //                 (data['acf_title'] ?? "PROGRAM").toUpperCase(),
  //                 style: TextStyle(
  //                   color: brandOrange,
  //                   fontWeight: FontWeight.w700,
  //                   fontSize: 16,
  //                   letterSpacing: 1.2,
  //                 ),
  //               ),
  //               const SizedBox(height: 12),
  //               Text(
  //                 data['title'] ?? "",
  //                 textAlign: TextAlign.center,
  //                 style: const TextStyle(
  //                   fontSize: 22,
  //                   fontWeight: FontWeight.w600,
  //                   color: Colors.black,
  //                   height: 1.1,
  //                 ),
  //               ),
  //               const SizedBox(height: 30),
  //               SizedBox(
  //                 width: double.infinity,
  //                 height: 60,
  //                 child: ElevatedButton(
  //                   onPressed: isEnabled
  //                       ? () async {
  //                     String? userId = await SessionManager.getUserId();
  //                     if (context.mounted) {
  //                       if (data['title']
  //                           .toString()
  //                           .toLowerCase()
  //                           .contains('workout')) {
  //                         Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                             builder: (context) =>
  //                                 SingleWorkoutPassScreen(
  //                                   postId: data['id'].toString(),
  //                                   userId: userId ?? "",
  //                                 ),
  //                           ),
  //                         );
  //                       } else {
  //                         Navigator.push(
  //                           context,
  //                           MaterialPageRoute(
  //                             builder: (context) => FormDetailScreen(
  //                               postId: data['id'].toString(),
  //                               userId: userId ?? "",
  //                             ),
  //                           ),
  //                         );
  //                       }
  //                     }
  //                   }
  //                       : null,
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: brandOrange,
  //                     foregroundColor: Colors.white,
  //                     disabledBackgroundColor: Colors.grey[400],
  //                     shape: const StadiumBorder(),
  //                     elevation: 0,
  //                   ),
  //                   child: Text(
  //                     (data['button'] ?? "REGISTER NOW").toUpperCase(),
  //                     style: const TextStyle(
  //                       fontWeight: FontWeight.w800,
  //                       fontSize: 16,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

//           Alternate Function
//Use this function if we have to always clickable Register button. (New function)
Widget _buildDynamicProgramCard(dynamic data) {
    bool isEnabled =
        data['register_now'] != null &&
            data['register_now'].toString().toUpperCase().contains("OPEN");

    final String imageUrl = (data['image'] ?? "").toString().trim();
    bool hasImage = imageUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      clipBehavior: Clip.none,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                frameBuilder: (context, child, frame, _) => frame == null
                    ? Container(
                        width: double.infinity,
                        height: 220,
                        color: Colors.grey[200],
                      )
                    : child,
                errorBuilder: (c, e, s) => Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.grey[200],
                ),
              ),
            )
          else
            const SizedBox(height: 0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            child: Column(
              children: [
                Text(
                  (data['main_heading'] ?? "PROGRAM").toUpperCase(),
                  style: TextStyle(
                    color: brandOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['acf_title'] ?? "",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    // ✅ FIXED: Button is always clickable; action execution is unblocked
                    onPressed: () async {
                      String? userId = await SessionManager.getUserId();
                      if (context.mounted) {
                        if (data['title']
                            .toString()
                            .toLowerCase()
                            .contains('workout')) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SingleWorkoutPassScreen(
                                    postId: data['id'].toString(),
                                    userId: userId ?? "",
                                  ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormDetailScreen(
                                postId: data['id'].toString(),
                                userId: userId ?? "",
                                isBack: true
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      // ✅ FIXED: Changes color safely based on the isEnabled flag state
                      backgroundColor: isEnabled ? brandOrange : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      (data['button'] ?? "REGISTER NOW").toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    int totalItems = _announcements.length > 4 ? 4 : _announcements.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalItems,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(top: 15, left: 4, right: 4),
          width: _currentPage == index ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: _currentPage == index ? brandOrange : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, {
        bool hasViewAll = false,
        required double padding,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: brandOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          if (hasViewAll)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllAnnouncementsScreen(
                        announcements: _announcements,
                        isFromAccount: false
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: brandOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brandOrange.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 13,
                    color: brandOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgramIntro(double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "START Your Journey with STARTING 5 BASKETBALL!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Our Programs",
            style: TextStyle(
              color: brandOrange,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}