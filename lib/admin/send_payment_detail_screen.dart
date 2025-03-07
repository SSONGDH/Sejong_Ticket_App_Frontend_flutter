import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';

class SendPaymentDetailScreen extends StatelessWidget {
  final String studentId;
  final String name;

  const SendPaymentDetailScreen({
    super.key,
    required this.studentId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
          title: "납부내역 상세화면", backgroundColor: Color(0xFF282727)),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Container(
                  height: 200, // 사진 박스를 더 크게 조정
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text("납부내역 사진", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 30),
                _buildInfoTile("이름", name),
                _buildInfoTile("학번", studentId),
                _buildInfoTile("전화번호", "010-5265-4339"),
                _buildInfoTile("행사", "컴공OT 뒤풀이"),
              ],
            ),
          ),
          Positioned(
            bottom: 30, // 화면 하단에 배치
            left: 30,
            right: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {},
              child: const Text("승인",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      width: double.infinity,
      height: 60, // 높이를 고정값으로 설정
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 10), // 간격 증가
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10), // 둥근 모서리 추가
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.black)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
