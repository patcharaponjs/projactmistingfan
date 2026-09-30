import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // =====================================================
  // CONTROLLERS
  // =====================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  // =====================================================
  // STATE
  // =====================================================

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // =====================================================
  // CREATE ACCOUNT
  // =====================================================

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword =
        confirmPasswordController.text;

    // ===================================================
    // VALIDATE
    // ===================================================

    if (name.isEmpty) {
      showMessage(
        'กรุณากรอกชื่อผู้ใช้',
        Colors.redAccent,
      );
      return;
    }

    if (email.isEmpty) {
      showMessage(
        'กรุณากรอกอีเมล',
        Colors.redAccent,
      );
      return;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      showMessage(
        'กรุณากรอกอีเมลให้ถูกต้อง',
        Colors.redAccent,
      );
      return;
    }

    if (password.isEmpty) {
      showMessage(
        'กรุณากรอกรหัสผ่าน',
        Colors.redAccent,
      );
      return;
    }

    if (password.length < 6) {
      showMessage(
        'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
        Colors.redAccent,
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      showMessage(
        'กรุณายืนยันรหัสผ่าน',
        Colors.redAccent,
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        'รหัสผ่านไม่ตรงกัน',
        Colors.redAccent,
      );
      return;
    }

    // ===================================================
    // START LOADING
    // ===================================================

    setState(() {
      isLoading = true;
    });

    try {
      // =================================================
      // SUPABASE SIGN UP
      // =================================================
      //
      // username จะถูกเก็บไว้ใน user_metadata
      // ไม่ต้องบันทึก password ลง profiles
      //
      // =================================================

      final response =
          await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': name,
        },
      );

      final user = response.user;

      // =================================================
      // CHECK USER
      // =================================================

      if (user == null) {
        throw Exception(
          'Supabase ไม่สามารถสร้างบัญชีได้',
        );
      }

      debugPrint('================================');
      debugPrint('USER CREATED SUCCESSFULLY');
      debugPrint('USER ID: ${user.id}');
      debugPrint('EMAIL: ${user.email}');
      debugPrint('USERNAME: $name');
      debugPrint('SESSION: ${response.session != null}');
      debugPrint('================================');

      // =================================================
      // SUCCESS
      // =================================================

      if (!mounted) return;

      showMessage(
        'สร้างบัญชีสำเร็จ',
        Colors.green,
      );

      // รอให้ผู้ใช้เห็นข้อความ
      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (!mounted) return;

      // =================================================
      // BACK TO LOGIN
      // =================================================

      Navigator.pop(context);
    } on AuthException catch (e) {
      // =================================================
      // SUPABASE AUTH ERROR
      // =================================================

      debugPrint('================================');
      debugPrint('SUPABASE AUTH ERROR');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('STATUS: ${e.statusCode}');
      debugPrint('================================');

      final error =
          e.message.toLowerCase();

      String message =
          'สมัครสมาชิกไม่สำเร็จ';

      if (error.contains('already registered') ||
          error.contains('user already exists') ||
          error.contains('already been registered')) {
        message = 'อีเมลนี้ถูกใช้งานแล้ว';
      } else if (error.contains('invalid email')) {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
      } else if (error.contains('password')) {
        message = 'รหัสผ่านไม่ถูกต้อง';
      } else if (error.contains('rate limit')) {
        message =
            'สมัครบ่อยเกินไป กรุณารอสักครู่';
      } else if (error.contains('signup')) {
        message =
            'ไม่สามารถสมัครสมาชิกได้ กรุณาตรวจสอบ Supabase';
      } else {
        message =
            'สมัครไม่สำเร็จ: ${e.message}';
      }

      if (mounted) {
        showMessage(
          message,
          Colors.redAccent,
        );
      }
    } catch (e) {
      // =================================================
      // GENERAL ERROR
      // =================================================

      debugPrint('================================');
      debugPrint('CREATE ACCOUNT ERROR');
      debugPrint('$e');
      debugPrint('================================');

      if (mounted) {
        showMessage(
          'เกิดข้อผิดพลาด: $e',
          Colors.redAccent,
        );
      }
    } finally {
      // =================================================
      // STOP LOADING
      // =================================================

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // SHOW MESSAGE
  // =====================================================

  void showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
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
        color: const Color(0xFF39B9F0),
      ),

      filled: true,

      fillColor: const Color(0xFF151B25),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF29313D),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF29313D),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF39B9F0),
          width: 2,
        ),
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF080D13),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF151B25),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'สร้างบัญชี',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // =================================================
              // ICON
              // =================================================

              const Center(
                child: Icon(
                  Icons.person_add_alt_1,
                  color: Color(0xFF39B9F0),
                  size: 65,
                ),
              ),

              const SizedBox(height: 15),

              // =================================================
              // TITLE
              // =================================================

              const Center(
                child: Text(
                  'สร้างบัญชีใหม่',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'สร้างบัญชีเพื่อใช้งาน Smart Mist Fan',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // =================================================
              // USERNAME
              // =================================================

              const Text(
                'ชื่อผู้ใช้',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    nameController,

                obscureText: false,

                keyboardType:
                    TextInputType.text,

                textInputAction:
                    TextInputAction.next,

                autocorrect: false,

                enableSuggestions: true,

                textCapitalization:
                    TextCapitalization.none,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),

                decoration:
                    inputDecoration(
                  hint: 'กรอกชื่อผู้ใช้',
                  icon:
                      Icons.person_outline,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // EMAIL
              // =================================================

              const Text(
                'อีเมล',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    emailController,

                obscureText: false,

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

                decoration:
                    inputDecoration(
                  hint: 'กรอกอีเมล',
                  icon:
                      Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // PASSWORD
              // =================================================

              const Text(
                'รหัสผ่าน',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    passwordController,

                obscureText:
                    hidePassword,

                obscuringCharacter: '•',

                keyboardType:
                    TextInputType.visiblePassword,

                textInputAction:
                    TextInputAction.next,

                autocorrect: false,

                enableSuggestions: false,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),

                decoration:
                    inputDecoration(
                  hint: 'กรอกรหัสผ่าน',
                  icon:
                      Icons.lock_outline,
                ).copyWith(
                  suffixIcon:
                      IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword =
                            !hidePassword;
                      });
                    },

                    icon: Icon(
                      hidePassword
                          ? Icons
                              .visibility_off_outlined
                          : Icons
                              .visibility_outlined,
                      color:
                          Colors.white54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // CONFIRM PASSWORD
              // =================================================

              const Text(
                'ยืนยันรหัสผ่าน',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller:
                    confirmPasswordController,

                obscureText:
                    hideConfirmPassword,

                obscuringCharacter: '•',

                keyboardType:
                    TextInputType.visiblePassword,

                textInputAction:
                    TextInputAction.done,

                autocorrect: false,

                enableSuggestions: false,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),

                decoration:
                    inputDecoration(
                  hint:
                      'กรอกรหัสผ่านอีกครั้ง',
                  icon:
                      Icons.lock_reset_outlined,
                ).copyWith(
                  suffixIcon:
                      IconButton(
                    onPressed: () {
                      setState(() {
                        hideConfirmPassword =
                            !hideConfirmPassword;
                      });
                    },

                    icon: Icon(
                      hideConfirmPassword
                          ? Icons
                              .visibility_off_outlined
                          : Icons
                              .visibility_outlined,
                      color:
                          Colors.white54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // CREATE BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : createAccount,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                            0xFF087FD0),

                    disabledBackgroundColor:
                        const Color(
                                0xFF087FD0)
                            .withOpacity(.5),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,

                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'สร้างบัญชี',
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
              // LOGIN
              // =================================================

              Center(
                child: TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                              Navigator.pop(
                                  context);
                            },

                  child: const Text(
                    'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                    style: TextStyle(
                      color:
                          Color(0xFF39B9F0),
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

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