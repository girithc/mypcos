import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:roo_mobile/utils/firebase_options.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/ui/components/chat.dart';
import 'package:roo_mobile/ui/store/events.dart';
import 'package:roo_mobile/ui/track/track_page.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: "https://itbezvuwkxkjvmwazicb.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0YmV6dnV3a3hranZtd2F6aWNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI3ODk4NDIsImV4cCI6MjA0ODM2NTg0Mn0.TI1t_5chVA3x0vhMsbTWQPQIWZIoLnpz8-odSKSQ-C4",
  );
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasError = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() {
      _checking = true;
      _hasError = false;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _goToLogin();
      return;
    }

    final token = await user.getIdToken();

    int retries = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 10);

    while (retries < maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse('${EnvConfig.baseUrl}/auth-login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'firebase_token': token, 'email': user.email}),
            )
            .timeout(const Duration(seconds: 25)); // generous timeout

        if (response.statusCode == 200) {
          _goToHome();
          return;
        } else {
          // Invalid token or server returned error
          await FirebaseAuth.instance.signOut();
          _goToLogin();
          return;
        }
      } on SocketException catch (_) {
        debugPrint('Network error');
      } on TimeoutException catch (_) {
        debugPrint('Request timed out');
      } catch (e, st) {
        debugPrint('Unexpected auth error: $e\n$st');
      }

      // Retry after a delay
      await Future.delayed(retryDelay);
      retries++;
    }

    // If all retries fail
    setState(() {
      _hasError = true;
      _checking = false;
    });
  }

  void _goToHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MyHomePage()),
      );
    });
  }

  void _goToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      // still trying
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Getting Ready",
                style: GoogleFonts.sriracha(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent.shade200,
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.pinkAccent.shade200),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      // show "no internet / retry" screen
      return Scaffold(
        appBar: AppBar(
          title: Text('Oops!', style: largeText(color: Colors.white)),
          backgroundColor: Color.fromARGB(255, 106, 0, 255),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 80, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'No internet connection.\nPlease check your network and try again.',
                  textAlign: TextAlign.center,
                  style: mediumText(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _checkAuthStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 106, 0, 255),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text('Retry', style: mediumText(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // default fallback (shouldn't get here)
    return const SizedBox.shrink();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
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

    // 👇 Show the loading dialog before making the API call
    showDialog(
      context: context,
      barrierDismissible: false, // prevent user from closing it
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Logging in..."),
              ],
            ),
          ),
    );

    final firebaseIdToken = await user.getIdToken();
    final requestBody = {
      'firebase_token': firebaseIdToken,
      'email': user.email,
    };

    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/auth-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("\n\n*******************");
      print("Body: ${requestBody}");
      print("Response Auth Login: ${response.body}");
      print("*******************\n\n");

      // 👇 Close the loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // ✅ Navigate to MyHomePage after successful authentication
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        }
      } else {
        print('Backend Authentication Failed: ${response.body}');
        if (context.mounted) {
          _showErrorDialog("Login failed. Please try again.");
        }
      }
    } catch (e) {
      if (context.mounted)
        Navigator.of(context).pop(); // Ensure dialog is closed
      log('Error sending token to backend: $e');
      if (context.mounted) {
        _showErrorDialog("Network error. Please try again.");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
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
                  color: Colors.pinkAccent.shade200,
                ),
                child: AnimatedTextKit(
                  pause: const Duration(seconds: 2),
                  totalRepeatCount: 2,
                  isRepeatingAnimation: true,
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Welcome to MyPCOS',
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
                /*
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _signInWithGoogle(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white, // Google sign-in button color
                      foregroundColor: Colors.black87, // Text color
                      minimumSize: Size(340, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Keep the button compact
                      children: [
                        Image.asset(
                          "assets/img/google.png",
                          height: 24, // Adjust the height as needed
                        ),
                        SizedBox(width: 8), // Space between icon and text
                        Text(
                          "Sign in with Google",
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),
                */
                SizedBox(height: 40),

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
    TrackPage(), //HomePage(),
    ChatPage(), // ✅ Dynamic switching
    HomeScreen(),

    //ChatHomePage(),
    //LibraryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabItems[selectedIndex], // Display the selected page
      extendBody: true,
      bottomNavigationBar: // In your PeriodCalendarSheetContent build(), update the FlashyTabBar section:
          FlashyTabBar(
        height: 50,
        animationCurve: Curves.linear,
        selectedIndex: selectedIndex,
        iconSize: 30,
        showElevation: false,
        onItemSelected: (index) {
          if (index == 1) {
            showChatBottomSheet(context);
          } else {
            setState(() {
              selectedIndex = index; // switch tabs normally
            });
          }
        },
        items: [
          FlashyTabBarItem(
            icon: Icon(Icons.home, color: Colors.pinkAccent.shade200),
            title: Text(
              'Home',
              style: mediumText(fontWeight: FontWeight.normal),
            ),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.auto_awesome, color: Colors.pinkAccent.shade200),
            title: Text('Roo', style: smallText()),
          ),
          FlashyTabBarItem(
            icon: Icon(Icons.store, color: Colors.pinkAccent.shade200),
            title: Text(
              'Store',
              style: mediumText(fontWeight: FontWeight.normal),
            ),
          ),
          /*
          FlashyTabBarItem(
            icon: Icon(Icons.chat, color: Colors.pinkAccent.shade200),
            title: Text(
              'Chat',
              style: mediumText(fontWeight: FontWeight.normal),
            ),
          ),
          
          FlashyTabBarItem(
            icon: Icon(Icons.collections, color: Colors.pinkAccent.shade200),
            title: Text(
              'Explore',
              style: mediumText(fontWeight: FontWeight.normal),
            ),
          ),
          */
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
