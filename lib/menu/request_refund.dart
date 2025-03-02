import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/click_button.dart';

class RequestRefundScreen extends StatefulWidget {
  const RequestRefundScreen({super.key});

  @override
  _RequestRefundScreenState createState() => _RequestRefundScreenState();
}

class _RequestRefundScreenState extends State<RequestRefundScreen> {
  String? selectedDate;
  String? selectedTime;

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
            _buildTextField("플레이스 홀더"),
            const SizedBox(height: 12),
            _buildLabel("환불 사유"),
            _buildTextField("플레이스 홀더"),
            const SizedBox(height: 12),
            _buildLabel("방문 가능 날짜"),
            _buildDatePickerField(),
            const SizedBox(height: 12),
            _buildLabel("방문 가능 시간"),
            _buildTimePickerField(),
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
          onPressed: () {
            // 버튼 클릭 시 동작 추가 가능
          },
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

  Widget _buildTextField(String hintText) {
    return SizedBox(
      height: 55, // 버튼과 높이 일치
      child: TextField(
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
                "${pickedDate.toLocal()}".split(' ')[0]; // 선택된 날짜를 텍스트로 변환
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
            selectedTime = pickedTime.format(context); // 선택된 시간
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
}
