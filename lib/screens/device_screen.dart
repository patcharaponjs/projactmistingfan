import 'package:flutter/material.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // =====================================================
  // CONTROLLER
  // =====================================================

  final TextEditingController serialController =
      TextEditingController();

  // =====================================================
  // DEVICE DATA
  // =====================================================

  String serialId = '';

  String deviceName = 'My Smart Mist Fan';

  String ipAddress = '192.168.1.100';

  String firmwareVersion = '1.2.0';

  String macAddress = '24:6F:28:AA:BB:CC';

  @override
  void dispose() {
    serialController.dispose();
    super.dispose();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05001A),

      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // HEADER
            // =================================================

            buildHeader(),

            // =================================================
            // CONTENT
            // =================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // ESP32 INFORMATION
                    // =================================================

                    const Text(
                      'ข้อมูล ESP32',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 14),

                    buildDeviceInfoCard(),

                    const SizedBox(height: 28),

                    // =================================================
                    // LOGOUT
                    // =================================================

                    buildLogoutButton(),
                  ],
                ),
              ),
            ),

            // =================================================
            // BOTTOM NAVIGATION
            // =================================================

            buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER
  // =====================================================

  Widget buildHeader() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        children: [
          // BACK BUTTON
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pop(context);
            },
            child: const SizedBox(
              width: 45,
              height: 50,
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 12),

          const Text(
            'อุปกรณ์',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DEVICE INFORMATION
  // =====================================================

  Widget buildDeviceInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151B25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF29313D),
        ),
      ),
      child: Column(
        children: [
          buildInfoRow(
            icon: Icons.memory_outlined,
            title: 'ชื่ออุปกรณ์',
            value: deviceName,
          ),

          buildDivider(),

          buildInfoRow(
            icon: Icons.account_tree_outlined,
            title: 'ที่อยู่ IP',
            value: ipAddress,
          ),

          buildDivider(),

          buildInfoRow(
            icon: Icons.router_outlined,
            title: 'เวอร์ชันเฟิร์มแวร์',
            value: firmwareVersion,
          ),

          buildDivider(),

          buildInfoRow(
            icon: Icons.fingerprint,
            title: 'ที่อยู่ MAC',
            value: macAddress,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // INFO ROW
  // =====================================================

  Widget buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF42B8EA),
            size: 27,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DIVIDER
  // =====================================================

  Widget buildDivider() {
    return const Divider(
      color: Color(0xFF29313D),
      height: 1,
    );
  }

  // =====================================================
  // LOGOUT BUTTON
  // =====================================================

  Widget buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {
          // ล้าง route ทั้งหมด
          // แล้วกลับหน้า Login
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        },
        icon: const Icon(
          Icons.logout,
          color: Color(0xFF9C6BFF),
        ),
        label: const Text(
          'ออกจากระบบ',
          style: TextStyle(
            color: Color(0xFF9C6BFF),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFF9C6BFF),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // BOTTOM NAVIGATION
  // =====================================================

  Widget buildBottomNavigation() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF171D27),
        border: Border(
          top: BorderSide(
            color: Color(0xFF29313D),
          ),
        ),
      ),
      child: Row(
        children: [
          // DASHBOARD
          Expanded(
            child: GestureDetector(
              behavior:
                  HitTestBehavior.opaque,
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/dashboard',
                );
              },
              child: buildBottomItem(
                icon: Icons.grid_view_rounded,
                text: 'แดชบอร์ด',
                selected: false,
              ),
            ),
          ),

          // DEVICE
          Expanded(
            child: GestureDetector(
              behavior:
                  HitTestBehavior.opaque,
              onTap: () {},
              child: buildBottomItem(
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

  // =====================================================
  // BOTTOM ITEM
  // =====================================================

  Widget buildBottomItem({
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
              ? const Color(0xFF42B8EA)
              : Colors.white54,
          size: 25,
        ),

        const SizedBox(height: 3),

        Text(
          text,
          style: TextStyle(
            color: selected
                ? const Color(0xFF42B8EA)
                : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}