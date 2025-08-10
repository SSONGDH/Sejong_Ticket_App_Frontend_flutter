import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart'; // Import for CupertinoAlertDialog
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:PASSTIME/screens/ticket_screen.dart';
import '../cookiejar_singleton.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class RequestRefundScreen extends StatefulWidget {
  const RequestRefundScreen({super.key});

  @override
  _RequestRefundScreenState createState() => _RequestRefundScreenState();
}

class _RequestRefundScreenState extends State<RequestRefundScreen> {
  String? selectedDate;
  String? selectedTime;
  String? selectedTicketId;
  String? refundReason;
  String? phoneNumber;
  List<Map<String, dynamic>> tickets = [];

  final TextEditingController refundReasonController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchTickets();
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

  Future<void> _fetchTickets() async {
    try {
      final response =
          await _dio.get('${dotenv.env['API_BASE_URL']}/ticket/main');
      final List<dynamic> data = response.data['result'];
      setState(() {
        tickets = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('티켓 불러오기 실패: $e');
    }
  }

  Future<void> _submitRefundRequest() async {
    if (selectedTicketId == null ||
        refundReasonController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null ||
        phoneNumberController.text.isEmpty) {
      _showCupertinoDialog('알림', '모든 필드를 입력해주세요.');
      return;
    }

    final body = {
      "phone": phoneNumberController.text,
      "refundReason": refundReasonController.text,
      "visitDate": selectedDate!,
      "visitTime": selectedTime!,
      "ticketId": selectedTicketId!,
    };

    try {
      final response = await _dio.post(
        '${dotenv.env['API_BASE_URL']}/refund/request',
        data: json.encode(body),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final result = response.data;
      if (result['isSuccess']) {
        _showCupertinoDialog('성공', '환불 요청이 완료되었습니다.', onConfirm: () {
          Navigator.of(context).pop(); // 팝업 닫기
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TicketScreen()),
          );
        });
      } else {
        _showCupertinoDialog('오류', result['message'] ?? '오류가 발생했습니다.');
      }
    } catch (e) {
      _showCupertinoDialog('오류', '요청 중 오류 발생: $e');
    }
  }

  void _showCupertinoDialog(String title, String content,
      {VoidCallback? onConfirm}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: onConfirm ?? () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: Color(0xFFC10230))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
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
              '환불 신청',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEventDropdown(),
                        const SizedBox(height: 14),
                        _buildInputField(
                          controller: refundReasonController,
                          label: "환불 사유",
                          hintText: "환불 사유 입력",
                        ),
                        const SizedBox(height: 14),
                        _buildDatePickerField(),
                        const SizedBox(height: 14),
                        _buildTimePickerField(),
                        const SizedBox(height: 14),
                        _buildInputField(
                          controller: phoneNumberController,
                          label: "전화번호",
                          hintText: "전화번호 입력",
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "현금 수령을 해야 하므로 방문이 필요합니다.",
                            style: TextStyle(
                                color: const Color(0xFFC10230).withOpacity(0.5),
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isFormValid() ? _submitRefundRequest : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC10230),
                      disabledBackgroundColor:
                          const Color(0xFFC10230).withOpacity(0.3),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withOpacity(0.7),
                    ),
                    child: const Text(
                      "신청",
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

  bool _isFormValid() {
    return selectedTicketId != null &&
        refundReasonController.text.isNotEmpty &&
        selectedDate != null &&
        selectedTime != null &&
        phoneNumberController.text.isNotEmpty;
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.3),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildEventDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "행사",
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Theme(
            data: Theme.of(context).copyWith(canvasColor: Colors.white),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTicketId,
                hint: Text(
                  '행사 선택',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                isExpanded: true,
                items: tickets.map((ticket) {
                  return DropdownMenuItem<String>(
                    value: ticket['_id'],
                    child: Text(ticket['eventTitle']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTicketId = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () {
        DatePicker.showDatePicker(
          context,
          showTitleActions: true,
          minTime: DateTime(1900, 1, 1),
          maxTime: DateTime(2100, 1, 1),
          onConfirm: (date) {
            setState(() {
              selectedDate =
                  "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}(${_getKoreanWeekday(date.weekday)})";
            });
          },
          currentTime: DateTime.now(),
          locale: LocaleType.ko,
        );
      },
      child: _buildDisplayField(
        label: "방문 가능 날짜",
        displayText: selectedDate ?? "방문 가능 날짜 선택",
        icon: Icons.calendar_today_outlined,
      ),
    );
  }

  Widget _buildTimePickerField() {
    return GestureDetector(
      onTap: () {
        DatePicker.showTimePicker(
          context,
          showTitleActions: true,
          showSecondsColumn: false,
          onConfirm: (date) {
            setState(() {
              final amPm = date.hour < 12 ? '오전' : '오후';
              final hour = date.hour > 12 ? date.hour - 12 : date.hour;
              final formattedHour = hour == 0 ? 12 : hour;
              selectedTime = "$amPm $formattedHour시";
            });
          },
          currentTime: DateTime.now(),
          locale: LocaleType.ko,
        );
      },
      child: _buildDisplayField(
        label: "방문 가능 시간",
        displayText: selectedTime ?? "방문 가능 시간 선택",
        icon: Icons.access_time_outlined,
      ),
    );
  }

  Widget _buildDisplayField({
    required String label,
    required String displayText,
    String? suffixText,
    IconData? icon,
  }) {
    // 텍스트 색상을 결정하는 로직
    final isHintText =
        displayText == "방문 가능 날짜 선택" || displayText == "방문 가능 시간 선택";
    final textColor = isHintText
        ? Colors.black.withOpacity(0.3)
        : Colors.black; // 선택된 값이면 검은색, 힌트면 흐린색

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: textColor, // 동적으로 색상 변경
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon ?? Icons.calendar_today_outlined,
                  color: Colors.grey, size: 20),
            ],
          ),
          if (suffixText != null) ...[
            const SizedBox(height: 5),
            Text(
              suffixText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _getKoreanWeekday(int weekday) {
    const weekdays = ["월", "화", "수", "목", "금", "토", "일"];
    return weekdays[weekday - 1];
  }
}
