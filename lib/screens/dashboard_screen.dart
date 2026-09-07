import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_screen.dart';
import 'notification_screen.dart';
import 'device_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;

  const DashboardScreen({
    super.key,
    required this.username,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  // =====================================================
  // SUPABASE DEVICE
  // =====================================================

  String? deviceId;

  bool loading = true;
  bool saving = false;

  // =====================================================
  // DEVICE STATES
  // =====================================================

  bool fanOn = false;
  bool mistOn = false;
  bool automaticMode = true;

  int fanLevel = 2;
  int mistLevel = 0;

  double humiditySetting = 45;

  bool emergencyStop = false;

  // =====================================================
  // SENSOR VALUES
  // =====================================================

  double temperature = 27.2;
  double humidity = 63.4;

  int waterLevel = 0;
  bool motionDetected = false;

  double ultrasonicDistance = 0.0;

  bool fanRunning = false;
  bool mistRunning = false;

  bool deviceOnline = false;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // =====================================================
  // LOAD DATA FROM SUPABASE
  // =====================================================

  Future<void> loadData() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      // ---------------------------------------------
      // โหลด device_controls
      // ---------------------------------------------
       
      final List<dynamic> controlRows = await supabase
          .from('device_controls')
          .select()
          .limit(1);

      debugPrint('device_controls rows = $controlRows');

      if (controlRows.isEmpty) {
        throw Exception(
          'ไม่พบข้อมูลใน device_controls '
          'หรือ RLS ไม่อนุญาตให้ SELECT',
        );
      }

      final controlData =
          controlRows.first as Map<String, dynamic>;

      // ---------------------------------------------
      // กำหนด deviceId ก่อน
      // ---------------------------------------------

      deviceId = controlData['device_id']?.toString();

      debugPrint('DEVICE ID = $deviceId');

      // ---------------------------------------------
      // โหลด relay_control
      //
      // relay1 = FAN
      // relay2 = MIST
      // ---------------------------------------------

      if (deviceId != null) {
        final relayData = await supabase
            .from('relay_control')
            .select('relay1, relay6')
            .eq('device_id', deviceId!)
            .maybeSingle();

        debugPrint('RELAY CONTROL = $relayData');

        if (relayData != null && mounted) {
          setState(() {
            fanOn = relayData['relay1'] == true;
            mistOn = relayData['relay6'] == true;
          });
        }
      }

      // ---------------------------------------------
      // โหลดค่าจาก device_controls
      // ---------------------------------------------

      final bool power =
          controlData['power'] == true;

      final String mode =
          controlData['mode']?.toString() ?? 'manual';

      final int loadedFanLevel =
          (controlData['fan_level'] as num?)
                  ?.toInt() ??
              0;

      final int loadedMistLevel =
          (controlData['mist_level'] as num?)
                  ?.toInt() ??
              0;

      final double loadedHumidity =
          (controlData['target_humidity'] as num?)
                  ?.toDouble() ??
              45;

      final bool loadedEmergency =
          controlData['emergency_stop'] == true;

      if (mounted) {
        setState(() {
          // ใช้ relay_control เป็นตัวกำหนด ON/OFF
          // ถ้า deviceId ไม่มี ค่อยใช้ device_controls

          if (deviceId == null) {
            fanOn = power;
            mistOn = loadedMistLevel > 0;
          }

          automaticMode = mode == 'auto';

          fanLevel = loadedFanLevel;
          mistLevel = loadedMistLevel;

          humiditySetting = loadedHumidity;

          emergencyStop = loadedEmergency;

          // ถ้า Emergency เปิดอยู่ ให้สถานะเป็น OFF
          if (emergencyStop) {
            fanOn = false;
            mistOn = false;
            fanLevel = 0;
            mistLevel = 0;
          }
        });
      }

      // ---------------------------------------------
      // โหลด device_status
      // ---------------------------------------------

      if (deviceId != null) {
        final statusData = await supabase
            .from('device_status')
            .select()
            .eq('device_id', deviceId!)
            .maybeSingle();

        if (statusData != null && mounted) {
          setState(() {
            temperature =
                (statusData['temperature'] as num?)
                        ?.toDouble() ??
                    temperature;

            humidity =
                (statusData['humidity'] as num?)
                        ?.toDouble() ??
                    humidity;

            waterLevel =
                (statusData['water_level'] as num?)
                        ?.toInt() ??
                    0;

            motionDetected =
                statusData['motion_detected'] == true;

            fanRunning =
                statusData['fan_running'] == true;

            mistRunning =
                statusData['mist_running'] == true;

            deviceOnline =
                statusData['last_seen'] != null;
          });
        }
      }

      

      debugPrint('================================');
      debugPrint('Supabase โหลดข้อมูลสำเร็จ');
      debugPrint('DEVICE ID = $deviceId');
      debugPrint('FAN RELAY1 = $fanOn');
      debugPrint('MIST RELAY2 = $mistOn');
      debugPrint(
        'MODE = ${automaticMode ? "auto" : "manual"}',
      );
      debugPrint('FAN LEVEL = $fanLevel');
      debugPrint('MIST LEVEL = $mistLevel');
      debugPrint('HUMIDITY = $humiditySetting');
      debugPrint('================================');
    } catch (e) {
      debugPrint('LOAD SUPABASE ERROR: $e');

      if (mounted) {
        showMessage(
          'โหลดข้อมูลจาก Supabase ไม่สำเร็จ\n$e',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
// =====================================================
// LOAD ULTRASONIC + DETECT PERSON
// =====================================================

if (deviceId != null) {
  final ultrasonicData = await supabase
      .from('sensor_readings')
      .select('distance_cm, recorded_at')
      .eq('device_id', deviceId!)
      .order('recorded_at', ascending: false)
      .limit(1)
      .maybeSingle();

  debugPrint('ULTRASONIC DATA = $ultrasonicData');

  if (ultrasonicData != null && mounted) {
    final distance =
        (ultrasonicData['distance_cm'] as num?)
                ?.toDouble() ??
            -1.0;

    setState(() {
      ultrasonicDistance = distance;

      // ==========================================
      // ตรวจจับคนจากระยะ Ultrasonic
      // 0 - 100 cm = พบคน
      // > 100 cm = ไม่พบ
      // -1 = อ่านค่าไม่ได้
      // ==========================================

      motionDetected =
          distance >= 0 && distance <= 100;
    });

    debugPrint(
      'Distance = $distance cm | '
      'Motion = $motionDetected',
    );
  } else {
    if (mounted) {
      setState(() {
        ultrasonicDistance = -1.0;
        motionDetected = false;
      });
    }
  }
}
  }

  // =====================================================
  // UPDATE DEVICE CONTROLS
  // =====================================================

  Future<bool> updateControls(
    Map<String, dynamic> values,
  ) async {
    if (deviceId == null) {
      showMessage(
        'ไม่พบ device_id',
        error: true,
      );
      return false;
    }

    try {
      setState(() {
        saving = true;
      });

      final data = await supabase
          .from('device_controls')
          .update({
            ...values,
            'updated_at':
                DateTime.now().toIso8601String(),
          })
          .eq('device_id', deviceId!)
          .select()
          .single();

      debugPrint('================================');
      debugPrint('DEVICE CONTROLS UPDATE SUCCESS');
      debugPrint(data.toString());
      debugPrint('================================');

      return true;
    } catch (e) {
      debugPrint('DEVICE CONTROLS UPDATE ERROR: $e');

      if (mounted) {
        showMessage(
          'บันทึก Controls ไม่สำเร็จ\n$e',
          error: true,
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // =====================================================
  // UPDATE RELAY CONTROL
  //
  // relay1 = FAN
  // relay2 = MIST
  //
  // UPDATE ก่อน
  // ถ้าไม่มี Row -> INSERT
  // =====================================================

  Future<bool> updateRelayControl(
    Map<String, dynamic> values,
  ) async {
    if (deviceId == null) {
      showMessage(
        'ไม่พบ device_id',
        error: true,
      );
      return false;
    }

    try {
      setState(() {
        saving = true;
      });

      final String currentDeviceId = deviceId!;

      final updateData = {
        ...values,
        'updated_at':
            DateTime.now().toIso8601String(),
      };

      debugPrint('================================');
      debugPrint('RELAY CONTROL');
      debugPrint('DEVICE ID = $currentDeviceId');
      debugPrint('UPDATE DATA = $updateData');
      debugPrint('================================');

      // =================================================
      // STEP 1 : UPDATE
      // =================================================

      final List<dynamic> updatedRows =
          await supabase
              .from('relay_control')
              .update(updateData)
              .eq('device_id', currentDeviceId)
              .select();

      debugPrint(
        'RELAY UPDATE RESULT = $updatedRows',
      );

      // =================================================
      // ถ้า UPDATE สำเร็จ
      // =================================================

      if (updatedRows.isNotEmpty) {
        debugPrint(
          'RELAY CONTROL UPDATE SUCCESS',
        );

        return true;
      }

      // =================================================
      // STEP 2 : ถ้าไม่มี Row -> INSERT
      // =================================================

      debugPrint(
        'ไม่พบ relay_control ของ device_id นี้',
      );

      final Map<String, dynamic> insertData = {
        'device_id': currentDeviceId,
        'relay1': values.containsKey('relay1')
            ? values['relay1']
            : fanOn,
        'relay2': values.containsKey('relay2')
            ? values['relay2']
            : mistOn,
        'updated_at':
            DateTime.now().toIso8601String(),
      };

      debugPrint(
        'RELAY INSERT DATA = $insertData',
      );

      final List<dynamic> insertedRows =
          await supabase
              .from('relay_control')
              .insert(insertData)
              .select();

      debugPrint(
        'RELAY INSERT RESULT = $insertedRows',
      );

      if (insertedRows.isNotEmpty) {
        debugPrint(
          'RELAY CONTROL INSERT SUCCESS',
        );

        return true;
      }

      showMessage(
        'ไม่สามารถสร้าง relay_control ได้',
        error: true,
      );

      return false;
    } on PostgrestException catch (e) {
      debugPrint('================================');
      debugPrint('RELAY POSTGRES ERROR');
      debugPrint('MESSAGE = ${e.message}');
      debugPrint('CODE = ${e.code}');
      debugPrint('DETAILS = ${e.details}');
      debugPrint('HINT = ${e.hint}');
      debugPrint('================================');

      if (mounted) {
        showMessage(
          'บันทึก Relay ไม่สำเร็จ\n'
          '${e.message}\n'
          'Code: ${e.code}',
          error: true,
        );
      }

      return false;
    } catch (e) {
      debugPrint('================================');
      debugPrint('RELAY CONTROL ERROR');
      debugPrint(e.toString());
      debugPrint('================================');

      if (mounted) {
        showMessage(
          'บันทึก Relay ไม่สำเร็จ\n$e',
          error: true,
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // =====================================================
  // FAN ON / OFF
  //
  // relay1 = FAN
  // TRUE  = ON
  // FALSE = OFF
  // =====================================================

  Future<void> toggleFan() async {
    if (emergencyStop) {
      showMessage('ระบบหยุดฉุกเฉินอยู่');
      return;
    }

    final bool newPower = !fanOn;

    final int newLevel = newPower
        ? (fanLevel == 0 ? 2 : fanLevel)
        : 0;

    // -----------------------------------------
    // บันทึก Relay 1
    // -----------------------------------------

    final relaySuccess =
        await updateRelayControl({
      'relay1': newPower,
    });

    if (!relaySuccess) return;

    // -----------------------------------------
    // บันทึก device_controls
    // -----------------------------------------

    final controlSuccess =
        await updateControls({
      'power': newPower,
      'fan_level': newLevel,
    });

    if (!controlSuccess) return;

    if (!mounted) return;

    setState(() {
      fanOn = newPower;
      fanLevel = newLevel;
    });

    showMessage(
      newPower
          ? 'เปิดพัดลมแล้ว'
          : 'ปิดพัดลมแล้ว',
    );
  }

  // =====================================================
  // FAN LEVEL
  // =====================================================

  Future<void> changeFanLevel(int level) async {
    if (emergencyStop) {
      showMessage('ระบบหยุดฉุกเฉินอยู่');
      return;
    }

    // -----------------------------------------
    // การเลือกระดับพัดลม = เปิด Relay 1
    // -----------------------------------------

    final relaySuccess =
        await updateRelayControl({
      'relay1': true,
    });

    if (!relaySuccess) return;

    // -----------------------------------------
    // บันทึกระดับพัดลม
    // -----------------------------------------

    final success =
        await updateControls({
      'power': true,
      'fan_level': level,
    });

    if (!success) return;

    if (!mounted) return;

    setState(() {
      fanOn = true;
      fanLevel = level;
    });

    showMessage(
      'ตั้งพัดลมระดับ $level แล้ว',
    );
  }

  // =====================================================
  // MIST ON / OFF
  //
  // relay2 = MIST
  // TRUE  = ON
  // FALSE = OFF
  // =====================================================

  Future<void> toggleMist(bool value) async {
    if (emergencyStop) {
      showMessage('ระบบหยุดฉุกเฉินอยู่');
      return;
    }

    // -----------------------------------------
    // บันทึก Relay 6
    // -----------------------------------------

    final relaySuccess =
        await updateRelayControl({
      'relay6': value,
    });

    if (!relaySuccess) return;

    // -----------------------------------------
    // บันทึกระดับหมอก
    // -----------------------------------------

    final int level = value ? 1 : 0;

    final success =
        await updateControls({
      'mist_level': level,
    });

    if (!success) return;

    if (!mounted) return;

    setState(() {
      mistOn = value;
      mistLevel = level;
    });

    showMessage(
      value
          ? 'เปิดระบบพ่นหมอกแล้ว'
          : 'ปิดระบบพ่นหมอกแล้ว',
    );
  }

  // =====================================================
  // MANUAL / AUTO
  // =====================================================

  Future<void> changeMode(
    bool automatic,
  ) async {
    final String newMode =
        automatic ? 'auto' : 'manual';

    final success =
        await updateControls({
      'mode': newMode,
    });

    if (!success) return;

    if (!mounted) return;

    setState(() {
      automaticMode = automatic;
    });

    showMessage(
      automatic
          ? 'เปลี่ยนเป็นโหมดอัตโนมัติ'
          : 'เปลี่ยนเป็นโหมดแมนนวล',
    );
  }

  // =====================================================
  // HUMIDITY SETTING
  // =====================================================

  Future<void> changeHumidity(
    double value,
  ) async {
    final int newValue = value.round();

    final success =
        await updateControls({
      'target_humidity': newValue,
    });

    if (!success) return;

    if (!mounted) return;

    setState(() {
      humiditySetting =
          newValue.toDouble();
    });
  }

  // =====================================================
  // EMERGENCY STOP
  // =====================================================

  Future<void> toggleEmergency() async {
    final bool newEmergency =
        !emergencyStop;

    // -----------------------------------------
    // Emergency ON
    // ปิด Relay 1 และ Relay 2
    // -----------------------------------------

    if (newEmergency) {
      final relaySuccess =
          await updateRelayControl({
        'relay1': false,
        'relay6': false,
      });

      if (!relaySuccess) return;
    }

    final success =
        await updateControls({
      'emergency_stop': newEmergency,
      'power':
          newEmergency ? false : fanOn,
      'fan_level':
          newEmergency ? 0 : fanLevel,
      'mist_level':
          newEmergency ? 0 : mistLevel,
    });

    if (!success) return;

    if (!mounted) return;

    setState(() {
      emergencyStop = newEmergency;

      if (newEmergency) {
        fanOn = false;
        mistOn = false;
        fanLevel = 0;
        mistLevel = 0;
      }
    });

    showMessage(
      newEmergency
          ? 'เปิดระบบหยุดฉุกเฉิน'
          : 'ยกเลิกระบบหยุดฉุกเฉิน',
    );
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            maxLines: 5,
          ),
          backgroundColor: error
              ? Colors.red.shade700
              : const Color(0xFF0878C9),
          duration:
              const Duration(seconds: 3),
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
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),

            Expanded(
              child: RefreshIndicator(
                color:
                    const Color(0xFF39B9F0),
                backgroundColor:
                    const Color(0xFF151B25),
                onRefresh: loadData,
                child:
                    SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    25,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // SENSOR
                      // ==========================================

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SensorCard(
                              title: 'อุณหภูมิ',
                              value:
                                  '${temperature.toStringAsFixed(1)}°',
                              subtitle: 'อุณหภูมิ',
                              icon:
                                  Icons.thermostat_outlined,
                              color:
                                  const Color(0xFFFF6B24),
                              progress:
                                  ((temperature - 15) /
                                          25)
                                      .clamp(
                                          0.0, 1.0),
                            ),
                          ),

                          const SizedBox(
                              width: 12),

                          Expanded(
                            child: SensorCard(
                              title: 'ความชื้น',
                              value:
                                  '${humidity.toStringAsFixed(1)}%',
                              subtitle: 'ความชื้น',
                              icon:
                                  Icons.water_drop_outlined,
                              color:
                                  const Color(0xFF2196F3),
                              progress:
                                  (humidity / 100)
                                      .clamp(
                                          0.0, 1.0),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 25),

                      // ==========================================
                      // FAN
                      // ==========================================

                      const SectionTitle(
                        title:
                            'ควบคุมพัดลม',
                      ),

                      const SizedBox(
                          height: 10),

                      buildFanControl(),

                      const SizedBox(
                          height: 26),

                      // ==========================================
                      // MIST
                      // ==========================================

                      const SectionTitle(
                        title:
                            'ควบคุมหมอก',
                      ),

                      const SizedBox(
                          height: 10),

                      buildMistControl(),

                      const SizedBox(
                          height: 26),

                      // ==========================================
                      // MODE
                      // ==========================================

                      const SectionTitle(
                        title:
                            'โหมดการทำงาน',
                      ),

                      const SizedBox(
                          height: 10),

                      buildModeControl(),

                      const SizedBox(
                          height: 26),

                      // ==========================================
                      // HUMIDITY
                      // ==========================================

                      Text(
                        'ค่าอุณหภูมิความชื้นที่กำหนด — '
                        '${humiditySetting.round()}%',
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                          height: 10),

                      buildHumiditySlider(),

                      const SizedBox(
                          height: 26),

                      // ==========================================
                      // DEVICE STATUS
                      // ==========================================

                      const SectionTitle(
                        title:
                            'สถานะอุปกรณ์',
                      ),

                      const SizedBox(
                          height: 10),

                      buildDeviceStatus(),

                      const SizedBox(
                          height: 20),

                      if (saving)
                        const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Color(0xFF46B9EA),
                          ),
                        ),

                      if (loading)
                        const Padding(
                          padding:
                              EdgeInsets.all(20),
                          child: Center(
                            child:
                                CircularProgressIndicator(
                              color:
                                  Color(0xFF46B9EA),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget buildHeaderButton(
    IconData icon,
  ) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(.13),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        30,
        20,
        20,
        18,
      ),
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          colors: [
            Color(0xFF087FD0),
            Color(0xFF0399D1),
            Color(0xFF009A9A),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(30),
          bottomRight:
              Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                          17),
                ),
                child: const Icon(
                  Icons.air,
                  color:
                      Color(0xFF0A93D1),
                  size: 37,
                ),
              ),

              const SizedBox(
                  width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'พัดลมไอน้ำ',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    Text(
                      'อัจฉริยะ',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                behavior:
                    HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationScreen(),
                    ),
                  );
                },
                child:
                    buildHeaderButton(
                  Icons.notifications_none,
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                behavior:
                    HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsScreen(
                        username:
                            widget.username,
                      ),
                    ),
                  );
                },
                child:
                    buildHeaderButton(
                  Icons.settings_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(.15),
                  borderRadius:
                      BorderRadius.circular(
                          20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(
                        color: deviceOnline
                            ? Colors
                                .greenAccent
                            : Colors
                                .orangeAccent,
                        shape:
                            BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                        width: 7),
                  ],
                ),
              ),

              const SizedBox(
                  width: 18),

              const Expanded(
                child: Text(
                  'My Smart Mist Fan',
                  style:
                      TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FAN CONTROL
  // =====================================================

  Widget buildFanControl() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      decoration: dashboardBox(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: toggleFan,
                child: Container(
                  width: 105,
                  height: 105,
                  decoration:
                      BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: fanOn
                          ? const Color(
                              0xFF36B7ED)
                          : const Color(
                              0xFF77808E),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons
                        .power_settings_new,
                    size: 58,
                    color: fanOn
                        ? const Color(
                            0xFF3DBDF1)
                        : const Color(
                            0xFFCBD0D8),
                  ),
                ),
              ),

              const SizedBox(
                  width: 38),

              Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                              0xFF29303C),
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                    child: const Icon(
                      Icons.air,
                      color:
                          Color(0xFFCBD0D8),
                      size: 34,
                    ),
                  ),

                  const SizedBox(
                      height: 5),

                  Text(
                    fanOn ? 'ON' : 'OFF',
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                              0xFF292F3B),
                      borderRadius:
                          BorderRadius.circular(
                              15),
                    ),
                    child: Text(
                      fanLevel == 0
                          ? 'ปิด'
                          : fanLevel == 1
                              ? 'ต่ำ'
                              : fanLevel == 2
                                  ? 'เปิด'
                                  : 'สูง',
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const SizedBox(width: 8),
              fanLevelButton(
                'ความแรงพัดลมระดับกลาง',
                2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget fanLevelButton(
    String text,
    int level,
  ) {
    final bool selected =
        fanOn && fanLevel == level;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          changeFanLevel(level);
        },
        child: Container(
          height: 50,
          decoration:
              BoxDecoration(
            color: selected
                ? const Color(
                    0xFF45B9EB)
                : const Color(
                    0xFF292F3B),
            borderRadius:
                BorderRadius.circular(
                    13),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white70,
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // MIST CONTROL
  // =====================================================

  Widget buildMistControl() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 17,
      ),
      decoration: dashboardBox(),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF29303C),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: Colors.white70,
              size: 34,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  mistOn
                      ? 'ควบคุมหมอก ON'
                      : 'ควบคุมหมอก OFF',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  mistOn
                      ? 'ระบบพ่นหมอกกำลังทำงาน'
                      : 'ระบบพ่นหมอกปิดอยู่',
                  style:
                      const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: mistOn,
            activeColor:
                const Color(0xFF46B9EA),
            onChanged:
                emergencyStop
                    ? null
                    : toggleMist,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // MODE
  // =====================================================

  Widget buildModeControl() {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: dashboardBox(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: modeButton(
                  'แมนนวล',
                  false,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: modeButton(
                  'อัตโนมัติ',
                  true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF0574C8),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 20,
                ),

                SizedBox(width: 7),

                Expanded(
                  child: Text(
                    'พัดลมเปิดเมื่อตรวจพบการเคลื่อนไหว; '
                    'หมอกเปิดเมื่อความชื้นต่ำกว่าค่าที่กำหนด',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget modeButton(
    String text,
    bool automatic,
  ) {
    final bool selected =
        automaticMode == automatic;

    return GestureDetector(
      onTap: () {
        changeMode(automatic);
      },
      child: Container(
        height: 52,
        decoration:
            BoxDecoration(
          color: selected
              ? const Color(0xFF42B8EA)
              : const Color(0xFF292F3B),
          borderRadius:
              BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // HUMIDITY SLIDER
  // =====================================================

  Widget buildHumiditySlider() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        15,
        10,
        15,
        8,
      ),
      decoration: dashboardBox(),
      child: Row(
        children: [
          const Text(
            '20%',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          Expanded(
            child: Slider(
              value:
                  humiditySetting.clamp(
                      20, 90),
              min: 20,
              max: 90,
              divisions: 70,
              activeColor:
                  const Color(0xFF45B9EA),
              inactiveColor:
                  const Color(0xFF292F3B),
              thumbColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  humiditySetting =
                      value;
                });
              },
              onChangeEnd:
                  changeHumidity,
            ),
          ),

          const Text(
            '90%',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DEVICE STATUS
  // =====================================================

  Widget buildDeviceStatus() {
    return Row(
      children: [
        Expanded(
          child: StatusCard(
            icon:
                Icons.water_drop_outlined,
            iconColor:
                const Color(0xFFFF7043),
            title: 'ถังน้ำ',
            value:
                '$waterLevel%',
          ),
        ),

        const SizedBox(width: 10),

Expanded(
  child: StatusCard(
    icon: Icons.sensors,
    iconColor: const Color(0xFF68D17D),
    title: 'เซ็นเซอร์',
    value: motionDetected
        ? 'พบคน'
        : 'ไม่พบ',
  ),
),
      ],
    );
  }

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  Widget buildBottomNavigation() {
    return Container(
      height: 76,
      decoration:
          const BoxDecoration(
        color: Color(0xFF171D27),
        border: Border(
          top: BorderSide(
            color: Color(0xFF29303A),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: bottomItem(
              icon:
                  Icons.grid_view_rounded,
              text: 'แดชบอร์ด',
              selected: true,
              onTap: () {},
            ),
          ),

          Expanded(
            child: bottomItem(
              icon:
                  Icons.memory_outlined,
              text: 'อุปกรณ์',
              selected: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DeviceScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomItem({
    required IconData icon,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected
                ? const Color(
                    0xFF46B9EA)
                : Colors.white54,
            size: 28,
          ),

          const SizedBox(height: 3),

          Text(
            text,
            style: TextStyle(
              color: selected
                  ? const Color(
                      0xFF46B9EA)
                  : Colors.white54,
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // BOX STYLE
  // =====================================================

  BoxDecoration dashboardBox() {
    return BoxDecoration(
      color:
          const Color(0xFF151B25),
      borderRadius:
          BorderRadius.circular(18),
      border: Border.all(
        color:
            const Color(0xFF29313D),
        width: 1,
      ),
    );
  }
}

// =======================================================
// SECTION TITLE
// =======================================================

class SectionTitle
    extends StatelessWidget {
  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(
      BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight:
            FontWeight.w700,
      ),
    );
  }
}

// =======================================================
// SENSOR CARD
// =======================================================

class SensorCard
    extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        18,
        14,
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF171D27),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                    BoxDecoration(
                  color: color
                      .withOpacity(.16),
                  borderRadius:
                      BorderRadius.circular(
                          12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter:
                    CircleProgressPainter(
                  progress:
                      progress,
                  color: color,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Text(
                        value,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 28,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 13,
                        ),
                      ),
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
}

// =======================================================
// CIRCLE PROGRESS
// =======================================================

class CircleProgressPainter
    extends CustomPainter {
  final double progress;
  final Color color;

  CircleProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        size.width / 2 - 12;

    final backgroundPaint =
        Paint()
          ..color =
              const Color(0xFF303743)
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap =
              StrokeCap.round;

    final progressPaint =
        Paint()
          ..color = color
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap =
              StrokeCap.round;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      2 *
          math.pi *
          progress.clamp(
              0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CircleProgressPainter
        oldDelegate,
  ) {
    return oldDelegate.progress !=
            progress ||
        oldDelegate.color != color;
  }
}

// =======================================================
// STATUS CARD
// =======================================================

class StatusCard
    extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const StatusCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      height: 126,
      padding:
          const EdgeInsets.all(10),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF151B25),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFF29313D),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                      11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 27,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            title,
            maxLines: 2,
            textAlign:
                TextAlign.center,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}