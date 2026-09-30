import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // GET DEVICE ID
  // =====================================================

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? deviceId =
        prefs.getString('smart_mist_device_id');

    if (deviceId == null || deviceId.isEmpty) {
      deviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}';

      await prefs.setString(
        'smart_mist_device_id',
        deviceId,
      );
    }

    return deviceId;
  }

  // =====================================================
  // LOGIN NOTIFICATION
  // =====================================================

  Future<void> createLoginNotification({
    required String userId,
    required String email,
  }) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .insert({
        'user_id': userId,
        'title': 'เข้าสู่ระบบ',
        'message': 'เข้าสู่ระบบสำเร็จด้วย $email',
        'type': 'login',
        'is_read': false,
      });

      debugPrint('LOGIN NOTIFICATION SUCCESS');
    } catch (e) {
      // ถ้าบันทึก Notification ไม่สำเร็จ
      // จะไม่ทำให้ Login ล้มเหลว
      debugPrint('LOGIN NOTIFICATION ERROR: $e');
    }
  }

  // =====================================================
  // CHECK DEVICE LIMIT
  // =====================================================

  Future<bool> checkDeviceLimit({
    required String userId,
  }) async {
    final deviceId = await getDeviceId();

    try {
      // ตรวจว่าเครื่องนี้เคยลงทะเบียนแล้วหรือยัง
      final existingDevice =
          await Supabase.instance.client
              .from('user_devices')
              .select('id')
              .eq('user_id', userId)
              .eq('device_id', deviceId)
              .maybeSingle();

      // =================================================
      // เครื่องเดิม
      // =================================================

      if (existingDevice != null) {
        await Supabase.instance.client
            .from('user_devices')
            .update({
          'last_seen': DateTime.now().toIso8601String(),
        })
            .eq('id', existingDevice['id']);

        return true;
      }

      // =================================================
      // เครื่องใหม่
      // =================================================

      final devices = await Supabase.instance.client
          .from('user_devices')
          .select('id')
          .eq('user_id', userId);

      // จำกัดสูงสุด 2 เครื่อง
      if (devices.length >= 2) {
        return false;
      }

      // เพิ่มเครื่องใหม่
      await Supabase.instance.client
          .from('user_devices')
          .insert({
        'user_id': userId,
        'device_id': deviceId,
        'device_name': 'Flutter Device',
        'last_seen': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('DEVICE CHECK ERROR: $e');
      rethrow;
    }
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
      // =================================================
      // SUPABASE LOGIN
      // =================================================

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

      // =================================================
      // CHECK DEVICE LIMIT
      // =================================================

      final deviceAllowed = await checkDeviceLimit(
        userId: user.id,
      );

      // =================================================
      // เกิน 2 เครื่อง
      // =================================================

      if (!deviceAllowed) {
        await Supabase.instance.client.auth.signOut();

        if (mounted) {
          showMessage(
            'บัญชีนี้ใช้งานได้สูงสุด 2 เครื่อง',
            Colors.redAccent,
          );
        }

        return;
      }

      // =================================================
      // LOGIN NOTIFICATION
      // =================================================

      await createLoginNotification(
        userId: user.id,
        email: email,
      );

      // =================================================
      // USERNAME
      // =================================================

      String username = '';

      final metadata = user.userMetadata;

      if (metadata != null &&
          metadata['username'] != null) {
        username = metadata['username'].toString();
      }

      if (username.isEmpty) {
        username = email.split('@').first;
      }

      // =================================================
      // GO TO DASHBOARD
      // =================================================

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
      debugPrint('LOGIN ERROR: $e');

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
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.air,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  'Smart Mist Fan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'เข้าสู่ระบบเพื่อควบคุมพัดลม',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 40),

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
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: inputDecoration(
                  hint: 'กรอกอีเมล',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 20),

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
                controller: passwordController,
                obscureText: hidePassword,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: inputDecoration(
                  hint: 'กรอกรหัสผ่าน',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF087FD0),
                    disabledBackgroundColor:
                        const Color(0xFF087FD0)
                            .withOpacity(0.5),
                    shape: RoundedRectangleBorder(
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
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'ยังไม่มีบัญชี? สมัครสมาชิก',
                    style: TextStyle(
                      color: Color(0xFF45B9EB),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

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