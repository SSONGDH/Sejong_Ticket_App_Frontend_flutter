import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/click_button.dart';
import 'package:passtime/screens/ticket_screen.dart';

class SendPaymentScreen extends StatefulWidget {
  const SendPaymentScreen({super.key});

  @override
  _SendPaymentScreenState createState() => _SendPaymentScreenState();
}

class _SendPaymentScreenState extends State<SendPaymentScreen> {
  String selectedEvent = ''; // 행사 목록 중 기본값을 비어있음

  final TextEditingController phoneController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode eventFocusNode = FocusNode();
  final List<String> events = ['행사1', '행사2', '행사3', '기타'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 화면을 터치하면 키보드 닫기
      child: Scaffold(
        resizeToAvoidBottomInset: false, // 키보드가 올라와도 버튼이 고정되도록 설정
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(
          title: "납부 내역 보내기",
          backgroundColor: Color(0xFFB93234),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // 스크롤 가능하도록 추가
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("학과"),
                    _buildTextField(initialValue: "컴퓨터공학과", enabled: false),
                    _buildLabel("학번"),
                    _buildTextField(initialValue: "24011184", enabled: false),
                    _buildLabel("이름"),
                    _buildTextField(initialValue: "윤재민", enabled: false),
                    _buildLabel("전화번호"),
                    _buildPhoneField(),
                    _buildLabel("행사"),
                    _buildEventField(),
                    _buildLabel("납부 내역 사진"),
                    _buildTextField(hintText: "사진 첨부"),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(30),
              child: CustomButton(
                onPressed: () {
                  if (_isFormValid()) {
                    // 양식이 모두 채워졌으면 제출 확인 팝업을 띄움
                    _showConfirmationDialog();
                  } else {
                    // 양식이 다 채워지지 않았으면 경고 팝업을 띄움
                    _showFormIncompleteDialog();
                  }
                },
                color: const Color(0xFFB93234),
                borderRadius: 5,
                height: 55,
                child: const Text(
                  "확인",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 양식이 전부 채워졌는지 확인하는 함수
  bool _isFormValid() {
    return phoneController.text.isNotEmpty && selectedEvent.isNotEmpty;
  }

  // 양식이 전부 입력되지 않았을 때 나타나는 팝업
  void _showFormIncompleteDialog() {
    String missingFields = '';

    // 누락된 필드 체크
    if (phoneController.text.isEmpty) {
      missingFields += '전화번호, ';
    }
    if (selectedEvent.isEmpty) {
      missingFields += '행사, ';
    }

    // 누락된 필드가 있으면 메시지 수정
    if (missingFields.isNotEmpty) {
      missingFields =
          missingFields.substring(0, missingFields.length - 2); // 마지막 쉼표 제거
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('양식이 전부 입력되지 않았습니다'),
            content: Text('다음 필드를 입력해주세요: $missingFields'),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업을 닫는다
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    }
  }

  // 확인 버튼을 눌렀을 때 나타날 iOS 스타일 팝업
  void _showConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('제출하시겠습니까?'),
          content: const Text('입력한 정보가 맞는지 확인하고 제출을 진행하세요.'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // 취소 버튼을 누르면 팝업을 닫는다
                FocusScope.of(context).unfocus(); // 취소 후 포커스를 해제
              },
              child: const Text('취소'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // 확인 버튼을 누르면 팝업을 닫고 "제출하였습니다" 메시지를 띄움
                _showSubmissionSuccessDialog(); // 성공 메시지 띄우기
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 제출 완료 후 "제출하였습니다" 메시지와 함께 화면 이동
  void _showSubmissionSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('제출하였습니다'),
          content: const Text('납부 내역이 제출되었습니다.'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // 팝업을 닫고 티켓 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TicketScreen()),
                );
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    String? hintText,
    TextInputType? keyboardType,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    VoidCallback? onEditingComplete, // 키보드 닫기 위한 콜백 추가
  }) {
    return TextField(
      controller: controller ??
          (initialValue != null
              ? TextEditingController(text: initialValue)
              : null),
      keyboardType: keyboardType,
      enabled: enabled,
      inputFormatters: inputFormatters, // 포맷터 추가
      focusNode: focusNode, // FocusNode 추가
      textInputAction: TextInputAction.done, // 완료 버튼 추가
      onEditingComplete: onEditingComplete, // 키보드 닫기 기능
      style: TextStyle(
        color: enabled ? Colors.black : Colors.black, // 입력값이 있는 경우 검정색 텍스트
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.grey), // 일관된 테두리 색상
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide:
              const BorderSide(color: Colors.grey), // 활성화 상태에서도 동일한 테두리 색상
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide:
              const BorderSide(color: Colors.grey), // 포커스 시에도 동일한 테두리 색상
        ),
      ),
    );
  }

  // 전화번호 입력 필드 수정
  Widget _buildPhoneField() {
    return _buildTextField(
      controller: phoneController,
      focusNode: phoneFocusNode, // FocusNode 연결
      keyboardType: TextInputType.number, // 숫자만 입력 받기
      hintText: "전화번호 입력",
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 가능
      ],
    );
  }

  // 행사 필드 - CupertinoPicker로 iOS 스타일 구현
  Widget _buildEventField() {
    return GestureDetector(
      onTap: () {
        // 포커스를 해제하는 코드
        FocusScope.of(context).unfocus();

        // CupertinoModalPopup을 띄우는 코드
        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) {
            return CupertinoActionSheet(
              title: const Text('행사 선택'),
              actions: events.map((event) {
                return CupertinoActionSheetAction(
                  child: Text(event),
                  onPressed: () {
                    setState(() {
                      selectedEvent = event;
                    });
                    Navigator.pop(context);
                    FocusScope.of(context).unfocus(); // 행사 선택 후 포커스 해제
                  },
                );
              }).toList(),
              cancelButton: CupertinoActionSheetAction(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.pop(context);
                  FocusScope.of(context).unfocus(); // 취소 후 포커스 해제
                },
              ),
            );
          },
        );
      },
      child: AbsorbPointer(
        child: _buildTextField(
          initialValue: selectedEvent.isEmpty
              ? null
              : selectedEvent, // 선택된 행사 값이 없으면 hintText 표시
          hintText: selectedEvent.isEmpty ? "행사 선택" : null, // 행사 선택을 힌트로 보여주기
          enabled: false, // 텍스트 필드는 클릭만 가능하게
        ),
      ),
    );
  }
}
