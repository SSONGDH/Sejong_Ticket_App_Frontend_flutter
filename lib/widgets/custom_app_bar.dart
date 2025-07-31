import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // ⭐ title 속성 추가 ⭐
  final String title;

  const CustomAppBar({
    super.key,
    required this.title, // ⭐ 생성자를 통해 title을 받도록 변경 ⭐
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 120,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 10.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/sejong_logo.png',
                    height: 40,
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ],
              ),
            ),
            Padding(
              // ⭐ const 제거하고 title 적용 ⭐
              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text(
                title, // ⭐ 동적으로 전달받은 title 사용 ⭐
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
