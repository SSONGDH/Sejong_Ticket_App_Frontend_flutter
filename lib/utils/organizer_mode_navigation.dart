import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passtime/admin/admin_ticket_screen.dart';
import 'package:passtime/cookiejar_singleton.dart';

Future<void> navigateToOrganizerMode(BuildContext context, Dio dio) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final uri = Uri.parse(baseUrl);
    final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);
    final cookieHeader = cookies.isNotEmpty
        ? cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ')
        : '';
    final headers = {'Cookie': cookieHeader};

    final mypageResponse = await dio.get(
      '$baseUrl/user/mypage',
      options: Options(headers: headers),
    );
    final isRoot = mypageResponse.data['result']?['root'] == true;

    if (!isRoot) {
      final authResponse = await dio.get(
        '$baseUrl/user/affiliation/authorized',
        options: Options(headers: headers),
      );
      final result = authResponse.data['result'];
      final hasAuthorized = authResponse.data['isSuccess'] == true &&
          result is List &&
          result.isNotEmpty;

      if (!hasAuthorized) {
        if (!context.mounted) return;
        _showNoAuthorizedAffiliationDialog(context);
        return;
      }
    }

    final connectionResponse = await dio.get(
      '$baseUrl/admin/connection',
      options: Options(headers: headers),
    );

    if (!context.mounted) return;

    if (connectionResponse.statusCode == 200 &&
        connectionResponse.data['isSuccess'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminTicketScreen()),
        (route) => false,
      );
    } else {
      _showOrganizerDeniedDialog(context);
    }
  } catch (_) {
    if (context.mounted) _showOrganizerDeniedDialog(context);
  }
}

void _showNoAuthorizedAffiliationDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text(
        '권한이 있는 소속이 없습니다!',
        textAlign: TextAlign.center,
      ),
      content: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          '소속 권한자에게 권한을 부여받거나\n위임받으세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
        ),
      ],
    ),
  );
}

void _showOrganizerDeniedDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('알림'),
      content: const Text('지정된 주최자가 아닙니다.'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
        ),
      ],
    ),
  );
}
