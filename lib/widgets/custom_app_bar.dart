import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:passtime/cookiejar_singleton.dart';
import 'package:passtime/admin/request_admin_list.dart';
import 'package:passtime/admin/admin_ticket_screen.dart';
import 'package:passtime/screens/ticket_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool isOrganizerMode;
  final bool logoNavigatesToParticipantHome;

  const CustomAppBar({
    super.key,
    required this.title,
    this.isOrganizerMode = false,
    this.logoNavigatesToParticipantHome = false,
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

  void _navigateToHome(BuildContext context) {
    final home = widget.logoNavigatesToParticipantHome || !widget.isOrganizerMode
        ? const TicketScreen()
        : const AdminTicketScreen();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
      (route) => false,
    );
  }

  Future<void> _handleRootAdminTap(BuildContext context) async {
    try {
      final apiUrl = '${dotenv.env['API_BASE_URL']}/root/connection';
      final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
      final cookies =
          await CookieJarSingleton().cookieJar.loadForRequest(uri);

      final response = await dio.get(
        apiUrl,
        options: Options(headers: {'Cookie': cookies}),
      );

      if (response.data['isSuccess'] == true) {
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const RequestAdminListScreen(),
          ),
        );
      }
    } on DioException {
      // root 권한 없음 — 무시
    }
  }

  void _handleTap(BuildContext context) async {
    final now = DateTime.now();

    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 1) {
      _tapCount = 0;
    }
    _tapCount++;
    _lastTapTime = now;

    if (_tapCount == 5) {
      _tapCount = 0;
      await _handleRootAdminTap(context);
      return;
    }

    final tapCountAtPress = _tapCount;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (_tapCount == tapCountAtPress && tapCountAtPress < 5) {
      _tapCount = 0;
      _navigateToHome(context);
    }
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
