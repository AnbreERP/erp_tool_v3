import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:erp_tool/widgets/sidebar_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<SidebarLayoutState> sidebarKey =
      GlobalKey<SidebarLayoutState>();

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    //load saved email & password
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await authProvider.login(emailController.text, passwordController.text);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (authProvider.isAuthenticated &&
        authProvider.moduleRoles.values.any((role) => role != 'None')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SidebarController(
            openPage: (page) => sidebarKey.currentState?.openPage(page),
            goBack: () => sidebarKey.currentState?.goBack(),
            child: SidebarLayout(key: sidebarKey),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or unauthorized login')),
      );
    }
  }

  //Save email and Password
  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('email', emailController.text);
      prefs.setString('password', passwordController.text);
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('email') ?? '';
    passwordController.text = prefs.getString('password') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  width: isMobile ? double.infinity : 800,
                  height: isMobile ? null : 560,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildIllustrationSection(isMobile: true),
                            _buildFormSection(isMobile: true),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                  child: _buildIllustrationSection(
                                      isMobile: false)),
                              Expanded(
                                  child: _buildFormSection(isMobile: false)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIllustrationSection({required bool isMobile}) {
    return Container(
      height: isMobile ? 200 : double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF3EE),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          ),
          child: Image.asset(
            'assets/images/Login.png',
            width: isMobile ? 200 : 480,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Column(
        mainAxisAlignment:
            isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/logoBlack.svg", height: 40),
          const SizedBox(height: 30),
          const Text("Welcome Back,",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Dive in and continue building excellence",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 40),
          _buildTextField(
            controller: emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            obscure: false,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 16),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                      if (_rememberMe) _saveCredentials();
                    },
                  ),
                  const Text("Remember me", style: TextStyle(fontSize: 12)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage()),
                  );
                },
                child: const Text(
                  "Forgot?",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 100,
            height: 30,
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text("Log in", style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      width: 280,
      height: 45,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffixIcon,
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
      ),
    );
  }
}

//------------------------------------------------------
//forgot password page
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isEmailVerified = false;
  bool isLoading = false;
  bool obscureNew = true;
  bool obscureConfirm = true;

  late AnimationController _controller;
  late Animation<double> _animation;

  final String baseUrl = 'http://127.0.0.1:4000/api';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> verifyEmail() async {
    final email = emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      showMessage("Please enter a valid email");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        setState(() => isEmailVerified = true);
      } else {
        showMessage("Email not found");
      }
    } catch (_) {
      showMessage("Something went wrong. Try again.");
    }

    setState(() => isLoading = false);
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim().toLowerCase();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword.length < 6) {
      showMessage("Password must be at least 6 characters");
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        showMessage("Password reset successful");
        Navigator.pop(context);
      } else {
        showMessage("Failed to reset password");
      }
    } catch (_) {
      showMessage("Something went wrong. Try again.");
    }

    setState(() => isLoading = false);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  width: isMobile ? double.infinity : 800,
                  height: isMobile ? null : 520,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildIllustrationSection(isMobile: true),
                            _buildFormSection(isMobile: true),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                  child: _buildIllustrationSection(
                                      isMobile: false)),
                              Expanded(
                                  child: _buildFormSection(isMobile: false)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIllustrationSection({required bool isMobile}) {
    final imagePath = isEmailVerified
        ? 'assets/resetpassword.png' // After email is verified
        : 'assets/forgotpassword.png'; // Before email is verified

    return Container(
      height: isMobile ? 200 : double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF3EE),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (_, child) => Transform.translate(
              offset: Offset(0, _animation.value), child: child),
          child: Image.asset(
            imagePath,
            width: isMobile ? 180 : 300,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Column(
        mainAxisAlignment:
            isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/logoBlack.svg", height: 40),
          const SizedBox(height: 30),
          Text(
            isEmailVerified ? "Reset Your Password" : "Forgot Password?",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isEmailVerified
                ? "Enter and confirm your new password"
                : "We’ll help you get back in.",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // Email field (always shown)
          _buildTextField(
            controller: emailController,
            label: "Email",
            icon: Icons.email_outlined,
            enabled: !isEmailVerified,
          ),
          const SizedBox(height: 15),

          // New password fields (only if email verified)
          if (isEmailVerified) ...[
            _buildTextField(
              controller: newPasswordController,
              label: "New Password",
              icon: Icons.lock_outline,
              obscure: obscureNew,
              suffixIcon: IconButton(
                icon:
                    Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => obscureNew = !obscureNew),
              ),
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: confirmPasswordController,
              label: "Confirm Password",
              icon: Icons.lock_outline,
              obscure: obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                    obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => obscureConfirm = !obscureConfirm),
              ),
            ),
            const SizedBox(height: 30),
          ],

          // Action button
          SizedBox(
            width: 160,
            height: 36,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : (isEmailVerified ? resetPassword : verifyEmail),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : Text(isEmailVerified ? "Update Password" : "Verify Email",
                      style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: 280,
      height: 45,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffixIcon,
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
      ),
    );
  }
}
