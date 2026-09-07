import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {

  // ==========================================
  // รายการแจ้งเตือนจาก Supabase
  // ==========================================

  List<Map<String, dynamic>> notifications = [];

  bool isLoading = true;

  // ==========================================
  // INIT
  // ==========================================

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  // ==========================================
  // LOAD NOTIFICATIONS
  // ==========================================

  Future<void> loadNotifications() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('ยังไม่มีผู้ใช้ Login');

        if (mounted) {
          setState(() {
            notifications = [];
            isLoading = false;
          });
        }

        return;
      }

      debugPrint('กำลังโหลดแจ้งเตือนของ User: ${user.id}');

      final data = await supabase
          .from('device_alerts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> result = [];

      for (final item in data) {
        final alertType = item['alert_type'] ?? '';

        IconData icon = Icons.notifications_none;
        Color color = Colors.cyanAccent;

        // ==========================================
        // ICON ตามประเภทแจ้งเตือน
        // ==========================================

        if (alertType == 'device_offline') {
          icon = Icons.wifi_off;
          color = Colors.redAccent;
        } else if (alertType == 'water_low') {
          icon = Icons.water_drop_outlined;
          color = Colors.cyanAccent;
        } else if (alertType == 'temperature_high') {
          icon = Icons.thermostat;
          color = Colors.orangeAccent;
        } else if (alertType == 'humidity_high') {
          icon = Icons.water_drop;
          color = Colors.blueAccent;
        } else if (alertType == 'motion_detected') {
          icon = Icons.show_chart;
          color = Colors.yellowAccent;
        }

        result.add({
          'id': item['id'],
          'title': item['title'] ?? 'แจ้งเตือน',
          'message': item['message'] ?? '',
          'time': formatDateTime(item['created_at']),
          'icon': icon,
          'color': color,
          'read': item['is_read'] ?? false,
        });
      }

      if (mounted) {
        setState(() {
          notifications = result;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load notifications error: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'โหลดการแจ้งเตือนไม่สำเร็จ\n$e',
            ),
          ),
        );
      }
    }
  }

  // ==========================================
  // FORMAT DATE TIME
  // ==========================================

  String formatDateTime(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final date = DateTime.parse(
        value.toString(),
      ).toLocal();

      // ค.ศ. → พ.ศ.
      final buddhistYear = date.year + 543;

      return '${date.day}/${date.month}/$buddhistYear '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}:'
          '${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return value.toString();
    }
  }

  // ==========================================
  // ทำเครื่องหมายว่าอ่านแล้วทั้งหมด
  // ==========================================

  Future<void> markAllAsRead() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await supabase
          .from('device_alerts')
          .update({
            'is_read': true,
          })
          .eq('user_id', user.id)
          .eq('is_read', false);

      setState(() {
        for (var item in notifications) {
          item['read'] = true;
        }
      });

      debugPrint('ทำเครื่องหมายอ่านทั้งหมดแล้ว');
    } catch (e) {
      debugPrint(
        'Mark all as read error: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ไม่สามารถทำเครื่องหมายว่าอ่านแล้วได้',
            ),
          ),
        );
      }
    }
  }

  // ==========================================
  // ลบทั้งหมด
  // ==========================================

  Future<void> clearAll() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    // ถ้าไม่มีข้อมูล
    if (notifications.isEmpty) {
      return;
    }

    try {
      await supabase
          .from('device_alerts')
          .delete()
          .eq('user_id', user.id);

      setState(() {
        notifications.clear();
      });

      debugPrint('ลบการแจ้งเตือนทั้งหมดแล้ว');
    } catch (e) {
      debugPrint(
        'Clear notifications error: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ไม่สามารถล้างการแจ้งเตือนได้',
            ),
          ),
        );
      }
    }
  }

  // ==========================================
  // MARK SINGLE NOTIFICATION AS READ
  // ==========================================

  Future<void> markAsRead(int index) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final item = notifications[index];

    if (item['read'] == true) {
      return;
    }

    final id = item['id'];

    try {
      await supabase
          .from('device_alerts')
          .update({
            'is_read': true,
          })
          .eq('id', id)
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          notifications[index]['read'] = true;
        });
      }
    } catch (e) {
      debugPrint(
        'Mark notification read error: $e',
      );
    }
  }

  // ==========================================
  // จำนวนที่ยังไม่ได้อ่าน
  // ==========================================

  int get unreadCount {
    return notifications
        .where(
          (item) => item['read'] == false,
        )
        .length;
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D13),

      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF39B9F0),
                ),
              )
            : Column(
                children: [

                  // ====================================
                  // HEADER
                  // ====================================

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      15,
                    ),

                    child: Row(
                      children: [

                        // ปุ่มย้อนกลับ
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },

                          child: Container(
                            width: 62,
                            height: 62,

                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF29313D),
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),

                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),

                        const SizedBox(width: 18),

                        // ชื่อหน้า
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              const Text(
                                'การแจ้งเตือน',

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '${notifications.length} การแจ้งเตือน',

                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // กระดิ่ง
                        Container(
                          width: 62,
                          height: 62,

                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF087FD0),
                            borderRadius:
                                BorderRadius.circular(18),
                          ),

                          child: const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ====================================
                  // BUTTONS
                  // ====================================

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),

                    child: Row(
                      children: [

                        // ทำเครื่องหมายว่าอ่านแล้ว
                        Expanded(
                          child: SizedBox(
                            height: 58,

                            child: ElevatedButton.icon(
                              onPressed:
                                  notifications.isEmpty
                                      ? null
                                      : markAllAsRead,

                              icon: const Icon(
                                Icons.done_all,
                                color: Colors.white,
                              ),

                              label: const Text(
                                'ทำเครื่องหมายว่าอ่านแล้ว',

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),

                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(
                                  0xFF0878C9,
                                ),

                                disabledBackgroundColor:
                                    const Color(
                                  0xFF29313D,
                                ),

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // ล้างทั้งหมด
                        SizedBox(
                          height: 58,

                          child:
                              OutlinedButton.icon(
                            onPressed:
                                notifications.isEmpty
                                    ? null
                                    : clearAll,

                            icon: const Icon(
                              Icons.delete_outline,
                              color:
                                  Color(0xFF39B9F0),
                            ),

                            label: const Text(
                              'ล้างทั้งหมด',

                              style: TextStyle(
                                color:
                                    Color(0xFF39B9F0),
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            style:
                                OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(
                                color: Colors.white54,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ====================================
                  // NOTIFICATION LIST
                  // ====================================

                  Expanded(
                    child: notifications.isEmpty
                        ? const Center(
                            child: Text(
                              'ไม่มีการแจ้งเตือน',

                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              20,
                            ),

                            itemCount:
                                notifications.length,

                            itemBuilder:
                                (context, index) {

                              final item =
                                  notifications[index];

                              return notificationCard(
                                index,
                                item,
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),

      // ========================================
      // BOTTOM NAVIGATION
      // ========================================

      bottomNavigationBar:
          buildBottomNavigation(),
    );
  }

  // =================================================
  // NOTIFICATION CARD
  // =================================================

  Widget notificationCard(
    int index,
    Map<String, dynamic> item,
  ) {
    return GestureDetector(
      onTap: () {
        markAsRead(index);
      },

      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: const Color(0xFF0865A8),

          borderRadius:
              BorderRadius.circular(22),
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // =================================
            // ICON
            // =================================

            Container(
              width: 65,
              height: 65,

              decoration: BoxDecoration(
                color:
                    const Color(0xFF202B37),

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Icon(
                item['icon'],
                color: item['color'],
                size: 34,
              ),
            ),

            const SizedBox(width: 15),

            // =================================
            // TEXT
            // =================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    item['title'],

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item['message'],

                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    item['time'],

                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // =================================
            // จุดแจ้งเตือน
            // =================================

            if (item['read'] == false)
              Container(
                width: 12,
                height: 12,

                decoration:
                    const BoxDecoration(
                  color: Color(0xFF57C9F5),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =================================================
  // BOTTOM NAVIGATION
  // =================================================

  Widget buildBottomNavigation() {
    return Container(
      height: 80,

      decoration: const BoxDecoration(
        color: Color(0xFF111923),

        border: Border(
          top: BorderSide(
            color: Color(0xFF29313D),
          ),
        ),
      ),

      child: Row(
        children: [

          // Dashboard
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/dashboard',
                );
              },

              child: bottomItem(
                icon: Icons.grid_view_rounded,
                text: 'แดชบอร์ด',
                selected: false,
              ),
            ),
          ),

          // Device
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/device',
                );
              },

              child: bottomItem(
                icon: Icons.memory_outlined,
                text: 'อุปกรณ์',
                selected: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================================================
  // BOTTOM ITEM
  // =================================================

  Widget bottomItem({
    required IconData icon,
    required String text,
    required bool selected,
  }) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [

        Icon(
          icon,

          color: selected
              ? const Color(0xFF46B9EA)
              : Colors.white54,

          size: 28,
        ),

        const SizedBox(height: 4),

        Text(
          text,

          style: TextStyle(
            color: selected
                ? const Color(0xFF46B9EA)
                : Colors.white54,

            fontSize: 13,

            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }
}