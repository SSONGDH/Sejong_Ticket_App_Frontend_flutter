import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../cookiejar_singleton.dart';
import 'package:passtime/screens/ticket_screen.dart';

class AddTicketNfcScreen extends StatefulWidget {
  const AddTicketNfcScreen({super.key});

  @override
  State<AddTicketNfcScreen> createState() => _AddTicketNfcScreenState();
}

class _AddTicketNfcScreenState extends State<AddTicketNfcScreen> {
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNfcSession();
    });
  }

  Future<void> _startNfcSession() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    print('[NFC] 지원 여부: $isAvailable');
    if (!mounted) return;

    // Android에서만 대기 팝업 표시
    if (Platform.isAndroid) _showWaitingDialog();

    try {
      await NfcManager.instance.startSession(
        alertMessage: "카드를 태그해주세요",
        onDiscovered: (NfcTag tag) async {
          // Android 팝업 닫기
          if (Platform.isAndroid && _isDialogShowing) Navigator.pop(context);
          _isDialogShowing = false;

          // Android에서 서버 요청 전 팝업 표시
          if (Platform.isAndroid) _showProcessingDialog();

          final ndef = Ndef.from(tag);
          String eventCode = '';
          if (ndef != null && ndef.cachedMessage?.records.isNotEmpty == true) {
            final payload = ndef.cachedMessage!.records.first.payload;
            eventCode = String.fromCharCodes(payload.skip(3));
          } else {
            final tagId = tag.data['id'];
            if (tagId != null) {
              eventCode = tagId
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join(':')
                  .toUpperCase();
            } else {
              if (Platform.isAndroid && _isDialogShowing)
                Navigator.pop(context);
              _isDialogShowing = false;
              return;
            }
          }

          await NfcManager.instance.stopSession(alertMessage: "등록 중...");
          await _sendTicketIdToServer(eventCode);
        },
        onError: (error) async {
          if (Platform.isAndroid && _isDialogShowing) Navigator.pop(context);
          _isDialogShowing = false;
          print("[NFC] 세션 에러: $error");
        },
      );
    } catch (e) {
      if (Platform.isAndroid && _isDialogShowing) Navigator.pop(context);
      _isDialogShowing = false;
      print("[NFC] startSession 예외: $e");
    }
  }

  void _showWaitingDialog() {
    if (!Platform.isAndroid) return; // iOS에서는 팝업 안 띄움
    _isDialogShowing = true;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        title: Text("NFC 대기 중"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("카드를 핸드폰에 태그해주세요"),
          ],
        ),
      ),
    );
  }

  void _showProcessingDialog() {
    if (!Platform.isAndroid) return; // iOS에서는 팝업 안 띄움
    _isDialogShowing = true;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        title: Text("등록 중"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("서버로 티켓을 전송 중입니다..."),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTicketIdToServer(String eventCode) async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/ticket/addNFC';
    final dio = Dio();
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);

    try {
      final response = await dio.post(
        apiUrl,
        data: {'eventCode': eventCode},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Cookie': cookies.map((c) => '${c.name}=${c.value}').join('; '),
          },
        ),
      );

      if (Platform.isAndroid && _isDialogShowing) Navigator.pop(context);
      _isDialogShowing = false;

      if (response.statusCode == 200 && response.data['isSuccess']) {
        if (mounted && Platform.isAndroid) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("성공"),
              content: const Text("입장권이 성공적으로 추가되었습니다!"),
              actions: [
                CupertinoDialogAction(
                  child: const Text("확인",
                      style: TextStyle(color: Color(0xFFC10230))),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TicketScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        } else if (mounted && !Platform.isAndroid) {
          // iOS에서는 바로 화면 전환만
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TicketScreen()),
          );
        }
      } else {
        if (mounted && Platform.isAndroid) {
          final message = response.data['message'] ?? '티켓 등록 실패';
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("오류"),
              content: Text(message),
              actions: [
                CupertinoDialogAction(
                  child: const Text("확인",
                      style: TextStyle(color: Color(0xFFC10230))),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (Platform.isAndroid && _isDialogShowing) Navigator.pop(context);
      _isDialogShowing = false;

      if (mounted && Platform.isAndroid) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text("네트워크 오류"),
            content: const Text("서버 오류. 다시 시도해 주세요."),
            actions: [
              CupertinoDialogAction(
                child: const Text("확인",
                    style: TextStyle(color: Color(0xFFC10230))),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 자체는 백그라운드용
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Color(0xFF334D61),
            size: 30,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'NFC',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const Center(),
    );
  }
}
  