import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;

  const CustomAppBar(
      {super.key, required this.title, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor, // 색상을 여기에 적용
      centerTitle: true,
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 22,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50); // 앱바의 높이 지정
}
