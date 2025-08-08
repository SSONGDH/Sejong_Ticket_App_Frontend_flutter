import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:PASSTIME/screens/login_screen.dart';
import 'package:PASSTIME/widgets/menu_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotificationOn = true;

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
              child: const Text(
                "취소",
              ),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              isDestructiveAction: true,
              child: const Text(
                "확인",
                style: TextStyle(color: Color(0xFFC10230)), // '확인' 버튼 색상 직접 지정
              ),
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
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: const CustomAppBar(title: "설정"),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomTile(
                  title: '알림',
                  isSwitch: true,
                  switchValue: isNotificationOn,
                  onSwitchChanged: (value) {
                    setState(() {
                      isNotificationOn = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildCustomTile(title: '문의사항', infoText: '010-1234-5678'),
                const SizedBox(height: 16),
                _buildCustomTile(title: '패치버전', infoText: '1.0.1'),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: _showLogoutDialog,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Color(0xFFC10230),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: const MenuButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCustomTile({
    required String title,
    String? infoText,
    bool isSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black,
            ),
          ),
          if (isSwitch)
            CupertinoSwitch(
              value: switchValue,
              onChanged: onSwitchChanged,
              activeTrackColor: const Color(0xFFC10230),
            )
          else if (infoText != null)
            Text(
              infoText,
              style: TextStyle(
                fontSize: 16.0,
                color: const Color(0xFF334D61).withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}
