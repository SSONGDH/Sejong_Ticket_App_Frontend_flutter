import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:PASSTIME/cookiejar_singleton.dart';
import 'package:PASSTIME/admin/request_admin_list.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    super.key,
    required this.title,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(100);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final Dio dio = Dio();
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cookies =
            await CookieJarSingleton().cookieJar.loadForRequest(uri);
        options.headers['Cookie'] = cookies.isNotEmpty
            ? cookies
                .map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; ')
            : '';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final responseCookies = response.headers['set-cookie'];
        if (responseCookies != null && responseCookies.isNotEmpty) {
          final parsedCookies = responseCookies
              .map((cookie) => Cookie.fromSetCookieValue(cookie.toString()))
              .toList();
          CookieJarSingleton().cookieJar.saveFromResponse(uri, parsedCookies);
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  void _handleTap(BuildContext context) async {
    final now = DateTime.now();

    if (_lastTapTime == null || now.difference(_lastTapTime!).inSeconds <= 1) {
      _tapCount++;
      if (_tapCount == 5) {
        _tapCount = 0;

        try {
          final apiUrl = '${dotenv.env['API_BASE_URL']}/admin/connection';
          final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
          final cookies =
              await CookieJarSingleton().cookieJar.loadForRequest(uri);

          final response = await dio.get(
            apiUrl,
            options: Options(headers: {'Cookie': cookies}),
          );

          // 서버 응답이 성공(isSuccess == true)일 때만 화면 전환
          if (response.data['isSuccess'] == true) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RequestAdminListScreen(),
              ),
            );
          }
          // else { ... } 실패 시 로직은 제거됨
        } on DioException {
          // catch (e) { ... } 오류 발생 시 로직은 제거됨
          // 아무런 동작도 하지 않습니다.
        }
      }
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 120,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 10.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _handleTap(context),
                    child: Image.asset(
                      'assets/images/sejong_logo.png',
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
