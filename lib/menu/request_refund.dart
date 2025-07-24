import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:PASSTIME/widgets/app_bar.dart';
import 'package:PASSTIME/widgets/click_button.dart';
import 'package:PASSTIME/screens/ticket_screen.dart';
import '../cookiejar_singleton.dart';

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
        refundReason == null ||
        selectedDate == null ||
        selectedTime == null ||
        phoneNumber == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('모든 필드를 입력해주세요.')));
      return;
    }

    final body = {
      "phone": phoneNumber,
      "refundReason": refundReason,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('환불 요청이 완료되었습니다.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TicketScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '오류가 발생했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청 중 오류 발생: $e')),
      );
    }
  }

  // 아래 부분은 UI이며 기존 코드 그대로 유지합니다

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
          title: "환불 신청", backgroundColor: Color(0xFFB93234)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("행사"),
            _buildTicketDropdown(),
            const SizedBox(height: 12),
            _buildLabel("환불 사유"),
            _buildTextField("플레이스 홀더", onChanged: (val) => refundReason = val),
            const SizedBox(height: 12),
            _buildLabel("방문 가능 날짜"),
            _buildDatePickerField(),
            const SizedBox(height: 12),
            _buildLabel("방문 가능 시간"),
            _buildTimePickerField(),
            const SizedBox(height: 12),
            _buildLabel("전화번호"),
            _buildTextField("010-0000-0000",
                keyboardType: TextInputType.phone,
                onChanged: (val) => phoneNumber = val),
            const SizedBox(height: 8),
            const Text(
              "현금 수령을 해야 하므로 방문이 필요합니다",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(30),
        child: CustomButton(
          onPressed: _submitRefundRequest,
          color: const Color(0xFFB93234),
          borderRadius: 5,
          height: 55,
          child: const Text(
            "신청",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String hintText,
      {TextInputType keyboardType = TextInputType.text,
      void Function(String)? onChanged}) {
    return SizedBox(
      height: 55,
      child: TextField(
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
        textInputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildTicketDropdown() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTicketId,
          hint: const Text('행사 선택'),
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
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() {
            selectedDate =
                "${pickedDate.year}.${pickedDate.month.toString().padLeft(2, '0')}.${pickedDate.day.toString().padLeft(2, '0')}(${_getKoreanWeekday(pickedDate.weekday)})";
          });
        }
      },
      child: _buildDisplayField(selectedDate ?? "날짜 선택"),
    );
  }

  Widget _buildTimePickerField() {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() {
            selectedTime = pickedTime.period == DayPeriod.am
                ? "오전 ${pickedTime.hourOfPeriod}시"
                : "오후 ${pickedTime.hourOfPeriod}시";
          });
        }
      },
      child: _buildDisplayField(selectedTime ?? "시간 선택"),
    );
  }

  Widget _buildDisplayField(String text) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(color: Colors.black)),
          const Icon(Icons.calendar_today, color: Colors.grey),
        ],
      ),
    );
  }

  String _getKoreanWeekday(int weekday) {
    const weekdays = ["월", "화", "수", "목", "금", "토", "일"];
    return weekdays[weekday - 1];
  }
}
