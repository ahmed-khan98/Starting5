import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'checkout_screen.dart';

class DynamicRegistrationForm extends StatefulWidget {
  final String productId;
  final String title;
  final String formId;
  final String userId;
  final Map<String, dynamic>? programData;

  const DynamicRegistrationForm({
    super.key,
    required this.productId,
    required this.title,
    required this.formId,
    required this.userId,
    required this.programData,
  });

  @override
  State<DynamicRegistrationForm> createState() => _DynamicRegistrationFormState();
}

class _FormOption {
  final String value;
  final String label;

  const _FormOption({required this.value, required this.label});
}

class _DynamicField {
  final String name;
  final String label;
  final String type;
  final bool required;
  final String content;
  final List<_FormOption> options;

  const _DynamicField({
    required this.name,
    required this.label,
    required this.type,
    required this.required,
    required this.content,
    required this.options,
  });

  factory _DynamicField.fromJson(Map<String, dynamic> json) {
    return _DynamicField(
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: (json['type'] ?? 'text').toString().toLowerCase(),
      required: _isRequiredFlag(json['required']),
      content: json['content']?.toString() ?? '',
      options: _parseOptions(json['options']),
    );
  }
}

bool _isRequiredFlag(dynamic value) {
  if (value == true) return true;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase().trim() ?? '';
  return text == 'true' || text == '1' || text == 'yes';
}

List<_FormOption> _parseOptions(dynamic raw) {
  if (raw is! List) return const [];
  final options = <_FormOption>[];
  for (final item in raw) {
    if (item is Map) {
      final value = item['value']?.toString() ?? '';
      final label = item['label']?.toString().trim() ?? '';
      options.add(_FormOption(
        value: value,
        label: label.isNotEmpty ? label : value,
      ));
    } else if (item != null) {
      final text = item.toString();
      options.add(_FormOption(value: text, label: text));
    }
  }
  return options;
}

