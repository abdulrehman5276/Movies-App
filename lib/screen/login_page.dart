import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movies_app/screen/homescreen.dart';
import 'package:movies_app/screen/sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.png'),
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
                  Colors.black.withAlpha(100),
                  Colors.black.withAlpha(200),
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
                      // Logo & Header
                      Hero(
                        tag: 'app_logo',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(50),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.movie_filter_rounded,
                                size: 60,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'CINEVERSE',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlimited movies, TV shows, and more.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.outfit(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Login Button
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
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HomeScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Sign In',
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
                      const SizedBox(height: 40),
                      // Social Logins
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or continue with',
                              style: GoogleFonts.outfit(color: Colors.white38),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _socialButton(
                            'google',
                            Icons.g_mobiledata_rounded,
                            () {},
                          ),
                          _socialButton('apple', Icons.apple_rounded, () {}),
                          _socialButton(
                            'facebook',
                            Icons.facebook_rounded,
                            () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "New to Cineverse? ",
                            style: GoogleFonts.outfit(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Sign Up Now",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: TextFormField(
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(color: Colors.white38),
              prefixIcon: Icon(icon, color: Colors.white70),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(String type, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
