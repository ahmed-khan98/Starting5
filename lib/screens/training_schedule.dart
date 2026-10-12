
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'register_form.dart';
import 'dynamic_registration_form.dart'; 
import 'single_workout_pass.dart';

class TrainingScheduleScreen extends StatefulWidget {
  const TrainingScheduleScreen({super.key});

  @override
  State<TrainingScheduleScreen> createState() =>
      _TrainingScheduleScreenState();
}

class _TrainingScheduleScreenState extends State<TrainingScheduleScreen> {
  bool isLoading = true;
  bool isFetchingProgram = false; 
  List scheduleList = [];

  @override
  void initState() {
    super.initState();
    getTrainingSchedule();
  }

  Future<void> getTrainingSchedule() async {
    final response = await ApiService.fetchTrainingSchedule();

    if (response['success'] == true) {
      setState(() {
        scheduleList = response['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ✅ NEW METHOD: Custom API fetch engine fetching payload before directing to form
  Future<void> _handleDevelopmentRegistrationTap() async {
    setState(() => isFetchingProgram = true);

    try {
      final String targetPostId = "46522"; 
      final result = await ApiService.fetchProgramSingle(targetPostId);
      String? userId = await SessionManager.getUserId();

      if (mounted) {
        setState(() => isFetchingProgram = false);

        if (result['success'] == true) {
          final programData = result['data'] ?? {};
          final String formName = programData['form_Name'] ?? '';
          final String programTitle = programData['acf_title'] ?? 'Program Details';
          final String formId = programData['form_id']?.toString() ?? targetPostId;
          final String productId = programData['product_id']?.toString() ?? targetPostId;

          final String registrationTitle = formName.isNotEmpty ? formName : programTitle;
          final bool isHalloweenForm = formId.trim() == '51020';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => isHalloweenForm
                  ? DynamicRegistrationForm(
                      productId: productId,
                      title: registrationTitle,
                      formId: formId.trim(),
                      userId: userId ?? "",
                      programData: programData,
                    )
                  : RegistrationForm(
                      productId: productId,
                      title: registrationTitle,
                      formId: formId,
                      userId: userId ?? "",
                      programData: programData,
                    ),
            ),
          );
        } else {
          _showError(result['message'] ?? "Failed to fetch registration data reference.");
        }
      }
    } catch (e) {
      if (mounted) setState(() => isFetchingProgram = false);
      _showError("An unexpected connectivity error occurred: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2638),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "TRAINING SCHEDULE",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
            fontSize: width * 0.045,
          ),
        ),
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE96225),
                  ),
                )
              : Column(
                  children: [
                    // ================= TOP FIXED NAVIGATION ACTION BUTTON =================
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFF2F2F2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE96225),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // ✅ FIXED: Calls our custom integrated background dynamic data fetch system method
                          onPressed: isFetchingProgram ? null : _handleDevelopmentRegistrationTap,
                          child: Text(
                            "Register for Development Training / Club Teams",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.038,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Main schedule scrolling grid track container
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: scheduleList.length,
                        padding: const EdgeInsets.only(
                          top: 14,
                          left: 12,
                          right: 12,
                          bottom: 40,
                        ),
                        itemBuilder: (context, index) {
                          final item = scheduleList[index];
                          final title = item['title']?.toString() ?? "";
                          final trainingSchedule = item['training_schedule'] ?? [];

                          String upperTitle = title.toUpperCase();
                          bool showWorkoutPassButton = upperTitle.contains("MONDAY") || 
                                                     upperTitle.contains("TUESDAY") ||
                                                     upperTitle.contains("MON") ||
                                                     upperTitle.contains("TUE");

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ================= CARD HEADER =================
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: width * 0.04,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2D3244),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      title.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFFE96225),
                                        fontSize: width * 0.044,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),

                                // ================= INNER CONTEXT PASSTHROUGH ACTION BUTTON =================
                                if (showWorkoutPassButton) ...[
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(width * 0.045, width * 0.045, width * 0.045, 0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE96225),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        onPressed: () async {
                                          String? userId = await SessionManager.getUserId();
                                          if (context.mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => SingleWorkoutPassScreen(
                                                  postId: "47498", 
                                                  userId: userId ?? "",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          "Purchase a Single Workout Pass",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: width * 0.038,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                SizedBox(height: width * 0.05),

                                // ================= TIMETABLE CONTENT LOOP =================
                                ListView.builder(
                                  itemCount: trainingSchedule.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    left: width * 0.045,
                                    right: width * 0.045,
                                    bottom: width * 0.03,
                                  ),
                                  itemBuilder: (context, i) {
                                    final schedule = trainingSchedule[i]['time_and_program']?.toString() ?? "";

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: width * 0.04,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // ================= ORANGE BULLET =================
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 5,
                                            ),
                                            child: Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(0xFFE96225),
                                                  width: 2.2,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: width * 0.035,
                                          ),
                                          // ================= TEXT BLOCK =================
                                          Expanded(
                                            child: Text(
                                              schedule,
                                              style: TextStyle(
                                                fontSize: width * 0.038,
                                                color: const Color(0xFF333333),
                                                height: 1.4,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ); 
                        },
                      ),
                    ),
                  ],
                ),
          
          // ✅ ADDED: Full screen overlay blocking touches when API details fetch runs
          if (isFetchingProgram)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE96225)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}