import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/click_button.dart';
import 'package:passtime/admin/admin_ticket_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TicketProduceScreen extends StatefulWidget {
  const TicketProduceScreen({super.key});

  @override
  _TicketProduceScreenState createState() => _TicketProduceScreenState();
}

class _TicketProduceScreenState extends State<TicketProduceScreen> {
  String? selectedDate;
  String? selectedStartTime;
  String? selectedEndTime;
  File? _image;

  final picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _placeCommentController = TextEditingController();
  final TextEditingController _eventCommentController = TextEditingController();
  final TextEditingController _eventCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEnvVariables(); // 환경 변수 로드
  }

  // 환경 변수를 로드하는 함수
  Future<void> _loadEnvVariables() async {
    await dotenv.load();
    print('API URL: ${dotenv.env['API_BASE_URL']}'); // 로드된 API_URL을 출력
  }

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
            _buildTextField(_titleController, "제목을 입력하세요"),
            const SizedBox(height: 12),
            _buildLabel("날짜"),
            _buildDatePickerField(),
            const SizedBox(height: 12),
            _buildLabel("시작 시간"),
            _buildStartTimePickerField(),
            const SizedBox(height: 12),
            _buildLabel("종료 시간"),
            _buildEndTimePickerField(),
            const SizedBox(height: 12),
            _buildLabel("장소"),
            _buildTextField(_placeController, "장소를 입력하세요"),
            const SizedBox(height: 12),
            _buildLabel("장소 설명"),
            _buildTextField(_placeCommentController, "장소 설명을 입력하세요"),
            const SizedBox(height: 12),
            _buildLabel("관리자 멘트"),
            _buildTextField(_eventCommentController, "관리자 멘트를 입력하세요"),
            const SizedBox(height: 12),
            _buildLabel("행사 코드"),
            _buildTextField(_eventCodeController, "행사 코드를 입력하세요"),
            const SizedBox(height: 12),
            _buildLabel("장소 사진"),
            _buildImagePicker(),
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

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: _image == null
          ? Container(
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(child: Text("사진을 선택하세요")),
            )
          : Image.file(_image!),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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
              Navigator.pop(context); // ✅ 먼저 Alert 닫고
              _createTicket(); // ✅ 티켓 생성 API 호출
              Navigator.pop(context, 'created'); // ✅ 이전 화면으로 'created' 반환하며 pop
              _navigateToAdminScreen();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createTicket() async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/ticket/createTicket');
    print(dotenv.env['API_BASE_URL']); // 로드된 API_URL 출력

    // 이미지가 선택되지 않았다면 선택하도록 유도
    if (_image == null) {
      await _pickImage();
    }

    // 폼 데이터 생성
    final request = http.MultipartRequest('POST', url)
      ..fields['eventTitle'] = _titleController.text
      ..fields['eventDay'] = selectedDate!
      ..fields['eventStartTime'] = selectedStartTime!
      ..fields['eventEndTime'] = selectedEndTime!
      ..fields['eventPlace'] = _placeController.text
      ..fields['eventPlaceComment'] = _placeCommentController.text
      ..fields['eventComment'] = _eventCommentController.text
      ..fields['eventCode'] = _eventCodeController.text
      ..files.add(
          await http.MultipartFile.fromPath('eventPlacePicture', _image!.path));

    // 디버그 로그: 전송되는 데이터 출력
    // print('Sending request with data:');
    // print('Title: ${_titleController.text}');
    // print('Event Day: $selectedDate');
    // print('Event Start Time: $selectedStartTime');
    // print('Event End Time: $selectedEndTime');
    // print('Event Place: ${_placeController.text}');
    // print('Event Place Comment: ${_placeCommentController.text}');
    // print('Event Comment: ${_eventCommentController.text}');
    // print('Event Code: ${_eventCodeController.text}');
    // print('Image Path: ${_image?.path}');

    try {
      final response = await request.send();

      // 응답 상태와 바디를 확인합니다.
      final responseBody = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      // 서버에서 JSON을 반환하는 경우
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(responseBody);
        print('Success response: $decodedResponse');
        if (decodedResponse['message'] != null) {
          print('Server message: ${decodedResponse['message']}');
        }

        if (!mounted) return; // context 안전하게 체크!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminTicketScreen()),
        );
      } else {
        print(
            'Error: Server responded with status code ${response.statusCode}');
        print('Error response: $responseBody');
      }
    } catch (e) {
      print('Error during ticket creation: $e'); // 실제 예외 메시지를 출력
    }
  }

  void _navigateToAdminScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminTicketScreen()),
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

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return SizedBox(
      height: 55,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Colors.grey),
          ),
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
            selectedDate = "${pickedDate.toLocal()}".split(' ')[0];
          });
        }
      },
      child: _buildDisplayField(selectedDate ?? "날짜 선택"),
    );
  }

  Widget _buildStartTimePickerField() {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() {
            selectedStartTime = pickedTime.format(context);
          });
        }
      },
      child: _buildDisplayField(selectedStartTime ?? "시작 시간 선택"),
    );
  }

  Widget _buildEndTimePickerField() {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() {
            selectedEndTime = pickedTime.format(context);
          });
        }
      },
      child: _buildDisplayField(selectedEndTime ?? "종료 시간 선택"),
    );
  }

  // 새로 추가된 메서드
  Widget _buildDisplayField(String text) {
    return Container(
      height: 55,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
