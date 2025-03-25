import 'dart:convert';
import 'dart:developer' show log;

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:introduction_screen/introduction_screen.dart';
import 'package:roo_mobile/firebase_options.dart';
import 'package:roo_mobile/ui/chat.dart';
import 'package:roo_mobile/ui/chat_home.dart';
import 'package:roo_mobile/ui/events.dart';
import 'package:roo_mobile/ui/home.dart';
import 'package:roo_mobile/ui/library.dart';
import 'package:roo_mobile/ui/track.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

const backgroundImage = 'assets/img/profile_pic.png';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    return MaterialApp(
      title: 'Introduction screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.white, // Set primary color to white
        colorScheme: ColorScheme.light(
          primary: Colors.white, // Set primary color to white
          secondary: Colors.white, // Set secondary color to white
        ),
        useMaterial3: true,
        scaffoldBackgroundColor:
            Colors.white, // Set scaffold background to white
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final storedToken = await _secureStorage.read(key: 'auth_token');
    print("Auth Token: $storedToken");
    if (storedToken != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    }
  }

  // Sign in with Google
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential authResult = await FirebaseAuth.instance
          .signInWithCredential(credential);
      _handleAuthSuccess(authResult);
    } catch (e) {
      log('Google Sign-In Error: $e');
    }
  }

  // Sign in with Apple
  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      UserCredential auth = await FirebaseAuth.instance.signInWithProvider(
        appleProvider,
      );
      _handleAuthSuccess(auth);
    } catch (e) {
      log('Apple Sign-In Error: $e');
    }
  }

  // Handle authentication success
  Future<void> _handleAuthSuccess(UserCredential auth) async {
    final user = auth.user;
    if (user == null) return;

    final firebaseIdToken = await user.getIdToken();
    final requestBody = {
      'provider': 'firebase',
      'firebase_token': firebaseIdToken,
      'email': user.email,
      'name': user.displayName,
    };

    final response = await http.post(
      Uri.parse('https://your-backend-url.com/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      await _secureStorage.write(
        key: 'auth_token',
        value: responseData['token'],
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } else {
      log('Backend Authentication Failed: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Space evenly vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            Container(
              child: DefaultTextStyle(
                style: GoogleFonts.sriracha(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 106, 0, 255),
                ),
                child: AnimatedTextKit(
                  pause: const Duration(seconds: 2),
                  totalRepeatCount: 2,
                  isRepeatingAnimation: true,
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Welcome to Roo',
                      speed: const Duration(milliseconds: 200),
                    ),
                    TypewriterAnimatedText(
                      'All Things PCOS',
                      speed: const Duration(milliseconds: 200),
                    ),
                    TypewriterAnimatedText(
                      'Take Control of PCOS',
                      speed: const Duration(milliseconds: 200),
                    ),
                  ],
                  onTap: () {
                    print("Tap Event");
                  },
                ),
              ),
            ),
            Image.asset("assets/img/women-arms.jpg"),
            Column(
              children: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _signInWithGoogle(context);
                    },
                    child: Text(
                      "Sign in with Google",
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white, // Google sign-in button color
                      foregroundColor: Colors.black87, // Text color
                      minimumSize: Size(340, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SignInWithAppleButton(
                  onPressed: () {
                    _signInWithApple(context);
                  },
                  style:
                      SignInWithAppleButtonStyle
                          .black, // Style of the button (black or white)
                  text: 'Sign in with Apple',
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // Optional: for rounded corners
                  height: 50, // Button height
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  OnBoardingPageState createState() => OnBoardingPageState();
}

class OnBoardingPageState extends State<OnBoardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MyHomePage()));
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset('assets/img/$assetName', width: width);
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      autoScrollDuration: 3000,
      infiniteAutoScroll: true,
      globalHeader: Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: _buildImage('profile_pic.png', 100),
          ),
        ),
      ),

      pages: [
        PageViewModel(
          title: "Fractional shares",
          body:
              "Instead of having to buy an entire share, invest any amount you want.",
          image: _buildImage('profile_pic.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Full Screen Page",
          body:
              "Pages can be full screen as well.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc id euismod lectus, non tempor felis. Nam rutrum rhoncus est ac venenatis.",
          backgroundImage: backgroundImage,
          decoration: pageDecoration.copyWith(
            contentMargin: const EdgeInsets.symmetric(horizontal: 16),
            bodyFlex: 2,
            imageFlex: 3,
            safeArea: 100,
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Display as right-to-left
      back: const Icon(Icons.arrow_back),
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding:
          kIsWeb
              ? const EdgeInsets.all(12.0)
              : const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}

class HomePage1 extends StatelessWidget {
  const HomePage1({super.key});

  void _onBackToIntro(context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnBoardingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This is the screen after Introduction"),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _onBackToIntro(context),
              child: const Text('Back to Introduction'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  bool showChatHome = true;

  /// Use a getter instead of a final list
  List<Widget> get tabItems => [
    HomePage(),
    HomeScreen(),
    showChatHome ? ChatHomePage() : ChatPage(), // ✅ Dynamic switching
    TrackPage(),
    LibraryPage(),
  ];

  void _onSearchPressed() {
    // Navigate to Chat page and remove the bottom nav bar
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(),
      ), // Replace with your actual Chat page
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabItems[selectedIndex], // Display the selected page
      extendBody: true,
      bottomNavigationBar: FlashyTabBar(
        animationCurve: Curves.linear,
        selectedIndex: selectedIndex,
        iconSize: 30,
        showElevation: false, // Removes appBar elevation
        onItemSelected: (index) {
          setState(() {
            selectedIndex = index; // Update selected index
          });
        },
        items: [
          FlashyTabBarItem(icon: Icon(Icons.home), title: Text('Home')),
          FlashyTabBarItem(icon: Icon(Icons.event), title: Text('Events')),
          FlashyTabBarItem(icon: Icon(Icons.chat), title: Text('Chat')),

          FlashyTabBarItem(
            icon: Icon(Icons.equalizer_outlined),
            title: Text('Track'),
          ),

          FlashyTabBarItem(
            icon: Icon(Icons.video_library_outlined),
            title: Text('Explore'),
          ),
        ],
      ),
    );
  }
}

/// add controller to check weather index through change or not. in page 1
class Page1 extends StatelessWidget {
  final NotchBottomBarController? controller;

  const Page1({Key? key, this.controller}) : super(key: key);

  void _onBackToIntro(context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnBoardingPage()),
    );
  }

  void _navigateToChatPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("This is the screen after Introduction"),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () => _onBackToIntro(context),
            child: const Text('Back to Introduction'),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () => _navigateToChatPage(context),
            child: const Text('Go to Chat Page'),
          ),
        ],
      ),
    );
  }
}

class AppleAccountModal extends StatelessWidget {
  final String? displayName;
  final String? email;
  final String? credentials;
  final VoidCallback onClose;
  final VoidCallback onContinue;

  const AppleAccountModal({
    super.key,
    required this.displayName,
    required this.email,
    required this.credentials,
    required this.onClose,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apple Account Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayName != null) Text('Name: $displayName'),
          if (email != null) Text('Email: $email'),
          const SizedBox(height: 20),
          const Text('You have successfully signed in with Apple.'),
        ],
      ),
      actions: [
        TextButton(onPressed: onClose, child: const Text('Close')),
        ElevatedButton(
          onPressed: onContinue,
          child: const Text(
            'Continue to Home',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
