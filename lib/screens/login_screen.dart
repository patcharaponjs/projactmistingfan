import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // =====================================================
  // CONTROLLERS
  // =====================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =====================================================
  // LOGIN WITH SUPABASE
  // =====================================================

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(
        'กรุณากรอกอีเมลและรหัสผ่าน',
        Colors.redAccent,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        showMessage(
          'เข้าสู่ระบบไม่สำเร็จ',
          Colors.redAccent,
        );
        return;
      }

      String username = '';

      final metadata = user.userMetadata;

      if (metadata != null && metadata['username'] != null) {
        username = metadata['username'].toString();
      }

      if (username.isEmpty) {
        username = email.split('@').first;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            username: username,
          ),
        ),
      );
    } on AuthException catch (e) {
      String message = 'เข้าสู่ระบบไม่สำเร็จ';

      if (e.message
          .toLowerCase()
          .contains('invalid login credentials')) {
        message = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      } else if (e.message
          .toLowerCase()
          .contains('email not confirmed')) {
        message = 'กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ';
      }

      if (mounted) {
        showMessage(
          message,
          Colors.redAccent,
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          'เกิดข้อผิดพลาด กรุณาลองใหม่',
          Colors.redAccent,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // =====================================================
  // INPUT DECORATION
  // =====================================================

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Colors.white38,
      ),

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF45B9EB),
      ),

      filled: true,

      fillColor: const Color(0xFF151B25),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF29313D),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF29313D),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF45B9EB),
          width: 2,
        ),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D13),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 30),

              // =================================================
              // LOGO
              // =================================================

              Center(
                child: Container(
                  width: 85,
                  height: 85,

                  decoration: BoxDecoration(
                    color: const Color(0xFF087FD0),
                    borderRadius:
                        BorderRadius.circular(25),
                  ),

                  child: const Icon(
                    Icons.air,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // APP NAME
              // =================================================

              const Center(
                child: Text(
                  'Smart Mist Fan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'พัดลมไอน้ำอัจฉริยะ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 45),

              // =================================================
              // LOGIN TITLE
              // =================================================

              const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'เข้าสู่ระบบเพื่อควบคุมพัดลมหมอกอัจฉริยะ',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // EMAIL LABEL
              // =================================================

              const Text(
                'อีเมล',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 8),

              // =================================================
              // EMAIL
              // =================================================

              TextField(
                controller: emailController,

                keyboardType:
                    TextInputType.emailAddress,

                textInputAction:
                    TextInputAction.next,

                autocorrect: false,

                enableSuggestions: false,

                textCapitalization:
                    TextCapitalization.none,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),

                // ป้องกัน / และ \ จากการถูกใส่เข้ามา
                inputFormatters: [
                  FilteringTextInputFormatter.deny(
                    RegExp(r'[/\\]'),
                  ),
                ],

                decoration: inputDecoration(
                  hint: 'กรอกอีเมล',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // PASSWORD LABEL
              // =================================================

              const Text(
                'รหัสผ่าน',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 8),

              // =================================================
              // PASSWORD
              // =================================================

              TextField(
                controller: passwordController,

                obscureText: hidePassword,

                textInputAction:
                    TextInputAction.done,

                autocorrect: false,

                enableSuggestions: false,

                textCapitalization:
                    TextCapitalization.none,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),

                // ป้องกัน / และ \ จากการถูกใส่เข้ามา
                inputFormatters: [
                  FilteringTextInputFormatter.deny(
                    RegExp(r'[/\\]'),
                  ),
                ],

                onSubmitted: (_) {
                  if (!isLoading) {
                    login();
                  }
                },

                decoration: inputDecoration(
                  hint: 'กรอกรหัสผ่าน',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword =
                            !hidePassword;
                      });
                    },

                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // LOGIN BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : login,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF087FD0),

                    disabledBackgroundColor:
                        const Color(0xFF087FD0)
                            .withOpacity(.5),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,

                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // OR
              // =================================================

              Row(
                children: [
                  const Expanded(
                    child: Divider(
                      color: Color(0xFF29313D),
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 15,
                    ),

                    child: Text(
                      'หรือ',

                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(.45),
                      ),
                    ),
                  ),

                  const Expanded(
                    child: Divider(
                      color: Color(0xFF29313D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // =================================================
              // REGISTER BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 52,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (context) =>
                            const RegisterScreen(),
                      ),
                    );
                  },

                  style:
                      OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF39B9F0),
                      width: 1.5,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    'สร้างบัญชี',

                    style: TextStyle(
                      color: Color(0xFF39B9F0),
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // FOOTER
              // =================================================

              const Center(
                child: Text(
                  'Smart Mist Fan IoT',

                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}