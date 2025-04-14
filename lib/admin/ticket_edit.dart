import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:passtime/widgets/app_bar.dart';

class TicketEditScreen extends StatefulWidget {
  final String ticketId;

  const TicketEditScreen({super.key, required this.ticketId});

  @override
  State<TicketEditScreen> createState() => _TicketEditScreenState();
}

class _TicketEditScreenState extends State<TicketEditScreen> {
  final _titleController = TextEditingController();
  final _dayController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _placeController = TextEditingController();
  final _placeCommentController = TextEditingController();
  final _commentController = TextEditingController();
  final _codeController = TextEditingController();

  File? _pickedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTicketDetail();
  }

  Future<void> _fetchTicketDetail() async {
    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/ticket/modifyTicketDetail?ticketId=${widget.ticketId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];

      setState(() {
        _titleController.text = result['eventTitle'] ?? '';
        _dayController.text = result['eventDay'] ?? '';
        _startTimeController.text = result['eventStartTime'] ?? '';
        _endTimeController.text = result['eventEndTime'] ?? '';
        _placeController.text = result['eventPlace'] ?? '';
        _placeCommentController.text = result['eventPlaceComment'] ?? '';
        _commentController.text = result['eventComment'] ?? '';
        _codeController.text = result['eventCode'] ?? '';
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("불러오기 실패: ${response.statusCode}")),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    final uri = Uri.parse('${dotenv.env['API_BASE_URL']}/ticket/modifyTicket');
    final request = http.MultipartRequest('PUT', uri);

    request.fields['eventTitle'] = _titleController.text;
    request.fields['eventDay'] = _dayController.text;
    request.fields['eventStartTime'] = _startTimeController.text;
    request.fields['eventEndTime'] = _endTimeController.text;
    request.fields['eventPlace'] = _placeController.text;
    request.fields['eventPlaceComment'] = _placeCommentController.text;
    request.fields['eventComment'] = _commentController.text;
    request.fields['eventCode'] = _codeController.text;
    request.fields['_id'] = widget.ticketId; // ✅ 반드시 포함해야 수정 대상 지정 가능

    if (_pickedImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'eventPlacePicture',
        _pickedImage!.path,
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("수정 완료!")),
        );
      } else {
        debugPrint("응답 본문: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("오류 발생: ${response.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("예외 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("네트워크 오류")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: "행사 수정",
        backgroundColor: Color(0xFF282727),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildTextField(label: "제목", controller: _titleController),
                  _buildTextField(label: "날짜", controller: _dayController),
                  _buildTextField(
                      label: "시작 시간", controller: _startTimeController),
                  _buildTextField(
                      label: "종료 시간", controller: _endTimeController),
                  _buildTextField(label: "장소", controller: _placeController),
                  _buildTextField(
                      label: "장소 설명",
                      hintText: "플레이스 홀더",
                      controller: _placeCommentController),
                  _buildImagePicker(),
                  _buildTextField(
                      label: "관리자 멘트",
                      hintText: "플레이스 홀더",
                      controller: _commentController),
                  _buildTextField(label: "이벤트 코드", controller: _codeController),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
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
    String? hintText,
    required TextEditingController controller,
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
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("장소 사진",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: _pickedImage != null
                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                  : const Center(child: Text("플레이스 홀더")),
            ),
          ),
        ],
      ),
    );
  }
}
