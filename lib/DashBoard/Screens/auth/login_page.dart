import 'package:bhajan_app/DashBoard/Screens/dashboard_page.dart';
import 'package:bhajan_app/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = Colors.brown;
  final LinearGradient primaryGradient = const LinearGradient(
    colors: [Colors.brown, Color(0xFF8B4513)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return Column(
            children: [
              isKeyboardVisible
                  ? SizedBox(height: screenHeight / 16)
                  : Container(
                      height: screenHeight / 3,
                      width: screenWidth,
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(screenWidth / 10),
                          bottomRight: Radius.circular(screenWidth / 10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.4),
                            offset: const Offset(0, 5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/gosaiji_highres.png',
                            width: screenWidth / 3,
                              height: screenWidth / 3,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
              Container(
                margin: EdgeInsets.only(
                  top: screenHeight / 20,
                  bottom: screenHeight / 20,
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    fontSize: screenWidth / 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldTitle("Email"),
                    customField("Enter Your Email", _emailController, false),
                    fieldTitle("Password"),
                    customField(
                      "Enter Your Password",
                      _passwordController,
                      true,
                    ),
                    GestureDetector(
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();

                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Email cannot be empty")),
                          );
                          return;
                        }
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Password cannot be empty")),
                          );
                          return;
                        }

                        final authService = AuthService();
                        String? result = await authService.signInWithEmailPassword(email, password);

                        if (result == null) {
                          // Navigate to your home page after login
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const DashboardPage()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result)),
                          );
                        }
                      },
                      child: Container(
                        height: 55,
                        width: screenWidth,
                        margin: EdgeInsets.only(top: screenHeight / 40),
                        decoration: BoxDecoration(
                          gradient: primaryGradient,
                          borderRadius: const BorderRadius.all(Radius.circular(30)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "LOGIN",
                            style: TextStyle(
                              fontFamily: "LatoBold",
                              fontSize: screenWidth / 20,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    )

                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: screenWidth / 21, fontFamily: "LatoRegular"),
      ),
    );
  }

  Widget customField(
    String hintText,
    TextEditingController controller,
    bool obscureText,
  ) {
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth / 6,
            child: Icon(Icons.person, color: primary, size: screenWidth / 15),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
                  ),
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
