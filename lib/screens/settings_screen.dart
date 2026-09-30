import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SettingsScreen extends StatefulWidget {
  final String username;

  const SettingsScreen({
    super.key,
    required this.username,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // =====================================================
  // SETTINGS
  // =====================================================

  bool waterAlert = true;
  bool offlineAlert = true;
  bool temperatureAlert = true;
  bool humidityAlert = true;
  bool motionAlert = true;

  bool isLoading = true;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // =====================================================
  // LOAD SETTINGS FROM SUPABASE
  // =====================================================

  Future<void> loadSettings() async {
    try {
      final user = supabase.auth.currentUser;

      // ยังไม่ได้ Login
      if (user == null) {
        debugPrint('ไม่มีผู้ใช้ที่ Login อยู่');

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        return;
      }

      debugPrint('User ID: ${user.id}');

      final data = await supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      // ==========================================
      // ยังไม่มีข้อมูล → สร้างข้อมูลเริ่มต้น
      // ==========================================

      if (data == null) {
        await createDefaultSettings(user.id);
      }

      // ==========================================
      // มีข้อมูลแล้ว → โหลดค่าจาก Supabase
      // ==========================================

      else {
        if (mounted) {
          setState(() {
            waterAlert =
                data['water_alert'] ?? true;

            offlineAlert =
                data['device_connection_alert'] ?? true;

            temperatureAlert =
                data['high_temperature_alert'] ?? true;

            humidityAlert =
                data['humidity_alert'] ?? true;

            motionAlert =
                data['motion_alert'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Load settings error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'โหลดการตั้งค่าไม่สำเร็จ\n$e',
            ),
          ),
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
  // CREATE DEFAULT SETTINGS
  // =====================================================

  Future<void> createDefaultSettings(
    String userId,
  ) async {
    try {
      await supabase.from('user_settings').insert({
        'user_id': userId,
        'water_alert': true,
        'device_connection_alert': true,
        'high_temperature_alert': true,
        'humidity_alert': true,
        'motion_alert': true,
      });

      debugPrint('สร้างค่า Settings เริ่มต้นแล้ว');
    } catch (e) {
      debugPrint(
        'Create default settings error: $e',
      );
    }
  }

  // =====================================================
  // UPDATE SETTING
  // =====================================================

  Future<void> updateSetting(
    String column,
    bool value,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('ไม่มี User Login');
      return;
    }

    try {
      await supabase
          .from('user_settings')
          .update({
            column: value,
            'updated_at':
                DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      debugPrint(
        'บันทึก $column = $value สำเร็จ',
      );
    } catch (e) {
      debugPrint(
        'Update setting error: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'บันทึกการตั้งค่าไม่สำเร็จ',
            ),
          ),
        );
      }
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D13),

      appBar: AppBar(
        backgroundColor: const Color(0xFF080D13),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ตั้งค่า',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF46B9EA),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // ==============================
                  // USER PROFILE
                  // ==============================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: const Color(0xFF151B25),
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF29313D),
                      ),
                    ),

                    child: Row(
                      children: [

                        const CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              Color(0xFF29313D),

                          child: Icon(
                            Icons.person,
                            color: Color(0xFF46B9EA),
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            const Text(
                              'ชื่อผู้ใช้',

                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              widget.username,

                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==============================
                  // NOTIFICATION SETTINGS
                  // ==============================

                  const Text(
                    'ตั้งค่าการแจ้งเตือน',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151B25),
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF29313D),
                      ),
                    ),

                    child: Column(
                      children: [

                        // ==========================
                        // WATER
                        // ==========================

                        buildSwitch(
                          icon:
                              Icons.water_drop_outlined,

                          title:
                              'แจ้งเตือนน้ำต่ำ',

                          value: waterAlert,

                          onChanged: (value) {
                            setState(() {
                              waterAlert = value;
                            });

                            updateSetting(
                              'water_alert',
                              value,
                            );
                          },
                        ),

                        // ==========================
                        // OFFLINE
                        // ==========================

                        buildSwitch(
                          icon: Icons.wifi_off,

                          title:
                              'แจ้งเตือนอุปกรณ์ถูกตัดการเชื่อมต่อ',

                          value: offlineAlert,

                          onChanged: (value) {
                            setState(() {
                              offlineAlert = value;
                            });

                            updateSetting(
                              'device_connection_alert',
                              value,
                            );
                          },
                        ),

                        // ==========================
                        // TEMPERATURE
                        // ==========================

                        buildSwitch(
                          icon: Icons.thermostat,

                          title:
                              'แจ้งเตือนอุณหภูมิสูง',

                          value:
                              temperatureAlert,

                          onChanged: (value) {
                            setState(() {
                              temperatureAlert =
                                  value;
                            });

                            updateSetting(
                              'high_temperature_alert',
                              value,
                            );
                          },
                        ),

                        // ==========================
                        // HUMIDITY
                        // ==========================

                        buildSwitch(
                          icon: Icons.water_drop,

                          title:
                              'แจ้งเตือนความชื้น',

                          value: humidityAlert,

                          onChanged: (value) {
                            setState(() {
                              humidityAlert =
                                  value;
                            });

                            updateSetting(
                              'humidity_alert',
                              value,
                            );
                          },
                        ),

                        // ==========================
                        // MOTION
                        // ==========================

                        buildSwitch(
                          icon: Icons.show_chart,

                          title:
                              'แจ้งเตือนการตรวจจับการเคลื่อนไหว',

                          value: motionAlert,

                          onChanged: (value) {
                            setState(() {
                              motionAlert =
                                  value;
                            });

                            updateSetting(
                              'motion_alert',
                              value,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==============================
                  // BACK BUTTON
                  // ==============================

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF46B9EA),
                      ),

                      label: const Text(
                        'กลับหน้าหลัก',

                        style: TextStyle(
                          color: Color(0xFF46B9EA),
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      style:
                          OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF46B9EA),
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // =====================================================
  // SWITCH WIDGET
  // =====================================================

  Widget buildSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Column(
      children: [

        SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),

          secondary: Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: const Color(0xFF29313D),
              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: const Color(0xFF46B9EA),
            ),
          ),

          title: Text(
            title,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),

          value: value,

          activeColor:
              const Color(0xFF46B9EA),

          onChanged: onChanged,
        ),

        const Divider(
          color: Color(0xFF29313D),
          height: 1,
        ),
      ],
    );
  }
}
