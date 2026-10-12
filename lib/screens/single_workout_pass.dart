
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/session_manager.dart';
import 'booking_appointment_screen.dart';
import '../services/api_service.dart';
import 'package:flutter_html/flutter_html.dart';

class SingleWorkoutPassScreen extends StatefulWidget {
  final String userId;
  final String postId;
  const SingleWorkoutPassScreen({super.key, required this.userId, required this.postId});

  @override
  State<SingleWorkoutPassScreen> createState() => _SingleWorkoutPassScreenState();
}

class _SingleWorkoutPassScreenState extends State<SingleWorkoutPassScreen> {
  int _currentStep = 0; // 0: Service Selection, 1: Date & Time, 2: Your Information, 3: Payments Review
  bool _isLoading = true;
  List<dynamic> _servicesList = [];
  Map<String, dynamic>? _programData;
  String _errorMessage = '';

  // Step 1 Selections
  Map<String, dynamic>? _selectedService;

  // Step 2 Selections
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Step 3 Controllers & Dropdowns
  final _formKey = GlobalKey<FormState>();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _playerNameController = TextEditingController();
  String? _selectedReferral;
  final List<String> _referralsList = ["Returning Member", "Our Social Media Presence", "Our Social Media Advertisement", "Referred by a Member/Friend", "Your School", "Known in the Community", "General Search/Found Us Online"];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _fetchProgramDetails();
    _fetchServicesData();
    _loadUserSessionData();
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  // --- API INTEGRATION ENGINE ---
  Future<void> _fetchServicesData() async {
    try {
      final response = await http.get(Uri.parse("https://starting5.net/wp-json/mobile/v1/services"));
      if (response.statusCode == 200) {
        setState(() {
          _servicesList = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load services framework: $e")));
    }
  }

  Future<void> _fetchProgramDetails() async {
    final result = await ApiService.fetchProgramSingle(widget.postId);

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

  void _loadUserSessionData() async {
    String? firstName = await SessionManager.getUserFirstName();
    String? lastName = await SessionManager.getUserLastName();
    String? email = await SessionManager.getUserEmail();
    if (mounted) {
      setState(() {
        _fNameController.text = (firstName ?? "").replaceAll(' ', '').trim();
        _lNameController.text = (lastName ?? "").replaceAll(' ', '').trim();
        _emailController.text = (email ?? "").replaceAll(' ', '').trim();
      });
    }
  }

  List<String> _getAvailableDaysForSelectedService() {
    if (_selectedService == null) return [];
    List<dynamic> schedule = _selectedService!['schedule'] ?? [];
    return schedule.map((item) => (item['day'] ?? "").toString().toLowerCase()).toList();
  }

  List<String> _getTimeSlotsForWeekday(String dayName) {
    if (_selectedService == null) return [];
    List<dynamic> schedule = _selectedService!['schedule'] ?? [];
    return schedule
        .where((item) => (item['day'] ?? "").toString().toLowerCase() == dayName.toLowerCase())
        .map((item) => (item['booking_time'] ?? "").toString())
        .toList();
  }

  String _getRawDigits(String text) {
    return text.replaceAll(RegExp(r'\D'), '');
  }

  void _handleContinueButton() {
    if (_currentStep == 0) {
      if (_selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a workout service option package.")));
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_selectedDate == null || _selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a valid workout session date & time slot.")));
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 3);
      }
    } else if (_currentStep == 3) {
      final double computedPrice = double.tryParse(_selectedService!['price']?.toString() ?? '25.0') ?? 25.0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingAppointmentScreen(
            entryId: _selectedService!['id']?.toString() ?? "0",
            userId: widget.userId,
            productTitle: "${_selectedService!['name']} Pass (${DateFormat('dd MMM').format(_selectedDate!)})",
            productId: _selectedService!['id']?.toString() ?? "0",
            formId: "single_pass",
            programData: {
              "subscription": "No",
              "product_price": computedPrice.toString(),
              "processing_fee": "3.5%",
              "sign_up_fee": "0",
              "workout_date": DateFormat('yyyy-MM-dd').format(_selectedDate!),
              "workout_time": _selectedTimeSlot,
              "player_name": _playerNameController.text.trim(),
              "parent_first_name": _fNameController.text.trim(),
              "parent_last_name": _lNameController.text.trim(),
              "parent_email": _emailController.text.trim(),
              "parent_phone": _phoneController.text,//_getRawDigits(_phoneController.text),
              "referral": _selectedReferral,
              "duration": _selectedService!['duration']?.toString() ?? "0",
              "service_name": _selectedService!['name']?.toString() ?? "",
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "Single Workout Pass",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE96225)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepProgressIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ ADDED: Web-style Header Banner (Visible during Service Selection)
                          if (_currentStep == 0) _buildWebsiteHeaderBanner(),
                          
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 5),
                            child: Text(
                              _getStepHeadingText(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B3147)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: _buildActiveStepLayout(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildFixedBottomActionBar(),
                ],
              ),
      ),
    );
  }

  String _getStepHeadingText() {
    switch (_currentStep) {
      case 0: return "Service Selection";
      case 1: return "Date & Time";
      case 2: return "Your Information";
      case 3: return "Payments";
      default: return "";
    }
  }

  Widget _buildStepProgressIndicator() {
    return Container(
      width: double.infinity,
      height: 4,
      color: Colors.grey.shade200,
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: index <= _currentStep ? const Color(0xFFE96225) : Colors.grey.shade200,
            ),
          );
        }),
      ),
    );
  }

  // ✅ NEW METHOD: Built exactly to mirror your custom branding layout specs cleanly
  Widget _buildWebsiteHeaderBanner() {
    final String programTitle = _programData!['acf_title'] ?? 'Program Details';
    final String description = _programData!['content'] ?? '';

  if (_errorMessage.isNotEmpty || _programData == null) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E201F), Color(0xFF1A1211)],
        ),
        image: DecorationImage(
          image: AssetImage("assets/images/dash_bg.png"), // Uses fallback token if needed
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            programTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
           SizedBox(height: 16),
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
                        fontSize: FontSize(14.5),
                        color: Colors.white,
                      ),
                      "strong": Style(
                        color: Colors.white,
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
          // Text(
          //   description,
          //   textAlign: TextAlign.center,
          //   style: TextStyle(
          //     color: Colors.white.withOpacity(0.85),
          //     fontSize: 14,
          //     height: 1.45,
          //     fontWeight: FontWeight.w400,
          //   ),
          // ),
          // const SizedBox(height: 16),
          // Text(
          //   "Our booking calendar below makes it easy to schedule your designated time frame for your child.",
          //   textAlign: TextAlign.center,
          //   style: TextStyle(
          //     color: Colors.white.withOpacity(0.85),
          //     fontSize: 14,
          //     height: 1.45,
          //     fontWeight: FontWeight.w400,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildActiveStepLayout() {
    switch (_currentStep) {
      case 0: return _buildServiceSelectionStep();
      case 1: return _buildDateTimeStep();
      case 2: return _buildInformationStep();
      case 3: return _buildSummaryPaymentStep();
      default: return const SizedBox.shrink();
    }
  }

  // ==========================================
  // STEP 1: SERVICE SELECTION
  // ==========================================
  Widget _buildServiceSelectionStep() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Service *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedService?['id']?.toString(),
              hint: const Text("Select Service", style: TextStyle(color: Colors.grey, fontSize: 14)),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              selectedItemBuilder: (BuildContext context) {
                return _servicesList.map<Widget>((service) {
                  return Text(
                    service['name'] ?? "",
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  );
                }).toList();
              },
              items: _servicesList.map<DropdownMenuItem<String>>((service) {
                return DropdownMenuItem<String>(
                  value: service['id']?.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 0.5))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            service['name'] ?? "",
                            style: const TextStyle(fontSize: 14, height: 1.2),
                            maxLines: 3,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "\$${service['price']}.00",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedService = _servicesList.firstWhere(
                    (element) => element['id']?.toString() == val,
                    orElse: () => null,
                  );
                  _selectedDate = null;
                  _selectedTimeSlot = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: DATE & TIME
  // ==========================================
  Widget _buildDateTimeStep() {
    List<String> activeWeekdays = _getAvailableDaysForSelectedService();
    String formattedSelectionHeader = '';

    if (_selectedDate != null && _selectedTimeSlot != null) {
      String cleanTime = _selectedTimeSlot!.split(" - ").first;
      formattedSelectionHeader = "${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)} - $cleanTime";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMMM yyyy').format(_focusedMonth), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.black87),
                          onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.black87),
                          onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                        ),
                      ],
                    )
                  ],
                ),
                const Center(child: Text("America/Los_Angeles", style: TextStyle(color: Color(0xFFFC790F), fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(height: 15),
                Row(
                  children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                      .map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black))))).toList(),
                ),
                const Divider(height: 20),
                _buildCalendarDaysGrid(activeWeekdays),
              ],
            ),
          ),
        ),

        if (_selectedDate != null) ...[
          const SizedBox(height: 25),
          if (formattedSelectionHeader.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
              child: Text(
                formattedSelectionHeader,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _getTimeSlotsForWeekday(DateFormat('EEEE').format(_selectedDate!)).map((slot) {
              bool isSelected = _selectedTimeSlot == slot;
              return ChoiceChip(
                label: Text(slot, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                selected: isSelected,
                selectedColor: const Color(0xFFE96225),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() => _selectedTimeSlot = slot);
                  }
                },
              );
            }).toList(),
          ),
        ]
      ],
    );
  }

  Widget _buildCalendarDaysGrid(List<String> activeWeekdays) {
    int daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    int weekdayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    List<Widget> dayCells = [];
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < weekdayOffset; i++) {
      dayCells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      String weekdayName = DateFormat('EEEE').format(cellDate).toLowerCase();

      bool isPastDate = cellDate.isBefore(todayMidnight);
      bool isAllowedWeekday = activeWeekdays.contains(weekdayName) && !isPastDate;

      bool isToday = todayMidnight.isAtSameMomentAs(cellDate);
      bool isSelected = _selectedDate != null && _selectedDate!.isAtSameMomentAs(cellDate);

      dayCells.add(
        GestureDetector(
          onTap: isAllowedWeekday ? () {
            List<String> availableSlots = _getTimeSlotsForWeekday(DateFormat('EEEE').format(cellDate));
            setState(() {
              _selectedDate = cellDate;
              _selectedTimeSlot = availableSlots.isNotEmpty ? availableSlots.first : null;
            });
          } : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE96225)
                      : (isAllowedWeekday ? const Color(0xFFFFF2EB) : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                  border: isAllowedWeekday && !isSelected
                      ? Border.all(color: const Color(0xFFFFC5A1), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isAllowedWeekday ? const Color(0xFFCB5312) : const Color(0xFFD1D5DB)),
                    ),
                  ),
                ),
              ),
              if (isToday)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(color: Color(0xFFE96225), shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      children: dayCells,
    );
  }

