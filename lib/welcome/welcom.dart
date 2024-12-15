import 'package:flutter/material.dart';
import 'package:smarthome/login/login.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0; // To track the current page

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            physics: BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index; // Update the current page
              });
            },
            children: [
              OnboardingPage(
                imageAsset: 'assets/images/screen1.png',
                title: 'Smarter life\nwith smart device',
                subtitle: 'Functionality',
                primaryColor: Colors.pink,
              ),
              OnboardingPage(
                imageAsset: 'assets/images/screen2.png',
                title: 'Maximise security\n& instant notification',
                subtitle: 'Security',
                primaryColor: Colors.orange,
              ),
              OnboardingPage(
                imageAsset: 'assets/images/screen3.png',
                title: 'Integrate your\ndevices seamlessly',
                subtitle: 'Connectivity',
                primaryColor: Colors.blue,
              ),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    dotColor: Colors.grey.shade400,
                    activeDotColor: Colors.pink,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                    spacing: 6.0,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip Button
                    TextButton(
                      onPressed: () {
                        _controller.jumpToPage(2); // Skip to the last page
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Conditional Button
                    _currentPage == 2
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                              );
                            },
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              _controller.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final Color primaryColor;

  const OnboardingPage({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular image with icons overlay
          Stack(
            children: [
              ClipOval(
                child: Image.asset(
                  imageAsset,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.lightbulb, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.lock, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 40),
          // Subtitle box
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor, width: 1),
            ),
            child: Text(
              subtitle.toUpperCase(),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
