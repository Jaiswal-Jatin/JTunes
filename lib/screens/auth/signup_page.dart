import 'package:flutter/material.dart';
import 'package:j3tunes/services/auth_service.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _signUp() async {
    print('[SignUpPage] _signUp button pressed.');
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        print('[SignUpPage] Validation failed: Date of birth not selected.');
        showToast(context, 'Please select your date of birth');
        return;
      }
      print('[SignUpPage] Form is valid. Proceeding with signup.');
      print('[SignUpPage] Name: ${_nameController.text.trim()}');
      print('[SignUpPage] Email: ${_emailController.text.trim()}');
      print('[SignUpPage] Mobile: ${_mobileController.text.trim()}');
      print('[SignUpPage] Address: ${_addressController.text.trim()}');
      print('[SignUpPage] DOB: $_selectedDate');
      setState(() {
        _isLoading = true;
      });
      final error = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        dob: _selectedDate!,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (error != null) {
          print('[SignUpPage] SignUp Error: $error');
          showToast(context, error);
        } else {
          showToast(context, 'Signup successful! Please log in.');
          print('[SignUpPage] SignUp successful. Navigating to /login.');
          context.go('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us and start listening!',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 30),
                  _buildTextFormField(
                      _nameController, 'Name', Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                      _emailController, 'Email', Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                      _mobileController, 'Mobile Number', Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                      _addressController, 'Address', Icons.home_outlined),
                  const SizedBox(height: 20),
                  _buildDobField(context),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                      _passwordController, 'Password', Icons.lock_outline,
                      isPassword: true),
                  const SizedBox(height: 20),
                  _buildTextFormField(_confirmPasswordController,
                      'Confirm Password', Icons.lock_outline,
                      isPassword: true, confirmPassword: true),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign Up',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        // style: TextButton.styleFrom(
                        //   shape: RoundedRectangleBorder(
                        //     borderRadius: BorderRadius.circular(8),
                        //     side: BorderSide(
                        //       color: theme.colorScheme.primary.withOpacity(0.5),
                        //     ),
                        //   ),
                        // ),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false,
      bool confirmPassword = false,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your $label';
        }
        if (label == 'Email' && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        if (isPassword && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (confirmPassword && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildDobField(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: _selectedDate == null
            ? ''
            : DateFormat.yMMMd().format(_selectedDate!),
      ),
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onTap: () => _selectDate(context),
      validator: (value) {
        if (_selectedDate == null) {
          return 'Please select your date of birth';
        }
        return null;
      },
    );
  }
}