//Below code is used to disable a specific date
/*
Widget _buildCalendarDaysGrid(List<String> activeWeekdays) {
    int daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    int weekdayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    List<Widget> dayCells = [];
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < weekdayOffset; i++) {
      dayCells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      String weekdayName = DateFormat('EEEE').format(cellDate).toLowerCase();

      // Check if the current cell date is September 7, 2026
      bool isDisabledDate = cellDate.year == 2026 && cellDate.month == 9 && cellDate.day == 7;

      bool isPastDate = cellDate.isBefore(todayMidnight);
      // Disable if past date OR specifically September 7, 2026
      bool isAllowedWeekday = activeWeekdays.contains(weekdayName) && !isPastDate && !isDisabledDate;

      bool isToday = todayMidnight.isAtSameMomentAs(cellDate);
      bool isSelected = _selectedDate != null && _selectedDate!.isAtSameMomentAs(cellDate);

      dayCells.add(
        GestureDetector(
          onTap: isAllowedWeekday ? () {
            List<String> availableSlots = _getTimeSlotsForWeekday(DateFormat('EEEE').format(cellDate));
            setState(() {
              _selectedDate = cellDate;
              _selectedTimeSlot = availableSlots.isNotEmpty ? availableSlots.first : null;
            });
          } : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE96225)
                      : (isAllowedWeekday ? const Color(0xFFFFF2EB) : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                  border: isAllowedWeekday && !isSelected
                      ? Border.all(color: const Color(0xFFFFC5A1), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isAllowedWeekday ? const Color(0xFFCB5312) : const Color(0xFFD1D5DB)),
                    ),
                  ),
                ),
              ),
              if (isToday)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(color: Color(0xFFE96225), shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      children: dayCells,
    );
  }*/

  // ==========================================
  // STEP 3: YOUR INFORMATION
  // ==========================================
  Widget _buildInformationStep() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildFormTextField("First Name *", "First Name", controller: _fNameController, isName: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildFormTextField("Last Name *", "Last Name", controller: _lNameController, isName: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildFormTextField("Email *", "Enter email", controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildFormTextField("Phone *", "(###) ###-####", controller: _phoneController, keyboardType: TextInputType.phone, isUSPhone: true),
              const SizedBox(height: 16),
              _buildFormTextField("Player Name (Please Indicate Child's Name) *", "Child's Name", controller: _playerNameController, isPlayerName: true),
              const SizedBox(height: 16),
              const Text("How did you hear about us? (Select Best Reason) *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReferral,
                isExpanded: true,
                hint: const Text("Select option...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _referralsList.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 15)))).toList(),
                onChanged: (val) => setState(() => _selectedReferral = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField(String label, String hint, {required TextEditingController controller, TextInputType keyboardType = TextInputType.text, bool isName = false, bool isPlayerName = false, bool isUSPhone = false}) {
    bool isEmail = keyboardType == TextInputType.emailAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: (isName || isPlayerName) ? TextCapitalization.words : TextCapitalization.none,
          maxLength: isUSPhone ? 14 : null,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          inputFormatters: [
            if (isName || isEmail) ...[FilteringTextInputFormatter.deny(RegExp(r'\s'))],
            if (isPlayerName) ...[
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.contains('  ')) return oldValue;
                return newValue;
              }),
            ],
            if (isUSPhone) ...[FilteringTextInputFormatter.digitsOnly],
          ],
          onChanged: isUSPhone ? (value) {
            String digits = _getRawDigits(value);
            String masked = "";
            if (digits.length > 0) {
              masked += "(" + digits.substring(0, digits.length > 3 ? 3 : digits.length);
            }
            if (digits.length > 3) {
              masked += ") " + digits.substring(3, digits.length > 6 ? 6 : digits.length);
            }
            if (digits.length > 6) {
              masked += "-" + digits.substring(6, digits.length > 10 ? 10 : digits.length);
            }
            controller.value = TextEditingValue(
              text: masked,
              selection: TextSelection.fromPosition(TextPosition(offset: masked.length)),
            );
          } : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (isUSPhone && _getRawDigits(v).length != 10) return 'Must be 10 digits';
            if (isEmail && !v.contains('@')) return 'Invalid email reference';
            return null;
          },
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: SUMMARY & BILLING REVIEW
  // ==========================================
  Widget _buildSummaryPaymentStep() {
    String formattedPassDate = _selectedDate != null ? DateFormat('MMMM dd, yyyy').format(_selectedDate!) : '';
    double baseCost = double.tryParse(_selectedService!['price']?.toString() ?? '25.0') ?? 25.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Services", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                "${_selectedService!['name']} (\$${baseCost.toStringAsFixed(2)}) × 1 person",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF131C32)),
              ),
              const SizedBox(height: 4),
              Text("Scheduled: $formattedPassDate @ $_selectedTimeSlot", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("\$${baseCost.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE96225))),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            "You will be redirected to the payment checkout.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        )
      ],
    );
  }

  // ==========================================
  // FIXED BOTTOM FOOTER BUTTON
  // ==========================================
  Widget _buildFixedBottomActionBar() {
    bool isButtonEnabled = true;

    if (_currentStep == 0 && _selectedService == null) {
      isButtonEnabled = false;
    }

    if (_currentStep == 1 &&
        (_selectedDate == null || _selectedTimeSlot == null)) {
      isButtonEnabled = false;
    }

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 12
            : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isButtonEnabled
                ? const Color(0xFFE96225)
                : Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: isButtonEnabled
              ? _handleContinueButton
              : null,
          child: const Text(
            "Continue",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

