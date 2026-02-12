import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/signup_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(120),
                  Colors.black.withAlpha(220),
                  Colors.black,
                ],
              ),
            ),
          ),
          // Main Content with Animation
          SafeArea(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // App Logo / Icon
                      Hero(
                        tag: 'app_logo',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(40),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.movie_filter_rounded,
                                size: 50,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'CREATE ACCOUNT',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join Cineverse today.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Sign Up Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              hintText: 'Full Name',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              hintText: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              hintText: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              onVisibilityToggle: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              hintText: 'Confirm Password',
                              icon: Icons.lock_clock_outlined,
                              isPassword: true,
                              isPasswordVisible: _isConfirmPasswordVisible,
                              onVisibilityToggle: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            // Sign Up Button
                            Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF4B2B),
                                    Color(0xFFFF416C),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF4B2B,
                                    ).withAlpha(100),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Add logic to register
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Create Account',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Social Sign Up
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or sign up with',
                              style: GoogleFonts.outfit(color: Colors.white38),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _socialButton(Icons.g_mobiledata_rounded, () {}),
                          _socialButton(Icons.apple_rounded, () {}),
                          _socialButton(Icons.facebook_rounded, () {}),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.outfit(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Sign In",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withAlpha(20),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: TextFormField(
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(color: Colors.white30),
              prefixIcon: Icon(icon, color: Colors.white60),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white60,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(25)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
