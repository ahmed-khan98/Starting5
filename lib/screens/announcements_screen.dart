import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnnouncementsScreen extends StatelessWidget {
  final List<dynamic> announcements;
  final String bannerImage;
  const AnnouncementsScreen({
    super.key,
    required this.announcements,
    required this.bannerImage,
  });



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Announcements",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/dash_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.black),
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          announcements.isEmpty
              ? const Center(
            child: Text(
              "No Record Found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 25,
            ),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];

              return AnnouncementCard(
                date: item['date']?.toString() ?? "",
                title: item['group_name']?.toString() ?? "",
                location: item['location']?.toString() ?? "",
                address: item['address']?.toString() ?? "",
                time: item['time']?.toString() ?? "",
                userName: item['user_name']?.toString() ?? "",
                imageUrl: bannerImage,
              );
            },
          ),
        ],
      ),
    );
  }
}

List<String> _parseNames(String html) {
  if (html.isEmpty) return [];
  final cleaned = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '||')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .trim();
  return cleaned
      .split('||')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

class AnnouncementCard extends StatelessWidget {
  final String date;
  final String title;
  final String location;
  final String address;
  final String time;
  final String userName;
  final String imageUrl;

  const AnnouncementCard({
    super.key,
    required this.date,
    required this.title,
    required this.location,
    required this.address,
    required this.time,
    required this.userName,
    required this.imageUrl,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.broken_image,
                      size: 50,
                    ),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Color(0xFFE96225),
                    ),
                  ),

                  // ---- Newly added: address & user_name below title ----
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (userName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: _parseNames(userName).map((name) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: 14,
                                  bottom: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin:
                                      const EdgeInsets.only(right: 6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE96225),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE96225),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // ---- End newly added ----

                  const SizedBox(height: 12),

                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Row(
                  //   children: const [
                  //     Text(
                  //       "VIEW DETAILS",
                  //       style: TextStyle(
                  //         fontWeight: FontWeight.w800,
                  //         fontSize: 15,
                  //         color: Colors.black,
                  //         decoration: TextDecoration.underline,
                  //       ),
                  //     ),
                  //     SizedBox(width: 5),
                  //     Icon(
                  //       Icons.arrow_forward_rounded,
                  //       size: 18,
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}