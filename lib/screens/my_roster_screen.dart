
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/MatchModel.dart';
import '../services/api_service.dart';

class MyRosterScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MyRosterScreen({super.key, required this.onBack});

  @override
  State<MyRosterScreen> createState() => _MyRosterScreenState();
}

class _MyRosterScreenState extends State<MyRosterScreen> {
  bool isLoading = true;
  String? teamTitle;
  String? coachName;
  String? coachPhoto;
  String? matchDate;
  List<MatchModel> matches = [];

  @override
  void initState() {
    super.initState();
    _loadRosterData();
  }

  Future<void> _loadRosterData() async {
    final response = await ApiService.fetchTeamRoster();

    if (response['success'] == true && response['data'] != null && (response['data'] as List).isNotEmpty) {
      // Assuming the API returns a list and we take the first team
      var teamData = response['data'][0];

      // Safe extraction of matches array list components
      var matchLocationData = teamData['match_location'] as List?;
      List<MatchModel> parsedMatches = [];
      if (matchLocationData != null) {
        parsedMatches = matchLocationData.map((m) => MatchModel.fromJson(m)).toList();
      }

      setState(() {
        teamTitle = teamData['title'];
        coachName = teamData['coach_name'];
        coachPhoto = teamData['coach_profile_photo'];
        matchDate = teamData['match_date'];
        matches = parsedMatches;
        isLoading = false;
      });

      // ✅ FIXED UI REQ: If matches array is completely empty, trigger error message workflow automatically
      if (matches.isEmpty) {
        _showNoRostersMessage();
      }
    } else {
      setState(() => isLoading = false);
      //_showNoRostersMessage();
    }
  }

  void _showNoRostersMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No Rosters Found.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED UI REQ: Clear screen visibility state checker flags
    bool showEmptyState = !isLoading && matches.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Team Roster",
          style: TextStyle(
            fontFamily: 'SFPro',
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black,
          ),
          onPressed: widget.onBack,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          // Background Assets Layout Layer Stack
          Positioned.fill(
            child: Image.asset(
              "assets/images/dash_bg.png",
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          // Core content builder allocation block
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (showEmptyState)
            // ✅ FIXED UI REQ: Complete screen overlay replacement layout block hiding all metadata elements cleanly
            const Center(
              child: Text(
                "No Rosters Found.",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SFPro',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 150),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE96225), Color(0xFF2C1E1A)],
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeaderInfo(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              matchDate ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'SFPro',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ...matches.map((match) => _matchCard(match)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF1B354D),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    "http://starting5.net/wp-content/uploads/2026/06/mobileapplogo.png",
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.sports_basketball,
                      color: Color(0xFFE96225),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    teamTitle ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: coachPhoto != null ? NetworkImage(coachPhoto!) : null,
                child: coachPhoto == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coachName ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'SFPro',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    "Head Coach",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _matchCard(MatchModel match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.time,
            style: const TextStyle(
              fontSize: 19,
              fontFamily: 'SFPro',
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                "V/s",
                style: TextStyle(
                  fontFamily: 'SFPro',
                  color: Color(0xFFE96225),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  match.opponent,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            match.address,
            style: const TextStyle(
              fontFamily: 'SFPro',
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  /*
  Widget _chatButton() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/Vector_Stroke.png",
            height: 18,
            color: Colors.white),
          const SizedBox(width: 10),
          const Text(
            "Chat",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }*/
}