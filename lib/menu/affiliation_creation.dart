import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../cookiejar_singleton.dart';
import 'package:PASSTIME/menu/my_page_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class MaskedInputController extends TextEditingController {
  @override
  set value(TextEditingValue newValue) {
    String newText = newValue.text;
    String cleanText = newText.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedText = _formatPhoneNumber(cleanText);

    super.value = newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _formatPhoneNumber(String text) {
    if (text.length <= 3) {
      return text;
    } else if (text.length <= 7) {
      return '${text.substring(0, 3)}-${text.substring(3)}';
    } else {
      return '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7, text.length)}';
    }
  }
}

class AffiliationCreationScreen extends StatefulWidget {
  final String hostName;
  final String studentId;

  const AffiliationCreationScreen({
    super.key,
    required this.hostName,
    required this.studentId,
  });

  @override
  State<AffiliationCreationScreen> createState() =>
      _AffiliationCreationScreenState();
}

class _AffiliationCreationScreenState extends State<AffiliationCreationScreen> {
  final TextEditingController _affiliationNameController =
      TextEditingController();
  late final TextEditingController _hostNameController;
  late final TextEditingController _studentIdController;
  // phoneNumberController를 MaskedInputController로 변경
  final MaskedInputController _phoneNumberController = MaskedInputController();

  final Dio _dio = Dio();

  bool _canCreate = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _hostNameController = TextEditingController(text: widget.hostName);
    _studentIdController = TextEditingController(text: widget.studentId);

    _affiliationNameController.addListener(_updateButtonState);
    _phoneNumberController.addListener(_updateButtonState);

    final uri = Uri.parse(dotenv.env['API_BASE_URL'] ?? '');

    // Interceptor 등록 (쿠키 자동 주입 및 저장)
    _dio.interceptors.add(InterceptorsWrapper(
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

  void _updateButtonState() {
    setState(() {});
  }

  @override
  void dispose() {
    _affiliationNameController.removeListener(_updateButtonState);
    _phoneNumberController.removeListener(_updateButtonState);

    _affiliationNameController.dispose();
    _hostNameController.dispose();
    _studentIdController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitAffiliationRequest() async {
    final apiUrl = '${dotenv.env['API_BASE_URL']}/affiliation/request';

    final requestBody = {
      "phone": _phoneNumberController.text.trim(),
      "affiliationName": _affiliationNameController.text.trim(),
      "createAffiliation": _canCreate,
      "requestAdmin": _hasPermission,
    };

    print('API 호출 시작: $requestBody');

    try {
      final response = await _dio.post(
        apiUrl,
        data: requestBody,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      print('API 호출 완료 - Status Code: ${response.statusCode}');
      print('Response Body: ${response.data}');

      if (response.data['code'] == 'SUCCESS-0000') {
        print('소속 신청이 성공적으로 완료되었습니다.');
        _showSuccessDialog();
      } else {
        print(
            '소속 생성 신청 실패 - Code: ${response.data['code']}, Message: ${response.data['message']}');
        _showFailureDialog('소속 생성 신청 실패', response.data['message']);
      }
    } catch (e, st) {
      print('API 호출 중 오류 발생: $e');
      print('Stacktrace: $st');
      _showFailureDialog('서버 오류', 'API 호출 중 오류가 발생했습니다.');
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('신청 완료'),
        content: const Text('소속 신청이 성공적으로 완료되었습니다.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyPageScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFFC10230)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(color: Color(0xFFC10230)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormValid = _affiliationNameController.text.isNotEmpty &&
        _phoneNumberController.text.isNotEmpty;

    // PopScope를 사용하여 뒤로가기 제스처를 제어합니다.
    return PopScope(
      // canPop을 false로 설정하여 자동 뒤로가기를 막습니다.
      canPop: false,
      // 뒤로가기 시도가 있을 때 호출됩니다.
      onPopInvoked: (bool didPop) {
        // 이미 pop이 되었다면 아무것도 하지 않습니다.
        if (didPop) return;

        // 사용자에게 확인 다이얼로그를 표시합니다.
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text('페이지를 나가시겠습니까?'),
              content: const Text('작성한 내용은 저장되지 않습니다.'),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: const Text('취소'),
                  onPressed: () {
                    // 다이얼로그만 닫습니다.
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('나가기'),
                  onPressed: () {
                    // 다이얼로그를 닫습니다.
                    Navigator.of(context).pop();
                    // 현재 화면을 닫습니다.
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
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
              // AppBar의 닫기 버튼은 기존처럼 동작하도록 pop을 직접 호출합니다.
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: const Text(
              '소속 생성',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: const Color(0xFFF5F6F7),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFormGroup(
                          label: '소속명',
                          child: _buildInputField(
                            controller: _affiliationNameController,
                            hintText: '소속명 입력',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormGroup(
                          label: '주최자명',
                          child: _buildReadOnlyField(
                            text: _hostNameController.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormGroup(
                          label: '학번',
                          child: _buildReadOnlyField(
                            text: _studentIdController.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormGroup(
                          label: '전화번호',
                          child: _buildInputField(
                            controller: _phoneNumberController,
                            hintText: '전화번호 입력',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormGroup(
                          label: '생성 요청',
                          child: _buildToggleButtons(
                            value: _canCreate,
                            onChanged: (newValue) {
                              setState(() {
                                _canCreate = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormGroup(
                          label: '권한 요청',
                          child: _buildToggleButtons(
                            value: _hasPermission,
                            onChanged: (newValue) {
                              setState(() {
                                _hasPermission = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: isFormValid ? _submitAffiliationRequest : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC10230),
                      disabledBackgroundColor:
                          const Color(0xFFC10230).withOpacity(0.3),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withOpacity(0.7),
                    ),
                    child: const Text(
                      '신청',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormGroup({
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: Colors.black.withOpacity(0.6))),
          const SizedBox(height: 3),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String text,
  }) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildToggleButtons({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => onChanged(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: value ? const Color(0xFFC10230) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color:
                      value ? const Color(0xFFC10230) : const Color(0xFFE2E2E2),
                ),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              '예',
              style: TextStyle(
                color: value ? Colors.white : const Color(0xFF868686),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => onChanged(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: value ? Colors.white : const Color(0xFF334D61),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color:
                      value ? const Color(0xFFE2E2E2) : const Color(0xFF334D61),
                ),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              '아니오',
              style: TextStyle(
                color: value ? const Color(0xFF868686) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
