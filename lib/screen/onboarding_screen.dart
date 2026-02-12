import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movies_app/screen/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Explore Unlimited Movies',
      description:
          'Discover thousands of movies and TV shows at your fingertips.',
      imageUrl: 'assets/images/onboarding_1.png',
    ),
    OnboardingData(
      title: 'Watch Anywhere',
      description:
          'Stream on your phone, tablet, laptop, and TV without paying more.',
      imageUrl: 'assets/images/onboarding_2.png',
    ),
    OnboardingData(
      title: 'Download & Go',
      description:
          'Save your favorites easily and always have something to watch.',
      imageUrl: 'assets/images/onboarding_3.png',
    ),
    OnboardingData(
      title: 'Personalized For You',
      description: 'Get recommendations based on your unique movie taste.',
      imageUrl: 'assets/images/onboarding_4.png',
    ),
    OnboardingData(
      title: 'Join The Community',
      description: 'Rate, review and share your favorite cinematic moments.',
      imageUrl: 'assets/images/onboarding_5.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return OnboardingPage(data: _onboardingData[index]);
            },
          ),

          // Navigation Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicator
                      Row(
                        children: List.generate(
                          _onboardingData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.redAccent
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Skip Button (Only on Screen 1 or whenever user wants to skip)
                      if (_currentPage < _onboardingData.length - 1)
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            'SKIP',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // Bottom Button
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4B2B), Color(0xFFFF416C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4B2B).withAlpha(100),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _onboardingData.length - 1
                            ? 'GET STARTED'
                            : 'CONTINUE',
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
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(child: Image.asset(data.imageUrl, fit: BoxFit.cover)),
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(50),
                  Colors.black.withAlpha(150),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String imageUrl;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imageUrl,
  });
}
