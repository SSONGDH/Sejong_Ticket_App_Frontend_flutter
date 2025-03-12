import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class TicketEditScreen extends StatelessWidget {
  const TicketEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
          title: "행사 수정", backgroundColor: Color(0xFF282727)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField(
                label: "제목", initialValue: "컴공OT 뒤풀이", enabled: false),
            _buildTextField(
                label: "날짜", initialValue: "2025.02.28(금)", enabled: false),
            _buildTextField(label: "시간", initialValue: "18:00", enabled: false),
            _buildTextField(label: "장소", initialValue: "지그재그", enabled: false),
            _buildTextField(label: "장소 설명", hintText: "플레이스 홀더"),
            _buildTextField(label: "장소 사진", hintText: "플레이스 홀더"),
            _buildTextField(label: "관리자 멘트", hintText: "플레이스 홀더"),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("확인",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    String? hintText,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[200],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
