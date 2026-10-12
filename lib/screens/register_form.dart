
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../services/api_service.dart';
import 'checkout_screen.dart';
import '../services/session_manager.dart';

class RegistrationForm extends StatefulWidget {
  final String productId;
  final String title;
  final String formId;
  final String userId;
  final Map<String, dynamic>? programData;

  const RegistrationForm({
    super.key, 
    required this.productId, 
    required this.title, 
    required this.formId, 
    required this.userId, 
    required this.programData
  });

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  
  bool _agreedToWaiver = false;
  bool _isSaving = false; 

  final List<String> _statesList = 
  ["Alabama","Alaska", "Arizona", "Arkansas", "California", "Colorado", 
  "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia", 
  "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", 
  "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", 
  "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", 
  "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", 
  "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", 
  "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", 
  "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", 
  "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"];

  String? _selectedGender;
  String? _selectedGrade;
  String? _selectedShirtSize;
  String? _selectedRelationship;
  String? _selectedReferral;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _schoolController = TextEditingController(); 
  final _parentFirstController = TextEditingController();
  final _parentLastController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _signatureController = TextEditingController();
  final _coachReferralController = TextEditingController();
  
  final _stateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  void loadUserName() async {
    String? firstName = await SessionManager.getUserFirstName();
    String? lastName = await SessionManager.getUserLastName();
    String? email = await SessionManager.getUserEmail();

    if (mounted) {
      setState(() {
        _firstNameController.text = (firstName ?? "").replaceAll(' ', '').trim();
        _lastNameController.text = (lastName ?? "").replaceAll(' ', '').trim();
        _emailController.text = (email ?? "").replaceAll(' ', '').trim();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); 
    _firstNameController.dispose();
    _lastNameController.dispose();
    _schoolController.dispose();
    _parentFirstController.dispose();
    _parentLastController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _signatureController.dispose();
    _coachReferralController.dispose();
    _stateController.dispose(); 
    super.dispose();
  }

  bool get isGirlsShootout => widget.title.contains("Girl Shootout Registration Form");
  bool get isJuniorShootout => widget.title.contains("Junior Shootout");
  bool get isDemoForm => widget.title.contains("Demo Form");
  bool get isMonthlyTraining => widget.title.contains("Development Training");
  bool get isOpenShooting => widget.title.contains("Open Shooting");
  bool get isShootoutLeague => widget.title.contains("Shootout Registration Form");

  List<String> _getGradeOptions() {
    if (isJuniorShootout) {
      return ["Kindergarten", "1st", "2nd", "3rd"];
    } else if (isMonthlyTraining) {
      return ["Kindergarten", "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "11th", "12th"];
    } else if (isGirlsShootout) {
      return ["4th", "5th", "6th", "7th", "8th"];
    } else if (isDemoForm) {
      return ["Kindergarten", "1st", "2nd", "3rd"];
    } else if (isOpenShooting) {
      return ["9th", "10th", "11th", "12th"]; 
    }
    return ["3rd", "4th", "5th", "6th", "7th", "8th"]; 
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
    );
  }

  Widget _buildTextField(String label, String hint, {TextInputType keyboardType = TextInputType.text, required TextEditingController controller, bool isRequired = true}) {
    bool isPhoneField = keyboardType == TextInputType.phone;
    bool isEmailField = keyboardType == TextInputType.emailAddress;
    bool isZipField = label.toLowerCase().contains("zipcode");
    
    bool isNameField = controller == _firstNameController || 
                       controller == _lastNameController || 
                       controller == _parentFirstController || 
                       controller == _parentLastController;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(label),
          TextFormField(
            controller: controller,
            keyboardType: isZipField ? TextInputType.number : keyboardType,
            textCapitalization: isNameField ? TextCapitalization.words : TextCapitalization.none,
            maxLength: isPhoneField ? null : (isZipField ? 9 : null), 
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, 
            style: const TextStyle(fontSize: 15),
            inputFormatters: [
              if (isPhoneField) ...[
                FilteringTextInputFormatter.digitsOnly,
                CustomPhoneTextInputFormatter(), 
              ],
              if (isZipField) ...[
                FilteringTextInputFormatter.digitsOnly, 
                LengthLimitingTextInputFormatter(9),
              ],
              if (isNameField || isEmailField || isZipField) ...[
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              if (!isNameField && !isEmailField && !isZipField && !isPhoneField) ...[
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.contains('  ')) {
                    return oldValue; 
                  }
                  return newValue; 
                }),
              ],
            ],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return 'Required';
              }
              if (value != null && value.trim().isNotEmpty) {
                if (isPhoneField) {
                  String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                  if (digitsOnly.length != 10) {
                    return 'Must be exactly 10 digits.';
                  }
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableStateField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(label),
          TextFormField(
            controller: controller,
            readOnly: true, 
            style: const TextStyle(fontSize: 15),
            onTap: () async {
              final String? selectedState = await showSearch<String>(
                context: context,
                delegate: StateSearchDelegate(states: _statesList),
              );
              if (selectedState != null && selectedState.isNotEmpty) {
                setState(() {
                  controller.text = selectedState;
                });
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
  String label, 
  List<String> items, 
  String? value, 
  Function(String?) onChanged, 
  {bool isRequired = true} // Add optional parameter
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        FormField<String>(
          initialValue: value,
          // Only trigger error if required and value is null
          validator: (val) => (isRequired && val == null) ? 'Required' : null,
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputDecorator(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    fillColor: Colors.white,
                    filled: true,
                    errorText: state.hasError ? state.errorText : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      isExpanded: true,
                      hint: const Text("Select option...", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      menuMaxHeight: 300,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                      onChanged: (String? newValue) {
                        state.didChange(newValue);
                        onChanged(newValue);
                      },
                      items: items.map<DropdownMenuItem<String>>((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.normal)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildRow(BuildContext context, Widget left, Widget right) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    if (right is SizedBox) return left; 
    if (isMobile) return Column(children: [left, right]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: left), const SizedBox(width: 20), Expanded(child: right)],
    );
  }

  void _scrollToFirstValidationError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      bool foundFirstError = false;

      void scrollElement(Element element) {
        if (foundFirstError) return; 

        if (element.widget is FormField) {
          final FormFieldState state = (element as StatefulElement).state as FormFieldState;
          if (state.hasError) {
            foundFirstError = true; 
            
            final renderBox = element.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final position = renderBox.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
              final offset = _scrollController.offset + position.dy - 140.0; 
              
              _scrollController.animateTo(
                offset < 0 ? 0 : offset,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
            return; 
          }
        }
        element.visitChildren(scrollElement);
      }
      context.visitChildElements(scrollElement);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String howDidYouAbout = "How did you hear about us? (Select Best Reason) *";
    bool isMandatory = true;
    if (isMonthlyTraining || isOpenShooting)
    {
      howDidYouAbout = "How did you hear about us? (Select Best Reason)";
      isMandatory = false;
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: kToolbarHeight + 10, 
          title: Text(
            widget.title,
            maxLines: 2, 
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black, 
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController, 
            padding: EdgeInsets.symmetric(horizontal: screenWidth > 800 ? screenWidth * 0.15 : 20, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Player's First Name & Last Name
                  _buildRow(context, 
                    _buildTextField("Player's First Name *", "Player's First Name", controller: _firstNameController), 
                    _buildTextField("Player's Last Name *", "Player's Last Name", controller: _lastNameController)
                  ),

                  // 2. OPEN SHOOTING SPECIFIC SEQUENCE
                  if (isOpenShooting) ...[
                    _buildRow(
                      context,
                      _buildDropdown("Player's Grade *", _getGradeOptions(), _selectedGrade, (val) => setState(() => _selectedGrade = val)),
                      _buildTextField("Player's School *", "Player's School", controller: _schoolController),
                    ),
                    _buildRow(context, 
                      _buildTextField("Parent/Guardian First Name *", "First Name", controller: _parentFirstController), 
                      _buildTextField("Parent/Guardian Last Name *", "Parent/Guardian Last Name", controller: _parentLastController)
                    ),
                    _buildRow(
                      context,
                      _buildTextField("Parent/Guardian Email *", "Email Address", keyboardType: TextInputType.emailAddress, controller: _emailController),
                      _buildTextField("Parent/Guardian Cell # *", "Parent/Guardian Cell #", keyboardType: TextInputType.phone, controller: _phoneController),
                    ),
                  ] 
                  
                  // 3. STANDARD FORM SEQUENCE FOR OTHER PROGRAMS
                  else ...[
                    if (!isGirlsShootout) 
                      _buildRow(context,
                        _buildDropdown("Player's Gender *", ["Male", "Female"], _selectedGender, (val) => setState(() => _selectedGender = val)),
                        const SizedBox.shrink(),
                      ),

                    _buildRow(
                      context,
                      _buildDropdown("Player's Grade *", _getGradeOptions(), _selectedGrade, (val) => setState(() => _selectedGrade = val)),
                      _buildDropdown("Player's Shirt Size *", ["Youth Sm", "Youth Med", "Youth Lrg", "Youth XL", "Adult Sm", "Adult Med", "Adult Lrg", "Adult XL"], _selectedShirtSize, (val) => setState(() => _selectedShirtSize = val)),
                    ),

                    _buildRow(context, 
                      _buildTextField("Parent/Guardian First Name *", "First Name", controller: _parentFirstController), 
                      _buildTextField("Parent/Guardian Last Name *", "Parent/Guardian Last Name", controller: _parentLastController)
                    ),
                    
                    _buildTextField("Parent/Guardian Address *", "Your Street Address", controller: _addressController),

                    if (screenWidth < 600) ...[
                      _buildTextField("City *", "City", controller: _cityController),
                      _buildTextField("Zipcode *", "Zipcode", controller: _zipController),
                      _buildSearchableStateField("State *", _stateController, "Select State..."),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildTextField("City *", "City", controller: _cityController)),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: _buildTextField("Zipcode *", "Zipcode", controller: _zipController)),
                          const SizedBox(width: 10),
                          Expanded(flex: 3, child: _buildSearchableStateField("State *", _stateController, "Select State...")),
                        ],
                      ),

                    _buildRow(
                      context,
                      _buildTextField("Parent/Guardian Email *", "Email Address", keyboardType: TextInputType.emailAddress, controller: _emailController),
                      _buildTextField("Parent/Guardian Cell # *", "Parent/Guardian Cell #", keyboardType: TextInputType.phone, controller: _phoneController),
                    ),

                    _buildRow(
                      context,
                      _buildTextField("Alternate Emergency Contact # *", "Alternate Emergency Contact #", keyboardType: TextInputType.phone, controller: _emergencyPhoneController),
                      _buildDropdown("Relationship to Player *", ["Mother", "Father", "Legal Guardian"], _selectedRelationship, (val) => setState(() => _selectedRelationship = val)),
                    ),
                  ],

                  // Referral Dropdown
                  _buildRow(context,
                    _buildDropdown(howDidYouAbout, ["Returning Member", "Our Social Media Presence", "Our Social Media Advertisement", "Referred by a Member/Friend", "Your School", "Known in the Community", "General Search/Found Us Online"], _selectedReferral, (val) => setState(() => _selectedReferral = val),isRequired: isMandatory),
                    const SizedBox.shrink(),
                  ),

                  if (isMonthlyTraining) 
                    _buildRow(context,
                      _buildTextField("Coaches Referral Name", "Please indicate Coach's name here", controller: _coachReferralController, isRequired: false),
                      const SizedBox.shrink(),
                    ),

                  const SizedBox(height: 10),
                  const Text("Liability Waiver for Guest and Member Participation:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  const Text(
                    "Guests and members are subject to all policies and procedures of STARTING 5 BASKETBALL. Upon any violations of policy or if you are deemed by the facility to be acting in a manner that is unacceptable to the facility, you will be required to leave immediately.\n\n"
                    "The facility reserves the right to refuse admission to any guest and member for any reason. Guests residing in a local community (communities within neighboring counties) may not enter the facility as guests more than three (3) times.\n\n"
                    "My signature below indicates full understanding and compliance with the above provisions and the waiver of liability.\n\n"
                    "I understand that using the exercise equipment and facilities at STARTING 5 BASKETBALL may subject me to certain physical and medical risks that I agree to assume. "
                    "I declare myself to be physically sound and do not have any physical impairment, condition or illness that would prevent my safe participation in any exercise program at STARTING 5 BASKETBALL. I further understand that the facility assumes no responsibility for my personal safety and I hereby release the facility and its owners, officers, directors, agents, trainers, instructors, coaches and employees from any and all liability which may arise directly or indirectly from any damage to me or my property as a result of my participation and/or use of the facilities.",
                    style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 67, 67, 67))
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Checkbox(value: _agreedToWaiver, onChanged: (val) => setState(() => _agreedToWaiver = val!), activeColor: Colors.blue),
                        const Text("I agree to the above waiver *", style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
                      ],
                    ),
                  ),

                  _buildTextField("\"Type your name\" here if you agree with the above statement. *", "Type your name here to Sign", controller: _signatureController),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Notice: Registration is not done until payment is completed on the next page.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        const Text("Please also indicate your child's name(s) in the NOTES SECTION BOX of the next Payment Page.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                        if (!isMonthlyTraining && !isOpenShooting && !isShootoutLeague) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Note: Please register your child for the grade they will be in during the 2026-27 school year.",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0572B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                      onPressed: _isSaving ? null : () {
                        if (_formKey.currentState!.validate()) {
                          if (!_agreedToWaiver) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please agree to the waiver!")));
                            return;
                          }
                          _saveForm();
                        } else {
                          _scrollToFirstValidationError(); 
                        }
                      },
                      child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveForm() async {
    setState(() => _isSaving = true);
    try {
      Map<String, String> data = {
        "player_first_name": _firstNameController.text.trim(),
        "player_last_name": _lastNameController.text.trim(),
        "player_grade": _selectedGrade ?? "",
        "player_shirt": isOpenShooting ? "" : (_selectedShirtSize ?? ""),
        "parent_first_name": _parentFirstController.text.trim(),
        "parent_last_name": _parentLastController.text.trim(),
        "street_address": isOpenShooting ? "" : _addressController.text.trim(),
        "city": isOpenShooting ? "" : _cityController.text.trim(),
        "zipcode": isOpenShooting ? "" : _zipController.text.trim(),
        "state": isOpenShooting ? "" : _stateController.text.trim(), 
        "parent_email": _emailController.text.trim(),
        "phonenumber": _phoneController.text,
        "player_relation": isOpenShooting ? "" : (_selectedRelationship ?? ""),
        "waiver_agree": "1",
        "accept_signature": _signatureController.text.trim(),
        "user_id": widget.userId,
        "form_id": widget.formId,
        "product_id": widget.productId,
        "about_us" : _selectedReferral ?? ""
      };

    if (!isOpenShooting) {
      if (!isGirlsShootout) {
        data["player_gender"] = _selectedGender ?? "";
      } else {
        data["player_gender"] = 'Female';
      }
      data["emergency_contact"] = _emergencyPhoneController.text;
    }else {
      data["player_school"] = _schoolController.text.trim();
    }
      if (isMonthlyTraining) {
        data["coach_referral"] = _coachReferralController.text.trim();
      }

      final result = await ApiService.saveRegistrationForm(
        formData: data,
        formType: widget.title,
      );

      if (result['success'] == true) {
        final Map<String, dynamic> responsePayload = result['data'] ?? {};
        String entryId = responsePayload['post_id']?.toString() ?? "";

        if (mounted) {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => CheckoutScreen(
                entryId: entryId,
                userId: widget.userId,
                productTitle: widget.title,
                productId: widget.productId,
                formId: widget.formId,
                cityStr: _cityController.text,
                stateStr: _stateController.text,
                zipStr: _zipController.text,
                phoneStr: _phoneController.text,
                programData: widget.programData,
              )
            )
          );
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Form submitted successfully!")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Submission failed!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class StateSearchDelegate extends SearchDelegate<String> {
  final List<String> states;

  StateSearchDelegate({required this.states});

  @override
  String get searchFieldLabel => 'Search State...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0.5),
      inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.black54),
          onPressed: () => query = '',
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final filteredStates = states
        .where((state) => state.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filteredStates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No states found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStates.length,
      itemBuilder: (context, index) {
        final item = filteredStates[index];
        return ListTile(
          title: Text(item, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          onTap: () => close(context, item),
        );
      },
    );
  }
}