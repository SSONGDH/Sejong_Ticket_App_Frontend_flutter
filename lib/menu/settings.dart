import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:PASSTIME/widgets/app_bar.dart';
import 'package:PASSTIME/screens/login_screen.dart';
import 'package:PASSTIME/widgets/click_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotificationOn = true;
  bool isDarkModeOn = false;

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("로그아웃"),
          content: const Text("로그아웃하시겠습니까?"),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("취소"),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              isDestructiveAction: true,
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          const CustomAppBar(title: "설정", backgroundColor: Color(0xFFB93234)),
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildSettingTile('알림', isNotificationOn, (value) {
                  setState(() {
                    isNotificationOn = value;
                  });
                }),
                _buildSettingTile('다크모드', isDarkModeOn, (value) {
                  setState(() {
                    isDarkModeOn = value;
                  });
                }),
                _buildInfoTile('문의사항', '010-5265-4339', isInfo: true),
                _buildInfoTile('패치버전', '1.0.1', isInfo: true),
              ],
            ),
          ),
          Positioned(
            bottom: 30, // 화면 하단에서의 간격 조정
            left: 30,
            right: 30,
            child: CustomButton(
              onPressed: _showLogoutDialog,
              color: const Color(0xFFB93234),
              borderRadius: 5,
              height: 55,
              child: const Text(
                '로그아웃',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      width: double.infinity,
      height: 60, // 높이를 고정값으로 설정
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16.0, color: Colors.black), // 텍스트 색상을 변경
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFB93234),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, {bool isInfo = false}) {
    return Container(
      width: double.infinity,
      height: 60, // 높이를 고정값으로 설정
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16.0, color: Colors.black),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16.0, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
