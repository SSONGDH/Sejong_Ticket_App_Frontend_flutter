import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:PASSTIME/admin/admin_ticket_screen.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import '../place_search_screen.dart';

class TicketEditScreen extends StatefulWidget {
  final String ticketId;

  const TicketEditScreen({super.key, required this.ticketId});

  @override
  State<TicketEditScreen> createState() => _TicketEditScreenState();
}

class _TicketEditScreenState extends State<TicketEditScreen> {
  String? selectedAffiliation;
  String? selectedDate;
  String? selectedStartTime;
  String? selectedEndTime;
  List<String> affiliations = [];

  final _titleController = TextEditingController();
  final _placeCommentController = TextEditingController();
  final _commentController = TextEditingController();
  final _codeController = TextEditingController();

  Map<String, dynamic>? _selectedPlace;
  File? _pickedImage;
  bool _isLoading = true;
  Map<String, dynamic>? _initialTicketData;

  @override
  void initState() {
    super.initState();
    _fetchTicketDetail();
    _fetchAffiliations();

    // 리스너 추가
    _titleController.addListener(_updateButtonState);
    _placeCommentController.addListener(_updateButtonState);
    _commentController.addListener(_updateButtonState);
    _codeController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateButtonState);
    _placeCommentController.removeListener(_updateButtonState);
    _commentController.removeListener(_updateButtonState);
    _codeController.removeListener(_updateButtonState);
    _titleController.dispose();
    _placeCommentController.dispose();
    _commentController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchAffiliations() async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/affiliation/List');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(utf8.decode(response.bodyBytes));
        if (decodedResponse['isSuccess'] == true) {
          final List<dynamic> affiliationList = decodedResponse['result'];
          setState(() {
            affiliations = affiliationList
                .map<String>((item) => item['name'] as String)
                .toList();
          });
        }
      } else {
        debugPrint('Failed to load affiliations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Network error: $e');
    }
  }

  Future<void> _fetchTicketDetail() async {
    final url = Uri.parse(
        '${dotenv.env['API_BASE_URL']}/ticket/modifyTicketDetail?ticketId=${widget.ticketId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final result = data['result'];

      setState(() {
        _initialTicketData = Map.from(result); // 초기 데이터 저장
        _titleController.text = result['eventTitle'] ?? '';
        selectedDate = result['eventDay'] ?? '';
        selectedStartTime = result['eventStartTime'] ?? '';
        selectedEndTime = result['eventEndTime'] ?? '';
        _selectedPlace = result['kakaoPlace'] != null
            ? {
                'place_name': result['kakaoPlace']['place_name'] ?? '',
                'address_name': result['kakaoPlace']['address_name'] ?? '',
                'x': result['kakaoPlace']['x'] ?? '',
                'y': result['kakaoPlace']['y'] ?? '',
              }
            : null;
        _placeCommentController.text = result['eventPlaceComment'] ?? '';
        _commentController.text = result['eventComment'] ?? '';
        selectedAffiliation = result['affiliation'] ?? '';
        _codeController.text = result['eventCode'] ?? '';
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to load details: ${response.statusCode}")),
      );
    }
  }

  Future<void> _submit() async {
    final uri = Uri.parse('${dotenv.env['API_BASE_URL']}/ticket/modifyTicket');
    final request = http.MultipartRequest('PUT', uri);

    request.fields['eventTitle'] = _titleController.text;
    request.fields['eventDay'] = selectedDate ?? '';
    request.fields['eventStartTime'] = selectedStartTime ?? '';
    request.fields['eventEndTime'] = selectedEndTime ?? '';
    request.fields['eventPlace'] = _selectedPlace?['place_name'] ?? '';
    request.fields['eventPlaceComment'] = _placeCommentController.text;
    request.fields['eventComment'] = _commentController.text;
    request.fields['affiliation'] = selectedAffiliation ?? '';
    request.fields['eventCode'] = _codeController.text;
    request.fields['_id'] = widget.ticketId;
    request.fields['kakaoPlace'] = json.encode(_selectedPlace);

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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("수정 완료!")),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminTicketScreen()),
          );
        });
      } else {
        debugPrint("Response body: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Exception: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("네트워크 오류")),
      );
    }
  }

  void _showConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("행사를 수정하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text("확인", style: TextStyle(color: Color(0xFFC10230))),
            onPressed: () {
              Navigator.pop(context);
              _submit();
            },
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    if (_initialTicketData == null) {
      return false;
    }

    final currentData = {
      'eventTitle': _titleController.text,
      'eventDay': selectedDate,
      'eventStartTime': selectedStartTime,
      'eventEndTime': selectedEndTime,
      'eventPlace': _selectedPlace?['place_name'],
      'eventPlaceComment': _placeCommentController.text,
      'eventComment': _commentController.text,
      'affiliation': selectedAffiliation,
      'eventCode': _codeController.text,
      'kakaoPlace': _selectedPlace,
    };

    // 이미지 변경 여부 확인
    if (_pickedImage != null) {
      return true;
    }

    // 다른 필드 변경 여부 확인
    if (currentData['eventTitle'] != _initialTicketData!['eventTitle'])
      return true;
    if (currentData['eventDay'] != _initialTicketData!['eventDay']) return true;
    if (currentData['eventStartTime'] != _initialTicketData!['eventStartTime'])
      return true;
    if (currentData['eventEndTime'] != _initialTicketData!['eventEndTime'])
      return true;
    if (currentData['eventPlace'] != _initialTicketData!['eventPlace'])
      return true;
    if (currentData['eventPlaceComment'] !=
        _initialTicketData!['eventPlaceComment']) return true;
    if (currentData['eventComment'] != _initialTicketData!['eventComment'])
      return true;
    if (currentData['affiliation'] != _initialTicketData!['affiliation'])
      return true;
    if (currentData['eventCode'] != _initialTicketData!['eventCode'])
      return true;
    if (currentData['kakaoPlace'] != null &&
        _initialTicketData!['kakaoPlace'] != null) {
      if (currentData['kakaoPlace']!['x'] !=
              _initialTicketData!['kakaoPlace']['x'] ||
          currentData['kakaoPlace']!['y'] !=
              _initialTicketData!['kakaoPlace']['y']) {
        return true;
      }
    } else if (currentData['kakaoPlace'] != null ||
        _initialTicketData!['kakaoPlace'] != null) {
      return true;
    }

    return false;
  }

  void _updateButtonState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _isFormValid();

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            toolbarHeight: 70,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.black,
                size: 30,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            title: const Text(
              '수정',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEDE3),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAffiliationDropdown(),
                            const SizedBox(height: 14),
                            _buildInputField(
                                controller: _titleController,
                                label: "제목",
                                hintText: "제목 입력"),
                            const SizedBox(height: 14),
                            _buildDatePickerField(),
                            const SizedBox(height: 14),
                            _buildStartTimePickerField(),
                            const SizedBox(height: 14),
                            _buildEndTimePickerField(),
                            const SizedBox(height: 14),
                            _buildPlaceSearchField(),
                            const SizedBox(height: 14),
                            _buildInputField(
                                controller: _placeCommentController,
                                label: "장소 설명",
                                hintText: "장소 설명 입력"),
                            const SizedBox(height: 14),
                            _buildInputField(
                                controller: _commentController,
                                label: "관리자 멘트",
                                hintText: "관리자 멘트 입력"),
                            const SizedBox(height: 14),
                            _buildInputField(
                                controller: _codeController,
                                label: "행사 코드",
                                hintText: "행사 코드 입력"),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                      child: SafeArea(
                        child: ElevatedButton(
                          onPressed: canSubmit ? _showConfirmationDialog : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSubmit
                                ? const Color(0xFF334D61)
                                : const Color(0xFF334D61).withOpacity(0.3),
                            disabledBackgroundColor:
                                const Color(0xFF334D61).withOpacity(0.3),
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                            disabledForegroundColor:
                                Colors.white.withOpacity(0.7),
                          ),
                          child: const Text(
                            "완료",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAffiliationDropdown() {
    final bool isAffiliationInList = affiliations.contains(selectedAffiliation);
    final bool hasValue = isAffiliationInList && selectedAffiliation != null;

    final String? dropdownValue =
        isAffiliationInList ? selectedAffiliation : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "소속",
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Theme(
            data: Theme.of(context).copyWith(canvasColor: Colors.white),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: dropdownValue,
                hint: Text(
                  '소속 선택',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                isExpanded: true,
                items: affiliations.map((affiliation) {
                  return DropdownMenuItem<String>(
                    value: affiliation,
                    child: Text(
                      affiliation,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAffiliation = value;
                    _updateButtonState();
                  });
                },
                style: TextStyle(
                  color:
                      hasValue ? Colors.black : Colors.black.withOpacity(0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (value) => _updateButtonState(),
            style: TextStyle(
              color: controller.text.isNotEmpty
                  ? Colors.black
                  : Colors.black.withOpacity(0.3),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.3),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField() {
    final bool hasValue = selectedDate != null && selectedDate!.isNotEmpty;
    return GestureDetector(
      onTap: () {
        DatePicker.showDatePicker(
          context,
          showTitleActions: true,
          minTime: DateTime(1900, 1, 1),
          maxTime: DateTime(2100, 1, 1),
          onConfirm: (date) {
            setState(() {
              selectedDate =
                  "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}(${_getKoreanWeekday(date.weekday)})";
              _updateButtonState();
            });
          },
          currentTime: DateTime.now(),
          locale: LocaleType.ko,
        );
      },
      child: _buildDisplayField(
        label: "날짜",
        displayText: selectedDate ?? "날짜 선택",
        icon: Icons.calendar_today_outlined,
        hasValue: hasValue,
      ),
    );
  }

  Widget _buildStartTimePickerField() {
    final bool hasValue =
        selectedStartTime != null && selectedStartTime!.isNotEmpty;
    return GestureDetector(
      onTap: () {
        DatePicker.showTimePicker(
          context,
          showTitleActions: true,
          showSecondsColumn: false,
          onConfirm: (date) {
            setState(() {
              final amPm = date.hour < 12 ? '오전' : '오후';
              final hour = date.hour > 12 ? date.hour - 12 : date.hour;
              final formattedHour = hour == 0 ? 12 : hour;
              selectedStartTime =
                  "$amPm $formattedHour시 ${date.minute.toString().padLeft(2, '0')}분";
              _updateButtonState();
            });
          },
          currentTime: DateTime.now(),
          locale: LocaleType.ko,
        );
      },
      child: _buildDisplayField(
        label: "시작 시간",
        displayText: selectedStartTime ?? "시작 시간 선택",
        icon: Icons.access_time_outlined,
        hasValue: hasValue,
      ),
    );
  }

  Widget _buildEndTimePickerField() {
    final bool hasValue =
        selectedEndTime != null && selectedEndTime!.isNotEmpty;
    return GestureDetector(
      onTap: () {
        DatePicker.showTimePicker(
          context,
          showTitleActions: true,
          showSecondsColumn: false,
          onConfirm: (date) {
            setState(() {
              final amPm = date.hour < 12 ? '오전' : '오후';
              final hour = date.hour > 12 ? date.hour - 12 : date.hour;
              final formattedHour = hour == 0 ? 12 : hour;
              selectedEndTime =
                  "$amPm $formattedHour시 ${date.minute.toString().padLeft(2, '0')}분";
              _updateButtonState();
            });
          },
          currentTime: DateTime.now(),
          locale: LocaleType.ko,
        );
      },
      child: _buildDisplayField(
        label: "종료 시간",
        displayText: selectedEndTime ?? "종료 시간 선택",
        icon: Icons.access_time_outlined,
        hasValue: hasValue,
      ),
    );
  }

  Widget _buildPlaceSearchField() {
    final bool hasValue = _selectedPlace?['place_name'] != null &&
        _selectedPlace!['place_name'].isNotEmpty;
    return GestureDetector(
      onTap: () async {
        final selected = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlaceSearchScreen()),
        );

        if (selected != null) {
          setState(() {
            _selectedPlace = selected;
            _updateButtonState();
          });
        }
      },
      child: _buildDisplayField(
        label: "장소",
        displayText: _selectedPlace?['place_name'] ?? "장소 선택",
        icon: Icons.search_outlined,
        hasValue: hasValue,
      ),
    );
  }

  Widget _buildDisplayField({
    required String label,
    required String displayText,
    IconData? icon,
    required bool hasValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF334D61).withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    color:
                        hasValue ? Colors.black : Colors.black.withOpacity(0.3),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon ?? Icons.calendar_today_outlined,
                  color: Colors.grey, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  String _getKoreanWeekday(int weekday) {
    const weekdays = ["월", "화", "수", "목", "금", "토", "일"];
    return weekdays[weekday - 1];
  }
}
