import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../cookiejar_singleton.dart';
import 'package:passtime/screens/ticket_screen.dart';
import 'package:passtime/widgets/app_bar.dart';

class AddTicketNfcScreen extends StatefulWidget {
  const AddTicketNfcScreen({super.key});

  @override
  State<AddTicketNfcScreen> createState() => _AddTicketNfcScreenState();
}

class _AddTicketNfcScreenState extends State<AddTicketNfcScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logNfcAvailability();
      _startNfcSession();
    });
  }

  Future<void> _logNfcAvailability() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    print('[NFC] 지원 여부: $isAvailable');
  }

  Future<void> _startNfcSession() async {
    await _logNfcAvailability();
    setState(() => _isLoading = true);

    print("[NFC] 기존 세션 중지 시도 (iOS 안정화용)");
    try {
      await NfcManager.instance.stopSession();
      print("[NFC] stopSession 완료");
    } catch (e) {
      print("[NFC] stopSession 예외 무시: $e");
    }

    // 딜레이를 1500ms로 늘림 (iOS 세션 종료 대기 시간 확보)
    await Future.delayed(const Duration(milliseconds: 1500));

    print("[NFC] 세션 시작 시도");
    try {
      await NfcManager.instance.startSession(
        alertMessage: "카드를 태그해주세요",
        onDiscovered: (NfcTag tag) async {
          print("[NFC] onDiscovered 호출됨"); // 이 로그가 뜨는지 확인
          await _logNfcAvailability();
          print("[NFC] 태그 발견됨: ${tag.data}");

          final ndef = Ndef.from(tag);
          if (ndef == null) {
            // NDEF 메시지는 없지만, UID 읽기 시도
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('NDEF 메시지는 없지만 태그 UID: $hexId')),
                );
                setState(() => _isLoading = false);
              }

              // 여기서 raw 태그 ID를 서버에 보내거나, 원하는 처리를 할 수 있습니다.
              // await _sendTicketIdToServer(hexId);

              return;
            } else {
              print("[NFC] NDEF 메시지도 없고 UID도 읽을 수 없음");
              await NfcManager.instance
                  .stopSession(alertMessage: "인식 불가 태그입니다.");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('읽을 수 없는 태그입니다.')),
                );
                setState(() => _isLoading = false);
              }
              return;
            }
          }

          print("[NFC] NDEF 태그 확인됨");
          print("[NFC] cachedMessage: ${ndef.cachedMessage}");

          final records = ndef.cachedMessage?.records;
          if (records == null || records.isEmpty) {
            print("[NFC] NDEF 레코드 없음");
            await NfcManager.instance
                .stopSession(alertMessage: "태그에 데이터가 없습니다.");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('태그에 데이터가 없습니다.')),
              );
              setState(() => _isLoading = false);
            }
            return;
          }

          print("[NFC] NDEF 레코드 수: ${records.length}");
          final payload = records.first.payload;
          print("[NFC] 첫 번째 레코드 payload(raw): $payload");

          final eventCode = String.fromCharCodes(payload.skip(3));
          print("[NFC] 추출된 eventCode: $eventCode");

          print("[NFC] 서버에 티켓 ID 전송 시작");
          await NfcManager.instance.stopSession(alertMessage: "등록 중...");

          if (mounted) {
            await _sendTicketIdToServer(eventCode);
          }
        },
        onError: (error) async {
          print("[NFC] 세션 에러 발생: $error");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('NFC 세션 에러: $error')),
            );
            setState(() => _isLoading = false);
          }
        },
      );
      print("[NFC] 세션 정상 시작됨");
    } catch (e) {
      print("[NFC] startSession 예외 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NFC 세션 시작 실패: $e')),
        );
        setState(() => _isLoading = false);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('입장권이 성공적으로 추가되었습니다!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TicketScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? '티켓 등록 실패')),
        );
      }
    } catch (e) {
      print("[API] 요청 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 오류. 다시 시도해 주세요.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "NFC",
        backgroundColor: Color(0xFFB93234),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text(
                'NFC 태그를 가까이 대주세요',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
      ),
    );
  }
}
