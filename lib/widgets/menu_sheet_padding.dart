import 'package:flutter/material.dart';

/// 메뉴 바텀시트 하단 여백 (스와이프 / 3버튼 내비게이션 대응)
double menuSheetBottomPadding(BuildContext context) {
  final bottomInset = MediaQuery.of(context).viewPadding.bottom;

  if (bottomInset > 0) {
    // 제스처 내비게이션: 홈 인디케이터
    return bottomInset;
  }

  // 3버튼 내비게이션: 하단 내비게이션 바 위로
  return 36;
}
