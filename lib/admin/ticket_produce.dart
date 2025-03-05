import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/click_button.dart';
import 'package:passtime/admin/admin_ticket_screen.dart';

class TicketProduceScreen extends StatefulWidget {
  const TicketProduceScreen({super.key});

  @override
  _TicketProduceScreenState createState() => _TicketProduceScreenState();
}

class _TicketProduceScreenState extends State<TicketProduceScreen> {
  String? selectedDate;
  String? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "행사 제작",
        backgroundColor: Color(0xFF282727),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("제목"),
            _buildTextField("플레이스 홀더"),
            const SizedBox(height: 12),
            _buildLabel("날짜"),
            _buildDatePickerField(),
            const SizedBox(height: 12),
            _buildLabel("시간"),
            _buildTimePickerField(),
            const SizedBox(height: 12),
            _buildLabel("장소"),
            _buildTextField("플레이스 홀더"),
            const SizedBox(height: 12),
            _buildLabel("장소 설명"),
            _buildTextField("플레이스 홀더"),
            const SizedBox(height: 12),
            _buildLabel("장소 사진"),
            _buildTextField("플레이스 홀더"),
            const SizedBox(height: 12),
            _buildLabel("관리자 멘트"),
            _buildTextField("플레이스 홀더"),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(30),
        child: CustomButton(
          onPressed: () => _showConfirmationDialog(),
          color: const Color(0xFF282727),
          borderRadius: 5,
          height: 55,
          child: const Text(
            "확인",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("행사를 제작하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text("확인"),
            onPressed: () {
              Navigator.pop(context);
              _navigateToAdminScreen();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToAdminScreen() {
    // 화면 전환 시 이전 화면으로 돌아가는 버튼을 유지하려면 push로 화면 전환
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminTicketScreen()),
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
      height: 55,
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
            selectedDate = "${pickedDate.toLocal()}".split(' ')[0];
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
            selectedTime = pickedTime.format(context);
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
