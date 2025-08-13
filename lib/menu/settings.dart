import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:PASSTIME/widgets/custom_app_bar.dart';
import 'package:PASSTIME/screens/login_screen.dart';
import 'package:PASSTIME/widgets/menu_button.dart';
import '../cookiejar_singleton.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotificationOn = false; // 초기 상태를 false로 설정
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchNotificationStatus(); // ✅ 앱 시작 시 알림 상태를 불러오는 함수 호출
  }

  void _setupDio() {
    final uri = Uri.parse(dotenv.env['API_BASE_URL']!);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cookies =
            await CookieJarSingleton().cookieJar.loadForRequest(uri);
        if (cookies.isNotEmpty) {
          options.headers[HttpHeaders.cookieHeader] = cookies
              .map((cookie) => '${cookie.name}=${cookie.value}')
              .join('; ');
        }
        handler.next(options);
      },
    ));
  }

  // ✅ 서버에서 현재 알림 상태를 가져오는 함수
  Future<void> _fetchNotificationStatus() async {
    final String? apiBaseUrl = dotenv.env['API_BASE_URL'];
    if (apiBaseUrl == null) {
      print('.env 파일에 API_BASE_URL이 설정되지 않았습니다.');
      return;
    }

    final url = '$apiBaseUrl/user/setting/';

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200 &&
          response.data['code'] == 'SUCCESS-0000') {
        setState(() {
          isNotificationOn = response.data['notification'];
        });
        print('알림 상태 불러오기 성공: $isNotificationOn');
      } else {
        print('알림 상태 불러오기 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('알림 상태 불러오기 중 네트워크 오류 발생: ${e.message}');
    }
  }

  Future<void> _toggleNotification(bool value) async {
    final String? apiBaseUrl = dotenv.env['API_BASE_URL'];
    if (apiBaseUrl == null) {
      print('.env 파일에 API_BASE_URL이 설정되지 않았습니다.');
      setState(() {
        isNotificationOn = !value;
      });
      return;
    }

    final url = '$apiBaseUrl/notification/toggle/';
    final requestBody = json.encode({'isNotificationOn': value});

    try {
      final response = await _dio.patch(
        url,
        data: requestBody,
        options: Options(
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        print('알림 상태가 성공적으로 업데이트되었습니다.');
      } else {
        print('알림 상태 업데이트 실패: ${response.statusCode}');
        setState(() {
          isNotificationOn = !value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 설정 변경에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } on DioException catch (e) {
      print('네트워크 오류 발생: ${e.message}');
      setState(() {
        isNotificationOn = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

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
              onPressed: () async {
                Navigator.of(context).pop();
                await CookieJarSingleton().cookieJar.deleteAll();
                _logout();
              },
              isDestructiveAction: true,
              child: const Text(
                "확인",
                style: TextStyle(color: Color(0xFFC10230)),
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
                    _toggleNotification(value);
                  },
                ),
                const SizedBox(height: 16),
                _buildCustomTile(title: '문의사항', infoText: '010-8839-3384'),
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
