import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/click_button.dart';
import 'package:passtime/admin/admin_ticket_screen.dart'; // Import the AdminTicketScreen

class AdminModeScreen extends StatelessWidget {
  const AdminModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
          title: "관리자 모드", backgroundColor: Color(0xFF282727)),
      body: const Center(
        child: Text(
          "관리자 모드를 사용할 수 없습니다",
          style: TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(30),
        child: CustomButton(
          onPressed: () {
            // Navigate to AdminTicketScreen when the button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminTicketScreen()),
            );
          },
          color: const Color(0xFF282727),
          borderRadius: 5,
          height: 55,
          child: const Text(
            "임시 이동 버튼",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
