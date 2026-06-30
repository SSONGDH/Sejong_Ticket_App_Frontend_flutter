import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentAiCriteria {
  final String announcementDate;
  final List<int> participationFees;
  final String accountHolderName;

  const PaymentAiCriteria({
    required this.announcementDate,
    required this.participationFees,
    required this.accountHolderName,
  });

  Map<String, dynamic> toJson() => {
        'announcementDate': announcementDate,
        'participationFee': participationFees.first,
        'participationFees': participationFees,
        'accountHolderName': accountHolderName,
      };
}

Future<PaymentAiCriteria?> showPaymentAiCriteriaDialog(
  BuildContext context, {
  PaymentAiCriteria? initial,
}) {
  return showModalBottomSheet<PaymentAiCriteria>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetContext) => _PaymentAiCriteriaSheet(initial: initial),
  );
}

class _PaymentAiCriteriaSheet extends StatefulWidget {
  final PaymentAiCriteria? initial;

  const _PaymentAiCriteriaSheet({this.initial});

  @override
  State<_PaymentAiCriteriaSheet> createState() =>
      _PaymentAiCriteriaSheetState();
}

class _PaymentAiCriteriaSheetState extends State<_PaymentAiCriteriaSheet> {
  late final TextEditingController _dateController;
  late final TextEditingController _accountController;
  late final List<TextEditingController> _feeControllers;

  InputDecoration get _fieldDecoration => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF334D61).withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
      );

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _dateController = TextEditingController(
      text: initial?.announcementDate ?? '',
    );
    _accountController = TextEditingController(
      text: initial?.accountHolderName ?? '',
    );

    final initialFees = initial?.participationFees ?? const <int>[];
    if (initialFees.isEmpty) {
      _feeControllers = [TextEditingController()];
    } else {
      _feeControllers = initialFees
          .map((fee) => TextEditingController(
                text: _ThousandsSeparatorInputFormatter.formatDigits(
                  fee.toString(),
                ),
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _accountController.dispose();
    for (final controller in _feeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addFeeField() {
    setState(() {
      _feeControllers.add(TextEditingController());
    });
  }

  void _removeFeeField(int index) {
    if (_feeControllers.length <= 1) return;
    setState(() {
      _feeControllers.removeAt(index).dispose();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _dateController.text.isNotEmpty
        ? (DateTime.tryParse(_dateController.text) ?? now)
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF334D61),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Color(0xFF334D61),
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStatePropertyAll(Colors.black),
              yearForegroundColor: WidgetStatePropertyAll(Colors.black),
              todayForegroundColor: WidgetStatePropertyAll(Color(0xFFC10230)),
              todayBorder: BorderSide(color: Color(0xFFC10230)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _dateController.text = formatted;
      setState(() {});
    }
  }

  List<int> _parseFees() {
    final fees = <int>[];
    for (final controller in _feeControllers) {
      final fee =
          int.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;
      if (fee > 0) {
        fees.add(fee);
      }
    }
    return fees;
  }

  void _submit() {
    final fees = _parseFees();
    final date = _dateController.text.trim();
    final account = _accountController.text.trim();

    if (date.isEmpty || fees.isEmpty || account.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('입력 확인'),
          content: const Text('공지일, 참가비, 받는 사람을 모두 입력해주세요.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      PaymentAiCriteria(
        announcementDate: date,
        participationFees: fees,
        accountHolderName: account,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'BETA AI 판별 기준',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '행사 공지일·참가비·받는 사람 계좌명을 입력하면\n납부 사진을 AI가 검토합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 20),
              _CriteriaField(
                label: '행사 공지일',
                child: GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dateController,
                      decoration: _fieldDecoration.copyWith(
                        hintText: 'YYYY-MM-DD',
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Color(0xFF334D61),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _CriteriaField(
                label: '참가비 (원)',
                hint: '뒤풀이 등 금액이 여러 개면 추가하세요',
                child: Column(
                  children: [
                    for (var i = 0; i < _feeControllers.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _feeControllers[i],
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                _ThousandsSeparatorInputFormatter(),
                              ],
                              decoration: _fieldDecoration.copyWith(
                                hintText: i == 0 ? '예: 5,000' : '예: 10,000',
                              ),
                            ),
                          ),
                          if (_feeControllers.length > 1) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _removeFeeField(i),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                                color: Color(0xFFC10230),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addFeeField,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('참가비 추가'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF334D61),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CriteriaField(
                label: '받는 사람',
                child: TextField(
                  controller: _accountController,
                  decoration: _fieldDecoration.copyWith(
                    hintText: '예: 홍길동',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334D61),
                        side: BorderSide(
                          color: const Color(0xFF334D61).withOpacity(0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334D61),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'AI 판별 시작',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static String formatDigits(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return oldValue;
    }

    final formatted = formatDigits(digits);
    final oldDigits = oldValue.text.replaceAll(',', '');
    final newDigits = digits;

    var cursor = formatted.length;
    if (newDigits.length >= oldDigits.length) {
      final digitsBeforeCursor = newValue.selection.end -
          _commaCount(newValue.text.substring(
            0,
            newValue.selection.end.clamp(0, newValue.text.length),
          ));
      var digitIndex = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != ',') {
          digitIndex++;
        }
        if (digitIndex >= digitsBeforeCursor) {
          cursor = i + 1;
          break;
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursor.clamp(0, formatted.length),
      ),
    );
  }

  static int _commaCount(String text) =>
      ','.allMatches(text).length;
}

class _CriteriaField extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _CriteriaField({
    required this.label,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334D61),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
