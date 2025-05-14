import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passtime/widgets/app_bar.dart';
import 'package:passtime/widgets/click_button.dart';
import 'package:passtime/screens/ticket_screen.dart';
import '../cookiejar_singleton.dart';

class SendPaymentScreen extends StatefulWidget {
  const SendPaymentScreen({super.key});

  @override
  _SendPaymentScreenState createState() => _SendPaymentScreenState();
}

class _SendPaymentScreenState extends State<SendPaymentScreen> {
  String selectedEvent = '';
  List<Map<String, dynamic>> tickets = [];
  String? selectedTicketId;
  final TextEditingController phoneController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode eventFocusNode = FocusNode();
  File? _image;
  final picker = ImagePicker();

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchTickets();
  }

  void _setupDio() {
    final uri = Uri.parse(dotenv.env['API_BASE_URL']!);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cookies =
            await CookieJarSingleton().cookieJar.loadForRequest(uri);
        if (cookies.isNotEmpty) {
          options.headers[HttpHeaders.cookieHeader] = cookies
              .map((cookie) => '${cookie.name}=${cookie.value}')
              .join('; ');
        }
        handler.next(options);
      },
    ));
  }

  Future<void> _fetchTickets() async {
    try {
      final response =
          await _dio.get('${dotenv.env['API_BASE_URL']}/ticket/List');
      final List<dynamic> data = response.data['result'];
      setState(() {
        tickets = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('티켓 불러오기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(
          title: "납부 내역 보내기",
          backgroundColor: Color(0xFFB93234),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("행사"),
                    _buildTicketDropdown(),
                    _buildLabel("전화번호"),
                    _buildPhoneField(),
                    _buildLabel("납부 내역 사진"),
                    _buildImagePickerField(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(30),
              child: CustomButton(
                onPressed: () {
                  if (_isFormValid()) {
                    _showConfirmationDialog();
                  } else {
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

  bool _isFormValid() {
    return phoneController.text.isNotEmpty &&
        selectedEvent.isNotEmpty &&
        _image != null;
  }

  void _showFormIncompleteDialog() {
    String missingFields = '';
    if (phoneController.text.isEmpty) missingFields += '전화번호, ';
    if (selectedEvent.isEmpty) missingFields += '행사, ';
    if (_image == null) missingFields += '납부 내역 사진, ';
    if (missingFields.isNotEmpty) {
      missingFields = missingFields.substring(0, missingFields.length - 2);
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('양식이 전부 입력되지 않았습니다'),
          content: Text('다음 필드를 입력해주세요: $missingFields'),
          actions: [
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    }
  }

  void _showConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('제출하시겠습니까?'),
        content: const Text('입력한 정보가 맞는지 확인하고 제출을 진행하세요.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).pop();
              _submitPayment();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    try {
      final formData = FormData.fromMap({
        'ticketId': selectedTicketId,
        'phone': phoneController.text,
        'paymentPicture': await MultipartFile.fromFile(
          _image!.path,
          filename: _image!.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        "${dotenv.env['API_BASE_URL']}/payment/paymentpost",
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      debugPrint('응답 코드: ${response.statusCode}');
      debugPrint('서버 응답: ${response.data}');

      if (response.data['isSuccess'] == true) {
        _showSubmissionSuccessDialog();
      } else {
        _showErrorDialog(response.data['message'] ?? '제출에 실패했습니다.');
      }
    } catch (e) {
      debugPrint('서버 오류 발생: $e');
      _showErrorDialog('서버 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  void _showSubmissionSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('제출하였습니다'),
        content: const Text('납부 내역이 제출되었습니다.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TicketScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
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
    VoidCallback? onEditingComplete,
  }) {
    return TextField(
      controller: controller ??
          (initialValue != null
              ? TextEditingController(text: initialValue)
              : null),
      keyboardType: keyboardType,
      enabled: enabled,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      textInputAction: TextInputAction.done,
      onEditingComplete: onEditingComplete,
      style: const TextStyle(color: Colors.black),
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
    );
  }

  Widget _buildPhoneField() {
    return _buildTextField(
      controller: phoneController,
      focusNode: phoneFocusNode,
      keyboardType: TextInputType.number,
      hintText: "전화번호 입력",
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildTicketDropdown() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTicketId,
          hint: const Text('행사 선택'),
          isExpanded: true,
          items: tickets.map((ticket) {
            return DropdownMenuItem<String>(
              value: ticket['_id'],
              child: Text(ticket['eventTitle']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedTicketId = value;
              selectedEvent = tickets
                  .firstWhere((ticket) => ticket['_id'] == value)['eventTitle'];
            });
          },
        ),
      ),
    );
  }

  Widget _buildImagePickerField() {
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
}
