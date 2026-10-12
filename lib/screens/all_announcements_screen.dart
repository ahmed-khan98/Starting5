import 'package:flutter/material.dart';
import '../services/api_service.dart'; 
import 'announcements_screen.dart';

class AllAnnouncementsScreen extends StatefulWidget {
  final List<dynamic> announcements;
  // Toggle flag allows target routes to override default data injection steps
  final bool isFromAccount;

  const AllAnnouncementsScreen({
    super.key, 
    required this.announcements,
    this.isFromAccount = false, // Defaults to false so previous routes don't break
  });

  @override
  State<AllAnnouncementsScreen> createState() => _AllAnnouncementsScreenState();
}

class _AllAnnouncementsScreenState extends State<AllAnnouncementsScreen> {
  late List<dynamic> _displayAnnouncements;
  Map<String, dynamic> _bannerInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with whatever data was passed in initially
    _displayAnnouncements = widget.announcements;

    // CONDITIONAL TRIGGER: Only fetches fresh data from the server if initialized via the account screen
    if (widget.isFromAccount) {
      _fetchLiveAnnouncements();
    }
  }

  Future<void> _fetchLiveAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.fetchAnnouncements();
      if (mounted && result['success'] == true) {
        setState(() {
          //_displayAnnouncements = result['data'] ?? [];
          _bannerInfo = result['data'];
          _displayAnnouncements = _bannerInfo['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching announcements directly: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1A237E); 
    const Color accentColor = Color(0xFFFF6D00);  

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), 
      appBar: AppBar(
        title: const Text("Announcements", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _displayAnnouncements.isEmpty
              ? const Center(
                  child: Text(
                    "No Announcements Found.",
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _displayAnnouncements.length,
                  itemBuilder: (context, index) {
                    final item = _displayAnnouncements[index];
                    
                    // Safe verification wrapper prevents variable mutations if item properties map onto null
                    if (item == null) return const SizedBox.shrink();

                    final String imageUrl = item["home_banner"]?.toString() ?? "";

                    return Card(
                      elevation: 3,
                      shadowColor: Colors.black12,
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl.isNotEmpty)
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                imageUrl, 
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  "assets/images/banner.png",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item["title"] ?? "").toString().replaceAll("&#8211;", "-"),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AnnouncementsScreen(
                                            announcements: item["announcement"] ?? [],
                                            bannerImage: imageUrl,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                    ),
                                    child: const Text("VIEW DETAILS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}