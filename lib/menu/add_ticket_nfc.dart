import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../cookiejar_singleton.dart';
import 'package:PASSTIME/screens/ticket_screen.dart';

class AddTicketNfcScreen extends StatefulWidget {
  const AddTicketNfcScreen({super.key});

  @override
  State<AddTicketNfcScreen> createState() => _AddTicketNfcScreenState();
}

class _AddTicketNfcScreenState extends State<AddTicketNfcScreen> {
  bool _isProcessingTag = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNfcSession();
    });
  }

  Future<void> _logNfcAvailability() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    print('[NFC] 지원 여부: $isAvailable');
  }

  Future<void> _startNfcSession() async {
    await _logNfcAvailability();
    if (!mounted) return;

    print("[NFC] 기존 세션 중지 시도 (iOS 안정화용)");
    try {
      await NfcManager.instance.stopSession();
      print("[NFC] stopSession 완료");
    } catch (e) {
      print("[NFC] stopSession 예외 무시: $e");
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    print("[NFC] 세션 시작 시도");
    try {
      await NfcManager.instance.startSession(
        alertMessage: "카드를 태그해주세요",
        onDiscovered: (NfcTag tag) async {
          print("[NFC] onDiscovered 호출됨");
          await _logNfcAvailability();
          print("[NFC] 태그 발견됨: ${tag.data}");

          if (mounted) {
            setState(() {
              _isProcessingTag = true;
            });
          }

          final ndef = Ndef.from(tag);
          if (ndef == null) {
            final tagId = tag.data['id'];
            if (tagId != null) {
              final hexId = tagId
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join(':')
                  .toUpperCase();
              print("[NFC] NDEF 아님, 태그 UID: $hexId");

              await NfcManager.instance
                  .stopSession(alertMessage: "태그 UID: $hexId");

              if (mounted) {
                setState(() => _isProcessingTag = false);
              }
              return;
            } else {
              print("[NFC] NDEF 메시지도 없고 UID도 읽을 수 없음");
              await NfcManager.instance
                  .stopSession(alertMessage: "인식 불가 태그입니다.");
              if (mounted) {
                setState(() => _isProcessingTag = false);
              }
              return;
            }
          }

          print("[NFC] NDEF 태그 확인됨");
          final records = ndef.cachedMessage?.records;
          if (records == null || records.isEmpty) {
            print("[NFC] NDEF 레코드 없음");
            await NfcManager.instance
                .stopSession(alertMessage: "태그에 데이터가 없습니다.");
            if (mounted) {
              setState(() => _isProcessingTag = false);
            }
            return;
          }

          final payload = records.first.payload;
          final eventCode = String.fromCharCodes(payload.skip(3));
          print("[NFC] 추출된 eventCode: $eventCode");

          await NfcManager.instance.stopSession(alertMessage: "등록 중...");

          if (mounted) {
            await _sendTicketIdToServer(eventCode);
          }
        },
        onError: (error) async {
          print("[NFC] 세션 에러 발생: $error");
          if (mounted) {
            setState(() => _isProcessingTag = false);
          }
        },
      );
      print("[NFC] 세션 정상 시작됨");
    } catch (e) {
      print("[NFC] startSession 예외 발생: $e");
      if (mounted) {
        setState(() => _isProcessingTag = false);
      }
    }
  }

  Future<void> _sendTicketIdToServer(String eventCode) async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/ticket/addNFC';
    final dio = Dio();
    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');
    final cookies = await CookieJarSingleton().cookieJar.loadForRequest(uri);

    try {
      print("[API] 티켓 등록 요청 시작: $eventCode");
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

      print("[API] 응답 수신: ${response.statusCode}, 데이터: ${response.data}");

      if (response.statusCode == 200 && response.data['isSuccess']) {
        if (mounted) {
          // ✅ 성공 시 자동으로 티켓 화면으로 이동
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
      print("[API] 요청 실패: $e");
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
    } finally {
      if (mounted) {
        setState(() => _isProcessingTag = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
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
        body: Align(
          alignment: const Alignment(0.0, -0.1),
          child: _isProcessingTag
              ? const CircularProgressIndicator()
              : Text(
                  'NFC 기능을 켜고 카드를 대주세요',
                  style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF334D61).withOpacity(0.5),
                      fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