class _DynamicRegistrationFormState extends State<DynamicRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, bool> _checks = {};

  List<_DynamicField> _fields = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  Future<void> _loadFields({bool refresh = false}) async {
    final generation = ++_loadGeneration;
    if (refresh && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final rawFields = await ApiService.fetchFormFields(widget.formId);
      final fields = <_DynamicField>[];
      for (final raw in rawFields) {
        if (raw is Map) {
          fields.add(_DynamicField.fromJson(Map<String, dynamic>.from(raw)));
        }
      }

      final firstName = await SessionManager.getUserFirstName();
      final lastName = await SessionManager.getUserLastName();
      final email = await SessionManager.getUserEmail();
      if (!mounted || generation != _loadGeneration) return;

      _disposeControllers();
      _selectValues.clear();
      _checks.clear();

      for (final field in fields) {
        if (field.name.isEmpty) continue;
        if (field.type != 'html' && field.type != 'select' && field.type != 'checkbox') {
          _controllers[field.name] = TextEditingController();
        }
      }

      _setIfEmpty('player_first_name', firstName);
      _setIfEmpty('player_last_name', lastName);
      _setIfEmpty('parent_email', email);

      setState(() {
        _fields = fields;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(RegExp(r'^[A-Za-z0-9_]*Exception:\s*'), '');
      });
    }
  }

  void _setIfEmpty(String name, String? value) {
    final controller = _controllers[name];
    if (controller == null || controller.text.trim().isNotEmpty) return;
    controller.text = (value ?? '').trim();
  }

  String? _meaningfulLabel(String label, String name) {
    final text = label.trim();
    if (text.isEmpty || text == name.trim()) return null;
    if (RegExp(r'^field_[A-Za-z0-9]+$').hasMatch(text)) return null;
    return text;
  }

  String _inputLabel(_DynamicField field) {
    final label = _meaningfulLabel(field.label, field.name) ?? field.name;
    if (field.required && !label.endsWith('*')) return '$label *';
    return label;
  }

  String _checkKey(String fieldName, String optionValue) => '$fieldName::$optionValue';

  List<_FormOption> _checkboxOptions(_DynamicField field) {
    if (field.options.isNotEmpty) return field.options;
    final label = _meaningfulLabel(field.label, field.name) ?? 'I agree';
    return [_FormOption(value: '1', label: label)];
  }

  bool _checkboxSatisfied(_DynamicField field) {
    return _checkboxOptions(field).any(
      (option) => _checks[_checkKey(field.name, option.value)] == true,
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(_DynamicField field) {
    final controller = _controllers[field.name];
    if (controller == null) return const SizedBox.shrink();

    final keyboardType = switch (field.type) {
      'email' => TextInputType.emailAddress,
      'phone' => TextInputType.phone,
      _ => TextInputType.text,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(_inputLabel(field)),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: field.type == 'email' || field.type == 'phone'
                ? TextCapitalization.none
                : TextCapitalization.words,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: _meaningfulLabel(field.label, field.name) ?? '',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
            validator: (value) {
              if (field.required && (value == null || value.trim().isEmpty)) {
                return 'Required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelect(_DynamicField field) {
    final seen = <String>{};
    final options = <_FormOption>[];
    for (final option in field.options) {
      if (option.value.isEmpty || !seen.add(option.value)) continue;
      options.add(option);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(_inputLabel(field)),
          FormField<String>(
            initialValue: _selectValues[field.name],
            validator: (val) => (field.required && (val == null || val.isEmpty)) ? 'Required' : null,
            builder: (state) {
              return InputDecorator(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  fillColor: Colors.white,
                  filled: true,
                  errorText: state.hasError ? state.errorText : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectValues[field.name],
                    isExpanded: true,
                    hint: const Text("Select option...", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    menuMaxHeight: 300,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    onChanged: (value) {
                      setState(() => _selectValues[field.name] = value);
                      state.didChange(value);
                    },
                    selectedItemBuilder: (context) {
                      return options.map((option) {
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            option.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        );
                      }).toList();
                    },
                    items: options.map((option) {
                      return DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(
                          option.label,
                          style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.normal),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(_DynamicField field) {
    final options = _checkboxOptions(field);
    final heading = field.options.isEmpty ? null : _meaningfulLabel(field.label, field.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: FormField<bool>(
        initialValue: _checkboxSatisfied(field),
        validator: (_) => (field.required && !_checkboxSatisfied(field)) ? 'Required' : null,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (heading != null)
                Text(
                  field.required ? '$heading *' : heading,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
              ...options.map((option) {
                final key = _checkKey(field.name, option.value);
                final checked = _checks[key] == true;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: checked,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() => _checks[key] = value ?? false);
                        state.didChange(_checkboxSatisfied(field) || value == true);
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          option.label,
                          style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    state.errorText ?? 'Required',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHtml(_DynamicField field) {
    final title = _meaningfulLabel(field.label, field.name);
    final content = field.content.trim();
    if (title == null && content.isEmpty) return const SizedBox.shrink();

    final looksLikeHtml = RegExp(r'<[a-zA-Z][^>]*>').hasMatch(content);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 10),
          ],
          if (content.isEmpty)
            const SizedBox.shrink()
          else if (!looksLikeHtml)
            Text(
              content,
              style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 67, 67, 67), height: 1.45),
            )
          else
            Html(
              data: content,
              style: {
                "body": Style(
                  color: const Color.fromARGB(255, 67, 67, 67),
                  fontSize: FontSize(15.0),
                  fontWeight: FontWeight.w400,
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  lineHeight: const LineHeight(1.45),
                ),
                "div": Style(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: FontSize(15.0),
                  margin: Margins.zero,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 8),
                ),
              },
            ),
        ],
      ),
    );
  }

  Widget _buildField(_DynamicField field) {
    switch (field.type) {
      case 'html':
        return _buildHtml(field);
      case 'select':
        return _buildSelect(field);
      case 'checkbox':
        return _buildCheckbox(field);
      case 'email':
      case 'phone':
      case 'text':
        return _buildTextField(field);
      default:
        return _buildTextField(field);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
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
            if (renderBox != null && _scrollController.hasClients) {
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

  String _fieldValue(String name) {
    if (_controllers.containsKey(name)) return _controllers[name]!.text.trim();
    return _selectValues[name]?.trim() ?? '';
  }

  Future<void> _saveForm() async {
    setState(() => _isSaving = true);
    try {
      final data = <String, String>{
        "user_id": widget.userId,
        "form_id": widget.formId,
        "product_id": widget.productId,
      };

      for (final field in _fields) {
        if (field.name.isEmpty || field.type == 'html') continue;

        if (field.type == 'checkbox') {
          final selected = <String>[];
          for (final option in _checkboxOptions(field)) {
            if (_checks[_checkKey(field.name, option.value)] == true && option.value.isNotEmpty) {
              selected.add(option.value);
            }
          }
          if (selected.isNotEmpty) {
            data[field.name] = selected.join(',');
          }
          continue;
        }

        final value = field.type == 'select'
            ? (_selectValues[field.name]?.trim() ?? '')
            : (_controllers[field.name]?.text.trim() ?? '');
        if (value.isNotEmpty) {
          data[field.name] = value;
        }
      }

      final result = await ApiService.saveRegistrationForm(
        formData: data,
        formType: widget.title,
      );

      if (result['success'] == true) {
        final Map<String, dynamic> responsePayload =
            result['data'] is Map ? Map<String, dynamic>.from(result['data'] as Map) : {};
        final String entryId = responsePayload['post_id']?.toString() ?? "";

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
                cityStr: _fieldValue('city'),
                stateStr: _fieldValue('state'),
                zipStr: _fieldValue('zipcode'),
                phoneStr: _fieldValue('phonenumber'),
                programData: widget.programData,
              ),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Form submitted successfully!")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Submission failed!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE65100)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0572B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () => _loadFields(refresh: true),
                    child: const Text(
                      "Try again",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 800 ? screenWidth * 0.15 : 20,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._fields.map(_buildField),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0572B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _saveForm();
                              } else {
                                _scrollToFirstValidationError();
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Submit",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                            ),
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
}
