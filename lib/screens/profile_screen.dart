
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; 
import '../services/session_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isEdited = false;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String _profileImageUrl = "";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _billingController = TextEditingController();
  final TextEditingController _billingCityController = TextEditingController();
  final TextEditingController _residenceController = TextEditingController();
  final TextEditingController _shippingCityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _setupListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _billingController.dispose();
    _billingCityController.dispose();
    _residenceController.dispose();
    _shippingCityController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _setupListeners() {
    List<TextEditingController> ctrls = [
      _nameController, _emailController, _phoneController,
      _billingController, _billingCityController, _residenceController,
      _shippingCityController, _dobController,
    ];
    for (var c in ctrls) {
      c.addListener(() {
        if (!_isLoading && !_isEdited) {
          setState(() => _isEdited = true);
        }
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFC790F)),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFC790F)),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _isEdited = true;
      });
    } catch (e) {
      debugPrint("IMAGE ERROR : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening $source: $e")),
      );
    }
  }

  Future<void> _loadProfileData() async {
    try {
      String? userId = await SessionManager.getUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final response = await http.get(Uri.parse("https://starting5.net/api/get-profile.php?user_id=$userId"));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['errcode'] == 200) {
          final profile = jsonData['profile'];
          final billing = profile['billing'];
          final shipping = profile['shipping'];

          var firstName = (profile['first_name']?.toString() ?? "").replaceAll(' ', '').trim();
          var lastName = (profile['last_name']?.toString() ?? "").replaceAll(' ', '').trim();
          var email = (profile['email']?.toString() ?? "").replaceAll(' ', '').trim();
          var userName = '$firstName $lastName';
          var dob = profile['dob']?.toString() ?? '';
          _profileImageUrl = profile['profile_photo_url']?.toString() ?? '';

          String formattedDob = dob;
          try {
            if (dob.isNotEmpty) {
              DateTime parsedDate = DateTime.parse(dob);
              formattedDob = DateFormat('MM-dd-yyyy').format(parsedDate);
            }
          } catch (_) {}

          _dobController.text = formattedDob;
          var rawPhone = (profile['phone']?.toString() ?? "").replaceAll(RegExp(r'\D'), '');
          _phoneController.text = _formatRawPhoneNumber(rawPhone);
          
          await SessionManager.setUserEmail(email);
          await SessionManager.setUserFirstName(firstName);
          await SessionManager.setUserLastName(lastName);
          await SessionManager.setUserName(userName);

          setState(() {
            _nameController.text = "$firstName $lastName".trim();
            _emailController.text = email;
            _billingController.text = billing['address1']?.toString() ?? '';
            _billingCityController.text = billing['city']?.toString() ?? '';
            _residenceController.text = shipping['address1']?.toString() ?? '';
            _shippingCityController.text = shipping['city']?.toString() ?? '';
            _dobController.text = formattedDob;
            _profileImageUrl = profile['profile_photo_url']?.toString() ?? '';
            
            _phoneController.text = _formatRawPhoneNumber(rawPhone);
            _isLoading = false;
            _isEdited = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatRawPhoneNumber(String rawDigits) {
    if (rawDigits.length > 10) rawDigits = rawDigits.substring(0, 10);
    if (rawDigits.length > 6) {
      return "(${rawDigits.substring(0, 3)}) ${rawDigits.substring(3, 6)} ${rawDigits.substring(6)}";
    } else if (rawDigits.length > 3) {
      return "(${rawDigits.substring(0, 3)}) ${rawDigits.substring(3)}";
    } else if (rawDigits.isNotEmpty) {
      return "($rawDigits";
    }
    return "";
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 10));
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('MM-dd-yyyy').parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFC790F),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('MM-dd-yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? userId = await SessionManager.getUserId();
      if (userId == null) return;
      final uri = Uri.parse("https://starting5.net/api/profile-update.php?user_id=$userId");
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({"Accept": "application/json"});
      
      List<String> nameParts = _nameController.text.trim().split(RegExp(r'\s+'));
      //String cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

      String cleanDob = _dobController.text.trim();
      try {
        if (cleanDob.isNotEmpty) {
          DateTime parsedDate = DateFormat('MM-dd-yyyy').parse(cleanDob);
          cleanDob = DateFormat('yyyy-MM-dd').format(parsedDate);
        }
      } catch (_) {}
      
      request.fields['user_id'] = userId;
      request.fields['first_name'] = nameParts.isNotEmpty ? nameParts.first.replaceAll(' ', '').trim() : "";
      request.fields['last_name'] = nameParts.length > 1 ? nameParts.sublist(1).join(" ").replaceAll(' ', '').trim() : "";
      request.fields['billing_phone'] = _phoneController.text;//cleanPhone;
      request.fields['billing_address_1'] = _billingController.text.trim();
      request.fields['billing_city'] = _billingCityController.text.trim();
      request.fields['shipping_address_1'] = _residenceController.text.trim();
      request.fields['shipping_city'] = _shippingCityController.text.trim();
      request.fields['dob'] = cleanDob;
      request.fields['phone'] = _phoneController.text;//cleanPhone;

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profile_photo', _selectedImage!.path));
      }

      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
        setState(() => _isEdited = false);
        await _loadProfileData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          // ✅ FIX: Kept background layout at the absolute base of the Stack tree to guarantee full-screen rendering under all states
          Positioned.fill(
            child: Image.asset(
              'assets/images/dash_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),
          
          Scaffold(
            // ✅ Makes the canvas transparent so our global fixed background can show through cleanly
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildMainGlassContainer(),
                            const SizedBox(height: 25),
                            _buildSaveButtonSmall(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainGlassContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFC790F), Color(0xFFCB5312)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _buildProfileInfo(),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDataCard("Parent/Player Details", [
                      _buildField("Parent/Guardian Name *", _nameController),
                      _buildField("Email *", _emailController, keyboardType: TextInputType.emailAddress),
                      _buildField("Phone *", _phoneController, keyboardType: TextInputType.phone),
                      _buildField("Date of Birth *", _dobController, isDatePicker: true),
                    ]),
                    // const SizedBox(height: 16),
                    // _buildDataCard("Contact", [
                    //   _buildField("Billing Address", _billingController),
                    //   _buildField("Billing City", _billingCityController),
                    //   _buildField("Residence Address", _residenceController),
                    //   _buildField("Shipping City", _shippingCityController),
                    // ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 54,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!) as ImageProvider
                      : _profileImageUrl.isNotEmpty
                          ? NetworkImage(_profileImageUrl)
                          : const AssetImage('assets/images/dash_bg.png'),
                ),
              ),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFFFC790F)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _nameController.text.isEmpty ? "Name" : _nameController.text,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        // Text(
        //   _dobController.text.isEmpty ? "DoB: " : "DoB: ${_dobController.text}",
        //   style: const TextStyle(color: Colors.white70, fontSize: 13),
        // ),
      ],
    );
  }

  Widget _buildDataCard(String title, List<Widget> fields) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.98), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF131C32))),
          const Divider(height: 20, color: Color(0xFFE1E4E8)),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildField(
    String label, 
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool isDatePicker = false,
  }) {
    bool isPhoneField = keyboardType == TextInputType.phone;
    bool isEmailField = keyboardType == TextInputType.emailAddress;
    bool isNameField = label.toLowerCase().contains("name");

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8E94A3), fontWeight: FontWeight.bold)),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: isNameField ? TextCapitalization.words : TextCapitalization.none,
            readOnly: isDatePicker,
            onTap: isDatePicker ? _selectDate : null,
            
            inputFormatters: [
              if (isPhoneField) ...[
                FilteringTextInputFormatter.digitsOnly,
                CustomPhoneTextInputFormatter(), 
              ],
              if (isEmailField) ...[
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              if (isNameField) ...[
                FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
              ],
              if (!isNameField && !isEmailField && !isPhoneField && !isDatePicker) ...[
                FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
              ],
            ],

            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1D294B)),
            decoration: InputDecoration(
              isDense: true, 
              border: InputBorder.none, 
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              errorStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              suffixIcon: isDatePicker 
                  ? const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8E94A3))
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),

            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Required';
              }
              if (isPhoneField) {
                String digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                if (digitsOnly.length != 10) {
                  return 'Must be exactly 10 digits.';
                }
              }
              if (isEmailField && !v.contains('@')) {
                return 'Invalid email address.';
              }
              if (isNameField) {
                List<String> tokens = v.trim().split(RegExp(r'\s+'));
                if (tokens.length < 2) {
                  return 'Please enter both your First and Last name.';
                }
              }
              return null;
            },
          ),
          const Divider(height: 1, color: Color(0xFFE1E4E8)),
        ],
      ),
    );
  }

  Widget _buildSaveButtonSmall() {
    return Center(
      child: ElevatedButton(
        onPressed: (_isEdited && !_isSaving) ? _saveProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFC790F),
          disabledBackgroundColor: Colors.white.withOpacity(0.1),
          fixedSize: const Size(200, 50),
          shape: const StadiumBorder(),
          elevation: 4,
        ),
        child: _isSaving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text("SAVE CHANGES", style: TextStyle(color: _isEdited ? Colors.white : Colors.white24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class CustomPhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    String digits = text.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 10) {
      return oldValue;
    }

    if (newValue.text.length < oldValue.text.length) {
      if (digits.length <= 3) {
        return TextEditingValue(
          text: digits,
          selection: TextSelection.collapsed(offset: digits.length),
        );
      }
      
      String masked = "";
      if (digits.isNotEmpty) {
        masked += "(${digits.substring(0, 3)})";
      }
      if (digits.length > 3) {
        masked += " ${digits.substring(3, digits.length > 6 ? 6 : digits.length)}";
      }
      if (digits.length > 6) {
        masked += " ${digits.substring(6)}";
      }
      return TextEditingValue(
        text: masked,
        selection: TextSelection.collapsed(offset: masked.length),
      );
    }

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final buffer = StringBuffer();
    int selectionIndex = newValue.selection.end;

    for (int i = 0; i < text.length; i++) {
      if (i == 0) {
        buffer.write('(${text[i]}');
        if (selectionIndex >= 1) selectionIndex++;
      } else if (i == 2) {
        buffer.write('${text[i]}) ');
        if (selectionIndex >= 3) selectionIndex += 2;
      } else if (i == 5) {
        buffer.write('${text[i]} ');
        if (selectionIndex >= 6) selectionIndex++;
      } else {
        buffer.write(text[i]);
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}